<!-- File: telegram.md | Documentation -->
# Telegram Bot Sending

Use the Bot API `sendMessage` method. Example request:

```bash
curl -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage"   -d "chat_id=${CHAT_ID}"   -d "text=${TEXT}"   -d "parse_mode=MarkdownV2"
```

## Markdown Rules (MarkdownV2)

Escape: `_ * [ ] ( ) ~ ` > # + - = | { } . !`

## Suggested Message Layout

- Subject
- From
- Date
- Snippet or first N lines
- Optional labels
