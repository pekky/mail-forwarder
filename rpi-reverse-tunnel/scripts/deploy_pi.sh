#!/usr/bin/env bash
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_DIR="${INSTALL_DIR:-/opt/rpi-reverse-tunnel}"
ENV_PATH="${ENV_PATH:-/etc/default/rpi-reverse-tunnel}"
SERVICE_NAME="rpi-reverse-tunnel.service"
TIMER_NAME="rpi-reverse-tunnel.timer"
HEARTBEAT_SERVICE="rpi-reverse-tunnel-heartbeat.service"
ENABLE_TIMER="${ENABLE_TIMER:-0}"

run_as_root() {
  if [[ "${EUID}" -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "[error] missing command: $1" >&2
    exit 1
  }
}

need_cmd bash
need_cmd install

if ! command -v autossh >/dev/null 2>&1; then
  echo "[deploy] autossh not found, installing..."
  if command -v apt-get >/dev/null 2>&1; then
    run_as_root apt-get update -y
    run_as_root apt-get install -y autossh openssh-client curl
  else
    echo "[error] autossh not installed and apt-get unavailable; install autossh manually." >&2
    exit 1
  fi
fi

echo "[deploy] installing files to ${INSTALL_DIR}"
run_as_root mkdir -p "${INSTALL_DIR}/scripts" "${INSTALL_DIR}/templates"
run_as_root install -m 0755 "${SKILL_DIR}/scripts/start_tunnel.sh" "${INSTALL_DIR}/scripts/start_tunnel.sh"
run_as_root install -m 0755 "${SKILL_DIR}/scripts/tunnel_health.sh" "${INSTALL_DIR}/scripts/tunnel_health.sh"

run_as_root install -m 0644 "${SKILL_DIR}/templates/rpi-reverse-tunnel.service" "/etc/systemd/system/${SERVICE_NAME}"
run_as_root install -m 0644 "${SKILL_DIR}/templates/rpi-reverse-tunnel.timer" "/etc/systemd/system/${TIMER_NAME}"
run_as_root install -m 0644 "${SKILL_DIR}/templates/rpi-reverse-tunnel-heartbeat.service" "/etc/systemd/system/${HEARTBEAT_SERVICE}"

if [[ ! -f "${ENV_PATH}" ]]; then
  echo "[deploy] creating env file at ${ENV_PATH}"
  run_as_root install -m 0644 "${SKILL_DIR}/templates/rpi-reverse-tunnel.env.example" "${ENV_PATH}"
  echo "[next] edit ${ENV_PATH} and fill VPS_HOST/VPS_USER/REMOTE_PORT before first start"
fi

echo "[deploy] reloading and enabling service"
run_as_root systemctl daemon-reload
run_as_root systemctl enable --now "${SERVICE_NAME}"

if [[ "${ENABLE_TIMER}" == "1" ]]; then
  echo "[deploy] enabling heartbeat timer"
  run_as_root systemctl enable --now "${TIMER_NAME}"
fi

echo "[ok] deployment complete"
echo "[check] systemctl status ${SERVICE_NAME}"
echo "[check] journalctl -u ${SERVICE_NAME} -n 100 --no-pager"
