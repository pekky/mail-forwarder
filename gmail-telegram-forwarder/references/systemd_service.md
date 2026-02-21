# systemd Service (Raspberry Pi OS)

Use this unit to run the Pub/Sub pull loop as a background service.

## Service File

Save as:

- `~/.config/systemd/user/openclawd-gmail-tg.service`

```ini
[Unit]
Description=OpenClawd Gmail to Telegram Forwarder
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=%h/.openclawd
Environment=PYTHONUNBUFFERED=1
ExecStart=%h/.openclawd/venv/bin/python \
  /Users/laibinqiang/.codex/skills/gmail-telegram-forwarder/scripts/pubsub_pull.py \
  --config %h/.openclawd/gmail_to_tg/config.yaml
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
```

## Commands

```bash
mkdir -p ~/.config/systemd/user
cp /path/to/openclawd-gmail-tg.service ~/.config/systemd/user/

systemctl --user daemon-reload
systemctl --user enable openclawd-gmail-tg.service
systemctl --user start openclawd-gmail-tg.service
systemctl --user status openclawd-gmail-tg.service
journalctl --user -u openclawd-gmail-tg.service -f
```

## Notes

- This is a **user service**, so it runs under your user account.
- Ensure `~/.openclawd/venv` exists and dependencies are installed.
- If you need a system-wide service, create a `/etc/systemd/system/` unit and adjust paths.
