#!/usr/bin/env bash

get_token() {
    curl -sX POST -H "Authorization: token ${ACCESS_TOKEN}" https://api.github.com/orgs/${ORGANISATION}/actions/runners/registration-token | jq .token --raw-output
}

CONTAINER_ID=$(awk -F/ '/docker/ {print substr($3,1,12); exit}' /proc/self/cgroup)

cd "${HOME}"/actions-runner || exit 1

config_options=()
config_options+=("--url" "https://github.com/${ORGANISATION}")
config_options+=("--token" "$(get_token)")
config_options+=("--name" "${CONTAINER_ID}")
config_options+=("--disableupdate")
config_options+=("--runnergroup" "${RUNNER_GROUP}")
[[ -n "$LABELS" ]] && config_options+=("--labels" "${LABELS}")
[[ "$EPHEMERAL" = true ]] && config_options+=("--ephemeral")

./config.sh "${config_options[@]}"

echo "ACTIONS_RUNNER_HOOK_JOB_COMPLETED=${HOME}/cleanup.sh" >> .env

cleanup() {
    echo "Removing runner..."
    ./config.sh remove --token "$(get_token)"
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

./run.sh & wait $!
