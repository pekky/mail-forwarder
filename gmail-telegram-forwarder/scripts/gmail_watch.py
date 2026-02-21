"""Initialize Gmail watch to Pub/Sub topic.

Requires:
- google-api-python-client
- google-auth-oauthlib
"""
from __future__ import annotations

import argparse
from pathlib import Path

from config import load_config


def build_gmail_service(credentials_path: str, token_path: str):
    try:
        from google.oauth2.credentials import Credentials
        from google_auth_oauthlib.flow import InstalledAppFlow
        from googleapiclient.discovery import build
    except Exception as exc:  # pragma: no cover
        raise RuntimeError(
            "Missing Google libraries. Install: pip install google-api-python-client google-auth-oauthlib"
        ) from exc

    scopes = ["https://www.googleapis.com/auth/gmail.readonly"]

    creds = None
    if Path(token_path).exists():
        creds = Credentials.from_authorized_user_file(token_path, scopes=scopes)

    if not creds or not creds.valid:
        flow = InstalledAppFlow.from_client_secrets_file(credentials_path, scopes=scopes)
        creds = flow.run_local_server(port=0)
        Path(token_path).write_text(creds.to_json(), encoding="utf-8")

    return build("gmail", "v1", credentials=creds, cache_discovery=False)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", required=True)
    args = parser.parse_args()

    cfg = load_config(args.config)
    gmail = cfg["gmail"]

    service = build_gmail_service(gmail["credentials_path"], gmail["token_path"])

    body = {
        "topicName": gmail["watch"]["topic"],
        "labelIds": gmail["watch"].get("label_ids", ["INBOX"]),
    }

    resp = service.users().watch(userId=gmail.get("user_id", "me"), body=body).execute()
    print("Watch response:", resp)
    print("Store historyId as last_history_id in your state store.")


if __name__ == "__main__":
    main()
