# Deployment (Raspberry Pi OS)

This skill includes two helper scripts:

- `scripts/pi_detect.sh` prints OS, model, and runtime details.
- `scripts/deploy.sh` installs Python dependencies and prepares `~/.openclawd`.

## Usage

```bash
bash scripts/pi_detect.sh
```

```bash
bash scripts/deploy.sh ~/.openclawd/gmail_to_tg/config.yaml
```

After deployment, place credentials at `~/.openclawd/secrets/credentials.json`, then run:

```bash
python scripts/gmail_watch.py --config ~/.openclawd/gmail_to_tg/config.yaml
python scripts/pubsub_pull.py --config ~/.openclawd/gmail_to_tg/config.yaml
```
