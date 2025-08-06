# github-runner-docker

A Dockerized self-hosted GitHub Actions runner for automating CI/CD workflows in your organization.

## Features

- Deploy a GitHub Actions runner in a Docker container
- Supports Linux-based workflows with Docker-in-Docker capabilities
- Simple configuration via environment variables or `.env` file
- Automatic runner removal on container exit to prevent orphaned runners
- Cleans up the runner's `_work` directory after each job
- Scalable deployment with configurable replicas
- Resource limits and health checks for production use

## Prerequisites

- Docker and Docker Compose installed
- A GitHub personal access token with read and write to organization self-hosted runners

## Usage

1. **Clone this repository:**

   ```sh
   git clone https://github.com/<org>/github-runner-docker.git
   cd github-runner-docker
   ```

2. **Create a `.env` file** by copying the example template and modifying the values:

   ```sh
   cp .env.example .env
   ```

   Then edit the `.env` file with your specific values:

   ```
   ORGANISATION=your_org_name
   RUNNER_GROUP=default
   LABELS=your,custom,labels
   REPLICAS=2
   ```

3. **Create a file named `access_token.txt`** in the root directory and paste your GitHub personal access token into it. This token should have permissions to manage self-hosted runners in your organization.

   ```
   github_pat_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```

   This file will be mounted as a secret in the Docker container to be read by the `start.sh` script.

   The secret is mounted via a tmpfs volume to ensure that it is not readable to the runner user (e.g. `github`).

4. **Modify the `docker-compose.yml` file** if necessary, especially deployment settings like the number of replicas or resource limits.

   The default configuration uses 2 replicas, but you can adjust this via the `REPLICAS` environment variable:
   ```yaml
   deploy:
     mode: replicated
     replicas: ${REPLICAS:-2}
   ```

   You can also adjust resource limits and health checks as needed:
   ```yaml
    resources:
      limits:
         cpus: '2'
         memory: 6144M
      reservations:
        cpus: '0.5'
        memory: 1024M
   ```

5. **Build and start the runner:**

   ```sh
   docker compose up -d
   ```

6. **Stop and remove the runner(s):**

   ```sh
   docker compose down
   ```

## Docker-in-Docker Support

This setup includes Docker-in-Docker (DinD) capabilities, allowing your GitHub Actions workflows to build and run Docker containers. This is achieved through:

- **socat service**: Acts as a proxy to expose the Docker daemon socket safely to the runner containers
- **Docker client**: Installed in the runner container to communicate with the host Docker daemon
- **Secure socket access**: The Docker socket is mounted read-only and accessed via the socat proxy at `socat:2375`

Your workflows can use Docker commands like `docker build`, `docker run`, and `docker-compose` without any additional configuration.

## Development

If you're contributing to this project, you can set up pre-commit hooks for code quality and security checks:

1. **Install pre-commit:**
   ```sh
   pip install pre-commit
   ```

2. **Install the hooks:**
   ```sh
   pre-commit install
   ```

The pre-commit configuration includes:
- Code formatting and linting checks
- YAML validation
- Security scanning with gitleaks
- Detection of private keys and large files

## File Overview

- **Dockerfile**: Builds the Docker image for the GitHub Actions runner, installing dependencies and copying setup scripts.
- **docker-compose.yml**: Defines the Docker service for the runner, including environment variables, health checks, and resource limits.
- **start.sh**: Entrypoint script that registers the runner with GitHub, configures it, and handles cleanup on shutdown.
- **cleanup.sh**: Script to clean the runner's `_work` directory after each job to ensure a fresh environment.
- **.env.example**: Template file showing the required environment variables for configuration.
- **.dockerignore**: Specifies which files to exclude from the Docker build context (only includes necessary scripts).
- **.gitignore**: Ensures sensitive files like `.env` and `access_token.txt` are not committed to version control.
- **.pre-commit-config.yaml**: Configuration for pre-commit hooks to maintain code quality and security.
- **README.md**: Documentation and usage instructions for this project.

## License

This project is licensed under the [MIT License](./LICENSE).
