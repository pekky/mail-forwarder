---
name: rpi-reverse-tunnel
description: Maintain resilient reverse SSH access from Raspberry Pi devices without fixed public IP by tunneling to a public VPS with autossh, reconnect logic, and outage/heartbeat notification hooks. Use when users ask for remote login back to a roaming Pi (hotel, travel, dynamic IP), reverse SSH (ssh -R), autossh setup, persistent tunnel with systemd, or disconnect alerts.
---

# Reverse Tunnel Workflow

1. Collect required variables: `VPS_HOST`, `VPS_USER`, `REMOTE_PORT`.
2. Fill environment file from `templates/rpi-reverse-tunnel.env.example`.
3. Run `scripts/deploy_pi.sh` on the Raspberry Pi to install/update service files.
4. Validate connect-back from your client machine.

# Files

- `scripts/deploy_pi.sh`: Install/update autossh, scripts, and systemd units on Pi.
- `scripts/start_tunnel.sh`: Start reverse SSH tunnel with keepalive and failure-safe options.
- `scripts/tunnel_health.sh`: Send up/down and heartbeat events to webhook endpoint.
- `templates/rpi-reverse-tunnel.service`: Persistent service template.
- `templates/rpi-reverse-tunnel.timer`: Optional heartbeat timer.
- `templates/rpi-reverse-tunnel-heartbeat.service`: Heartbeat runner for timer.
- `templates/rpi-reverse-tunnel.env.example`: Environment variable template.

# Configure Variables

Use these variables in `/etc/default/rpi-reverse-tunnel`:

- `VPS_HOST`: Public VPS hostname or IP.
- `VPS_USER`: Tunnel user on VPS.
- `VPS_PORT`: SSH port on VPS. Default `22`.
- `REMOTE_PORT`: Port exposed on VPS for connect-back.
- `LOCAL_PORT`: Pi local SSH port. Default `22`.
- `STATUS_WEBHOOK`: Optional webhook for `up`/`down` notifications.
- `HEALTHCHECK_URL`: Optional heartbeat URL.

# Deploy on Pi

- Main deploy:
  - `bash scripts/deploy_pi.sh`
- Enable timer during deploy:
  - `ENABLE_TIMER=1 bash scripts/deploy_pi.sh`
- Custom install path:
  - `INSTALL_DIR=/opt/rpi-reverse-tunnel bash scripts/deploy_pi.sh`

# Verify

- Check service: `systemctl status rpi-reverse-tunnel.service`
- Check logs: `journalctl -u rpi-reverse-tunnel.service -n 100 --no-pager`
- Connect back: `ssh -p <REMOTE_PORT> pi@<VPS_HOST>`

# VPS Requirements

Ensure VPS `sshd_config` allows forwarding:

- `AllowTcpForwarding yes`
- `GatewayPorts clientspecified` (or `yes` if required)

Restart SSH service after config changes.

# Captive Portal Constraint

If network requires web login (hotel or flight Wi-Fi), complete captive portal authentication first. Tunnel cannot establish before full internet access is available.

# Security Baseline

- Use SSH key authentication.
- Use a dedicated VPS user for tunnel.
- Restrict `REMOTE_PORT` with firewall allowlist when possible.
- Keep `REMOTE_PORT` non-default.
