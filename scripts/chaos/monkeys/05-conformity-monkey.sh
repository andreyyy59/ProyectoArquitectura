#!/bin/bash
# Conformity Monkey - Checks configuration compliance

run_conformity_monkey() {
  header "📋 CONFORMITY MONKEY"
  report_section "Conformity Monkey"

  # 1. Environment variable checks
  if [[ "$CONFORMITY_CHECK_ENVVARS" == "true" ]]; then
    step "Environment Variable Compliance"
    declare -A REQUIRED_ENVVARS
    REQUIRED_ENVVARS["ms-01-user"]="DB_HOST DB_PORT DB_DATABASE DB_USERNAME DB_PASSWORD REDIS_HOST JWT_SECRET"
    REQUIRED_ENVVARS["ms-03-content"]="DB_HOST DB_PORT DB_DATABASE DB_USERNAME DB_PASSWORD REDIS_HOST STORAGE_DRIVER S3_ENDPOINT S3_BUCKET"
    REQUIRED_ENVVARS["ms-05-adaptive"]="DB_HOST DB_PORT DB_DATABASE DB_USERNAME REDIS_HOST AI_SERVICE_URL"
    REQUIRED_ENVVARS["ms-06-ai"]="REDIS_HOST REDIS_PORT OLLAMA_URL OLLAMA_MODEL MODEL_PATH"
    REQUIRED_ENVVARS["frontend"]="VITE_API_GATEWAY"
    REQUIRED_ENVVARS["ms-04-sync"]="DB_HOST DB_PORT DB_DATABASE DB_USERNAME REDIS_HOST"

    for svc in "${!REQUIRED_ENVVARS[@]}"; do
      local cid
      cid=$(get_container_id "$svc")
      [[ -z "$cid" ]] && { warn "📋 $svc not running, skipping env check"; continue; }

      local env_vars
      env_vars=$(docker inspect "$cid" --format '{{range .Config.Env}}{{.}} {{end}}' 2>/dev/null)
      local missing=0
      for var in ${REQUIRED_ENVVARS[$svc]}; do
        if ! echo "$env_vars" | grep -q "${var}="; then
          warn "📋 $svc missing env var: $var"
          report_add "Conformity Monkey" "📋 Missing env var \`$var\` in \`$svc\`"
          missing=$((missing + 1))
        fi
      done
      if [[ "$missing" -eq 0 ]]; then
        ok "📋 $svc: all required env vars present"
      fi
    done
  fi

  # 2. Volume mount checks
  if [[ "$CONFORMITY_CHECK_VOLUMES" == "true" ]]; then
    step "Volume Mount Compliance"
    declare -A EXPECTED_VOLUMES
    EXPECTED_VOLUMES["mysql-user"]="/var/lib/mysql"
    EXPECTED_VOLUMES["redis"]="/data"
    EXPECTED_VOLUMES["ms-06-ai"]="/models"
    EXPECTED_VOLUMES["minio"]="/data"
    EXPECTED_VOLUMES["ollama"]="/root/.ollama"

    for svc in "${!EXPECTED_VOLUMES[@]}"; do
      local cid
      cid=$(get_container_id "$svc")
      [[ -z "$cid" ]] && continue

      local expected="${EXPECTED_VOLUMES[$svc]}"
      local mounts
      mounts=$(docker inspect "$cid" --format '{{range .Mounts}}{{.Destination}} {{end}}' 2>/dev/null)
      if echo "$mounts" | grep -q "$expected"; then
        ok "📋 $svc: volume $expected mounted"
      else
        warn "📋 $svc: volume $expected NOT mounted"
        report_add "Conformity Monkey" "📋 \`$svc\` missing volume \`$expected\`"
      fi
    done
  fi

  # 3. Network assignment checks
  if [[ "$CONFORMITY_CHECK_NETWORKS" == "true" ]]; then
    step "Network Compliance"
    local network="${COMPOSE_PROJECT}_educonnect-network"

    if docker network ls --format '{{.Name}}' | grep -q "$network"; then
      ok "📋 Network $network exists"
      # Check all services are on it
      local on_network=0
      for svc in "${ALL_SERVICES[@]}"; do
        local cid
        cid=$(get_container_id "$svc")
        [[ -z "$cid" ]] && continue
        if docker inspect "$cid" --format '{{range $net,$v := .NetworkSettings.Networks}}{{$net}} {{end}}' 2>/dev/null | grep -q "$network"; then
          on_network=$((on_network + 1))
        else
          warn "📋 $svc NOT on $network"
          report_add "Conformity Monkey" "📋 \`$svc\` not connected to \`$network\`"
        fi
      done
      ok "📋 $on_network services on $network"
    else
      err "📋 Network $network does not exist"
    fi
  fi

  # 4. Label checks
  if [[ "$CONFORMITY_CHECK_LABELS" == "true" ]]; then
    step "Label Compliance"
    local labeled=0 unlabeled=0
    for svc in "${ALL_SERVICES[@]}"; do
      local cid
      cid=$(get_container_id "$svc")
      [[ -z "$cid" ]] && continue
      local labels
      labels=$(docker inspect "$cid" --format '{{json .Config.Labels}}' 2>/dev/null)
      if [[ "$labels" == "{}" ]]; then
        warn "📋 $svc has no labels"
        unlabeled=$((unlabeled + 1))
      else
        labeled=$((labeled + 1))
      fi
    done
    ok "📋 $labeled containers have labels"
    [[ "$unlabeled" -gt 0 ]] && warn "📋 $unlabeled containers without labels"
  fi

  # 5. Restart policy compliance
  step "Restart Policy Compliance"
  local wrong_policy=0
  for svc in "${ALL_SERVICES[@]}"; do
    local cid
    cid=$(get_container_id "$svc")
    [[ -z "$cid" ]] && continue
    local policy
    policy=$(docker inspect "$cid" --format '{{.HostConfig.RestartPolicy.Name}}' 2>/dev/null)
    if [[ "$policy" != "unless-stopped" ]] && [[ "$policy" != "always" ]]; then
      warn "📋 $svc: restart policy is '$policy' (expected: unless-stopped)"
      report_add "Conformity Monkey" "📋 \`$svc\` restart policy is '$policy'"
      wrong_policy=$((wrong_policy + 1))
    fi
  done
  assert "All services have correct restart policy" [[ $wrong_policy -eq 0 ]]
}
