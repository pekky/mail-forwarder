#!/usr/bin/env bash
# Description: Demonstrate PATH precedence with venv
set -euo pipefail

VENV_DIR="$HOME/.openclawd/venv"

if [ ! -d "$VENV_DIR" ]; then
  echo "[demo] venv not found at $VENV_DIR"
  echo "[demo] create one with: python3 -m venv $VENV_DIR"
  exit 1
fi

echo "[demo] system python: $(command -v python3)"
if command -v sqlite3 >/dev/null 2>&1; then
  echo "[demo] system sqlite3: $(command -v sqlite3)"
else
  echo "[demo] system sqlite3: not found"
fi

echo ""
echo "[demo] activating venv..."
# shellcheck disable=SC1090
source "$VENV_DIR/bin/activate"

echo "[demo] venv python: $(command -v python)"
if command -v sqlite3 >/dev/null 2>&1; then
  echo "[demo] sqlite3 after venv: $(command -v sqlite3)"
else
  echo "[demo] sqlite3 after venv: not found"
fi

# show python sqlite3 module path
python - <<'PY'
import sqlite3, sys
print("[demo] python sqlite3 module:", sqlite3.__file__)
print("[demo] python executable:", sys.executable)
PY
