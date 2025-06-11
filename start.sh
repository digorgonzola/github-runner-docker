#!/usr/bin/env bash

get_token() {
    curl -sX POST -H "Authorization: token ${ACCESS_TOKEN}" https://api.github.com/orgs/${ORGANISATION}/actions/runners/registration-token | jq .token --raw-output
}

CONTAINER_ID=$(cat /proc/self/cgroup | grep docker | head -1 | cut -d/ -f3 | cut -c1-12)

cd ${HOME}/actions-runner

./config.sh --url https://github.com/${ORGANISATION} \
    --token $(get_token) \
    --name ${CONTAINER_ID} \
    --runnergroup ${RUNNER_GROUP} \
    --labels ${LABELS} \
    --no-default-labels \
    --disableupdate \
    --ephemeral

cleanup() {
    echo "Removing runner..."
    ./config.sh remove --token $(get_token)
}    
    
trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

./run.sh & wait $!

# Always cleanup work directory
echo "Removing work directory..."
rm -rf ${HOME}/actions-runner/_work
