#!/usr/bin/env bash
# Description: One-off local environment check helper
set -euo pipefail

echo "== OS =="
if [ -f /etc/os-release ]; then
  . /etc/os-release
  echo "NAME=${NAME:-}"
  echo "VERSION=${VERSION:-}"
  echo "VERSION_CODENAME=${VERSION_CODENAME:-}"
  echo "ID=${ID:-}"
  echo "ID_LIKE=${ID_LIKE:-}"
else
  echo "/etc/os-release not found"
fi

echo ""
echo "== Kernel =="
uname -a || true

echo ""
echo "== Raspberry Pi Model =="
if [ -f /proc/device-tree/model ]; then
  tr -d '\0' < /proc/device-tree/model
  echo ""
else
  echo "/proc/device-tree/model not found"
fi

echo ""
echo "== Python =="
if command -v python3 >/dev/null 2>&1; then
  python3 --version
  python3 - <<'PY'
import sys
print("executable:", sys.executable)
PY
else
  echo "python3 not found"
fi

echo ""
echo "== Node =="
if command -v node >/dev/null 2>&1; then
  node -v
  command -v npm >/dev/null 2>&1 && npm -v || echo "npm not found"
else
  echo "node not found"
fi

echo ""
echo "== Timezone =="
if command -v timedatectl >/dev/null 2>&1; then
  timedatectl | sed -n '1,6p'
else
  date
fi


echo ""
echo "== Disk =="
if command -v df >/dev/null 2>&1; then
  df -h /
fi


echo ""
echo "== Memory =="
if command -v free >/dev/null 2>&1; then
  free -h
fi
