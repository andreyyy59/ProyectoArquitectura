#!/bin/bash
# Latency Monkey - Injects network latency between services

LATENCY_CONTAINER=""

cleanup_latency() {
  if [[ -n "$LATENCY_CONTAINER" ]]; then
    info "Cleaning up latency injection container..."
    docker rm -f "$LATENCY_CONTAINER" &>/dev/null || true
    LATENCY_CONTAINER=""
  fi
}

inject_latency() {
  local target_service="$1"
  local delay_ms="${2:-$LATENCY_DELAY_MS}"
  local jitter_ms="${3:-$LATENCY_JITTER_MS}"
  local duration="${4:-$LATENCY_DURATION}"

  local cid
  cid=$(get_container_id "$target_service")
  [[ -z "$cid" ]] && { err "Target service $target_service not running"; return 1; }

  info "🐒 Injecting ${delay_ms}ms ±${jitter_ms}ms latency into $target_service"

  # Use a privileged alpine container to run tc
  local chaos_container
  chaos_container=$(docker run -d --rm --privileged \
    --network "container:$cid" \
    --name "chaos-latency-$$" \
    alpine:latest sh -c "
      apk add -q iproute2;
      TC=\$(which tc);
      echo 'Setting latency on eth0...';
      \$TC qdisc replace dev eth0 root netem delay ${delay_ms}ms ${jitter_ms}ms;
      echo 'Latency active. Sleeping ${duration}s...';
      sleep $duration;
      \$TC qdisc del dev eth0 root;
      echo 'Latency removed.'
    " 2>/dev/null)

  if [[ -n "$chaos_container" ]]; then
    LATENCY_CONTAINER="$chaos_container"
    report_add "Latency Monkey" "🐢 Injected ${delay_ms}ms ±${jitter_ms}ms into \`$target_service\`"
    ok "🐢 Latency monkey active on $target_service"
    return 0
  else
    err "Failed to start latency container"
    return 1
  fi
}

run_latency_monkey() {
  header "🐢 LATENCY MONKEY"
  report_section "Latency Monkey"

  trap cleanup_latency EXIT

  local target="${1:-$LATENCY_TARGET_SERVICE}"

  if ! service_is_running "$target"; then
    warn "Target $target not running. Starting it..."
    dc up -d "$target" &>/dev/null
    sleep 5
  fi

  assert "$target is running" service_is_running "$target"

  confirm "Inject ${LATENCY_DELAY_MS}ms latency into $target?" && {
    inject_latency "$target" "$LATENCY_DELAY_MS" "$LATENCY_JITTER_MS" "$LATENCY_DURATION" && {
      info "Testing system under latency..."
      sleep "$LATENCY_DURATION"
      ok "Latency test completed for $target"
    }
  }

  cleanup_latency
}
