<!-- File: config.md | Documentation -->
# Configuration Schema

Use YAML (preferred) or JSON with the following fields. All times are local to `timezone`.

## Minimal Example

```yaml
timezone: "Asia/Shanghai"

gmail:
  user_id: "me"
  credentials_path: "/opt/openclawd/secrets/credentials.json"
  token_path: "/opt/openclawd/secrets/token.json"
  watch:
    topic: "projects/PROJECT_ID/topics/gmail-watch"
    label_ids: ["INBOX"]

pubsub:
  project_id: "PROJECT_ID"
  subscription: "gmail-watch-sub"
  pull_interval_seconds: 15
  max_messages: 10

telegram:
  bot_token: "123456:ABC"
  chat_id: "123456789"
  parse_mode: "MarkdownV2"

schedule:
  realtime_start: "08:00"
  realtime_end: "24:00"
  catchup_time: "07:59"

rules:
  - name: "Alerts"
    from: ["ARK Trading Desk <tradingdesk@arkfunds.com>"]
    subject_keywords: ["ALERT", "WARN"]
    labels: ["INBOX", "IMPORTANT"]
    unread_only: true

cache:
  db_path: "/var/lib/openclawd/gmail_to_tg/cache.sqlite"
  max_age_days: 7
  max_items: 2000

state_path: "/var/lib/openclawd/gmail_to_tg/state.json"

delivery:
  include_fields: ["from", "subject", "date", "snippet"]
  body_lines: 20
  include_attachments: false
```

## Notes

- `realtime_end` can be "24:00" to represent end of day.
- If current time is outside the real-time window, cache and send at `catchup_time`.
- `labels` are label names; resolve to label IDs once at startup.
- Use `parse_mode: MarkdownV2` when you escape Markdown characters.
