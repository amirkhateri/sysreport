#!/usr/bin/env bash

report_webstack() {
  local apache_version nginx_version php_version cpanel_version accounts suspended fpm_services disabled_functions

  sysreport_section "Web Stack"

  if sysreport_have httpd; then
    apache_version="$(httpd -v 2>/dev/null | awk 'NR==1 {print $3}')"
    sysreport_item "Apache" "${apache_version:-detected}"
  elif sysreport_have apache2; then
    apache_version="$(apache2 -v 2>/dev/null | awk 'NR==1 {print $3}')"
    sysreport_item "Apache" "${apache_version:-detected}"
  else
    sysreport_item "Apache" "not detected"
  fi

  if sysreport_have nginx; then
    nginx_version="$(nginx -v 2>&1 | sed 's/^nginx version: //')"
    sysreport_item "Nginx" "${nginx_version:-detected}"
  else
    sysreport_item "Nginx" "not detected"
  fi

  if pgrep -af 'litespeed|lshttpd' >/dev/null 2>&1; then
    sysreport_item "LiteSpeed" "running"
  else
    sysreport_item "LiteSpeed" "not detected"
  fi

  if sysreport_have php; then
    php_version="$(php -v 2>/dev/null | awk 'NR==1 {print $1 " " $2}')"
    disabled_functions="$(php -r 'echo ini_get("disable_functions");' 2>/dev/null || true)"
    sysreport_item "PHP CLI" "${php_version:-detected}"
    sysreport_item "PHP OPcache" "$(php -v 2>/dev/null | grep -iq opcache && echo enabled || echo not detected)"
    sysreport_item "PHP disable_functions" "${disabled_functions:-empty}"
  else
    sysreport_item "PHP CLI" "not detected"
  fi

  if sysreport_have systemctl; then
    fpm_services="$(systemctl list-units --type=service --no-legend 2>/dev/null | awk '/php.*fpm|ea-php.*fpm/ {print $1 " " $4}' | head -n 20)"
    sysreport_item "PHP-FPM units" "${fpm_services:-none detected}"
  fi

  if [[ -x /usr/local/cpanel/cpanel ]]; then
    cpanel_version="$(/usr/local/cpanel/cpanel -V 2>/dev/null || true)"
    accounts="$(find /var/cpanel/users -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' ')"
    suspended="$(find /var/cpanel/suspended -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' ')"
    sysreport_item "cPanel/WHM" "version ${cpanel_version:-unknown}; accounts ${accounts:-0}; suspended ${suspended:-0}"
  else
    sysreport_item "cPanel/WHM" "not detected"
  fi
}

sysreport_register_section "webstack" "Web, PHP, and cPanel profile" "report_webstack"
