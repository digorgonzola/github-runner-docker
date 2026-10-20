#!/usr/bin/env bash
# Usage: send-heartbeat.sh <exit-code>
# Called from the EXIT trap in update-and-redeploy.sh. The exit code is passed
# in rather than read from systemd's SERVICE_RESULT, which needs systemd 232+
# (CentOS 7 ships 219).
set -euo pipefail

exit_code="${1:?usage: send-heartbeat.sh <exit-code>}"

# Read only this key from .env: loading the whole file via systemd's
# EnvironmentFile would override docker compose's own .env parsing, and the
# two parsers differ (e.g. inline comments, interpolation).
if [[ -z "${HEARTBEAT_URL:-}" && -f .env ]]; then
  HEARTBEAT_URL=$(sed -n 's/^HEARTBEAT_URL=//p' .env | tail -n 1 | tr -d "\"'")
fi

if [[ -z "${HEARTBEAT_URL:-}" ]]; then
  echo "HEARTBEAT_URL not set; skipping heartbeat."
  exit 0
fi

url="$HEARTBEAT_URL"
if [[ "$exit_code" != "0" ]]; then
  url="${HEARTBEAT_URL%/}/fail"
fi

curl -fsS --max-time 10 --retry 3 -o /dev/null "$url"
echo "Heartbeat sent (exit code: $exit_code)."
