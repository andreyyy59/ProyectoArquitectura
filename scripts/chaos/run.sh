#!/bin/bash
# 🐒 EduConnect Rural - Chaos Engineering Toolkit
# Usage: ./run.sh [monkey1 monkey2 ...]
#   Without args: runs all monkeys in sequence
#   With args: runs specific monkeys (chaos, latency, gorilla, doctor, conformity, security, janitor)

set -e

# Load config and library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# shellcheck source=./config.sh
source ./config.sh
# shellcheck source=./lib.sh
source ./lib.sh

# Source all monkey scripts
for monkey in ./monkeys/*.sh; do
  # shellcheck disable=SC1090
  source "$monkey"
done

# ─── Entry point ──────────────────────────────────────────

echo ""
echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║     🐒 EDUCONNECT RURAL - CHAOS ENGINEERING TOOLKIT    ║${NC}"
echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Mode:        ${BOLD}$MODE${NC}"
echo -e "  Project:     $COMPOSE_PROJECT"
echo -e "  Compose:     $COMPOSE_FILE"
echo -e "  Services:    ${#ALL_SERVICES[@]} defined"
echo -e "  Log:         $LOG_FILE"
echo -e "  Report:      $REPORT_FILE"
echo ""

# Init report
echo "# Chaos Engineering Report" > "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "**Date:** $(date)" >> "$REPORT_FILE"
echo "**Mode:** $MODE" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Parse args
RUN_ALL=true
REQUESTED_MONKEYS=()
if [[ $# -gt 0 ]]; then
  RUN_ALL=false
  for arg in "$@"; do
    case "$arg" in
      chaos|monkey)       REQUESTED_MONKEYS+=("chaos") ;;
      latency)            REQUESTED_MONKEYS+=("latency") ;;
      gorilla)            REQUESTED_MONKEYS+=("gorilla") ;;
      doctor)             REQUESTED_MONKEYS+=("doctor") ;;
      conformity)         REQUESTED_MONKEYS+=("conformity") ;;
      security)           REQUESTED_MONKEYS+=("security") ;;
      janitor)            REQUESTED_MONKEYS+=("janitor") ;;
      all)                RUN_ALL=true ;;
      dry-run|report)     MODE="report" ;;
      automatic|auto|y)   MODE="automatic" ;;
      *)
        echo -e "${RED}Unknown monkey: $arg${NC}"
        echo "Available: chaos, latency, gorilla, doctor, conformity, security, janitor, all"
        exit 1
        ;;
    esac
  done
fi

# Run selected monkeys
if $RUN_ALL || [[ " ${REQUESTED_MONKEYS[*]} " =~ " chaos " ]]; then
  run_chaos_monkey
fi

if $RUN_ALL || [[ " ${REQUESTED_MONKEYS[*]} " =~ " latency " ]]; then
  run_latency_monkey
fi

if $RUN_ALL || [[ " ${REQUESTED_MONKEYS[*]} " =~ " gorilla " ]]; then
  run_gorilla
fi

if $RUN_ALL || [[ " ${REQUESTED_MONKEYS[*]} " =~ " doctor " ]]; then
  run_doctor_monkey
fi

if $RUN_ALL || [[ " ${REQUESTED_MONKEYS[*]} " =~ " conformity " ]]; then
  run_conformity_monkey
fi

if $RUN_ALL || [[ " ${REQUESTED_MONKEYS[*]} " =~ " security " ]]; then
  run_security_monkey
fi

if $RUN_ALL || [[ " ${REQUESTED_MONKEYS[*]} " =~ " janitor " ]]; then
  run_janitor_monkey
fi

# Print final summary
print_summary

echo -e "${GREEN}✅ Chaos Engineering run complete.${NC}"
echo -e "   Report: ${BOLD}$REPORT_FILE${NC}"
