FROM ubuntu:22.04 AS deps

ARG RUNNER_VERSION="2.327.1"
ARG RUNNER_HOME="/opt/actions-runner"
ARG RUNNER_USER="github"

RUN apt-get update -y && apt-get upgrade -y && useradd -m ${RUNNER_USER}

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    gettext-base \
    jq \
    libffi-dev \
    libssl-dev \
    python3 \
    python3-dev \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc \
    && chmod a+r /etc/apt/keyrings/docker.asc

RUN echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update -y \
    && apt-get install -y --no-install-recommends \
    containerd.io \
    docker-buildx-plugin \
    docker-ce \
    docker-ce-cli \
    docker-compose-plugin \
    && usermod -a -G docker ${RUNNER_USER} \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p ${RUNNER_HOME} && chown -R ${RUNNER_USER}:${RUNNER_USER} ${RUNNER_HOME}

USER ${RUNNER_USER}
RUN cd ${RUNNER_HOME} \
    && curl -O -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && rm actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

USER root
RUN bash ${RUNNER_HOME}/bin/installdependencies.sh && rm -rf /var/lib/apt/lists/*

FROM deps AS runner

WORKDIR ${RUNNER_HOME}

# copy over scripts
COPY . .

RUN envsubst < cleanup.sh > cleanup.sh.tmp && mv cleanup.sh.tmp cleanup.sh

RUN chmod +x cleanup.sh start.sh

USER ${RUNNER_USER}
