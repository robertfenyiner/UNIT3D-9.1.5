#!/bin/bash
# Enhanced server info script with tracker diagnostics
# Reads TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID from environment (do NOT hardcode tokens!)

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

# Database connection for user lookup (optional - will work without it)
MYSQL_CMD="$(command -v mysql || true)"
DB_HOST="${DB_HOST:-localhost}"
DB_DATABASE="${DB_DATABASE:-unit3d}"
DB_USERNAME="${DB_USERNAME:-}"
DB_PASSWORD="${DB_PASSWORD:-}"

# Function to get username from passkey
get_username_from_passkey() {
  local passkey="$1"
  if [[ -n "$MYSQL_CMD" && -x "$MYSQL_CMD" && -n "$DB_USERNAME" ]]; then
    if [[ -n "$DB_PASSWORD" ]]; then
      mysql -h "$DB_HOST" -u "$DB_USERNAME" -p"$DB_PASSWORD" "$DB_DATABASE" -se "SELECT username FROM users WHERE passkey='$passkey' LIMIT 1;" 2>/dev/null || echo "unknown"
    else
      mysql -h "$DB_HOST" -u "$DB_USERNAME" "$DB_DATABASE" -se "SELECT username FROM users WHERE passkey='$passkey' LIMIT 1;" 2>/dev/null || echo "unknown"
    fi
  else
    echo "unknown"
  fi
}

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
SERVICES=("nginx" "redis-server" "php8.4-fpm")
SERVICIO_STATUS=""
for service in "${SERVICES[@]}"; do
  if systemctl is-active --quiet "$service"; then
    SERVICIO_STATUS+="🟢 $service"$'\n'
  else
    SERVICIO_STATUS+="🔴 $service"$'\n'
  fi
done

# Tracker analysis
if [[ -f "$ACCESS_LOG" ]]; then
  ANNOUNCE_REQUESTS=$(tail -n "$TAIL_LINES" "$ACCESS_LOG" | grep -c "$ANNOUNCE_PATH" || echo "0")
  ANNOUNCE_UNIQUE_IPS=$(tail -n "$TAIL_LINES" "$ACCESS_LOG" | grep "$ANNOUNCE_PATH" | awk '{print $1}' | sort -u | wc -l || echo "0")
  ANNOUNCE_429_COUNT=$(tail -n "$TAIL_LINES" "$ACCESS_LOG" | grep "$ANNOUNCE_PATH" | grep -c ' 429 ' || echo "0")
  TRACKER_LOG_MATCHES=$(tail -n "$TAIL_LINES" "$ACCESS_LOG" | grep -c "$ANNOUNCE_PATH" || echo "0")
  
  # Top IPs making announce requests
  TOP_IPS_RAW=$(tail -n "$TAIL_LINES" "$ACCESS_LOG" | grep "$ANNOUNCE_PATH" | awk '{print $1}' | sort | uniq -c | sort -nr | head -n 3)
  if [[ -n "$TOP_IPS_RAW" ]]; then
    TOP_IPS=$(echo "$TOP_IPS_RAW" | awk '{print "🔸 " $2 ": " $1 " reqs"}')
  else
    TOP_IPS="(none)"
  fi
  
  # Top User-Agents making announce requests
  TOP_UAS_RAW=$(tail -n "$TAIL_LINES" "$ACCESS_LOG" | grep "$ANNOUNCE_PATH" | sed 's/.*"\([^"]*\)"$/\1/' | sort | uniq -c | sort -nr | head -n 3)
  if [[ -n "$TOP_UAS_RAW" ]]; then
    TOP_UAS=$(echo "$TOP_UAS_RAW" | awk '{$1=$1; gsub(/^[0-9]+ /, ""); print "🔸 " substr($0, 1, 40) "..."}')
  else
    TOP_UAS="(none)"
  fi
  
  # Top passkeys (extract from announce URLs with usernames)
  TOP_PASSKEYS_RAW=$(tail -n "$TAIL_LINES" "$ACCESS_LOG" | grep "$ANNOUNCE_PATH" | grep -oE 'passkey=[a-f0-9]{32}' | cut -d= -f2 | sort | uniq -c | sort -nr | head -n 3)
  if [[ -n "$TOP_PASSKEYS_RAW" ]]; then
    TOP_PASSKEYS=""
    while read -r count passkey; do
      if [[ -n "$count" && -n "$passkey" ]]; then
        username=$(get_username_from_passkey "$passkey")
        if [[ "$username" != "unknown" && -n "$username" ]]; then
          TOP_PASSKEYS+="🔸 $username ($(echo $passkey | cut -c1-8)...): $count reqs"$'\n'
        else
          TOP_PASSKEYS+="🔸 $(echo $passkey | cut -c1-8)...: $count reqs"$'\n'
        fi
      fi
    done <<< "$TOP_PASSKEYS_RAW"
  else
    TOP_PASSKEYS="(none)"
  fi
else
  ANNOUNCE_REQUESTS="(log not found)"
  ANNOUNCE_UNIQUE_IPS="(log not found)"
  ANNOUNCE_429_COUNT="(log not found)"
  TRACKER_LOG_MATCHES="(log not found)"
  TOP_IPS="(no data)"
  TOP_UAS="(no data)"
  TOP_PASSKEYS="(no data)"
fi

