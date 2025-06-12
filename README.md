# github-runner-docker

A Dockerized self-hosted GitHub Actions runner for automating CI/CD workflows in your organization.

## Features

- Easily deploy a GitHub Actions runner in a Docker container
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
   ACCESS_TOKEN=your_github_token
   ORGANISATION=your_org_name
   RUNNER_GROUP=default
   LABELS=your,custom,labels
   ```

3. **Modify the `docker-compose.yml` file** if necessary, especially deployment settings like the number of replicas or resource limits.

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

4. **Build and start the runner:**

   ```sh
   docker compose up -d
   ```

5. **Stop and remove the runner(s):**

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
