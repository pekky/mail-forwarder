#!/usr/bin/env bash
# Description: Check and install missing system dependencies
set -euo pipefail

missing=()

need_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    missing+=("$cmd")
  fi
}

need_cmd python3
need_cmd pip3
need_cmd sqlite3
need_cmd node
need_cmd npm

if [ ${#missing[@]} -eq 0 ]; then
  echo "[deps] all required commands are installed."
  exit 0
fi

echo "[deps] missing: ${missing[*]}"

if command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update -y
  for m in "${missing[@]}"; do
    case "$m" in
      python3)
        sudo apt-get install -y python3 python3-venv
        ;;
      pip3)
        sudo apt-get install -y python3-pip
        ;;
      sqlite3)
        sudo apt-get install -y sqlite3
        ;;
      node|npm)
        echo "[deps] Installing Node.js 20.x via NodeSource..."
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt-get install -y nodejs
        ;;
      *)
        echo "[deps] unknown dependency: $m"
        ;;
    esac
  done
else
  echo "[deps] apt-get not found. Install manually: ${missing[*]}"
  exit 1
fi
