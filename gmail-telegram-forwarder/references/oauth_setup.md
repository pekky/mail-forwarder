# Gmail OAuth Initialization (Raspberry Pi OS)

This is a one-time setup to create `token.json`.

## Prerequisites

- `credentials.json` downloaded from Google Cloud Console
- Gmail API enabled for the project
- OAuth consent screen configured

## Steps (Headless-Friendly)

1) Copy credentials to:

```
~/.openclawd/secrets/credentials.json
```

2) Create a temporary auth script on the Pi:

```bash
source ~/.openclawd/venv/bin/activate
python /Users/laibinqiang/.codex/skills/gmail-telegram-forwarder/scripts/gmail_watch.py \
  --config ~/.openclawd/gmail_to_tg/config.yaml
```

3) A browser window will open (or a URL will be printed).
   - If the Pi has no GUI, copy the URL to another machine, complete login, and paste the code back.

4) On success, `token.json` is created at:

```
~/.openclawd/secrets/token.json
```

## Notes

- Scope is `gmail.readonly` by default.
- If you need to mark as read or apply labels, switch to `gmail.modify` in `scripts/gmail_watch.py` and re-run the flow.
