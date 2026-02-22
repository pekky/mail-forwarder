#!/usr/bin/env bash
# Description: Ubuntu 24.04 VPS bootstrap for Gmail -> Telegram skill and ClawdBot linkage
set -euo pipefail

SKILL_NAME="gmail-telegram-forwarder"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_SRC_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

BASE_DIR="${OPENCLAWD_BASE_DIR:-$HOME/.openclawd}"
CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"
CONFIG_PATH="${1:-$BASE_DIR/gmail_to_tg/config.yaml}"
VENV_DIR="$BASE_DIR/venv"
SECRETS_DIR="$BASE_DIR/secrets"
LOG_DIR="$BASE_DIR/logs"
DATA_DIR="$BASE_DIR/gmail_to_tg"
SKILL_LINK_DIR="$CODEX_HOME_DIR/skills"
SKILL_LINK_PATH="$SKILL_LINK_DIR/$SKILL_NAME"
SERVICE_NAME="openclawd-gmail-tg.service"
SERVICE_PATH="$HOME/.config/systemd/user/$SERVICE_NAME"

need_cmd() {
  command -v "$1" >/dev/null 2>&1
}

echo "[deploy-vps] target config: $CONFIG_PATH"

if [[ -f /etc/os-release ]]; then
  # shellcheck source=/dev/null
  source /etc/os-release
  echo "[deploy-vps] detected OS: ${PRETTY_NAME:-unknown}"
  if [[ "${ID:-}" != "ubuntu" ]]; then
    echo "[warn] This script is optimized for Ubuntu. Continuing anyway."
  fi
fi

if ! need_cmd sudo; then
  echo "[error] sudo is required on VPS setup."
  exit 1
fi

sudo apt-get update -y
sudo apt-get install -y \
  ca-certificates curl gnupg lsb-release \
  python3 python3-venv python3-pip sqlite3

if ! need_cmd node || ! node -v | grep -Eq '^v(20|21|22|23|24)\.'; then
  echo "[deploy-vps] installing Node.js 20.x"
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  sudo apt-get install -y nodejs
fi

mkdir -p "$SECRETS_DIR" "$LOG_DIR" "$DATA_DIR" "$SKILL_LINK_DIR" "$HOME/.config/systemd/user"

if [[ ! -d "$VENV_DIR" ]]; then
  python3 -m venv "$VENV_DIR"
fi

# shellcheck source=/dev/null
source "$VENV_DIR/bin/activate"
pip install --upgrade pip
pip install \
  google-api-python-client \
  google-auth \
  google-auth-oauthlib \
  google-cloud-pubsub \
  pyyaml

if [[ ! -f "$CONFIG_PATH" ]]; then
  cat > "$CONFIG_PATH" <<CFG
# Gmail -> Telegram config (edit with your real values)
timezone: "Asia/Shanghai"

gmail:
  user_id: "me"
  credentials_path: "$SECRETS_DIR/credentials.json"
  token_path: "$SECRETS_DIR/token.json"
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
  - name: "Default"
    from: []
    subject_keywords: []
    labels: ["INBOX"]
    unread_only: true

cache:
  db_path: "$DATA_DIR/cache.sqlite"
  max_age_days: 7
  max_items: 2000

state_path: "$DATA_DIR/state.json"

delivery:
  include_fields: ["from", "subject", "date", "snippet"]
  body_lines: 20
  include_attachments: false
CFG
fi

ln -sfn "$SKILL_SRC_DIR" "$SKILL_LINK_PATH"

echo "[deploy-vps] skill linked: $SKILL_LINK_PATH -> $SKILL_SRC_DIR"

cat > "$SERVICE_PATH" <<UNIT
[Unit]
Description=OpenClawd Gmail to Telegram Forwarder
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=$BASE_DIR
Environment=PYTHONUNBUFFERED=1
ExecStart=$VENV_DIR/bin/python $SKILL_LINK_PATH/scripts/pubsub_pull.py --config $CONFIG_PATH
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
UNIT

if command -v systemctl >/dev/null 2>&1 && systemctl --user daemon-reload >/dev/null 2>&1; then
  systemctl --user enable "$SERVICE_NAME"
else
  echo "[warn] systemctl --user is not available in this session. Enable service manually later:"
  echo "       systemctl --user daemon-reload"
  echo "       systemctl --user enable $SERVICE_NAME"
fi

echo "[deploy-vps] done"
echo
echo "Next steps:"
echo "1) Put Gmail OAuth client at: $SECRETS_DIR/credentials.json"
echo "2) Edit config: $CONFIG_PATH"
echo "3) Generate token: $VENV_DIR/bin/python $SKILL_LINK_PATH/scripts/gmail_watch.py --config $CONFIG_PATH"
echo "4) Start service: systemctl --user start $SERVICE_NAME"
echo "5) Follow logs: journalctl --user -u $SERVICE_NAME -f"
echo
echo "To make ClawdBot read this skill, restart your bot process after skill link update."
