#!/bin/bash
# Enhanced server info script with tracker diagnostics
# Reads TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID from environment (do NOT hardcode tokens)

# Load environment file if present (so running with sudo will still pick credentials)
ENV_FILE="/etc/default/metrics_bot_env"
if [[ -f "$ENV_FILE" ]]; then
  # shellcheck source=/etc/default/metrics_bot_env
  source "$ENV_FILE"
fi

BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}" 
CHAT_ID="${TELEGRAM_CHAT_ID:-}" 

if [[ -z "$BOT_TOKEN" || -z "$CHAT_ID" ]]; then
  echo "Please export TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID before running." >&2
  exit 1
fi

# Config (tune for your environment)
ACCESS_LOG="/var/log/nginx/access.log"
ANNOUNCE_PATH="/announce/"
TAIL_LINES=20000
TIME_WINDOW_MIN=60
REDIS_CLI="$(command -v redis-cli || true)"

HOSTNAME=$(hostname)
UPTIME=$(uptime -p)
LOAD=$(uptime | awk -F'load average:' '{ print $2 }' | sed 's/^ //')
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8"%"}' 2>/dev/null || echo "n/a")
USED_MEM=$(free -m | awk '/Mem:/ {print $3}' 2>/dev/null || echo "n/a")
TOTAL_MEM=$(free -m | awk '/Mem:/ {print $2}' 2>/dev/null || echo "n/a")
USED_SWAP=$(free -m | awk '/Swap:/ {print $3}' 2>/dev/null || echo "n/a")
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' 2>/dev/null || echo "n/a")
DATE=$(date '+%Y-%m-%d %H:%M:%S')

TOP_CPU=$(ps -eo pid,comm,%cpu --sort=-%cpu | head -n 4 | tail -n 3 | awk '{print "🔸 " $2 " (PID " $1 "): " $3 "% CPU"}')
TOP_MEM=$(ps -eo pid,comm,%mem --sort=-%mem | head -n 4 | tail -n 3 | awk '{print "🔸 " $2 " (PID " $1 "): " $3 "% RAM"}')
ACTIVE_CONNS=$(ss -tun | grep ESTAB | wc -l 2>/dev/null || echo "n/a")
SSH_SESSIONS=$(who | wc -l 2>/dev/null || echo "n/a")

# Services monitored
SERVICIOS=("nginx" "mysql" "redis" "php-fpm" "meilisearch")
SERVICIO_STATUS=""
for SERV in "${SERVICIOS[@]}"; do
  STATUS=$(systemctl is-active $SERV 2>/dev/null || echo "not found")
  ICON="✅"
  [[ "$STATUS" != "active" ]] && ICON="❌"
  SERVICIO_STATUS+="${ICON} *${SERV}*: ${STATUS}"$'\n'
done

# Tracker diagnostics (access log sample)
ANNOUNCE_REQUESTS="(no log)"
ANNOUNCE_UNIQUE_IPS="(no log)"
ANNOUNCE_429_COUNT="(no log)"
TOP_IPS="(no data)"
TOP_UAS="(no data)"
TOP_PASSKEYS="(no data)"
TRACKER_LOG_MATCHES="(no logs)"
REDIS_INFO="(redis-cli not found)"
REDIS_ANNOUNCE_KEYS="(redis-cli not found)"
QUEUE_INFO=""

