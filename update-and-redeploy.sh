#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(git rev-parse --show-toplevel)"
BRANCH="main"

cd "$REPO_DIR"

git fetch origin

LOCAL_HASH=$(git rev-parse "$BRANCH")
REMOTE_HASH=$(git rev-parse "origin/$BRANCH")

if [ "$LOCAL_HASH" = "$REMOTE_HASH" ]; then
  echo "[$(date)] No new commits. Checking services only."
else
  echo "[$(date)] New commits detected: $LOCAL_HASH -> $REMOTE_HASH"

  # Stash any local uncommitted changes
  STASHED=false
  if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "[$(date)] Stashing local changes..."
    git stash save "auto-stash before update-and-redeploy"
    STASHED=true
  fi

  git pull --rebase origin "$BRANCH"

  # Reapply stashed changes if we stashed anything
  if [ "$STASHED" = true ]; then
    echo "[$(date)] Reapplying stashed changes..."
    git stash apply
  fi

  docker compose build
  docker buildx bake -f docker-compose.yml --pull
  docker compose down
fi

# Runs even without new commits so the heartbeat also reports services that
# died between updates. --wait exits non-zero if a service is not running or
# healthy within the timeout, which fails the unit and sends /fail.
docker compose up -d --wait --wait-timeout 300

echo "[$(date)] Services running and healthy."
