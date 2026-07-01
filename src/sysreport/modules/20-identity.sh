#!/usr/bin/env bash

report_identity() {
  local hostname_value private_ipv4 public_ipv4 public_ipv6 location ip_info country city

  sysreport_section "Identity and Location"

  hostname_value="$(hostname -f 2>/dev/null || hostname 2>/dev/null || echo unknown)"
  private_ipv4="$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for (i=1;i<=NF;i++) if ($i=="src") {print $(i+1); exit}}')"

  if sysreport_have curl; then
    public_ipv4="$(curl -fsS --max-time 3 -4 https://icanhazip.com 2>/dev/null | head -n1 || true)"
    public_ipv6="$(curl -fsS --max-time 3 -6 https://icanhazip.com 2>/dev/null | head -n1 || true)"
  fi

  sysreport_item "Hostname" "$hostname_value"
  sysreport_item "Primary IPv4" "${private_ipv4:-unknown}"
  sysreport_item "Public IPv4" "${public_ipv4:-unknown}"
  sysreport_item "Public IPv6" "${public_ipv6:-not detected}"

  if [[ -n "${public_ipv4:-}" ]] && sysreport_have curl && sysreport_have jq; then
    ip_info="$(curl -fsS --max-time 4 "http://ip-api.com/json/${public_ipv4}" 2>/dev/null || true)"
    country="$(printf '%s' "$ip_info" | jq -r '.country // empty' 2>/dev/null || true)"
    city="$(printf '%s' "$ip_info" | jq -r '.city // empty' 2>/dev/null || true)"
    location="$(printf '%s, %s' "${city:-unknown}" "${country:-unknown}")"
    sysreport_item "Geolocation" "$location"
  else
    sysreport_item "Geolocation" "skipped (requires curl, jq, and public IPv4)"
  fi
}

sysreport_register_section "identity" "Host identity and public IP" "report_identity"
