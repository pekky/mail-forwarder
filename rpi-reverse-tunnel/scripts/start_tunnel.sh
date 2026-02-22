#!/usr/bin/env bash
set -euo pipefail

VPS_HOST="${VPS_HOST:?missing VPS_HOST}"
VPS_USER="${VPS_USER:?missing VPS_USER}"
VPS_PORT="${VPS_PORT:-22}"
REMOTE_PORT="${REMOTE_PORT:?missing REMOTE_PORT}"
LOCAL_PORT="${LOCAL_PORT:-22}"

exec /usr/bin/autossh \
  -M 0 \
  -N \
  -o "ServerAliveInterval=30" \
  -o "ServerAliveCountMax=3" \
  -o "ExitOnForwardFailure=yes" \
  -o "StrictHostKeyChecking=accept-new" \
  -p "${VPS_PORT}" \
  -R "${REMOTE_PORT}:127.0.0.1:${LOCAL_PORT}" \
  "${VPS_USER}@${VPS_HOST}"