# Queue info
QUEUE_INFO="(none found)"
if [[ -n "$REDIS_CLI" && -x "$REDIS_CLI" ]]; then
  REDIS_INFO="🟢 Redis OK"
  REDIS_ANNOUNCE_KEYS=$($REDIS_CLI --scan --pattern '*announce*' 2>/dev/null | wc -l || echo "0")
  
  # Laravel queues (common queue names)
  QUEUE_NAMES=("default" "high" "low" "emails" "notifications")
  QUEUE_STATUS=""
  for queue in "${QUEUE_NAMES[@]}"; do
    queue_length=$($REDIS_CLI llen "queues:$queue" 2>/dev/null || echo "0")
    if [[ "$queue_length" -gt 0 ]]; then
      QUEUE_STATUS+="🔸 $queue: $queue_length jobs"$'\n'
    fi
  done
  if [[ -n "$QUEUE_STATUS" ]]; then
    QUEUE_INFO="$QUEUE_STATUS"
  else
    QUEUE_INFO="🟢 All queues empty"
  fi
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
    PHP_FPM_POOLS_INFO+="🔸 $name: $pm_children max"$'\n'
    if [[ "$pm_children" =~ ^[0-9]+$ ]]; then
      total_max=$((total_max + pm_children))
    fi
  done
  PHP_FPM_TOTAL_MAX_CHILDREN="$total_max"
  
  # Count actual running PHP-FPM processes
  PHP_FPM_PROCESS_COUNT=$(pgrep -c -f 'php.*fpm' 2>/dev/null || echo "0")
  
  # Average RSS of PHP-FPM processes
  avg_rss_kb=$(pgrep -f 'php.*fpm' | xargs -r ps -o rss= -p 2>/dev/null | awk '{sum+=$1; n+=1} END{ if(n>0) printf("%.0f", sum/n); else print "0"}')
  if [[ "$avg_rss_kb" =~ ^[0-9]+$ && "$avg_rss_kb" -gt 0 ]]; then
    PHP_FPM_AVG_RSS_MB=$(awk "BEGIN {printf \"%.1f\", ($avg_rss_kb/1024)}")
  fi
fi

# Build message with proper line breaks
MSG=$'🧾 ESTADO DEL SERVIDOR - '"${HOSTNAME}"$'\n'
MSG+=$'━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
MSG+=$'📆 '"${DATE}"$'\n\n'

MSG+=$'🖥️ SISTEMA\n'
MSG+=$'─────────\n'
MSG+=$'⏱️ Uptime: '"${UPTIME}"$'\n'
MSG+=$'📊 Carga: '"${LOAD}"$'\n'
MSG+=$'⚙️ CPU: '"${CPU_USAGE}"$'\n'
MSG+=$'💾 RAM: '"${USED_MEM}"$'MB / '"${TOTAL_MEM}"$'MB\n'
MSG+=$'📦 Swap: '"${USED_SWAP}"$'MB\n'
MSG+=$'🗃️ Disco /: '"${DISK_USAGE}"$'\n'
MSG+=$'🌐 Conexiones: '"${ACTIVE_CONNS}"$' | 🔐 SSH: '"${SSH_SESSIONS}"$'\n\n'

MSG+=$'📊 TOP PROCESOS\n'
MSG+=$'──────────────\n'
MSG+=$'🔍 CPU:\n'"${TOP_CPU}"$'\n\n'
MSG+=$'🧠 RAM:\n'"${TOP_MEM}"$'\n\n'

MSG+=$'🧩 SERVICIOS\n'
MSG+=$'───────────\n'
MSG+="${SERVICIO_STATUS}"$'\n'

MSG+=$'🛰️ TRACKER\n'
MSG+=$'──────────\n'
MSG+=$'📈 Announces: '"${ANNOUNCE_REQUESTS}"$'\n'
MSG+=$'🌍 IPs únicas: '"${ANNOUNCE_UNIQUE_IPS}"$'\n'
if [[ "$ANNOUNCE_429_COUNT" != "0" ]]; then
  MSG+=$'⚠️ HTTP 429: '"${ANNOUNCE_429_COUNT}"$'\n'
fi
MSG+=$'\n'

if [[ "$TOP_IPS" != "(none)" && "$TOP_IPS" != "(no data)" ]]; then
  MSG+=$'🥇 TOP IPs:\n'"${TOP_IPS}"$'\n'
fi
if [[ "$TOP_PASSKEYS" != "(none)" && "$TOP_PASSKEYS" != "(no data)" ]]; then
  MSG+=$'� TOP USUARIOS:\n'"${TOP_PASSKEYS}"$'\n'
fi

MSG+=$'\n🔧 REDIS & COLAS\n'
MSG+=$'──────────────\n'
MSG+="${REDIS_INFO}"$'\n'
MSG+=$'🗝️ Keys '"'"'announce'"'"': '"${REDIS_ANNOUNCE_KEYS}"$'\n'
MSG+=$'📋 Colas:\n'"${QUEUE_INFO}"$'\n'

MSG+=$'🧩 PHP-FPM & CPU\n'
MSG+=$'───────────────\n'
MSG+=$'🖥️ CPUs: '"${CPU_COUNT}"$'\n'
MSG+=$'⚙️ Pools: '"${PHP_FPM_TOTAL_MAX_CHILDREN}"$' max\n'
MSG+=$'🔄 Procesos: '"${PHP_FPM_PROCESS_COUNT}"$'\n'
MSG+=$'💾 Avg RSS: '"${PHP_FPM_AVG_RSS_MB}"$' MB\n'

# Send to Telegram
curl -s -X POST \
  "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
  -d "chat_id=${CHAT_ID}" \
  -d "text=${MSG}" \
  -d "parse_mode=HTML" >/dev/null

echo "Server info report sent to Telegram."