if [[ -f "$ACCESS_LOG" ]]; then
  # Use tail to bound the amount of log lines we analyze
  LOG_SAMPLE=$(tail -n "$TAIL_LINES" "$ACCESS_LOG" 2>/dev/null || true)
  if [[ -n "$LOG_SAMPLE" ]]; then
    # Count announce requests (simple substring match) and unique IPs for those requests
    ANNOUNCE_REQUESTS=$(echo "$LOG_SAMPLE" | grep -F "$ANNOUNCE_PATH" | wc -l)
    ANNOUNCE_UNIQUE_IPS=$(echo "$LOG_SAMPLE" | grep -F "$ANNOUNCE_PATH" | awk '{print $1}' | sort -u | wc -l)
    # Count HTTP 429 responses seen in the sample
    ANNOUNCE_429_COUNT=$(echo "$LOG_SAMPLE" | grep ' 429 ' | wc -l)

    # Top IPs hitting announce (top 10)
    TOP_IPS=$(echo "$LOG_SAMPLE" | grep -F "$ANNOUNCE_PATH" | awk '{print $1}' | sort | uniq -c | sort -rn | head -n 10 | awk '{print $2 " (" $1 ")"}' | paste -sd ", " -)
    [[ -z "$TOP_IPS" ]] && TOP_IPS="(none)"

    # Top User-Agents for announce (top 10)
    TOP_UAS=$(echo "$LOG_SAMPLE" | grep -F "$ANNOUNCE_PATH" | awk -F '"' '{print $6}' | sort | uniq -c | sort -rn | head -n 10 | awk '{$1=$1; print substr($0,index($0,$2)) " (" $1 ")"}' | paste -sd ", " -)
    [[ -z "$TOP_UAS" ]] && TOP_UAS="(none)"

    # Top passkeys extracted from the path /announce/{passkey}
    TOP_PASSKEYS=$(echo "$LOG_SAMPLE" | grep -F "$ANNOUNCE_PATH" | awk -F '"' '{print $2}' | awk '{print $2}' | sed -n 's|.*/announce/\([^/? ]*\).*|\1|p' | sort | uniq -c | sort -rn | head -n 10 | awk '{print $2 " (" $1 ")"}' | paste -sd ", " -)
    [[ -z "$TOP_PASSKEYS" ]] && TOP_PASSKEYS="(none)"
  fi
else
  ACCESS_LOG="(not found)"
fi

# Grep application logs (Laravel) for tracker-related exceptions or 429s
LOG_DIR="storage/logs"
if [[ -d "$LOG_DIR" ]]; then
  TRACKER_LOG_MATCHES=$(grep -E "TrackerException|HTTP 429|Too Many Requests|announce" -R --line-number "$LOG_DIR" 2>/dev/null | wc -l)
else
  TRACKER_LOG_MATCHES="(no storage/logs)"
fi

# Redis metrics (if redis-cli exists)
if command -v redis-cli >/dev/null 2>&1; then
  # Basic info
  REDIS_INFO=$(redis-cli INFO SERVER | sed -n 's/\r//g; /instantaneous_ops_per_sec/p; /connected_clients/p; /used_memory_human/p' 2>/dev/null || echo "(redis info failed)")
  # Count keys with 'announce' in the name (tries to use SCAN to avoid blocking)
  if redis-cli --scan --pattern '*announce*' >/dev/null 2>&1; then
    REDIS_ANNOUNCE_KEYS=$(redis-cli --scan --pattern '*announce*' 2>/dev/null | wc -l)
  else
    REDIS_ANNOUNCE_KEYS=$(redis-cli KEYS '*announce*' 2>/dev/null | wc -l)
  fi

  # Check common Laravel queue keys for length (announce or default)
  for q in "queues:announce" "queues:default" "queues:high" "queues:low" "queues:processing"; do
    if redis-cli EXISTS "$q" >/dev/null 2>&1; then
      len=$(redis-cli LLEN "$q" 2>/dev/null || echo "0")
      QUEUE_INFO+="${q}: ${len}\n"
    fi
  done
else
  REDIS_INFO="(redis-cli not found)"
  REDIS_ANNOUNCE_KEYS="(redis-cli not found)"
fi

# PHP-FPM diagnostics (pools and process metrics)
PHP_FPM_POOLS_INFO="(none found)"
PHP_FPM_TOTAL_MAX_CHILDREN="(none)"
PHP_FPM_PROCESS_COUNT=0
PHP_FPM_AVG_RSS_MB="0"
CPU_COUNT=$(nproc 2>/dev/null || echo "n/a")

