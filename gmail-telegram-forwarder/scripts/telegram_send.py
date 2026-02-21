"""Telegram send helper (MarkdownV2).

Uses urllib to avoid external dependencies.
"""
from __future__ import annotations

import json
import urllib.request
import urllib.parse

MARKDOWN_V2_ESCAPES = "_ * [ ] ( ) ~ ` > # + - = | { } . !".split()


def escape_markdown_v2(text: str) -> str:
    for ch in MARKDOWN_V2_ESCAPES:
        text = text.replace(ch, "\" + ch)
    return text


def send_message(bot_token: str, chat_id: str, text: str, parse_mode: str = "MarkdownV2") -> None:
    url = f"https://api.telegram.org/bot{bot_token}/sendMessage"
    payload = {
        "chat_id": chat_id,
        "text": text,
        "parse_mode": parse_mode,
        "disable_web_page_preview": True,
    }
    data = urllib.parse.urlencode(payload).encode("utf-8")
    req = urllib.request.Request(url, data=data, method="POST")
    with urllib.request.urlopen(req, timeout=20) as resp:
        body = resp.read().decode("utf-8")
    result = json.loads(body)
    if not result.get("ok"):
        raise RuntimeError(f"Telegram API error: {result}")
