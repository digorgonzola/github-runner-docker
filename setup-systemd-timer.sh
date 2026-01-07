#!/usr/bin/env bash
set -euo pipefail

### CONFIG – EDIT IF NEEDED ###

# Relative path (inside the repo) to the update script
UPDATE_SCRIPT_REL="update-and-redeploy.sh"

# Systemd unit base name (without .service/.timer)
UNIT_NAME="github-runner-docker-update"

# User that should run the service (often root for docker)
RUN_AS_USER="root"

# How often to run (systemd OnCalendar format)
# Examples: "hourly", "daily", "*:0/5" (every 5 minutes), "Mon..Fri 03:00"
ON_CALENDAR="daily"

### END CONFIG ###

# Require being inside a git repo
REPO_DIR="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$REPO_DIR" ]]; then
  echo "Error: not inside a Git repository. cd into the repo before running this script."
  exit 1
fi

if [[ $EUID -ne 0 ]]; then
  echo "Please run as root, e.g.: sudo $0"
  exit 1
fi

SERVICE_PATH="/etc/systemd/system/${UNIT_NAME}.service"
TIMER_PATH="/etc/systemd/system/${UNIT_NAME}.timer"
UPDATE_SCRIPT_ABS="$REPO_DIR/$UPDATE_SCRIPT_REL"

if [[ ! -f "$UPDATE_SCRIPT_ABS" ]]; then
  echo "Error: update script not found at $UPDATE_SCRIPT_ABS"
  echo "Configure UPDATE_SCRIPT_REL correctly in this script."
  exit 1
fi

if [[ ! -x "$UPDATE_SCRIPT_ABS" ]]; then
  echo "Making update script executable: $UPDATE_SCRIPT_ABS"
  chmod +x "$UPDATE_SCRIPT_ABS"
fi

echo "Repo directory detected as: $REPO_DIR"
echo "Using update script:        $UPDATE_SCRIPT_ABS"
echo

cat > "$SERVICE_PATH" <<EOF
[Unit]
Description=Auto update and redeploy service from Git
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
User=$RUN_AS_USER
WorkingDirectory=$REPO_DIR
ExecStart=$UPDATE_SCRIPT_ABS
EOF

cat > "$TIMER_PATH" <<EOF
[Unit]
Description=Run ${UNIT_NAME}.service periodically

[Timer]
OnCalendar=$ON_CALENDAR
Persistent=true

[Install]
WantedBy=timers.target
EOF

echo "Reloading systemd daemon..."
systemctl daemon-reload

echo "Enabling and starting timer ${UNIT_NAME}.timer"
systemctl enable --now "${UNIT_NAME}.timer"

echo
echo "Setup complete."
echo "Check timer status with:  systemctl status ${UNIT_NAME}.timer"
echo "Check last run with:      journalctl -u ${UNIT_NAME}.service --no-pager -n 50"
