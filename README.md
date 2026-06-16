*This project has been created as part of the 42 curriculum by hladeiro.*

# Inception (42 project)

## Description

This repository contains the "Inception" project: a small infrastructure built with Docker Compose and several dedicated containers running inside a virtual machine. The required services are:

- `nginx` acting as the only public entrypoint (TLS v1.2 or v1.3 only) on port 443
- `wordpress` running WordPress with `php-fpm` (no nginx inside the WordPress container)
- `mariadb` running MariaDB (database only)

The project requires that all images are built from your Dockerfiles (no pulling ready-made images; using Debian or Alpine stable versions), that each service runs in its own container, and that persistent data is stored in Docker named volumes located under `/home/<your_login>/data` on the host.

This README explains what is in the repository, how to build and run the project, and which design choices and constraints the project follows.

## Goals / Success criteria

- A secure NGINX reverse proxy that exposes the site on `https://<your_login>.42.fr` using TLSv1.2 or TLSv1.3 only.
- WordPress served by PHP-FPM in its own container and MariaDB in its own container.
- Two Docker named volumes: one for MariaDB data and one for WordPress files. Both volumes must be backed by host paths under `/home/<your_login>/data`.
- No secrets or plaintext passwords stored inside Dockerfiles or committed to the repository. Use `.env` for non-sensitive configuration and Docker secrets where appropriate.
- All containers restart on crash (using Docker restart policies) and do not rely on hacky infinite-loop entrypoints.

## Project layout (expected)

Top-level files and directories (example):

```
Makefile
README.md
LICENSE
inception.pdf
srcs/
  .env               # (should be gitignored)
  docker-compose.yml
  requirements/
    mariadb/
      Dockerfile
      tools/
        setup.sh
    wordpress/
      Dockerfile
      tools/
        setup.sh
    nginx/
      Dockerfile
      conf/
        default.conf
        setup.sh
  secrets/           # local-only, gitignored
```

Files in this repository of interest:
- `srcs/docker-compose.yml` — compose file that defines services, networks and volumes.
- `srcs/requirements/*/Dockerfile` — build contexts for each service (you must create and complete `tools/` and `conf/` files referenced by the Dockerfiles).
- `inception.pdf` — project statement and grading rules.

Note: replace `<your_login>` in paths and domain names with your actual 42 login.

## Prerequisites

- A virtual machine (Linux) where you have a regular user account (your 42 login).
- Docker Engine (compatible with Docker Compose) installed inside the VM.
- `docker` and `docker-compose` (or `docker compose`) available on the VM.
- `make` (GNU Make) available if you want to use the example Makefile below.

## Basic usage / commands

1. Create `srcs/.env` and `srcs/secrets` (see the Environment section below). Do NOT commit secrets to git.
2. From the repository root (`git/inception`) you can use the following example commands (these are examples; your Makefile may be slightly different):

```sh
# build all images (Makefile or direct compose)
make build
# OR
docker-compose -f srcs/docker-compose.yml --env-file srcs/.env build

# launch (detached)
make up
# OR
docker-compose -f srcs/docker-compose.yml --env-file srcs/.env up -d

# stop and remove containers
make down
# OR
docker-compose -f srcs/docker-compose.yml --env-file srcs/.env down
```

If you don't use a Makefile, be explicit about the compose file path and the env-file path as shown above.

### Example `.env` (place in `srcs/.env` and do NOT commit)

```
DOMAIN_NAME=<your_login>.42.fr
MYSQL_ROOT_PASSWORD=replace_with_strong_password
MYSQL_DATABASE=wordpress
MYSQL_USER=wp_user
MYSQL_PASSWORD=replace_with_strong_password_for_wp
WP_ADMIN_USER=siteowner     # MUST NOT contain admin/administrator
WP_ADMIN_PASSWORD=replace_with_admin_password
```

Replace the placeholders above. The README author recommends placing any truly sensitive material (passwords, API keys) in Docker secrets or a local `srcs/secrets` folder that is gitignored.

## Environment variables & secrets

- Use `srcs/.env` for non-sensitive configuration and service wiring (domain name, database name, non-sensitive usernames).
- Do not hardcode passwords in Dockerfiles. Avoid committing `.env` or credentials files to the repository. Add `srcs/.env` and `srcs/secrets` to `.gitignore`.
- Docker secrets are recommended for confidential information. Note: Docker secrets require Docker Swarm (or compatible orchestrator) to use the `secrets:` object in compose. If you cannot use Swarm, store sensitive files locally and mount them read-only into containers (but keep them out of git).

## Main design choices (what was chosen and why)

