#!/usr/bin/env bash

echo "Cleaning up work directory $RUNNER_HOME/_work/*"
find "${RUNNER_HOME}/_work" -mindepth 1 -type d -exec rm -rf {} +
