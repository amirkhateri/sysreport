#!/usr/bin/env bash

report_database() {
  local mysql_version slow_log buffer_pool pg_version

  sysreport_section "Database"

  if sysreport_have mysql; then
    mysql_version="$(mysql -V 2>/dev/null)"
    sysreport_item "MySQL client" "${mysql_version:-detected}"

    slow_log="$(mysql --batch --skip-column-names -e "SHOW VARIABLES LIKE 'slow_query_log';" 2>/dev/null | awk '{print $2}' || true)"
    sysreport_item "MySQL slow query log" "${slow_log:-unknown or access denied}"

    buffer_pool="$(mysql --batch --skip-column-names -e "SHOW VARIABLES LIKE 'innodb_buffer_pool_size';" 2>/dev/null | awk '{printf "%.2f GB", $2/1024/1024/1024}' || true)"
    sysreport_item "InnoDB buffer pool" "${buffer_pool:-unknown or access denied}"
  else
    sysreport_item "MySQL client" "not detected"
  fi

  if sysreport_have psql; then
    pg_version="$(psql --version 2>/dev/null)"
    sysreport_item "PostgreSQL client" "${pg_version:-detected}"
  else
    sysreport_item "PostgreSQL client" "not detected"
  fi
}

sysreport_register_section "database" "Database summary" "report_database"
