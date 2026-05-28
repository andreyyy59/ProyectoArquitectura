#!/bin/bash
# Chaos Engineering Library - shared functions

# ─── Colors ───────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; MAGENTA='\033[0;35m'; CYAN='\033[0;36m'
BOLD='\033[1m'; NC='\033[0m'

# ─── Logging ──────────────────────────────────────────────
log()   { echo -e "$(date '+%H:%M:%S') $*" | tee -a "$LOG_FILE"; }
info()  { log "${BLUE}[INFO]${NC} $*"; }
ok()    { log "${GREEN}[OK]${NC} $*"; }
warn()  { log "${YELLOW}[WARN]${NC} $*"; }
err()   { log "${RED}[ERR]${NC} $*"; }
step()  { log "\n${CYAN}══════════════════════════════════════════════════${NC}"; log "${CYAN}  $*${NC}"; log "${CYAN}══════════════════════════════════════════════════${NC}\n"; }
header(){ log "\n${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; log "${MAGENTA}  $*${NC}"; log "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"; }

# ─── Interaction ──────────────────────────────────────────
confirm() {
  local msg="$1"
  case "$MODE" in
    automatic) return 0 ;;
    report) warn "[DRY-RUN] Would: $msg"; return 1 ;;
    *)
      echo -en "${YELLOW}❓ $msg [y/N] ${NC}"
      read -r response
      [[ "$response" =~ ^[yYsS] ]]
      return $?
      ;;
  esac
}

dry_run() {
  if [[ "$MODE" == "report" ]]; then
    warn "[DRY-RUN] $*"
    return 0
  fi
  return 1
}

# ─── Docker helpers ───────────────────────────────────────
dc() { docker compose -f "$COMPOSE_FILE" -p "$COMPOSE_PROJECT" "$@"; }

get_running_services() {
  dc ps --services 2>/dev/null | grep -v "exit" || true
}

get_healthy_services() {
  dc ps 2>/dev/null | awk 'NR>1 && $3 ~ /Up/ && $NF !~ /exit/ {print $1}' || true
}

get_container_id() {
  local service="$1"
  docker ps --filter "name=${COMPOSE_PROJECT}-${service}" --filter "name=${service}" --format '{{.ID}}' 2>/dev/null | head -1
}

service_is_running() {
  local service="$1"
  local id
  id=$(get_container_id "$service")
  [[ -n "$id" ]]
}

count_running() {
  local count=0
  for svc in "${ALL_SERVICES[@]}"; do
    service_is_running "$svc" && count=$((count + 1))
  done
  echo "$count"
}

# ─── Report helpers ───────────────────────────────────────
report_add() {
  local section="$1"; shift
  local line="$*"
  echo "- $line" >> "$REPORT_FILE"
}

report_section() {
  local title="$1"
  {
    echo ""
    echo "## $title"
    echo ""
  } >> "$REPORT_FILE"
}

# ─── Metrics ──────────────────────────────────────────────
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

assert() {
  local desc="$1"; shift
  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  if "$@"; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
    ok "✓ $desc"
    report_add "Assertions" "✅ $desc"
  else
    FAILED_TESTS=$((FAILED_TESTS + 1))
    err "✗ $desc"
    report_add "Assertions" "❌ $desc"
  fi
}

# ─── Summary ──────────────────────────────────────────────
print_summary() {
  local total=$((PASSED_TESTS + FAILED_TESTS))
  local pct=0
  [[ $total -gt 0 ]] && pct=$((PASSED_TESTS * 100 / total))

  echo ""
  header "📊 CHAOS ENGINEERING SUMMARY"
  echo ""
  echo "  Total assertions: $total"
  echo "  Passed:           ${GREEN}$PASSED_TESTS${NC}"
  echo "  Failed:           ${RED}$FAILED_TESTS${NC}"
  echo "  Success rate:     $pct%"
  echo ""
  echo "  Report:           $REPORT_FILE"
  echo ""

  {
    echo "# Chaos Engineering Report"
    echo ""
    echo "**Date:** $(date)"
    echo "**Mode:** $MODE"
    echo ""
    echo "## Results"
    echo ""
    echo "| Metric | Value |"
    echo "|--------|-------|"
    echo "| Total Assertions | $total |"
    echo "| Passed | $PASSED_TESTS |"
    echo "| Failed | $FAILED_TESTS |"
    echo "| Success Rate | $pct% |"
    echo ""
  } >> "$REPORT_FILE"
}
