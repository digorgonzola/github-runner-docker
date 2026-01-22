#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(git rev-parse --show-toplevel)"
BRANCH="main"

cd "$REPO_DIR"

git fetch origin

LOCAL_HASH=$(git rev-parse "$BRANCH")
REMOTE_HASH=$(git rev-parse "origin/$BRANCH")

if [ "$LOCAL_HASH" = "$REMOTE_HASH" ]; then
  echo "[$(date)] No new commits. Exiting."
  exit 0
fi

echo "[$(date)] New commits detected: $LOCAL_HASH -> $REMOTE_HASH"

# Stash any local uncommitted changes
STASHED=false
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "[$(date)] Stashing local changes..."
  git stash push -m "auto-stash before update-and-redeploy"
  STASHED=true
fi

git pull --rebase origin "$BRANCH"

# Reapply stashed changes if we stashed anything
if [ "$STASHED" = true ]; then
  echo "[$(date)] Reapplying stashed changes..."
  git stash pop
fi

docker compose build
docker compose down
docker compose up -d

echo "[$(date)] Update complete."
