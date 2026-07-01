#!/usr/bin/env bash

report_security_port() {
  local port="$1" service
  if sysreport_have ss && ss -H -tln 2>/dev/null | awk '{print $4}' | grep -Eq "[:.]${port}$"; then
    service="$(ss -H -tlnp 2>/dev/null | awk -v port="$port" '$4 ~ ":" port "$" {print $0; exit}' | sed 's/.*users:(("//; s/".*//')"
    sysreport_ok "port $port open${service:+ ($service)}"
  else
    sysreport_warn "port $port closed or not visible"
  fi
}

report_security() {
  local ssh_config ssh_port root_login password_auth firewall_state

  sysreport_section "Security"

  ssh_config="/etc/ssh/sshd_config"
  if [[ -r "$ssh_config" ]]; then
    ssh_port="$(awk 'tolower($1)=="port" {print $2; exit}' "$ssh_config")"
    root_login="$(awk 'tolower($1)=="permitrootlogin" {print $2; exit}' "$ssh_config")"
    password_auth="$(awk 'tolower($1)=="passwordauthentication" {print $2; exit}' "$ssh_config")"
  fi

  sysreport_item "SSH port" "${ssh_port:-22}"
  [[ "${ssh_port:-22}" == "22" ]] && sysreport_warn "SSH is using the default port 22" || sysreport_ok "SSH port is customized"
  sysreport_item "SSH root login" "${root_login:-default}"
  [[ "${root_login:-}" == "yes" ]] && sysreport_warn "PermitRootLogin is enabled" || sysreport_ok "PermitRootLogin is not explicitly enabled"
  sysreport_item "SSH password auth" "${password_auth:-default}"

  if sysreport_have systemctl; then
    if systemctl is-active --quiet firewalld 2>/dev/null; then
      firewall_state="firewalld active"
    elif systemctl is-active --quiet ufw 2>/dev/null; then
      firewall_state="ufw active"
    elif systemctl is-active --quiet csf 2>/dev/null; then
      firewall_state="csf active"
    else
      firewall_state="no common firewall service active"
    fi
    sysreport_item "Firewall" "$firewall_state"
  fi

  if sysreport_have fail2ban-client; then
    sysreport_item "Fail2ban" "$(fail2ban-client ping 2>/dev/null | tr '\n' ' ' || echo detected)"
  else
    sysreport_item "Fail2ban" "not detected"
  fi

  printf '\n'
  sysreport_item "Common exposed ports" ""
  for port in 22 80 443 3306 5432 6379 8080 2083 2087; do
    report_security_port "$port"
  done
}

sysreport_register_section "security" "Security posture" "report_security"
