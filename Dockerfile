FROM ubuntu:22.04

ARG RUNNER_VERSION="2.325.0"
ARG RUNNER_USER="github"

RUN apt-get update -y && apt-get upgrade -y && useradd -m ${RUNNER_USER}

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    curl jq build-essential libssl-dev libffi-dev python3 python3-venv python3-dev python3-pip

USER ${RUNNER_USER}
WORKDIR /home/${RUNNER_USER}

RUN mkdir actions-runner && cd actions-runner \
    && curl -O -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && rm actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

USER root
RUN actions-runner/bin/installdependencies.sh

# copy over scripts
COPY start.sh start.sh
COPY cleanup.sh cleanup.sh

# make the scripts executable
RUN chmod +x *.sh && chown ${RUNNER_USER}:${RUNNER_USER} *.sh

USER ${RUNNER_USER}

# set the entrypoint to the start.sh script
ENTRYPOINT ["./start.sh"]
