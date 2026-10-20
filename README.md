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
- **setup-systemd-timer.sh**: Installs the systemd service and timer that run the automatic update on the host.
- **update-and-redeploy.sh**: Pulls new commits, rebuilds and restarts the services, and checks that they are healthy.
- **send-heartbeat.sh**: Sends the Betterstack heartbeat after each update run.
- **.env.example**: Template file showing the required environment variables for configuration.
- **.dockerignore**: Specifies which files to exclude from the Docker build context (only includes necessary scripts).
- **.gitignore**: Ensures sensitive files like `.env` and `access_token.txt` are not committed to version control.
- **.pre-commit-config.yaml**: Configuration for pre-commit hooks to maintain code quality and security.
- **README.md**: Documentation and usage instructions for this project.

## Maintenance

Github Action Runner version gets out of date. Update the Dockerfile, update the version number, e.g. v2.328.0 to v2.330.0. Then rebuild/run;

```
docker compose up -d --build
```

### Automatic updates (systemd timer)

`setup-systemd-timer.sh` installs a systemd service and timer on the host. Each run executes `update-and-redeploy.sh`, which:

1. Pulls new commits from `main` and, if there are any, rebuilds the images.
2. Runs `docker compose up -d --wait` on every run, including runs with no new commits. The run fails if a service is not running and healthy within 5 minutes.

Because step 2 runs every time, the timer also starts services that were stopped, and applies `.env` changes such as `REPLICAS`. Stop the timer (`sudo systemctl stop github-runner-docker-update.timer`) before maintenance that needs the services to stay down.

Install or update the units (run again after changes to the setup script):

```sh
sudo ./setup-systemd-timer.sh
```

Edit `ON_CALENDAR` in the script to change how often the timer runs (default: `daily`).

### Monitoring with Betterstack

The service can send a [Betterstack heartbeat](https://betterstack.com/docs/uptime/cron-and-heartbeat-monitor/) after each run:

- On success, it pings `HEARTBEAT_URL`.
- On failure (for example, a failed `git pull`, a failed build, or an unhealthy service), it pings `HEARTBEAT_URL/fail`, so Betterstack alerts at once.
- If the timer stops, no ping arrives and Betterstack alerts when the heartbeat period expires.

To set it up:

1. In Betterstack, create a heartbeat monitor. Set the period to match `ON_CALENDAR` (for example, 1 day) and add a grace period that covers a full rebuild (for example, 30 minutes).
2. Copy the heartbeat URL from the monitor's page in Betterstack and add it to `.env`:

   ```
   HEARTBEAT_URL=https://incidents.betterstack.com/api/v1/heartbeat/<token>
   ```

3. Run `sudo ./setup-systemd-timer.sh` again. This adds `ExecStopPost` to the service unit.
4. Test with `sudo systemctl start github-runner-docker-update.service`, then check the logs with `journalctl -u github-runner-docker-update.service -n 50`.

The heartbeat only checks the services when the timer runs. A runner that fails between runs is reported on the next run.

## License

This project is licensed under the [MIT License](./LICENSE).
