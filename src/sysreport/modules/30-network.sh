#!/usr/bin/env bash

report_network_ping() {
  local target="$1" ms
  if ! sysreport_have ping; then
    sysreport_unknown "ping command not available"
    return 0
  fi

  ms="$(ping -c 1 -W 2 "$target" 2>/dev/null | awk -F'time=' '/time=/{print $2}' | awk '{print $1; exit}')"
  if [[ -n "$ms" ]]; then
    sysreport_ok "$target reachable (${ms} ms)"
  else
    sysreport_warn "$target timeout or unreachable"
  fi
}

report_network() {
  local targets target

  sysreport_section "Network"

  targets="${SYSREPORT_PING_TARGETS:-1.1.1.1 google.com github.com}"
  sysreport_item "Ping targets" "$targets"
  for target in $targets; do
    report_network_ping "$target"
  done

  printf '\n'
  sysreport_item "DNS resolvers" ""
  if [[ -r /etc/resolv.conf ]]; then
    awk '/^nameserver/ {print "  " $2}' /etc/resolv.conf
  else
    sysreport_unknown "/etc/resolv.conf is not readable"
  fi

  printf '\n'
  sysreport_item "Listening TCP ports" ""
  if sysreport_have ss; then
    ss -H -tln 2>/dev/null | awk '{print "  " $4}' | sed 's/.*://' | sort -n | uniq | head -n 30
  else
    sysreport_unknown "ss command not available"
  fi
}

sysreport_register_section "network" "Network diagnostics" "report_network"
