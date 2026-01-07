#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(git rev-parse --show-toplevel)"
BRANCH="main"

cd "$REPO_DIR"

git fetch origin "$BRANCH"

LOCAL_HASH=$(git rev-parse "$BRANCH")
REMOTE_HASH=$(git rev-parse "origin/$BRANCH")

if [ "$LOCAL_HASH" = "$REMOTE_HASH" ]; then
  echo "[$(date)] No new commits. Exiting."
  exit 0
fi

echo "[$(date)] New commits detected: $LOCAL_HASH -> $REMOTE_HASH"

git pull --rebase origin "$BRANCH"

docker compose build
docker compose down
docker compose up -d

echo "[$(date)] Update complete."
