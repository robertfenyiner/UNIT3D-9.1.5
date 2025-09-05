#!/bin/bash
# Enhanced server info script with tracker diagnostics
# Reads TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID from environment (do NOT hardcode tokens)

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
  SERVICIO_STATUS+="${ICON} *${SERV}*: ${STATUS}\n"
done

# Tracker diagnostics (access log sample)
ANNOUNCE_REQUESTS="(no log)"
ANNOUNCE_UNIQUE_IPS="(no log)"
ANNOUNCE_429_COUNT="(no log)"
TRACKER_LOG_MATCHES="(no logs)"
REDIS_INFO="(redis-cli not found)"
REDIS_ANNOUNCE_KEYS="(redis-cli not found)"
QUEUE_INFO="(redis-cli not found)"

if [[ -f "$ACCESS_LOG" ]]; then
  LOG_SAMPLE=$(tail -n "$TAIL_LINES" "$ACCESS_LOG" 2>/dev/null || true)
  if [[ -n "$LOG_SAMPLE" ]]; then
    ANNOUNCE_REQUESTS=$(echo "$LOG_SAMPLE" | grep -F "$ANNOUNCE_PATH" | wc -l)
    ANNOUNCE_UNIQUE_IPS=$(echo "$LOG_SAMPLE" | grep -F "$ANNOUNCE_PATH" | awk '{print $1}' | sort -u | wc -l)
    ANNOUNCE_429_COUNT=$(echo "$LOG_SAMPLE" | grep ' 429 ' | wc -l)
  fi
fi

# Laravel logs quick scan
LOG_DIR="storage/logs"
if [[ -d "$LOG_DIR" ]]; then
  TRACKER_LOG_MATCHES=$(grep -E "TrackerException|Too Many Requests|announce" -R --line-number "$LOG_DIR" 2>/dev/null | wc -l)
else
  TRACKER_LOG_MATCHES="(no storage/logs)"
fi

# Redis & queues
if [[ -n "$REDIS_CLI" ]]; then
  REDIS_INFO=$(redis-cli INFO SERVER | sed -n 's/\r//g; /instantaneous_ops_per_sec/p; /connected_clients/p; /used_memory_human/p' 2>/dev/null || echo "(redis info failed)")
  # Count keys without blocking using SCAN
  if redis-cli --scan --pattern '*announce*' >/dev/null 2>&1; then
    REDIS_ANNOUNCE_KEYS=$(redis-cli --scan --pattern '*announce*' 2>/dev/null | wc -l)
  else
    REDIS_ANNOUNCE_KEYS=$(redis-cli KEYS '*announce*' 2>/dev/null | wc -l)
  fi

  QUEUE_INFO=""
  for q in "queues:announce" "queues:default" "queues:high" "queues:low"; do
    # LLEN for lists, or ZCARD for sorted sets
    len=$(redis-cli LLEN "$q" 2>/dev/null || echo "0")
    [[ -n "$len" ]] && QUEUE_INFO+="${q}: ${len}\n"
  done
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
MSG+="• Tracker-related log matches: ${TRACKER_LOG_MATCHES}\n\n"
MSG+="🔧 *Redis & queues:*\n"
MSG+="• Redis INFO (ops/clients/memory):\n${REDIS_INFO}\n"
MSG+="• Redis keys matching '*announce*': ${REDIS_ANNOUNCE_KEYS}\n"
MSG+="• Queue lengths:\n${QUEUE_INFO}\n"

# Send message
curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
  -d chat_id="${CHAT_ID}" \
  -d text="$MSG" \
  -d parse_mode="Markdown"
