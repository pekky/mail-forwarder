#!/usr/bin/env bash
# Description: Verify a real file path and preview contents
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "usage: verify_file.sh /absolute/path/to/file"
  exit 1
fi

FILE="$1"

if [ ! -e "$FILE" ]; then
  echo "[verify] not found: $FILE"
  exit 1
fi

if [ -d "$FILE" ]; then
  echo "[verify] is a directory: $FILE"
  exit 1
fi

echo "[verify] path: $FILE"
ls -la "$FILE"

if command -v shasum >/dev/null 2>&1; then
  echo "[verify] sha256: $(shasum -a 256 "$FILE" | awk '{print $1}')"
fi

echo "[verify] first 20 lines:"
awk 'NR<=20 {print}' "$FILE"
