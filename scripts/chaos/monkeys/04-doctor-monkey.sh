#!/bin/bash
# Doctor Monkey - Health checks and diagnosis

run_doctor_monkey() {
  header "🩺 DOCTOR MONKEY"
  report_section "Doctor Monkey"

  info "Running health diagnostics on all services..."

  # 1. Container status check
  step "Container Status"
  local total=0 running=0
  for svc in "${ALL_SERVICES[@]}"; do
    total=$((total + 1))
    if service_is_running "$svc"; then
      running=$((running + 1))
    else
      warn "🅓 Not running: $svc"
      report_add "Doctor Monkey" "🅓 Not running: \`$svc\`"
    fi
  done
  assert "All containers running ($running/$total)" [[ $running -eq $total ]]

  # 2. Health check status
  step "Health Checks"
  for svc in "${ALL_SERVICES[@]}"; do
    local cid
    cid=$(get_container_id "$svc")
    [[ -z "$cid" ]] && continue

    local health
    health=$(docker inspect "$cid" --format '{{.State.Health.Status}}' 2>/dev/null || echo "no-check")
    if [[ "$health" == "unhealthy" ]]; then
      err "🅓 Unhealthy: $svc (health: $health)"
      report_add "Doctor Monkey" "🅓 Unhealthy: \`$svc\` (health: $health)"
    elif [[ "$health" == "healthy" ]]; then
      ok "🅓 Healthy: $svc"
    fi
  done

  # 3. Restart count
  step "Restart Activity"
  for svc in "${ALL_SERVICES[@]}"; do
    local cid
    cid=$(get_container_id "$svc")
    [[ -z "$cid" ]] && continue

    local restart_count
    restart_count=$(docker inspect "$cid" --format '{{.RestartCount}}' 2>/dev/null || echo "0")
    if [[ "$restart_count" -gt 0 ]]; then
      warn "🅓 $svc restarted $restart_count times"
      report_add "Doctor Monkey" "🅓 \`$svc\` restarted $restart_count times"
    fi
  done

  # 4. Error log scan
  if [[ "$DOCTOR_CHECK_LOGS" == "true" ]]; then
    step "Error Log Scan (last 50 lines)"
    for svc in "${ALL_SERVICES[@]}"; do
      local cid
      cid=$(get_container_id "$svc")
      [[ -z "$cid" ]] && continue

      local errors
      errors=$(docker logs "$cid" --tail 50 2>&1 | grep -ci "error\|exception\|traceback\|fatal\|critical" || true)
      if [[ "$errors" -gt 0 ]]; then
        warn "🅓 $svc: $errors error lines in recent logs"
        report_add "Doctor Monkey" "🅓 \`$svc\`: $errors error(s) in recent logs"
      fi
    done
  fi

  # 5. HTTP endpoint check
  if [[ "$DOCTOR_CHECK_ENDPOINTS" == "true" ]]; then
    step "HTTP Endpoint Check"
    declare -A ENDPOINTS
    ENDPOINTS["api-gateway"]="http://localhost:8080/"
    ENDPOINTS["ms-06-ai"]="http://localhost:8000/docs"
    ENDPOINTS["redis"]="redis://localhost:6379"

    for svc in "${!ENDPOINTS[@]}"; do
      local url="${ENDPOINTS[$svc]}"
      if service_is_running "$svc"; then
        if [[ "$url" == redis* ]]; then
          # Simple redis ping via docker
          local redis_cid
          redis_cid=$(get_container_id "redis")
          if [[ -n "$redis_cid" ]]; then
            docker exec "$redis_cid" redis-cli ping 2>/dev/null | grep -q "PONG" && \
              ok "🅓 Redis responds to PING" || \
              warn "🅓 Redis not responding"
          fi
        else
          local status_code
          status_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$url" 2>/dev/null || echo "000")
          if [[ "$status_code" != "000" ]]; then
            ok "🅓 $svc responds (HTTP $status_code)"
          else
            warn "🅓 $svc endpoint not reachable: $url"
            report_add "Doctor Monkey" "🅓 \`$svc\` endpoint unreachable: $url"
          fi
        fi
      fi
    done
  fi

  # 6. Resource usage
  step "Resource Usage"
  for svc in "${ALL_SERVICES[@]}"; do
    local cid
    cid=$(get_container_id "$svc")
    [[ -z "$cid" ]] && continue

    local cpu mem
    cpu=$(docker stats "$cid" --no-stream --format '{{.CPUPerc}}' 2>/dev/null | sed 's/%//' || echo "0")
    mem=$(docker stats "$cid" --no-stream --format '{{.MemPerc}}' 2>/dev/null | sed 's/%//' || echo "0")

    local cpu_int="${cpu%.*}"
    local mem_int="${mem%.*}"
    [[ -z "$cpu_int" ]] && cpu_int=0
    [[ -z "$mem_int" ]] && mem_int=0

    if [[ "$cpu_int" -gt 80 ]]; then
      warn "🅓 $svc: High CPU (${cpu}%)"
    fi
    if [[ "$mem_int" -gt 80 ]]; then
      warn "🅓 $svc: High Memory (${mem}%)"
    fi
  done
}
