#!/usr/bin/env bash

ACCESS_TOKEN=$(cat "${ACCESS_TOKEN_SECRET_FILE}")

# Usage: fetch_token registration-token|remove-token
# Fails instead of printing "null", which config.sh would otherwise send to GitHub
# and get back an unhelpful 404 from the runner-registration endpoint.
fetch_token() {
    local response token
    response=$(curl -sSX POST -H "Authorization: token ${ACCESS_TOKEN}" https://api.github.com/orgs/"${ORGANISATION}"/actions/runners/"$1")
    token=$(jq -r '.token // empty' <<< "${response}" 2> /dev/null)
    if [[ -z "${token}" ]]; then
        echo "ERROR: could not fetch $1 for organisation '${ORGANISATION}': $(jq -r '.message // empty' <<< "${response}" 2> /dev/null)" >&2
        echo "Check that the access token in ${ACCESS_TOKEN_SECRET_FILE} is valid and can manage the organisation's self-hosted runners." >&2
        return 1
    fi
    echo "${token}"
}

CONTAINER_ID=$(grep -oP '(?<=docker/containers/)[a-f0-9]{12}' /proc/self/mountinfo | head -1)

REGISTRATION_TOKEN=$(fetch_token registration-token) || exit 1

config_options=()
config_options+=("--url" "https://github.com/${ORGANISATION}")
config_options+=("--token" "${REGISTRATION_TOKEN}")
config_options+=("--name" "${CONTAINER_ID}")
config_options+=("--disableupdate")
config_options+=("--runnergroup" "${RUNNER_GROUP}")
[[ -n "$LABELS" ]] && config_options+=("--labels" "${LABELS}")
[[ "$EPHEMERAL" = true ]] && config_options+=("--ephemeral")

su "${RUNNER_USER}" -c "./config.sh ${config_options[*]}"

echo "ACTIONS_RUNNER_HOOK_JOB_COMPLETED=${RUNNER_HOME}/cleanup.sh" >> .env

cleanup() {
    echo "Removing runner..."
    local remove_token
    remove_token=$(fetch_token remove-token) || return 1
    su "${RUNNER_USER}" -c "./config.sh remove --token ${remove_token}"
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

su "${RUNNER_USER}" -c "./run.sh" & wait $!