- Base image: Debian (stable) is recommended for ease of use and compatibility with PHP packages; Alpine is smaller but may require extra package adjustments. Either Debian or Alpine (stable) satisfies the project rules.
- One service per container: keep WordPress, MariaDB and NGINX isolated for clarity, portability and security.
- NGINX as single entrypoint: TLS termination and static file serving are handled by nginx; PHP-FPM runs in the WordPress container and is reached via the Docker network.
- Named volumes stored under `/home/<your_login>/data`: evaluator requires data to be accessible at that host path, so named volumes are configured to use host paths under `/home/<your_login>/data`.
- Restart policy: `restart: unless-stopped` or `restart: always` is used in compose to ensure containers restart on crash.

## Comparisons (required by the project statement)

### Virtual Machines vs Docker

- Virtual Machines:
  - Pros: strong isolation, own kernel, easy to run different OS versions; good for multi-tenant systems.
  - Cons: heavier (disk, memory), slower to start.
- Docker / Containers:
  - Pros: lightweight, fast startup, small images, easy to compose microservices, share host kernel.
  - Cons: less kernel-level isolation; careful security and capabilities management required.

Recommendation: Use a VM (as required) to host Docker; containers are used to implement the services inside the VM.

### Secrets vs Environment Variables

- Environment variables (`.env`): easy to use, but commonly accessible to anyone who can view container environment and are often mistakenly committed.
- Docker secrets: encrypted at rest in the Swarm manager and only exposed to services that need them; more secure for production use.

Recommendation: store non-sensitive configuration in `.env` (gitignored) and use Docker secrets for passwords when possible.

### Docker Network vs Host Network

- Docker network (bridge/overlay): isolates containers and provides DNS-based service discovery. Recommended for microservices.
- Host network: containers share the host network namespace (e.g., `network_mode: "host"`). This is simpler for some use cases but breaks port isolation and is not allowed for this project.

Recommendation: use a private Docker network as required by the project.

### Docker Volumes vs Bind Mounts

- Docker named volumes: managed by Docker, portable, the recommended way for persistent container data. They can be created with driver options to point at a host path if required by the evaluator.
- Bind mounts: directly mount a host directory into a container. Powerful for development, but not allowed for persistent storage in this project (named volumes required).

Recommendation: use named volumes and (when required) configure them so their backing path is under `/home/<your_login>/data`.

## How AI was used for this project

- This README and a set of suggested configuration examples and implementation steps were drafted with the assistance of ChatGPT (OpenAI).
- Tasks where AI was used: drafting this README, proposing example `.env` contents, suggesting Dockerfile/entrypoint patterns, sketching `docker-compose.yml` improvements, and producing example shell snippets.
- Important: example scripts and snippets produced by AI should be reviewed, tested and adapted before use (especially anything that manages passwords or initial database setup).

## Resources

- Docker docs: https://docs.docker.com/
- Docker Compose: https://docs.docker.com/compose/
- NGINX: https://nginx.org/
- TLS best practices: https://nginx.org/en/docs/http/configuring_https_servers.html
- WordPress docs: https://wordpress.org/documentation/
- MariaDB: https://mariadb.org/

## Next steps (checklist)

1. Replace `<your_login>` in this README and in configuration files with your actual 42 login.
2. Add `srcs/.env` with real values and do NOT commit it.
3. Create `srcs/secrets/` (gitignored) for any secret files or use Docker secrets in Swarm.
4. Add/complete the `tools/setup.sh` scripts for each service and the `nginx/conf` files referenced by the Dockerfiles.
5. Ensure Dockerfiles use Debian or Alpine stable (no `latest` tag) and do not contain passwords.
6. Add a Makefile at the repository root that calls `docker-compose` with the `--env-file` option, as required by the project statement.
7. Configure Docker named volumes so they store data under `/home/<your_login>/data` on the host.
8. Generate or provide TLS cert/key for nginx and configure nginx to allow only TLSv1.2 and TLSv1.3.
9. Verify the WordPress DB contains two users, one of them being the administrator, and that the admin username does not contain `admin` or `administrator`.
10. Test and validate: HTTPS only on port 443, no `tail -f`/infinite loop hacks, PID 1 is a real service process in each container, restart policies set, and no credentials committed.

---

If you want, I can now:
- (A) Replace `<your_login>` with your 42 login across the repo (README, compose and volume driver options) if you send your login, or
- (B) Create a `srcs/.env` example, a `Makefile`, and/or implement the basic `tools/setup.sh` scripts and nginx config files.

Tell me which of the above you want me to do next, and provide your 42 login if you want placeholders replaced automatically.
