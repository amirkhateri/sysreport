#!/usr/bin/env bash

report_optimization() {
  local disk_usage load_one cpu_cores swap_used disabled_funcs

  sysreport_section "Optimization Checks"

  disk_usage="$(df / 2>/dev/null | awk 'NR==2 {gsub("%","",$5); print $5}')"
  if [[ -n "$disk_usage" && "$disk_usage" -ge 85 ]]; then
    sysreport_fail "root disk usage is high (${disk_usage}%)"
  elif [[ -n "$disk_usage" ]]; then
    sysreport_ok "root disk usage is healthy (${disk_usage}%)"
  else
    sysreport_unknown "root disk usage unavailable"
  fi

  load_one="$(uptime 2>/dev/null | awk -F'load average: ' '{print $2}' | cut -d, -f1 | tr -d ' ')"
  cpu_cores="$(nproc 2>/dev/null || echo 1)"
  if [[ -n "${load_one:-}" ]] && awk "BEGIN {exit !($load_one > $cpu_cores)}" 2>/dev/null; then
    sysreport_warn "1-minute load (${load_one}) is above CPU cores (${cpu_cores})"
  else
    sysreport_ok "1-minute load (${load_one:-unknown}) is within CPU capacity (${cpu_cores})"
  fi

  swap_used="$(free -m 2>/dev/null | awk '/^Swap:/ {print $3}')"
  if [[ -n "$swap_used" && "$swap_used" -gt 500 ]]; then
    sysreport_warn "swap usage is above 500 MB (${swap_used} MB)"
  elif [[ -n "$swap_used" ]]; then
    sysreport_ok "swap usage is low (${swap_used} MB)"
  else
    sysreport_unknown "swap usage unavailable"
  fi

  if pgrep -af 'redis-server|memcached' >/dev/null 2>&1; then
    sysreport_ok "object cache service detected"
  else
    sysreport_warn "no Redis or Memcached process detected"
  fi

  if sysreport_have php; then
    disabled_funcs="$(php -r 'echo ini_get("disable_functions");' 2>/dev/null || true)"
    if [[ -z "$disabled_funcs" ]]; then
      sysreport_warn "PHP disable_functions is empty"
    else
      sysreport_ok "PHP disable_functions is configured"
    fi
  else
    sysreport_unknown "PHP CLI not available for PHP hardening check"
  fi
}

sysreport_register_section "optimization" "Operational optimization checks" "report_optimization"
