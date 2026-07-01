#!/usr/bin/env bash

report_service_status() {
  local label="$1" unit="$2"

  if ! sysreport_have systemctl; then
    sysreport_unknown "systemctl not available for $label"
    return 0
  fi

  if systemctl list-unit-files --no-legend "$unit" 2>/dev/null | grep -q . || \
    systemctl list-units --no-legend "$unit" 2>/dev/null | grep -q .; then
    if systemctl is-active --quiet "$unit" 2>/dev/null; then
      sysreport_ok "$label active ($unit)"
    else
      sysreport_warn "$label installed but not active ($unit)"
    fi
  else
    sysreport_unknown "$label not detected ($unit)"
  fi
}

report_services() {
  sysreport_section "Core Services"

  report_service_status "OpenSSH" "sshd.service"
  report_service_status "Nginx" "nginx.service"
  report_service_status "Apache httpd" "httpd.service"
  report_service_status "Apache apache2" "apache2.service"
  report_service_status "MariaDB" "mariadb.service"
  report_service_status "MySQL" "mysql.service"
  report_service_status "PostgreSQL" "postgresql.service"
  report_service_status "Redis" "redis.service"
  report_service_status "Memcached" "memcached.service"
  report_service_status "Docker" "docker.service"
}

sysreport_register_section "services" "Core service status" "report_services"
