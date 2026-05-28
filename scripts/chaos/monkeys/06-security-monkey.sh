#!/bin/bash
# Security Monkey - Security vulnerability scanning

run_security_monkey() {
  header "🔒 SECURITY MONKEY"
  report_section "Security Monkey"

  # 1. Exposed port analysis
  if [[ "$SECURITY_CHECK_PORTS" == "true" ]]; then
    step "Port Exposure Analysis"
    for svc in "${ALL_SERVICES[@]}"; do
      local cid
      cid=$(get_container_id "$svc")
      [[ -z "$cid" ]] && continue

      local ports
      ports=$(docker port "$cid" 2>/dev/null)
      if [[ -n "$ports" ]]; then
        info "🔒 $svc exposes: $ports"
        while IFS= read -r mapping; do
          if echo "$mapping" | grep -qE '0\.0\.0\.0|:::' && ! echo "$mapping" | grep -qE '127\.0\.0\.1|localhost'; then
            local host_port container_port
            host_port=$(echo "$mapping" | awk -F '->' '{print $1}' | sed 's/.*://')
            container_port=$(echo "$mapping" | awk -F '->' '{print $2}' | sed 's/.*://' | sed 's/\/tcp//' | sed 's/\/udp//')
            # Flag unusual ports
            if [[ "$container_port" -gt 8000 ]] || [[ "$container_port" == "8080" ]] || [[ "$container_port" == "3000" ]]; then
              warn "🔒 $svc: port $host_port->$container_port exposed on 0.0.0.0"
              report_add "Security Monkey" "🔒 \`$svc\` exposes port $host_port→$container_port on 0.0.0.0"
            fi
          fi
        done <<< "$ports"
      fi
    done
  fi

  # 2. Secrets in environment variables
  if [[ "$SECURITY_CHECK_ENV_SECRETS" == "true" ]]; then
    step "Secrets Exposure Scan"
    declare -a SECRET_PATTERNS=("PASSWORD" "SECRET" "TOKEN" "KEY" "CREDENTIAL" "AUTH")
    for svc in "${ALL_SERVICES[@]}"; do
      local cid
      cid=$(get_container_id "$svc")
      [[ -z "$cid" ]] && continue

      local env_vars
      env_vars=$(docker inspect "$cid" --format '{{range .Config.Env}}{{.}} {{end}}' 2>/dev/null)
      for pattern in "${SECRET_PATTERNS[@]}"; do
        while IFS= read -r match; do
          if [[ -n "$match" ]]; then
            local var_name="${match%%=*}"
            local var_val="${match#*=}"
            local val_len=${#var_val}
            if [[ "$val_len" -gt 3 ]] && [[ "$var_val" != "chang"* ]] && [[ "$var_val" != "secret" ]]; then
              local masked="${var_val:0:3}...${var_val: -3}"
              warn "🔒 $svc: $var_name=$masked (${val_len} chars)"
              report_add "Security Monkey" "🔒 \`$svc\` has secret \`$var_name\` (${val_len} chars)"
            fi
          fi
        done <<< "$(echo "$env_vars" | tr ' ' '\n' | grep -i "${pattern}=")"
      done
    done
  fi

  # 3. Image security
  step "Image Security"
  for svc in "${ALL_SERVICES[@]}"; do
    local cid
    cid=$(get_container_id "$svc")
    [[ -z "$cid" ]] && continue

    local image
    image=$(docker inspect "$cid" --format '{{.Config.Image}}' 2>/dev/null)
    # Check if image has a tag
    if ! echo "$image" | grep -q ":"; then
      warn "🔒 $svc: image '$image' has no tag (using :latest)"
      report_add "Security Monkey" "🔒 \`$svc\` image '$image' has no tag"
    fi
  done

  # 4. Container isolation
  if [[ "$SECURITY_CHECK_NETWORK_ISOLATION" == "true" ]]; then
    step "Network Isolation"
    local network="${COMPOSE_PROJECT}_educonnect-network"
    # Check non-services on the network
    local containers
    containers=$(docker network inspect "$network" --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null)
    for c in $containers; do
      local is_service=false
      for svc in "${ALL_SERVICES[@]}"; do
        if echo "$c" | grep -qi "$svc"; then
          is_service=true
          break
        fi
      done
      if ! $is_service; then
        warn "🔒 Foreign container on network: $c"
        report_add "Security Monkey" "🔒 Foreign container \`$c\` on network"
      fi
    done

    # Check if containers run as root
    for svc in "${ALL_SERVICES[@]}"; do
      local cid
      cid=$(get_container_id "$svc")
      [[ -z "$cid" ]] && continue
      local user
      user=$(docker inspect "$cid" --format '{{.Config.User}}' 2>/dev/null)
      if [[ -z "$user" || "$user" == "root" || "$user" == "0" ]]; then
        warn "🔒 $svc runs as root (user: '$user')"
        report_add "Security Monkey" "🔒 \`$svc\` runs as root"
      fi
    done
  fi

  # 5. Privileged mode check
  step "Privileged Mode Check"
  for svc in "${ALL_SERVICES[@]}"; do
    local cid
    cid=$(get_container_id "$svc")
    [[ -z "$cid" ]] && continue
    local privileged
    privileged=$(docker inspect "$cid" --format '{{.HostConfig.Privileged}}' 2>/dev/null)
    if [[ "$privileged" == "true" ]]; then
      warn "🔒 $svc runs in PRIVILEGED mode"
      report_add "Security Monkey" "🔒 \`$svc\` runs in PRIVILEGED mode"
    fi
  done
}
