#!/usr/bin/env bash
set -euo pipefail

echo "[detect] os"
if [ -f /etc/os-release ]; then
  . /etc/os-release
  echo "NAME=${NAME:-}"
  echo "VERSION=${VERSION:-}"
  echo "VERSION_CODENAME=${VERSION_CODENAME:-}"
  echo "ID=${ID:-}"
  echo "ID_LIKE=${ID_LIKE:-}"
else
  echo "OS_RELEASE=missing"
fi

echo "[detect] kernel"
uname -a || true

echo "[detect] model"
if [ -f /proc/device-tree/model ]; then
  tr -d '\0' < /proc/device-tree/model
  echo ""
else
  echo "MODEL=missing"
fi

echo "[detect] python"
if command -v python3 >/dev/null 2>&1; then
  python3 --version
  python3 - <<'PY'
import sys
print("executable:", sys.executable)
PY
else
  echo "python3=missing"
fi

echo "[detect] node"
if command -v node >/dev/null 2>&1; then
  node -v
  command -v npm >/dev/null 2>&1 && npm -v || echo "npm=missing"
else
  echo "node=missing"
fi

echo "[detect] timezone"
if command -v timedatectl >/dev/null 2>&1; then
  timedatectl | sed -n '1,8p'
else
  date
fi

echo "[detect] disk"
df -h / || true

echo "[detect] memory"
command -v free >/dev/null 2>&1 && free -h || true
