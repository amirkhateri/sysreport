#!/bin/bash

# --- Color Variables ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'
BOLD='\033[1m'

echo -e "${BLUE}${BOLD}=====================================================${NC}"
echo -e "${CYAN}${BOLD} 🚀 Ultimate WHM/cPanel DevOps Audit Tool v4.0       ${NC}"
echo -e "${BLUE}${BOLD}=====================================================${NC}"

# --- [1] Hardware & OS (Fastfetch) ---
if ! command -v fastfetch &> /dev/null; then
    echo -e "${YELLOW}[*] Installing fastfetch...${NC}"
    if command -v dnf &> /dev/null; then sudo dnf install fastfetch -y &>/dev/null
    elif command -v apt-get &> /dev/null; then sudo apt-get update -y && sudo apt-get install fastfetch -y &>/dev/null
    fi
fi

echo -e "\n${BLUE}${BOLD}--- [1] Hardware & OS Summary ---${NC}"
command -v fastfetch &> /dev/null && fastfetch || uname -a


# --- [2] Server Identity & Geolocation ---
echo -e "\n${BLUE}${BOLD}--- [2] Identity & Geolocation ---${NC}"

SERVER_IPV4=$(curl -s -m 3 -4 icanhazip.com)
SERVER_IPV6=$(curl -s -m 3 -6 icanhazip.com || echo "Not configured / No IPv6 Route")
SERVER_IP=$(curl -s -4 icanhazip.com || curl -s ifconfig.me)
HOSTNAME=$(hostname -f)

