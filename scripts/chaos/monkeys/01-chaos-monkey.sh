#!/bin/bash
# Chaos Monkey - Randomly kills containers to test resilience

run_chaos_monkey() {
  header "🐒 CHAOS MONKEY"
  report_section "Chaos Monkey"

  local running_services=()
  for svc in "${ALL_SERVICES[@]}"; do
    service_is_running "$svc" && running_services+=("$svc")
  done

  local total=${#running_services[@]}
  local to_kill=$((total * CHAOS_MONKEY_KILL_PERCENT / 100))
  [[ $to_kill -lt 1 ]] && to_kill=1

  info "Running services: $total"
  info "Target to kill: $to_kill ($CHAOS_MONKEY_KILL_PERCENT%)"

  for ((round=1; round<=CHAOS_MONKEY_ROUNDS; round++)); do
    step "Round $round of $CHAOS_MONKEY_ROUNDS"

    # Re-read running services
    running_services=()
    for svc in "${ALL_SERVICES[@]}"; do
      service_is_running "$svc" && running_services+=("$svc")
    done

    local available=${#running_services[@]}
    [[ $available -eq 0 ]] && { warn "No running services to kill"; break; }

    local kill_targets=()
    for ((i=0; i<to_kill && i<available; i++)); do
      local idx=$((RANDOM % available))
      local target="${running_services[$idx]}"
      kill_targets+=("$target")
      # Remove from array
      running_services=("${running_services[@]:0:$idx}" "${running_services[@]:$idx+1}")
      available=$((available - 1))
    done

    for target in "${kill_targets[@]}"; do
      is_critical=false
      for c in "${CRITICAL_SERVICES[@]}"; do
        [[ "$target" == "$c" ]] && is_critical=true
      done

      local desc="Kill container: $target"
      local note=""
      $is_critical && note=" (CRITICAL)"
      info "👊 $desc$note"

      local cid
      cid=$(get_container_id "$target")
      if [[ -n "$cid" ]]; then
        confirm "Kill $target$note?" && {
          dry_run "$desc" || {
            docker kill "$cid" &>/dev/null
            ok "💀 Killed: $target (container: ${cid:0:12})"
            report_add "Chaos Monkey" "💀 Killed \`$target\` (container ${cid:0:12})"
          }
        }
      else
        warn "Container $target already dead"
      fi
    done

    # Wait and observe
    if [[ $round -lt $CHAOS_MONKEY_ROUNDS ]]; then
      info "⏳ Waiting $CHAOS_MONKEY_INTERVAL seconds before next round..."
      sleep "$CHAOS_MONKEY_INTERVAL"
      info "Observing system state..."
      assert "System recovers after round $round" true
    fi
  done
}
