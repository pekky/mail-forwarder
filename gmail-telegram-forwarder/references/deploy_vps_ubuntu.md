<!-- File: deploy_vps_ubuntu.md | Documentation -->
# Deployment on Ubuntu 24.04 VPS

Use this flow to deploy and link the skill for ClawdBot/Codex skill loading.

## 1) Upload/Open repo on VPS

Assume skill source path is:

- `/opt/mail-forwarder/gmail-telegram-forwarder`

## 2) Run bootstrap script

```bash
cd /opt/mail-forwarder/gmail-telegram-forwarder
bash scripts/deploy_vps_ubuntu.sh ~/.openclawd/gmail_to_tg/config.yaml
```

This script will:

- install system deps and Node.js 20
- create `~/.openclawd/{venv,secrets,logs,gmail_to_tg}`
- install Python packages
- create config file if missing
- link skill to `~/.codex/skills/gmail-telegram-forwarder`
- generate a systemd user unit `openclawd-gmail-tg.service`

## 3) Put secrets and update config

- `~/.openclawd/secrets/credentials.json` (Gmail OAuth client)
- edit `~/.openclawd/gmail_to_tg/config.yaml`
  - set `project_id`, `topic`, `subscription`
  - set Telegram `bot_token`, `chat_id`

## 4) Generate Gmail token

```bash
~/.openclawd/venv/bin/python ~/.codex/skills/gmail-telegram-forwarder/scripts/gmail_watch.py \
  --config ~/.openclawd/gmail_to_tg/config.yaml
```

## 5) Start forwarder service

```bash
systemctl --user start openclawd-gmail-tg.service
systemctl --user status openclawd-gmail-tg.service
journalctl --user -u openclawd-gmail-tg.service -f
```

## 6) Connect ClawdBot to this skill

ClawdBot reads local skills from `~/.codex/skills`.

Check link:

```bash
ls -la ~/.codex/skills/gmail-telegram-forwarder
```

If missing, create manually:

```bash
ln -sfn /opt/mail-forwarder/gmail-telegram-forwarder ~/.codex/skills/gmail-telegram-forwarder
```

Then restart your ClawdBot process so it reloads the skill index.

Common restart forms:

```bash
systemctl --user restart clawdbot.service
# or
systemctl --user restart openclawd.service
```

If your service name differs, list it first:

```bash
systemctl --user list-units --type=service | grep -Ei 'clawd|codex|openclawd'
```
