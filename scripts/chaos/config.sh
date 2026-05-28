#!/bin/bash
# Chaos Engineering Configuration
# Edit this file to customize chaos behavior

# ─── Project ──────────────────────────────────────────────
PROJECT_NAME="educonnectrural"
COMPOSE_FILE="../../docker-compose.yml"
COMPOSE_PROJECT="educonnect"

# ─── Services (in dependency order) ───────────────────────
ALL_SERVICES=(
  "redis"
  "mysql-user" "mysql-content" "mysql-sync" "mysql-analytics" "mysql-reports"
  "minio"
  "ms-01-user"
  "ms-02-edge-node"
  "ms-03-content"
  "ms-04-sync"
  "ms-05-adaptive"
  "ms-06-ai"
  "ollama"
  "ms-07-analytics"
  "ms-08-connectivity"
  "ms-09-reports"
  "ms-10-notifications"
  "api-gateway"
  "frontend"
  "mailhog"
)

# Critical infrastructure (killing these breaks everything)
CRITICAL_SERVICES=("redis" "api-gateway" "mysql-user" "ms-01-user")

# Non-critical services (safe to kill first)
EXPENDABLE_SERVICES=("mailhog" "ms-09-reports" "ms-10-notifications" "ms-07-analytics" "ms-08-connectivity")

# AI pipeline services
AI_PIPELINE=("ollama" "ms-06-ai" "ms-05-adaptive")

# ─── Chaos Monkey Settings ────────────────────────────────
CHAOS_MONKEY_KILL_PERCENT=30        # What % of running containers to kill
CHAOS_MONKEY_INTERVAL=30           # Seconds between chaos rounds
CHAOS_MONKEY_ROUNDS=3              # Number of rounds

# ─── Latency Monkey Settings ──────────────────────────────
LATENCY_DELAY_MS=2000              # Milliseconds of added latency
LATENCY_JITTER_MS=500              # Jitter
LATENCY_TARGET_SERVICE="ms-06-ai"  # Target for latency injection
LATENCY_DURATION=60                # Seconds to keep latency

# ─── Gorilla Settings ─────────────────────────────────────
GORILLA_TARGET="mysql"             # Target group (mysql, redis, ai)
GORILLA_DURATION=30                # Seconds to keep down

# ─── Doctor Monkey Settings ───────────────────────────────
DOCTOR_HEALTH_TIMEOUT=10           # Seconds to wait for health check
DOCTOR_CHECK_ENDPOINTS=true        # Check HTTP endpoints
DOCTOR_CHECK_LOGS=true             # Check recent error logs

# ─── Conformity Monkey Settings ───────────────────────────
CONFORMITY_CHECK_ENVVARS=true
CONFORMITY_CHECK_VOLUMES=true
CONFORMITY_CHECK_NETWORKS=true
CONFORMITY_CHECK_LABELS=true

# ─── Security Monkey Settings ─────────────────────────────
SECURITY_CHECK_PORTS=true
SECURITY_CHECK_ENV_SECRETS=true
SECURITY_CHECK_NETWORK_ISOLATION=true

# ─── Janitor Monkey Settings ──────────────────────────────
JANITOR_DRY_RUN=true               # Set to false to actually clean
JANITOR_CLEAN_IMAGES=true
JANITOR_CLEAN_VOLUMES=true
JANITOR_CLEAN_NETWORKS=true

# ─── Mode ─────────────────────────────────────────────────
# interactive: ask before each action
# automatic: run without asking
# report: dry-run, just report what would happen
MODE="interactive"

# ─── Logging ──────────────────────────────────────────────
LOG_FILE="./reports/chaos-$(date +%Y%m%d-%H%M%S).log"
REPORT_FILE="./reports/chaos-report-$(date +%Y%m%d-%H%M%S).md"