echo -e "${GREEN}• Hostname:${NC} $HOSTNAME"
echo -e "${GREEN}• IPv4 Address:${NC} ${SERVER_IPV4:-"Unknown"}"
echo -e "${GREEN}• IPv6 Address:${NC} ${SERVER_IPV6}"
# جایگزین یا مکمل در بخش 2
IP_INFO=$(curl -s http://ip-api.com/json/$SERVER_IPV4)
COUNTRY=$(echo $IP_INFO | jq -r '.country')
CITY=$(echo $IP_INFO | jq -r '.city')
echo -e "${GREEN}• Location:${NC} $CITY, $COUNTRY"


# --- [3] System Health & Resources ---
echo -e "\n${BLUE}${BOLD}--- [3] System Health & Resources ---${NC}"
LOAD_AVG=$(uptime | awk -F'load average:' '{ print $2 }' | xargs)
CPU_CORES=$(nproc)
SWAP_USAGE=$(free -m | awk '/Swap/ {print $3}')
OOM_KILLS=$(dmesg -T 2>/dev/null | grep -i "out of memory" | wc -l)

echo -e "${GREEN}• CPU Cores:${NC} $CPU_CORES"
echo -e "${GREEN}• Load Average (1m, 5m, 15m):${NC} $LOAD_AVG"
echo -ne "${GREEN}• Swap Usage:${NC} "
[ "$SWAP_USAGE" -gt 500 ] && echo -e "${RED}${SWAP_USAGE} MB (Warning: High Swap!)${NC}" || echo "${SWAP_USAGE} MB (Healthy)"
echo -ne "${GREEN}• OOM Kills (Recent):${NC} "
[ "$OOM_KILLS" -gt 0 ] && echo -e "${RED}$OOM_KILLS process(es) killed due to lack of RAM!${NC}" || echo "0 (No Out-of-Memory issues)"

# --- [4] Network Connectivity & Ping ---
echo -e "\n${BLUE}${BOLD}--- [4] Network & Connectivity ---${NC}"
ping_test() {
    local target=$1
    local ms=$(ping -c 1 -W 2 $target 2>/dev/null | grep time= | awk -F'time=' '{print $2}' | awk '{print $1}')
    if [ -n "$ms" ]; then echo -e "  $target: ${GREEN}OK ($ms ms)${NC}"; else echo -e "  $target: ${RED}Timeout/Failed${NC}"; fi
}
echo -e "${GREEN}• External Pings:${NC}"
ping_test "google.com"
ping_test "wordpress.org"
ping_test "digikala.ir"
ping_test "snapp.ir"
ping_test "webline.dev"

echo -e "${GREEN}• System Resolvers (/etc/resolv.conf):${NC}"
grep "nameserver" /etc/resolv.conf | sed 's/^/  /'

# --- [5] WHM/cPanel Statistics ---
echo -e "\n${BLUE}${BOLD}--- [5] WHM/cPanel Statistics ---${NC}"
if [ -f /usr/local/cpanel/cpanel ]; then
    CP_VER=$(/usr/local/cpanel/cpanel -V)
    ACCOUNTS=$(ls /var/cpanel/users 2>/dev/null | wc -l)
    SUSPENDED=$(ls /var/cpanel/suspended 2>/dev/null | wc -l)
    echo -e "${GREEN}• Version:${NC} $CP_VER"
    echo -e "${GREEN}• Hosted Accounts:${NC} Total: $ACCOUNTS | Suspended: $SUSPENDED"
else
    echo -e "${RED}• cPanel/WHM not detected.${NC}"
fi

# --- [6] Web Services, DB & PHP ---
echo -e "\n${BLUE}${BOLD}--- [6] Web, Database & PHP Profiles ---${NC}"
echo -ne "${GREEN}• Web Server:${NC} "
if command -v httpd &> /dev/null; then
    HTTPD_VER=$(httpd -v | head -n1 | awk '{print $3}')
    ps aux | grep -i litespeed | grep -v grep &> /dev/null && echo "LiteSpeed (with Apache $HTTPD_VER)" || echo "Apache ($HTTPD_VER)"
else echo "Unknown/Not Running"; fi

echo -ne "${GREEN}• Database:${NC} "
command -v mysql &> /dev/null && echo "$(mysql -V | awk '{print $4, $5}')" || echo "Not detected"

echo -e "${GREEN}• PHP Profiles (SAPI / FPM):${NC}"
[ -f /usr/local/cpanel/bin/rebuild_phpconf ] && /usr/local/cpanel/bin/rebuild_phpconf --current | sed 's/^/  /'

echo -e "${GREEN}• PHP-FPM Service Status:${NC}"
FPM_SERVICES=$(systemctl list-units --type=service | grep ea-php | grep fpm | awk '{print $1}')
if [ -z "$FPM_SERVICES" ]; then
    echo -e "  ${YELLOW}No EA-PHP-FPM services found running.${NC}"
else
    echo "$FPM_SERVICES" | while read -r service; do
        STATUS=$(systemctl is-active "$service")
        [ "$STATUS" == "active" ] && echo -e "  $service: ${GREEN}Running${NC}" || echo -e "  $service: ${RED}Stopped/Failed${NC}"
    done
fi

DISABLED_FUNCS=$(php -r 'echo ini_get("disable_functions");')
echo -ne "${GREEN}• CLI PHP Disabled Functions:${NC} "
[ -z "$DISABLED_FUNCS" ] && echo -e "${RED}NONE (High Security Risk!)${NC}" || echo -e "${YELLOW}$DISABLED_FUNCS${NC}"

# --- [7] Security & Firewall ---
echo -e "\n${BLUE}${BOLD}--- [7] Security & Firewall Status ---${NC}"
echo -ne "${GREEN}• CSF Firewall:${NC} "
[ -f /usr/sbin/csf ] && (systemctl is-active --quiet csf && echo -e "${GREEN}Active & Running${NC}" || echo -e "${RED}Installed but STOPPED${NC}") || echo -e "${YELLOW}Not Installed${NC}"

echo -ne "${GREEN}• Imunify360:${NC} "
command -v imunify360-agent &> /dev/null && (systemctl is-active --quiet imunify360 && echo -e "${GREEN}Active${NC}" || echo -e "${RED}Stopped${NC}") || echo "Not Installed"

SSH_PORT=$(grep -i "^Port" /etc/ssh/sshd_config | awk '{print $2}' | head -n1)
ROOT_LOGIN=$(grep -i "^PermitRootLogin" /etc/ssh/sshd_config | awk '{print $2}' | head -n1)
echo -ne "${GREEN}• SSH Configuration:${NC} Port: "
[ "${SSH_PORT:-22}" -eq 22 ] && echo -ne "${RED}22 (Unsafe)${NC}" || echo -ne "${GREEN}${SSH_PORT} (Secured)${NC}"
echo -ne " | Root Login: "
[[ "$ROOT_LOGIN" == "yes" ]] && echo -e "${RED}Enabled (Password allowed)${NC}" || echo -e "${GREEN}Secured ($ROOT_LOGIN)${NC}"

echo -e "${GREEN}• Critical Ports Status:${NC}"
for port in 22 80 443 2083 2087 3306; do
    if ss -tulpn | grep -q ":$port "; then
        SERVICE=$(ss -tulpn | grep ":$port " | awk '{print $7}' | cut -d'"' -f2 | head -n1)
        echo -e "  Port $port: ${GREEN}OPEN${NC} ($SERVICE)"
    else
        echo -e "  Port $port: ${RED}CLOSED${NC}"
    fi
done

# --- [8] Optimization Audit ---
echo -e "\n${BLUE}${BOLD}--- [8] DevOps Optimization Audit ---${NC}"
# Disk Space
DISK_USAGE=$(df / | tail -n1 | awk '{print $5}' | sed 's/%//')
[ "$DISK_USAGE" -gt 85 ] && echo -e "  [${RED}❌${NC}] Root Disk Usage Critical: ${RED}$DISK_USAGE% used!${NC}" || echo -e "  [${GREEN}✔${NC}] Disk Space healthy: $DISK_USAGE% used."
# Object Caching
if ps aux | grep -E "redis|memcached" | grep -v grep &> /dev/null; then echo -e "  [${GREEN}✔${NC}] Object Caching (Redis/Memcached) is active."; else echo -e "  [${YELLOW}⚠${NC}] No Object Cache active (Affects WP Performance)."; fi
# Default SSH
[ "${SSH_PORT:-22}" -eq 22 ] && echo -e "  [${RED}❌${NC}] SSH is on default port 22. Change it!" || echo -e "  [${GREEN}✔${NC}] SSH port is customized."
# Disabled Functions
[ -z "$DISABLED_FUNCS" ] && echo -e "  [${RED}❌${NC}] PHP disable_functions is empty. Add exec, shell_exec, etc." || echo -e "  [${GREEN}✔${NC}] PHP functions are restricted."



# --- [9] Performance, SEO & Core Web Vitals (TTFB) ---
echo -e "\n${BLUE}${BOLD}--- [9] SEO Performance & Web Protocols ---${NC}"
echo -ne "${GREEN}• Web Server:${NC} "
if command -v httpd &> /dev/null; then
    HTTPD_VER=$(httpd -v | head -n1 | awk '{print $3}')
    if ps aux | grep -i litespeed | grep -v grep &> /dev/null; then
        echo "LiteSpeed (Drop-in for Apache $HTTPD_VER)"
        HTTP3_STATUS="${GREEN}Supported (Native in LiteSpeed)${NC}"
    else
        echo "Apache ($HTTPD_VER)"
        HTTP3_STATUS="${YELLOW}Not Supported (Requires LiteSpeed/Nginx)${NC}"
    fi
else 
    echo "Unknown/Not Running"
    HTTP3_STATUS="Unknown"
fi

# Checking HTTP/2 and Compression
HTTP2_STATUS="${RED}Disabled${NC}"
BROTLI_STATUS="${RED}Disabled${NC}"
GZIP_STATUS="${RED}Disabled${NC}"

if command -v httpd &> /dev/null; then
    httpd -M 2>/dev/null | grep -q "http2_module" && HTTP2_STATUS="${GREEN}Enabled${NC}"
    httpd -M 2>/dev/null | grep -q "brotli_module" && BROTLI_STATUS="${GREEN}Enabled${NC}"
    httpd -M 2>/dev/null | grep -q "deflate_module" && GZIP_STATUS="${GREEN}Enabled${NC}"
fi

echo -e "${GREEN}• HTTP/2 Protocol:${NC} $HTTP2_STATUS"
echo -e "${GREEN}• HTTP/3 (QUIC):${NC} $HTTP3_STATUS"
echo -e "${GREEN}• Compression Modules:${NC} Brotli: $BROTLI_STATUS | Gzip: $GZIP_STATUS"

# Checking PHP Cache (OPcache)
echo -ne "${GREEN}• PHP OPcache (Critical for TTFB):${NC} "
if php -v 2>/dev/null | grep -iq "opcache"; then
    echo -e "${GREEN}Enabled & Active${NC}"
else
    echo -e "${RED}Disabled (Enable in MultiPHP INI for better TTFB)${NC}"
fi

# Object Caching
echo -ne "${GREEN}• Object Caching (Redis/Memcached):${NC} "
if ps aux | grep redis-server | grep -v grep &> /dev/null; then
    echo -e "${GREEN}Redis is Running${NC}"
elif ps aux | grep memcached | grep -v grep &> /dev/null; then
    echo -e "${GREEN}Memcached is Running${NC}"
else
    echo -e "${YELLOW}None (Affects Heavy WordPress DB Queries)${NC}"
fi



# --- [10] Database Deep Dive ---
echo -e "\n${BLUE}${BOLD}--- [10] Database Configuration ---${NC}"
echo -ne "${GREEN}• Database Version:${NC} "
command -v mysql &> /dev/null && echo "$(mysql -V | awk '{print $4, $5}')" || echo "Not detected"

echo -ne "${GREEN}• Slow Query Log:${NC} "
SLOW_LOG=$(mysql -N -s -e "show variables like 'slow_query_log';" 2>/dev/null | awk '{print $2}')
if [ "$SLOW_LOG" == "ON" ]; then
    echo -e "${GREEN}Enabled (Good for debugging)${NC}"
else
    echo -e "${YELLOW}Disabled (Enable temporarily if TTFB is high)${NC}"
fi

echo -e "\n${BLUE}${BOLD}--- [11] Advanced Database Health ---${NC}"
# چک کردن مقدار InnoDB Buffer Pool
BUF_POOL=$(mysql -N -s -e "show variables like 'innodb_buffer_pool_size';" | awk '{print $2/1024/1024/1024 " GB"}')
echo -e "${GREEN}• InnoDB Buffer Pool Size:${NC} $BUF_POOL"

# بررسی تعداد جداول خراب (Crashed Tables)
CRASHED=$(mysqlcheck --all-databases --fast --silent 2>&1 | grep "Table is marked as crashed")
if [ -z "$CRASHED" ]; then
    echo -e "${GREEN}• Table Integrity:${NC} All tables healthy"
else
    echo -e "${RED}• Table Integrity:${NC} WARNING: Crashed tables detected!"
fi


echo -e "\n${BLUE}${BOLD}===================================================================${NC}"
echo -e "${GREEN}${BOLD} 📊 Audit Complete! / AmirXDev: Thanks For Use :) (Khateri.ir) ${NC}"
echo -e "${BLUE}${BOLD}=====================================================================${NC}"