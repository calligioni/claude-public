---
name: run-local
description: Start local development environment with automatic dependency installation, service orchestration, and health checks. Use when developers ask to run locally, start dev server, launch the app, or spin up the development environment.
user-invocable: true
context: fork
model: haiku
allowed-tools:
  - Bash
  - Read
  - Write
  - Glob
  - Grep
  - AskUserQuestion
inject:
  - bash: ls package.json pyproject.toml go.mod Cargo.toml docker-compose.yml .run-local.json 2>/dev/null
---

# Run Local - Development Environment Manager

Automatically detect, configure, and start local development environments for any project.

## Commands

- `/run-local` - Start local development (creates run script if missing)
- `/run-local status` - Check health of all running services
- `/run-local stop` - Stop all running services
- `/run-local logs` - Show aggregated logs from all services

## What It Does

This skill automatically:

1. Checks for existing `.run-local.json` config or `scripts/run-local.sh`
2. If missing, analyzes the project to detect services and dependencies
3. Creates a run script tailored to the project
4. Installs all required dependencies
5. Starts all services (backend, frontend, databases, etc.)
6. Runs health checks to confirm everything is working

## Discovery Flow

When run in a project without configuration:

```
Analyzing project structure...

Detected Services:
| Service    | Type       | Port  | Start Command           |
|------------|------------|-------|-------------------------|
| api        | Node.js    | 3001  | npm run dev             |
| frontend   | Next.js    | 3000  | npm run dev             |
| postgres   | Database   | 5432  | docker-compose up -d    |
| redis      | Cache      | 6379  | docker-compose up -d    |

Dependencies to install:
- Node.js packages (package.json)
- Python packages (requirements.txt)
- Docker containers (docker-compose.yml)

Proceed with setup? [Yes/No]
```

## Configuration

The skill uses `.run-local.json` in the project root:

```json
{
  "services": [
    {
      "name": "api",
      "type": "nodejs",
      "path": "./apps/api",
      "port": 3001,
      "start": "npm run dev",
      "healthCheck": "http://localhost:3001/health",
      "env": {
        "NODE_ENV": "development"
      }
    },
    {
      "name": "frontend",
      "type": "nextjs",
      "path": "./apps/web",
      "port": 3000,
      "start": "npm run dev",
      "healthCheck": "http://localhost:3000",
      "dependsOn": ["api"]
    },
    {
      "name": "postgres",
      "type": "docker",
      "container": "postgres:15",
      "port": 5432,
      "healthCheck": "pg_isready -h localhost -p 5432"
    }
  ],
  "dependencies": {
    "install": [
      { "path": ".", "command": "pnpm install" },
      { "path": "./apps/api", "command": "pip install -r requirements.txt" }
    ],
    "preStart": ["docker-compose up -d postgres redis"]
  },
  "healthCheck": {
    "timeout": 60,
    "interval": 2
  }
}
```

### Config Fields

| Field                    | Type   | Description                              |
| ------------------------ | ------ | ---------------------------------------- |
| `services`               | array  | List of services to manage               |
| `services[].name`        | string | Service identifier                       |
| `services[].type`        | string | nodejs, python, nextjs, docker, go, etc. |
| `services[].path`        | string | Working directory for the service        |
| `services[].port`        | number | Port the service runs on                 |
| `services[].start`       | string | Command to start the service             |
| `services[].healthCheck` | string | URL or command to verify service health  |
| `services[].dependsOn`   | array  | Services that must start first           |
| `services[].env`         | object | Environment variables                    |
| `dependencies.install`   | array  | Dependency installation commands         |
| `dependencies.preStart`  | array  | Commands to run before starting services |
| `healthCheck.timeout`    | number | Max seconds to wait for health checks    |
| `healthCheck.interval`   | number | Seconds between health check attempts    |

## Project Detection

The skill automatically detects:

### Package Managers

- `package.json` → npm/yarn/pnpm
- `pnpm-workspace.yaml` → pnpm monorepo
- `requirements.txt` / `pyproject.toml` → pip/poetry
- `go.mod` → Go modules
- `Cargo.toml` → Rust/Cargo

### Frameworks

- `next.config.*` → Next.js (port 3000)
- `vite.config.*` → Vite (port 5173)
- `angular.json` → Angular (port 4200)
- `manage.py` → Django (port 8000)
- `main.go` / `cmd/` → Go server
- `Dockerfile` / `docker-compose.yml` → Docker services

### Databases

- `docker-compose.yml` with postgres/mysql/redis → Docker databases
- `.env` with DATABASE_URL → Database connection

## Example Output

```
Starting local development environment...

[1/4] Installing dependencies...
  ✓ pnpm install (root)
  ✓ pip install -r requirements.txt (apps/api)

[2/4] Starting infrastructure...
  ✓ docker-compose up -d postgres redis
  • Waiting for postgres... ready (port 5432)
  • Waiting for redis... ready (port 6379)

[3/4] Starting services...
  ✓ api started (http://localhost:3001)
  ✓ frontend started (http://localhost:3000)

[4/4] Health checks...
  ✓ api: healthy (http://localhost:3001/health)
  ✓ frontend: healthy (http://localhost:3000)
  ✓ postgres: healthy (pg_isready)
  ✓ redis: healthy (redis-cli ping)

All services running!

Quick access:
  Frontend: http://localhost:3000
  API:      http://localhost:3001
  API Docs: http://localhost:3001/docs

Stop all: /run-local stop
View logs: /run-local logs
```

## Service Types

| Type       | Detection          | Default Port | Health Check     |
| ---------- | ------------------ | ------------ | ---------------- |
| `nodejs`   | package.json       | 3000         | HTTP GET /       |
| `nextjs`   | next.config.\*     | 3000         | HTTP GET /       |
| `vite`     | vite.config.\*     | 5173         | HTTP GET /       |
| `python`   | requirements.txt   | 8000         | HTTP GET /health |
| `django`   | manage.py          | 8000         | HTTP GET /admin  |
| `fastapi`  | main.py + fastapi  | 8000         | HTTP GET /docs   |
| `go`       | go.mod + main.go   | 8080         | HTTP GET /health |
| `docker`   | docker-compose.yml | varies       | container health |
| `postgres` | docker/native      | 5432         | pg_isready       |
| `redis`    | docker/native      | 6379         | redis-cli ping   |
| `mysql`    | docker/native      | 3306         | mysqladmin ping  |

## Requirements

- Must be run from within a project directory
- Docker (for containerized services)
- Appropriate runtimes (Node.js, Python, Go, etc.)

## Notes

- Services are started in dependency order
- Background processes are managed with proper cleanup
- Logs are aggregated and can be viewed with `/run-local logs`
- Config is saved for quick restarts
- Use `/run-local stop` to cleanly shut down all services
