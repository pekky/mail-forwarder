---
name: gmail-telegram-forwarder
description: Build, update, or troubleshoot an Openclawd skill that forwards Gmail messages to Telegram via a Bot using Gmail API watch + Google Pub/Sub pull (no public IP). Use when configuring sender/subject/label/unread filters, quiet-hours caching with a daily catch-up push, OAuth setup, or Markdown formatting on Raspberry Pi.
---
<!-- File: SKILL.md | Skill definition and workflow -->
# Gmail to Telegram Forwarder (Openclawd)

Follow this workflow to implement or update the Openclawd skill.

## Workflow

1. Confirm constraints and goals.
   - Assume no public IP; use Gmail API watch + Pub/Sub pull.
   - Default timezone is Asia/Shanghai unless config overrides.
   - Real-time window and catch-up time must be configurable.

2. Gather inputs.
   - Gmail OAuth `credentials.json` and `token.json` paths.
   - Google Cloud project id, Pub/Sub topic, and subscription.
   - Telegram bot token and target `chat_id`.
   - Forwarding rules: sender, subject keywords, labels, unread-only.

3. Configure Gmail watch and Pub/Sub.
   - Ensure Gmail API enabled and OAuth consent configured.
   - Create Pub/Sub topic and subscription.
   - Grant Gmail push service account publish rights.
   - Call `users.watch` with topic and label filters.
   - Persist `historyId` from the watch response.

4. Implement pull loop.
   - Pull Pub/Sub messages on a short interval.
   - Decode message payload to read `historyId`.
   - Call `users.history.list` from last stored `historyId`.
   - Fetch messages with `users.messages.get` and gather metadata.
   - Ack Pub/Sub messages only after successful processing.
   - If `historyId` is too old (404), re-sync and reset state.

5. Apply filtering rules.
   - Match sender, subject keywords, label names, and unread-only.
   - Resolve label names to IDs on startup and cache the mapping.
   - Support multiple rules; forward when any rule matches.

6. Enforce quiet hours and caching.
   - If current time is inside real-time window, send immediately.
   - Otherwise store items in a local cache (SQLite recommended).
   - At the configured catch-up time, send cached items in order.
   - De-duplicate by message id and keep a sent-log window.

7. Send Telegram messages.
   - Use Markdown formatting with escape handling.
   - Include fields specified in config (from, subject, date, snippet).
   - For long bodies, include first N lines only.

8. Persist state.
   - Store `last_history_id`.
   - Store cached items and recent sent ids.

## Read These References

- `references/config.md` for configuration schema and examples.
- `references/gmail_setup.md` for Gmail OAuth and watch setup.
- `references/pubsub_pull.md` for Pub/Sub pull + history handling.
- `references/telegram.md` for Telegram formatting and send API.
- `references/deploy.md` for Raspberry Pi OS detection and deployment.
- `references/deploy_vps_ubuntu.md` for Ubuntu VPS deployment and ClawdBot skill linkage.
- `references/systemd_service.md` for systemd service setup.
- `references/oauth_setup.md` for Gmail OAuth initialization on Pi.

## Bundled Scripts

- `scripts/gmail_watch.py` Initialize Gmail watch to Pub/Sub topic.
- `scripts/pubsub_pull.py` Pull Pub/Sub messages, apply rules, cache, and send.
- `scripts/telegram_send.py` Send formatted Telegram messages.
- `scripts/config.py` Load YAML/JSON config.
- `scripts/cache_db.py` Cache and idempotency store (SQLite).
- `scripts/pi_detect.sh` Detect OS, model, and runtime versions.
- `scripts/deploy.sh` Install deps and prepare `~/.openclawd` layout.
- `scripts/deploy_vps_ubuntu.sh` One-command Ubuntu 24.04 VPS bootstrap and skill link setup.
- `scripts/check_deps.sh` Detect and install missing dependencies.
- `scripts/venv_path_demo.sh` Demonstrate PATH precedence with venv.
- `scripts/verify_file.sh` Verify a real file path and show contents.
