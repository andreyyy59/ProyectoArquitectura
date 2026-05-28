#!/bin/bash
# Janitor Monkey - Cleans up unused Docker resources

run_janitor_monkey() {
  header "🧹 JANITOR MONKEY"
  report_section "Janitor Monkey"

  local dry_run_flag=""
  $JANITOR_DRY_RUN && dry_run_flag="--dry-run"

  # 1. Unused containers
  step "Unused Containers"
  local unused_containers
  unused_containers=$(docker ps -a --filter "status=exited" --filter "status=created" --format '{{.ID}} {{.Names}} ({{.Image}})' 2>/dev/null)
  if [[ -n "$unused_containers" ]]; then
    info "🧹 Found unused containers:"
    echo "$unused_containers"
    confirm "Remove all unused containers?" && {
      if [[ "$MODE" != "report" ]]; then
        local count
        count=$(docker ps -a -q --filter "status=exited" --filter "status=created" 2>/dev/null | wc -l)
        if [[ "$count" -gt 0 ]]; then
          dry_run "docker container prune -f" || {
            docker container prune -f &>/dev/null
            ok "🧹 Removed $count unused containers"
            report_add "Janitor Monkey" "🧹 Removed $count unused containers"
          }
        fi
      fi
    }
  else
    ok "🧹 No unused containers found"
  fi

  # 2. Unused images
  if [[ "$JANITOR_CLEAN_IMAGES" == "true" ]]; then
    step "Unused Images"
    local dangling_images
    dangling_images=$(docker images -f "dangling=true" --format '{{.ID}} {{.Repository}}:{{.Tag}}' 2>/dev/null)
    if [[ -n "$dangling_images" ]]; then
      info "🧹 Dangling images:"
      echo "$dangling_images"
      confirm "Remove dangling images?" && {
        if [[ "$MODE" != "report" ]]; then
          local count
          count=$(docker images -q -f "dangling=true" 2>/dev/null | wc -l)
          if [[ "$count" -gt 0 ]]; then
            dry_run "docker image prune -f" || {
              docker image prune -f &>/dev/null
              ok "🧹 Removed $count dangling images"
              report_add "Janitor Monkey" "🧹 Removed $count dangling images"
            }
          fi
        fi
      }
    else
      ok "🧹 No dangling images found"
    fi
  fi

  # 3. Unused volumes
  if [[ "$JANITOR_CLEAN_VOLUMES" == "true" ]]; then
    step "Unused Volumes"
    local unused_volumes
    unused_volumes=$(docker volume ls -f "dangling=true" --format '{{.Name}}' 2>/dev/null)
    if [[ -n "$unused_volumes" ]]; then
      info "🧹 Unused volumes:"
      echo "$unused_volumes"
      # Filter to only non-project volumes
      local project_volumes=""
      local non_project=""
      while IFS= read -r vol; do
        if echo "$vol" | grep -qi "${COMPOSE_PROJECT}\|educonnect"; then
          project_volumes="$project_volumes $vol"
        else
          non_project="$non_project $vol"
        fi
      done <<< "$unused_volumes"
      if [[ -n "$project_volumes" ]]; then
        info "🧹 Project unused volumes:$project_volumes"
      fi
      confirm "Remove unused volumes?" && {
        if [[ "$MODE" != "report" ]]; then
          dry_run "docker volume prune -f" || {
            docker volume prune -f &>/dev/null
            ok "🧹 Removed unused volumes"
            report_add "Janitor Monkey" "🧹 Removed unused volumes"
          }
        fi
      }
    else
      ok "🧹 No unused volumes found"
    fi
  fi

  # 4. Unused networks
  if [[ "$JANITOR_CLEAN_NETWORKS" == "true" ]]; then
    step "Unused Networks"
    local unused_networks
    unused_networks=$(docker network ls --filter "driver=bridge" --format '{{.Name}}' 2>/dev/null | grep -v "${COMPOSE_PROJECT}" | grep -v "bridge\|host\|none")
    if [[ -n "$unused_networks" ]]; then
      info "🧹 Unused networks:"
      echo "$unused_networks"
      confirm "Remove unused networks?" && {
        if [[ "$MODE" != "report" ]]; then
          echo "$unused_networks" | while IFS= read -r net; do
            dry_run "docker network rm $net" || {
              docker network rm "$net" &>/dev/null && ok "🧹 Removed network: $net"
            }
          done
          report_add "Janitor Monkey" "🧹 Cleaned unused networks"
        fi
      }
    else
      ok "🧹 No unused networks found"
    fi
  fi

  # 5. Build cache
  step "Build Cache"
  local build_cache
  build_cache=$(docker builder du --format '{{.DiskUsage}}' 2>/dev/null || echo "unknown")
  info "🧹 Build cache size: $build_cache"
  confirm "Prune build cache?" && {
    if [[ "$MODE" != "report" ]]; then
      dry_run "docker builder prune -f" || {
        docker builder prune -f &>/dev/null
        ok "🧹 Build cache pruned"
        report_add "Janitor Monkey" "🧹 Pruned Docker build cache"
      }
    fi
  }
}
