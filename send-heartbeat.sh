#!/usr/bin/env bash
# Runs as ExecStopPost of the update service, so it fires after both successful
# and failed runs. systemd sets SERVICE_RESULT ("success" or a failure reason);
# HEARTBEAT_URL comes from the repo's .env via EnvironmentFile.
set -euo pipefail

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
