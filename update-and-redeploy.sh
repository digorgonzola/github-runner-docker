#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(git rev-parse --show-toplevel)"
BRANCH="main"

cd "$REPO_DIR"

# Report every run, including failed ones, to the Betterstack heartbeat.
# Runs from the repo dir; the script's exit code is kept.
trap './send-heartbeat.sh $? || echo "Heartbeat failed." >&2' EXIT

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
fi

# No `docker compose down`: `up` already recreates containers whose image or
# config changed, and removing the network can fail while Docker is still
# releasing the old endpoints ("network ... has active endpoints").
# Runs even without new commits so the heartbeat also reports services that
# died between updates. --wait exits non-zero if a service is not running or
# healthy within the timeout, which sends /fail.
docker compose up -d --remove-orphans --wait --wait-timeout 300

echo "[$(date)] Services running and healthy."
