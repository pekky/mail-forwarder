#!/usr/bin/env bash
set -euo pipefail

CONFIG_PATH="${1:-$HOME/.openclawd/gmail_to_tg/config.yaml}"
BASE_DIR="$HOME/.openclawd"
VENV_DIR="$BASE_DIR/venv"
SECRETS_DIR="$BASE_DIR/secrets"
LOG_DIR="$BASE_DIR/logs"
DATA_DIR="$BASE_DIR/gmail_to_tg"

mkdir -p "$SECRETS_DIR" "$LOG_DIR" "$DATA_DIR"

echo "[deploy] config path: $CONFIG_PATH"

# Detect OS
if [ -f /etc/os-release ]; then
  . /etc/os-release
  OS_ID="${ID:-}"
  OS_VERSION="${VERSION_CODENAME:-}"
else
  OS_ID="unknown"
  OS_VERSION="unknown"
fi

echo "[deploy] OS: $OS_ID ($OS_VERSION)"

# Install system deps (best effort)
if command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update -y
  sudo apt-get install -y python3 python3-venv python3-pip
else
  echo "[warn] apt-get not found. Install python3, python3-venv, python3-pip manually."
fi

# Python venv
if [ ! -d "$VENV_DIR" ]; then
  python3 -m venv "$VENV_DIR"
fi

# shellcheck disable=SC1090
source "$VENV_DIR/bin/activate"

pip install --upgrade pip
pip install google-api-python-client google-auth google-auth-oauthlib google-cloud-pubsub pyyaml

# Node version check (OpenClawd expects Node 20+)
if command -v node >/dev/null 2>&1; then
  NODE_VERSION=$(node -v | sed 's/^v//')
  NODE_MAJOR=${NODE_VERSION%%.*}
  if [ "$NODE_MAJOR" -lt 20 ]; then
    echo "[warn] Node version is $NODE_VERSION (< 20). Please upgrade for OpenClawd stability."
  else
    echo "[deploy] Node version OK: $NODE_VERSION"
  fi
else
  echo "[warn] Node not found. Install Node.js 20+ for OpenClawd."
fi

echo "[deploy] Done."

echo "Next steps:"
cat <<EOF
1) Put Gmail OAuth credentials at: $SECRETS_DIR/credentials.json
2) Run gmail_watch.py to generate token.json
3) Start pubsub_pull.py (or set up a systemd service)
EOF
