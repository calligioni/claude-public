# Instructions for /run-local Skill

When the user invokes `/run-local`, follow these steps:

## 1. Validate Environment

Check that we're in a project directory:
```bash
pwd
ls -la
```

Store the project root:
```bash
PROJECT_ROOT=$(pwd)
PROJECT_NAME=$(basename "$PROJECT_ROOT")
```

## 2. Parse Arguments

- No args: Start local development (detect or create config, then run)
- `status`: Check health of running services
- `stop`: Stop all running services
- `logs`: Show aggregated logs
- `--force`: Force reinstall dependencies

## 3. Check for Existing Configuration

Look for config files in order of priority:

```bash
# Check for run-local config
if [[ -f ".run-local.json" ]]; then
  # Use existing config
elif [[ -f "scripts/run-local.sh" ]]; then
  # Use existing script
else
  # Run discovery (step 4)
fi
```

If config exists with valid services → Skip to step 6 (Install Dependencies)

## 4. Project Discovery

### 4.1 Detect Package Managers

```bash
# Node.js
[[ -f "package.json" ]] && echo "nodejs"
[[ -f "pnpm-workspace.yaml" ]] && echo "pnpm-monorepo"
[[ -f "yarn.lock" ]] && echo "yarn"
[[ -f "pnpm-lock.yaml" ]] && echo "pnpm"
[[ -f "package-lock.json" ]] && echo "npm"

# Python
[[ -f "requirements.txt" ]] && echo "pip"
[[ -f "pyproject.toml" ]] && echo "poetry"
[[ -f "Pipfile" ]] && echo "pipenv"

# Other
[[ -f "go.mod" ]] && echo "go"
[[ -f "Cargo.toml" ]] && echo "cargo"
[[ -f "Gemfile" ]] && echo "bundler"
```

### 4.2 Detect Frameworks and Services

Scan for framework indicators:

```bash
# Frontend frameworks
[[ -f "next.config.js" || -f "next.config.mjs" || -f "next.config.ts" ]] && echo "nextjs:3000"
[[ -f "vite.config.js" || -f "vite.config.ts" ]] && echo "vite:5173"
[[ -f "angular.json" ]] && echo "angular:4200"
[[ -f "svelte.config.js" ]] && echo "sveltekit:5173"

# Backend frameworks
[[ -f "manage.py" ]] && echo "django:8000"
grep -q "fastapi" requirements.txt 2>/dev/null && echo "fastapi:8000"
grep -q "flask" requirements.txt 2>/dev/null && echo "flask:5000"
[[ -f "main.go" || -d "cmd" ]] && echo "go:8080"

# Databases (from docker-compose)
grep -q "postgres" docker-compose.yml 2>/dev/null && echo "postgres:5432"
grep -q "mysql" docker-compose.yml 2>/dev/null && echo "mysql:3306"
grep -q "redis" docker-compose.yml 2>/dev/null && echo "redis:6379"
grep -q "mongo" docker-compose.yml 2>/dev/null && echo "mongodb:27017"
```

### 4.3 Detect Monorepo Structure

```bash
# Check for monorepo patterns
if [[ -d "apps" ]]; then
  ls apps/ | while read app; do
    # Analyze each app
    analyze_app "apps/$app"
  done
fi

if [[ -d "packages" ]]; then
  ls packages/ | while read pkg; do
    # Check if package has runnable service
    [[ -f "packages/$pkg/package.json" ]] && check_scripts "packages/$pkg"
  done
fi
```

### 4.4 Analyze package.json Scripts

For each package.json found:
```bash
# Extract dev/start scripts
jq -r '.scripts | to_entries[] | select(.key | test("dev|start|serve")) | "\(.key): \(.value)"' package.json
```

Look for:
- `dev`, `start`, `serve` scripts
- Port configurations in scripts (e.g., `--port 3001`)
- Environment-specific scripts

### 4.5 Build Service List

Create a table of discovered services:

```
Detected Services:
| #  | Service    | Type       | Path        | Port  | Start Command           |
|----|------------|------------|-------------|-------|-------------------------|
| 1  | api        | fastapi    | ./apps/api  | 8000  | uvicorn main:app        |
| 2  | frontend   | nextjs     | ./apps/web  | 3000  | npm run dev             |
| 3  | postgres   | docker     | .           | 5432  | docker-compose up -d    |
| 4  | redis      | docker     | .           | 6379  | docker-compose up -d    |
```

## 5. Get User Confirmation

Use AskUserQuestion to confirm:

**Question:** "I've detected these services. Proceed with setup?"

**Options:**
- "Yes, start all services" - Proceed with full setup
- "Customize" - Let me adjust the configuration
- "Skip" - Cancel

If user selects "Customize", present options to:
- Add/remove services
- Change ports
- Modify start commands

### 5.1 Save Configuration

Create `.run-local.json`:

```json
{
  "projectName": "my-project",
  "services": [...],
  "dependencies": {
    "install": [...],
    "preStart": [...]
  },
  "healthCheck": {
    "timeout": 60,
    "interval": 2
  }
}
```

## 6. Install Dependencies

### 6.1 Check and Install System Dependencies

```bash
# Check for required tools
command -v node >/dev/null || echo "Node.js not found"
command -v python3 >/dev/null || echo "Python not found"
command -v docker >/dev/null || echo "Docker not found"
```

### 6.2 Install Project Dependencies

For each dependency entry in config:

