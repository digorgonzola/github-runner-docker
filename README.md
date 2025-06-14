# github-runner-docker

A Dockerized self-hosted GitHub Actions runner for automating CI/CD workflows in your organization.

## Features

- Deploy a GitHub Actions runner in a Docker container
- Supports Linux-based workflows
- Simple configuration via environment variables or `.env` file
- Automatic runner removal on container exit to prevent orphaned runners
- Cleans up the runner's `_work` directory after each job

## Prerequisites

- Docker and Docker Compose installed
- A GitHub personal access token with read and write to organization self-hosted runners

## Usage

1. **Clone this repository:**

   ```sh
   git clone https://github.com/isw-kudos/github-runner-docker.git
   cd github-runner-docker
   ```

2. **Create a `.env` file** with the following variables:

   ```
   ORGANISATION=your_org_name
   RUNNER_GROUP=default
   LABELS=your,custom,labels
   ```

3. **Create a file named `access_token.txt`** in the root directory and paste your GitHub personal access token into it. This token should have permissions to manage self-hosted runners in your organization.

   ```
   github_pat_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```

   This file will be mounted as a secret in the Docker container to be read by the `start.sh` script.

   The secret is mounted via a tmpfs volume to ensure that it is not readable to the runner user (e.g. `github`).

4. **Modify the `docker-compose.yml` file** if necessary, especially deployment settings like the number of replicas or resource limits.

   ```yaml
   deploy:
     mode: replicated
     replicas: 3
   ```

   You can also adjust resource limits and health checks as needed:
   ```yaml
    resources:
      limits:
         cpus: '1.0'
         memory: 2G
      reservations:
        cpus: '0.5'
        memory: 1G
   ```

5. **Build and start the runner:**

   ```sh
   docker compose up -d
   ```

6. **Stop and remove the runner(s):**

   ```sh
   docker compose down
   ```

## File Overview

- **Dockerfile**: Builds the Docker image for the GitHub Actions runner, installing dependencies and copying setup scripts.
- **docker-compose.yml**: Defines the Docker service for the runner, including environment variables, health checks, and resource limits.
- **start.sh**: Entrypoint script that registers the runner with GitHub, configures it, and handles cleanup on shutdown.
- **cleanup.sh**: Script to clean the runner's `_work` directory after each job to ensure a fresh environment.
- **.gitignore**: Ensures sensitive files like `.env` are not committed to version control.
- **README.md**: Documentation and usage instructions for this project.

## License

This project is licensed under the [MIT License](./LICENSE).
