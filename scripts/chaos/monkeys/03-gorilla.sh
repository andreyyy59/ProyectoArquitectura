#!/bin/bash
# Gorilla Monkey - Simulates full infrastructure/zone failure

run_gorilla() {
  header "🦍 GORILLA MONKEY"
  report_section "Gorilla (Full Infrastructure Failure)"

  local target_group="${1:-$GORILLA_TARGET}"
  local duration="${2:-$GORILLA_DURATION}"

  declare -A GROUPS
  GROUPS["mysql"]="mysql-user mysql-content mysql-sync mysql-analytics mysql-reports"
  GROUPS["redis"]="redis"
  GROUPS["minio"]="minio"
  GROUPS["ai"]="ollama ms-06-ai"
  GROUPS["frontend"]="frontend api-gateway"
  GROUPS["all-dbs"]="mysql-user mysql-content mysql-sync mysql-analytics mysql-reports redis"
  GROUPS["all-ms"]="ms-01-user ms-02-edge-node ms-03-content ms-04-sync ms-05-adaptive ms-06-ai ms-07-analytics ms-08-connectivity ms-09-reports ms-10-notifications"

  local targets="${GROUPS[$target_group]}"
  if [[ -z "$targets" ]]; then
    err "Unknown group: $target_group"
    err "Available: ${!GROUPS[*]}"
    return 1
  fi

  info "🦍 Gorilla attacking group: $target_group"
  info "Targets: $targets"
  info "Duration: ${duration}s"

  confirm "Take down $target_group for ${duration}s?" || return 0

  # Record initial state
  local initial_count
  initial_count=$(count_running)

  # Kill all targets
  local killed=0
  for target in $targets; do
    local cid
    cid=$(get_container_id "$target")
    if [[ -n "$cid" ]]; then
      dry_run "docker kill $target" || {
        docker kill "$cid" &>/dev/null
        info "💀 Killed: $target"
        killed=$((killed + 1))
      }
    fi
  done

  report_add "Gorilla" "🦍 Took down group \`$target_group\` ($killed containers)"

  # Verify they're down
  local down_count=0
  for target in $targets; do
    service_is_running "$target" && down_count=$((down_count + 1))
  done

  if [[ "$MODE" != "report" ]]; then
    assert "All $target_group containers are down" [[ $down_count -eq 0 ]]
  fi

  # Wait and observe system behavior
  info "⏳ System running without $target_group for ${duration}s..."
  sleep "$duration"
  info "Observing degraded behavior..."

  # Restart everything
  info "🔄 Restoring $target_group..."
  for target in $targets; do
    dry_run "docker compose up -d $target" || {
      dc up -d "$target" &>/dev/null
      info "⏫ Restarting: $target"
    }
  done

  # Wait for recovery
  info "⏳ Waiting 15s for recovery..."
  sleep 15

  # Check recovery
  local recovered=0
  for target in $targets; do
    service_is_running "$target" && recovered=$((recovered + 1))
  done

  if [[ "$MODE" != "report" ]]; then
    assert "All $target_group containers recovered" [[ $recovered -eq $(echo "$targets" | wc -w) ]]
  fi

  info "Gorilla test completed. Killed $killed, recovered $recovered."
}
