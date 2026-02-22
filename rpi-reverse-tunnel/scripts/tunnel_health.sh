#!/usr/bin/env bash
set -euo pipefail

STATUS_WEBHOOK="${STATUS_WEBHOOK:-}"
HEALTHCHECK_URL="${HEALTHCHECK_URL:-}"

send_webhook() {
  local text="$1"
  [[ -z "${STATUS_WEBHOOK}" ]] && return 0
  curl -fsS -X POST -d "text=${text}" "${STATUS_WEBHOOK}" >/dev/null || true
}

send_heartbeat() {
  [[ -z "${HEALTHCHECK_URL}" ]] && return 0
  curl -fsS "${HEALTHCHECK_URL}" >/dev/null || true
}

case "${1:-}" in
  up)
    send_webhook "[rpi-tunnel] up $(date '+%F %T')"
    send_heartbeat
    ;;
  down)
    send_webhook "[rpi-tunnel] down $(date '+%F %T')"
    ;;
  beat)
    send_heartbeat
    ;;
  *)
    echo "usage: $0 {up|down|beat}" >&2
    exit 1
    ;;
esac
