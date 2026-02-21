"""Pub/Sub pull loop + Gmail history processing.

Requires:
- google-cloud-pubsub
- google-api-python-client
- google-auth-httplib2
- google-auth
"""
from __future__ import annotations

import argparse
import base64
import json
import time
from datetime import datetime, time as dtime
from zoneinfo import ZoneInfo

from cache_db import already_sent, enqueue, dequeue_all, init_db, mark_sent
from config import load_config
from telegram_send import escape_markdown_v2, send_message


def within_realtime_window(now: datetime, start_hhmm: str, end_hhmm: str) -> bool:
    start_h, start_m = map(int, start_hhmm.split(":"))
    end_h, end_m = map(int, end_hhmm.split(":"))
    start = dtime(start_h, start_m)
    if end_h == 24 and end_m == 0:
        end = dtime(23, 59, 59)
    else:
        end = dtime(end_h, end_m)

    now_t = now.time()
    if start <= end:
        return start <= now_t <= end
    # Overnight window
    return now_t >= start or now_t <= end


def is_catchup_time(now: datetime, catchup_hhmm: str) -> bool:
    h, m = map(int, catchup_hhmm.split(":"))
    return now.hour == h and now.minute == m


def build_gmail_service(credentials_path: str, token_path: str):
    try:
        from google.oauth2.credentials import Credentials
        from googleapiclient.discovery import build
    except Exception as exc:  # pragma: no cover
        raise RuntimeError(
            "Missing Google libraries. Install: pip install google-api-python-client google-auth"
        ) from exc

    scopes = ["https://www.googleapis.com/auth/gmail.readonly"]
    creds = Credentials.from_authorized_user_file(token_path, scopes=scopes)
    return build("gmail", "v1", credentials=creds, cache_discovery=False)


def load_state(path: str) -> dict:
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        return {}


def save_state(path: str, state: dict) -> None:
    with open(path, "w", encoding="utf-8") as f:
        json.dump(state, f)


def build_pubsub_client():
    try:
        from google.cloud import pubsub_v1
    except Exception as exc:  # pragma: no cover
        raise RuntimeError("Missing Pub/Sub client. Install: pip install google-cloud-pubsub") from exc
    return pubsub_v1.SubscriberClient()


def pull_messages(subscriber, subscription_path: str, max_messages: int):
    response = subscriber.pull(subscription=subscription_path, max_messages=max_messages, timeout=10)
    return response.received_messages


def ack_messages(subscriber, subscription_path: str, ack_ids: list[str]) -> None:
    if ack_ids:
        subscriber.acknowledge(subscription=subscription_path, ack_ids=ack_ids)


def format_message(meta: dict, delivery_cfg: dict) -> str:
    parts = []
    if "subject" in delivery_cfg["include_fields"]:
        parts.append(f"*Subject:* {escape_markdown_v2(meta.get('subject',''))}")
    if "from" in delivery_cfg["include_fields"]:
        parts.append(f"*From:* {escape_markdown_v2(meta.get('from',''))}")
    if "date" in delivery_cfg["include_fields"]:
        parts.append(f"*Date:* {escape_markdown_v2(meta.get('date',''))}")
    if "snippet" in delivery_cfg["include_fields"]:
        parts.append(f"*Snippet:* {escape_markdown_v2(meta.get('snippet',''))}")
    return "\n".join(parts)


def match_rules(meta: dict, rules: list[dict]) -> bool:
    sender = meta.get("from", "")
    subject = meta.get("subject", "")
    labels = set(meta.get("labels", []))
    unread = meta.get("unread", False)

    for rule in rules:
        if rule.get("from") and sender not in rule["from"]:
            continue
        if rule.get("subject_keywords"):
            if not any(k in subject for k in rule["subject_keywords"]):
                continue
        if rule.get("labels"):
            if not labels.intersection(rule["labels"]):
                continue
        if rule.get("unread_only") and not unread:
            continue
        return True
    return False


def list_labels(service, user_id: str) -> tuple[dict, dict]:
    resp = service.users().labels().list(userId=user_id).execute()
    labels = resp.get("labels", [])
    id_to_name = {l["id"]: l["name"] for l in labels}
    name_to_id = {l["name"]: l["id"] for l in labels}
    return id_to_name, name_to_id


def get_profile_history_id(service, user_id: str) -> str:
    profile = service.users().getProfile(userId=user_id).execute()
    return profile.get("historyId")


def history_message_ids(service, user_id: str, start_history_id: str) -> list[str]:
    message_ids = []
    page_token = None
    while True:
        resp = (
            service.users()
            .history()
            .list(
                userId=user_id,
                startHistoryId=start_history_id,
                historyTypes=["messageAdded", "labelAdded"],
                pageToken=page_token,
            )
            .execute()
        )
        for h in resp.get("history", []):
            for msg in h.get("messages", []):
                if "id" in msg:
                    message_ids.append(msg["id"])
        page_token = resp.get("nextPageToken")
        if not page_token:
            break
    return list(dict.fromkeys(message_ids))


