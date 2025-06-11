# base
FROM ubuntu:22.04

# set the github runner version
ARG RUNNER_VERSION="2.325.0"

# set the github runner user
ARG RUNNER_USER="github"

# update the base packages and add a non-sudo user
RUN apt-get update -y && apt-get upgrade -y && useradd -m ${RUNNER_USER}

# install python and the packages the your code depends on along with jq so we can parse JSON
# add additional packages as necessary
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    curl jq build-essential libssl-dev libffi-dev python3 python3-venv python3-dev python3-pip

USER ${RUNNER_USER}
WORKDIR /home/${RUNNER_USER}

# cd into the user directory, download and unzip the github actions runner
RUN mkdir actions-runner && cd actions-runner \
    && curl -O -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && rm actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

# install some additional dependencies
USER root
RUN /home/${RUNNER_USER}/actions-runner/bin/installdependencies.sh

# copy over the start.sh script
COPY start.sh /home/${RUNNER_USER}/start.sh

# # make the script executable
RUN chmod +x /home/${RUNNER_USER}/start.sh && chown ${RUNNER_USER}:${RUNNER_USER} /home/${RUNNER_USER}/start.sh

USER ${RUNNER_USER}

# set the entrypoint to the start.sh script
ENTRYPOINT ["./start.sh"]