# Try to read pool files for any PHP version
POOL_FILES=$(ls /etc/php/*/fpm/pool.d/*.conf 2>/dev/null || true)
if [[ -n "$POOL_FILES" ]]; then
  PHP_FPM_POOLS_INFO=""
  total_max=0
  for f in $POOL_FILES; do
    name=$(basename "$f" .conf)
    pm_children=$(grep -E '^pm.max_children' "$f" 2>/dev/null | awk -F'=' '{gsub(/ /,"",$2); print $2}' || true)
    if [[ -z "$pm_children" ]]; then pm_children="(unset)"; fi
    PHP_FPM_POOLS_INFO+="${name}: pm.max_children=${pm_children}\n"
    if [[ "$pm_children" =~ ^[0-9]+$ ]]; then total_max=$((total_max + pm_children)); fi
  done
  if [[ $total_max -gt 0 ]]; then PHP_FPM_TOTAL_MAX_CHILDREN=$total_max; fi
fi

# Count php-fpm processes and estimate average RSS
PHP_FPM_PROCESS_COUNT=$(pgrep -f 'php.*fpm' | wc -l 2>/dev/null || echo 0)
if [[ "$PHP_FPM_PROCESS_COUNT" -gt 0 ]]; then
  avg_rss_kb=$(pgrep -f 'php.*fpm' | xargs -r ps -o rss= -p 2>/dev/null | awk '{sum+=$1; n+=1} END{ if(n>0) printf("%.0f", sum/n); else print "0"}')
  if [[ "$avg_rss_kb" =~ ^[0-9]+$ && "$avg_rss_kb" -gt 0 ]]; then
    PHP_FPM_AVG_RSS_MB=$(awk "BEGIN {printf \"%.1f\", ($avg_rss_kb/1024)}")
  fi
fi

# Build message
MSG="🧾 *Estado del servidor - ${HOSTNAME}*\n\n"
MSG+="📆 *Hora:* ${DATE}\n"
MSG+="🖥️ *Uptime:* ${UPTIME}\n"
MSG+="📊 *Carga promedio:* ${LOAD}\n"
MSG+="⚙️ *CPU en uso:* ${CPU_USAGE}\n"
MSG+="💾 *RAM:* ${USED_MEM}MB / ${TOTAL_MEM}MB\n"
MSG+="📦 *Swap usada:* ${USED_SWAP}MB\n"
MSG+="🗃️ *Disco en /*: ${DISK_USAGE}\n"
MSG+="🌐 *Conexiones activas:* ${ACTIVE_CONNS}\n"
MSG+="🔐 *Sesiones SSH:* ${SSH_SESSIONS}\n\n"
MSG+="🔍 *Top procesos por CPU:*\n${TOP_CPU}\n\n"
MSG+="🧠 *Top procesos por RAM:*\n${TOP_MEM}\n\n"
MSG+="🧩 *Servicios monitoreados:*\n${SERVICIO_STATUS}\n"

MSG+="\n🛰️ *Tracker diagnostics (last ${TAIL_LINES} lines of access log or until file end):*\n"
MSG+="• Access log: ${ACCESS_LOG}\n"
MSG+="• Announce requests (sample): ${ANNOUNCE_REQUESTS}\n"
MSG+="• Unique IPs hitting announce (sample): ${ANNOUNCE_UNIQUE_IPS}\n"
MSG+="• HTTP 429 in sample: ${ANNOUNCE_429_COUNT}\n"
MSG+="\n🔝 *Top IPs (announce):* ${TOP_IPS}\n"
MSG+="\n🧾 *Top User-Agents (announce):* ${TOP_UAS}\n"
MSG+="\n🔑 *Top passkeys (announce):* ${TOP_PASSKEYS}\n"
MSG+="• Tracker-related log matches: ${TRACKER_LOG_MATCHES}\n\n"
MSG+="🔧 *Redis & queues:*\n"
MSG+="• Redis INFO (ops/clients/memory):\n${REDIS_INFO}\n"
MSG+="• Redis keys matching '*announce*': ${REDIS_ANNOUNCE_KEYS}\n"
MSG+="• Queue lengths:\n${QUEUE_INFO}\n"

# Append PHP-FPM and CPU details
MSG+=$'\n'"🧩 *PHP-FPM & CPU diagnostics:*\n"
MSG+="• CPU count: ${CPU_COUNT}\n"
MSG+="• PHP-FPM pools found:\n${PHP_FPM_POOLS_INFO}\n"
MSG+="• Total configured pm.max_children (sum of pools): ${PHP_FPM_TOTAL_MAX_CHILDREN}\n"
MSG+="• PHP-FPM running processes: ${PHP_FPM_PROCESS_COUNT}\n"
MSG+="• Avg RSS per php-fpm process: ${PHP_FPM_AVG_RSS_MB} MB\n"

# Send message
curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
  -d chat_id="${CHAT_ID}" \
  --data-urlencode "text=${MSG}"
