#!/usr/bin/env bash

report_system() {
  local os kernel uptime_text load_avg cpu_cores memory_line swap_line root_usage

  sysreport_section "System Summary"

  os="$(sysreport_read_os_release)"
  kernel="$(uname -r 2>/dev/null || echo unknown)"
  uptime_text="$(uptime -p 2>/dev/null || uptime 2>/dev/null || echo unknown)"
  load_avg="$(uptime 2>/dev/null | awk -F'load average: ' '{print $2}' || true)"
  cpu_cores="$(nproc 2>/dev/null || getconf _NPROCESSORS_ONLN 2>/dev/null || echo unknown)"
  memory_line="$(free -h 2>/dev/null | awk '/^Mem:/ {print $3 " used / " $2 " total"}')"
  swap_line="$(free -h 2>/dev/null | awk '/^Swap:/ {print $3 " used / " $2 " total"}')"
  root_usage="$(df -h / 2>/dev/null | awk 'NR==2 {print $5 " used on " $1 " (" $4 " free)"}')"

  sysreport_item "OS" "$os"
  sysreport_item "Kernel" "$kernel"
  sysreport_item "Uptime" "$uptime_text"
  sysreport_item "CPU cores" "$cpu_cores"
  sysreport_item "Load average" "${load_avg:-unknown}"
  sysreport_item "Memory" "${memory_line:-unknown}"
  sysreport_item "Swap" "${swap_line:-unknown}"
  sysreport_item "Root filesystem" "${root_usage:-unknown}"

  if sysreport_have fastfetch && sysreport_use_color; then
    printf '\n'
    fastfetch --pipe false 2>/dev/null || true
  fi
}

sysreport_register_section "system" "System summary" "report_system"