def get_message_meta(service, user_id: str, message_id: str, id_to_name: dict) -> dict:
    msg = (
        service.users()
        .messages()
        .get(
            userId=user_id,
            id=message_id,
            format="metadata",
            metadataHeaders=["From", "Subject", "Date"],
        )
        .execute()
    )
    headers = {h["name"]: h["value"] for h in msg.get("payload", {}).get("headers", [])}
    label_ids = msg.get("labelIds", [])
    label_names = [id_to_name.get(l, l) for l in label_ids]
    return {
        "id": msg.get("id"),
        "thread_id": msg.get("threadId"),
        "from": headers.get("From", ""),
        "subject": headers.get("Subject", ""),
        "date": headers.get("Date", ""),
        "snippet": msg.get("snippet", ""),
        "labels": label_names,
        "unread": "UNREAD" in label_ids,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", required=True)
    args = parser.parse_args()

    cfg = load_config(args.config)
    tz = ZoneInfo(cfg.get("timezone", "Asia/Shanghai"))

    init_db(cfg["cache"]["db_path"])

    subscriber = build_pubsub_client()
    subscription_path = subscriber.subscription_path(cfg["pubsub"]["project_id"], cfg["pubsub"]["subscription"])

    gmail = cfg["gmail"]
    gmail_service = build_gmail_service(gmail["credentials_path"], gmail["token_path"])
    user_id = gmail.get("user_id", "me")

    id_to_name, _ = list_labels(gmail_service, user_id)

    telegram_cfg = cfg["telegram"]
    schedule = cfg["schedule"]
    delivery_cfg = cfg["delivery"]

    state_path = cfg.get("state_path", f"{cfg['cache']['db_path']}.state.json")
    state = load_state(state_path)
    last_history_id = state.get("last_history_id")

    while True:
        now = datetime.now(tz)

        if is_catchup_time(now, schedule["catchup_time"]):
            for message_id, payload in dequeue_all(cfg["cache"]["db_path"]):
                if already_sent(cfg["cache"]["db_path"], message_id):
                    continue
                send_message(telegram_cfg["bot_token"], telegram_cfg["chat_id"], payload, telegram_cfg.get("parse_mode", "MarkdownV2"))
                mark_sent(cfg["cache"]["db_path"], message_id)

        received = pull_messages(subscriber, subscription_path, cfg["pubsub"].get("max_messages", 10))
        ack_ids = []

        for rmsg in received:
            try:
                data = json.loads(base64.b64decode(rmsg.message.data).decode("utf-8"))
                history_id = data.get("historyId")

                if last_history_id is None:
                    last_history_id = history_id
                    state["last_history_id"] = last_history_id
                    save_state(state_path, state)
                    ack_ids.append(rmsg.ack_id)
                    continue

                try:
                    message_ids = history_message_ids(gmail_service, user_id, last_history_id)
                except Exception as exc:
                    status_code = getattr(exc, "status_code", None)
                    if status_code is None and getattr(exc, "resp", None) is not None:
                        status_code = getattr(exc.resp, "status", None)
                    if status_code == 404:
                        last_history_id = get_profile_history_id(gmail_service, user_id)
                        state["last_history_id"] = last_history_id
                        save_state(state_path, state)
                        ack_ids.append(rmsg.ack_id)
                        continue
                    raise

                for message_id in message_ids:
                    if already_sent(cfg["cache"]["db_path"], message_id):
                        continue
                    meta = get_message_meta(gmail_service, user_id, message_id, id_to_name)
                    if not match_rules(meta, cfg["rules"]):
                        continue

                    text = format_message(meta, delivery_cfg)
                    if within_realtime_window(now, schedule["realtime_start"], schedule["realtime_end"]):
                        send_message(
                            telegram_cfg["bot_token"],
                            telegram_cfg["chat_id"],
                            text,
                            telegram_cfg.get("parse_mode", "MarkdownV2"),
                        )
                        mark_sent(cfg["cache"]["db_path"], message_id)
                    else:
                        enqueue(cfg["cache"]["db_path"], message_id, text)

                last_history_id = history_id
                state["last_history_id"] = last_history_id
                save_state(state_path, state)

                ack_ids.append(rmsg.ack_id)
            except Exception:
                # Leave unacked so it can be retried
                continue

        ack_messages(subscriber, subscription_path, ack_ids)
        time.sleep(cfg["pubsub"].get("pull_interval_seconds", 15))


if __name__ == "__main__":
    main()