```bash
# Node.js
if [[ -f "package.json" ]]; then
  if [[ -f "pnpm-lock.yaml" ]]; then
    pnpm install
  elif [[ -f "yarn.lock" ]]; then
    yarn install
  else
    npm install
  fi
fi

# Python
if [[ -f "requirements.txt" ]]; then
  pip install -r requirements.txt
fi

if [[ -f "pyproject.toml" ]]; then
  poetry install
fi
```

Report progress:
```
[1/4] Installing dependencies...
  ✓ pnpm install (root) - 45 packages
  ✓ pip install -r requirements.txt (apps/api) - 23 packages
```

## 7. Start Infrastructure Services

Start databases and caches first (services with no dependencies):

```bash
# Docker-based infrastructure
if [[ -f "docker-compose.yml" ]]; then
  # Start only infrastructure services
  docker-compose up -d postgres redis
fi
```

Wait for infrastructure health:
```bash
# Wait for postgres
until pg_isready -h localhost -p 5432 2>/dev/null; do
  echo "Waiting for postgres..."
  sleep 2
done

# Wait for redis
until redis-cli ping 2>/dev/null; do
  echo "Waiting for redis..."
  sleep 2
done
```

## 8. Start Application Services

Start services in dependency order:

```bash
# For each service (in order based on dependsOn)
for service in "${SERVICES[@]}"; do
  cd "$service_path"

  # Start in background, capture PID
  $start_command > "/tmp/run-local-${service_name}.log" 2>&1 &
  echo $! > "/tmp/run-local-${service_name}.pid"

  echo "✓ $service_name started (http://localhost:$port)"
done
```

## 9. Run Health Checks

For each service, verify it's running:

```bash
check_health() {
  local url="$1"
  local timeout="${2:-60}"
  local interval="${3:-2}"
  local elapsed=0

  while [[ $elapsed -lt $timeout ]]; do
    if curl -sf "$url" > /dev/null 2>&1; then
      return 0
    fi
    sleep $interval
    elapsed=$((elapsed + interval))
  done
  return 1
}

# Check each service
for service in "${SERVICES[@]}"; do
  if check_health "$health_url" 60 2; then
    echo "✓ $service_name: healthy"
  else
    echo "✗ $service_name: unhealthy (timeout after 60s)"
  fi
done
```

### Health Check Types

| Type | Check Method |
|------|--------------|
| HTTP URL | `curl -sf $url` |
| Postgres | `pg_isready -h localhost -p $port` |
| Redis | `redis-cli -p $port ping` |
| MySQL | `mysqladmin -h localhost -P $port ping` |
| MongoDB | `mongosh --eval "db.runCommand({ping:1})"` |
| Docker | `docker inspect --format='{{.State.Health.Status}}'` |

## 10. Generate Summary

Output final status:

```
All services running!

Quick access:
  Frontend: http://localhost:3000
  API:      http://localhost:8000
  API Docs: http://localhost:8000/docs
  Database: localhost:5432

Logs:     /run-local logs
Status:   /run-local status
Stop all: /run-local stop
```

## 11. Status Command

If user runs `/run-local status`:

```bash
# Check each service
for service in config.services; do
  # Check if PID file exists and process is running
  if [[ -f "/tmp/run-local-${service}.pid" ]]; then
    pid=$(cat "/tmp/run-local-${service}.pid")
    if ps -p $pid > /dev/null 2>&1; then
      # Check health
      if check_health "$health_url"; then
        echo "✓ $service: running (PID $pid)"
      else
        echo "⚠ $service: running but unhealthy"
      fi
    else
      echo "✗ $service: not running"
    fi
  fi
done
```

## 12. Stop Command

If user runs `/run-local stop`:

```bash
echo "Stopping services..."

# Stop application services first
for service in $(reverse_order "${SERVICES[@]}"); do
  if [[ -f "/tmp/run-local-${service}.pid" ]]; then
    pid=$(cat "/tmp/run-local-${service}.pid")
    kill $pid 2>/dev/null && echo "✓ Stopped $service"
    rm "/tmp/run-local-${service}.pid"
  fi
done

# Stop docker services
if [[ -f "docker-compose.yml" ]]; then
  docker-compose down
fi

echo "All services stopped."
```

## 13. Logs Command

If user runs `/run-local logs`:

```bash
# Aggregate logs from all services
echo "=== Service Logs ==="
for service in "${SERVICES[@]}"; do
  echo "--- $service ---"
  tail -50 "/tmp/run-local-${service}.log"
  echo ""
done
```

Or use `tail -f` for live logs:
```bash
tail -f /tmp/run-local-*.log
```

## Error Handling

| Error | Resolution |
|-------|------------|
| Port already in use | Find and kill existing process, or use different port |
| Dependency install failed | Show error, offer to continue without |
| Service won't start | Show logs, check for common issues |
| Health check timeout | Show service logs, suggest debugging |
| Docker not running | Prompt to start Docker Desktop |
| Missing runtime | Suggest installation command |

## Environment Variables

Check for and load environment files:

```bash
# Load in order of priority
[[ -f ".env.local" ]] && source .env.local
[[ -f ".env.development" ]] && source .env.development
[[ -f ".env" ]] && source .env
```

Create `.env.local` template if missing and required variables aren't set.

## Output Format

Use these symbols:
- ✓ Success
- • In progress / Neutral
- ✗ Error
- ⚠ Warning

Keep output concise. Show progress indicators for long operations.
