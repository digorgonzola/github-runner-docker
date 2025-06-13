FROM ubuntu:22.04 as deps

ARG RUNNER_VERSION="2.325.0"
ARG RUNNER_HOME="/opt/actions-runner"
ARG RUNNER_USER="github"

RUN apt-get update -y && apt-get upgrade -y && useradd -m ${RUNNER_USER}

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    curl jq build-essential libssl-dev libffi-dev python3 python3-venv python3-dev python3-pip

RUN mkdir -p ${RUNNER_HOME} && cd ${RUNNER_HOME} \
    && curl -O -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && rm actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

RUN bash ${RUNNER_HOME}/bin/installdependencies.sh && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN chown -R ${RUNNER_USER}:${RUNNER_USER} ${RUNNER_HOME}

FROM deps as runner

WORKDIR ${RUNNER_HOME}

# copy over scripts
COPY . .

RUN chmod +x cleanup.sh start.sh

USER ${RUNNER_USER}
