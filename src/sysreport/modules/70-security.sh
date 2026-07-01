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

report_security_unit() {
  local label="$1" unit="$2" status

  if ! sysreport_have systemctl; then
    return 1
  fi

  if ! systemctl list-unit-files --no-legend "$unit" 2>/dev/null | grep -q . && \
    ! systemctl list-units --no-legend "$unit" 2>/dev/null | grep -q .; then
    return 1
  fi

  status="$(systemctl is-active "$unit" 2>/dev/null || true)"
  case "$status" in
    active)
      sysreport_ok "$label active ($unit)"
      ;;
    failed)
      sysreport_fail "$label installed but failed ($unit)"
      ;;
    inactive|deactivating|activating)
      sysreport_warn "$label installed but $status ($unit)"
      ;;
    *)
      sysreport_warn "$label installed but status is ${status:-unknown} ($unit)"
      ;;
  esac

  return 0
}

report_security() {
  local ssh_config ssh_port root_login password_auth found_security_unit

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

  printf '\n'
  sysreport_item "Firewall and hardening services" ""
  found_security_unit=0
  report_security_unit "CSF firewall" "csf.service" && found_security_unit=1
  report_security_unit "LFD login failure daemon" "lfd.service" && found_security_unit=1
  report_security_unit "Imunify360" "imunify360.service" && found_security_unit=1
  report_security_unit "firewalld" "firewalld.service" && found_security_unit=1
  report_security_unit "ufw" "ufw.service" && found_security_unit=1
  [[ "$found_security_unit" -eq 0 ]] && sysreport_unknown "no common firewall or hardening service detected"

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
