#!/usr/bin/env bash
# Runs as ExecStopPost of the update service, so it fires after both successful
# and failed runs. systemd sets SERVICE_RESULT ("success" or a failure reason).
set -euo pipefail

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
if [[ "${SERVICE_RESULT:-}" != "success" ]]; then
  url="${HEARTBEAT_URL%/}/fail"
fi

curl -fsS --max-time 10 --retry 3 -o /dev/null "$url"
echo "Heartbeat sent (result: ${SERVICE_RESULT:-unknown})."
