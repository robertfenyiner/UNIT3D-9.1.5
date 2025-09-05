#!/bin/bash
# Enhanced alert script with tracker checks
# Expects TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID in environment

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

# Thresholds
MAX_SWAP_MB=2048
MAX_DISK_PCT=90
MAX_MEM_PCT=85
MAX_CPU_PCT=85

# Tracker / log settings
ACCESS_LOG="/var/log/nginx/access.log"
ANNOUNCE_PATH="/announce/"
TAIL_LINES=20000

# Collect system metrics
USED_SWAP=$(free -m | awk '/Swap/ {print $3}' 2>/dev/null || echo "0")
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//' 2>/dev/null || echo "0")
MEM_USAGE=$(free | awk '/Mem:/ {printf("%.0f", $3/$2 * 100)}' 2>/dev/null || echo "0")
CPU_USAGE_INT=$(top -bn1 | grep "Cpu(s)" | awk '{printf("%.0f", 100 - $8)}' 2>/dev/null || echo "0")
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Processes
TOP_CPU=$(ps -eo pid,comm,%cpu --sort=-%cpu | head -n 4 | tail -n 3 | awk '{print "🔸 " $2 " (PID " $1 "): " $3 "% CPU"}')
TOP_MEM=$(ps -eo pid,comm,%mem --sort=-%mem | head -n 4 | tail -n 3 | awk '{print "🔸 " $2 " (PID " $1 "): " $3 "% RAM"}')

# Connections
ACTIVE_CONNS=$(ss -tun | grep ESTAB | wc -l 2>/dev/null || echo "0")
SSH_SESSIONS=$(who | wc -l 2>/dev/null || echo "0")

# Services
SERVICIOS=("nginx" "mysql" "redis" "php-fpm" "meilisearch")

ALERT_MSG=""
SEND_ALERT=false

# Checks
if [ "$USED_SWAP" -gt "$MAX_SWAP_MB" ]; then
  ALERT_MSG+="⚠️ *Swap alta:* ${USED_SWAP}MB (umbral: ${MAX_SWAP_MB}MB)\n"
  SEND_ALERT=true
fi
if [ "$DISK_USAGE" -gt "$MAX_DISK_PCT" ]; then
  ALERT_MSG+="⚠️ *Disco lleno:* ${DISK_USAGE}% (umbral: ${MAX_DISK_PCT}%)\n"
  SEND_ALERT=true
fi
if [ "$MEM_USAGE" -gt "$MAX_MEM_PCT" ]; then
  ALERT_MSG+="⚠️ *RAM alta:* ${MEM_USAGE}% (umbral: ${MAX_MEM_PCT}%)\n"
  SEND_ALERT=true
fi
if [ "$CPU_USAGE_INT" -gt "$MAX_CPU_PCT" ]; then
  ALERT_MSG+="⚠️ *CPU alta:* ${CPU_USAGE_INT}% (umbral: ${MAX_CPU_PCT}%)\n"
  SEND_ALERT=true
fi

for SERV in "${SERVICIOS[@]}"; do
  STATUS=$(systemctl is-active $SERV 2>/dev/null || echo "not found")
  if [[ "$STATUS" != "active" ]]; then
    ALERT_MSG+="❌ *Servicio caído:* ${SERV} (${STATUS})\n"
    SEND_ALERT=true
  fi
done

# Tracker quick checks: look for 429s and announce spikes
ANNOUNCE_REQUESTS=0
ANNOUNCE_429=0
ANNOUNCE_UNIQUE_IPS=0
if [[ -f "$ACCESS_LOG" ]]; then
  SAMPLE=$(tail -n "$TAIL_LINES" "$ACCESS_LOG" 2>/dev/null || true)
  if [[ -n "$SAMPLE" ]]; then
    ANNOUNCE_REQUESTS=$(echo "$SAMPLE" | grep -F "$ANNOUNCE_PATH" | wc -l)
    ANNOUNCE_429=$(echo "$SAMPLE" | grep -F " 429 " | wc -l)
    ANNOUNCE_UNIQUE_IPS=$(echo "$SAMPLE" | grep -F "$ANNOUNCE_PATH" | awk '{print $1}' | sort -u | wc -l)
    if [ "$ANNOUNCE_429" -gt 0 ]; then
      ALERT_MSG+="⚠️ *HTTP 429s detected in access log:* ${ANNOUNCE_429} occurrences (sample)\n"
      SEND_ALERT=true
    fi
    # Heuristic: sudden spike threshold (adjust to your normal traffic)
    if [ "$ANNOUNCE_REQUESTS" -gt 1000 ]; then
      ALERT_MSG+="⚠️ *High announce rate:* ${ANNOUNCE_REQUESTS} announces in sample (possible bot/spike)\n"
      SEND_ALERT=true
    fi
  fi
fi

# If alert, append details and send
if [ "$SEND_ALERT" = true ]; then
  ALERT_TEXT="🚨 *ALERTA CRÍTICA - $(hostname)* 🚨\n\n"
  ALERT_TEXT+="📆 *Hora:* ${DATE}\n\n"
  ALERT_TEXT+=$ALERT_MSG
  ALERT_TEXT+=$'\n'"🔍 *Top procesos por CPU:*\n${TOP_CPU}\n\n"
  ALERT_TEXT+=$'\n'"🧠 *Top procesos por RAM:*\n${TOP_MEM}\n\n"
  ALERT_TEXT+=$'\n'"🌐 *Conexiones activas:* ${ACTIVE_CONNS}\n"
  ALERT_TEXT+=$'\n'"🔐 *Sesiones SSH:* ${SSH_SESSIONS}\n\n"
  ALERT_TEXT+=$'\n'"🛰️ *Tracker quick stats (sample last ${TAIL_LINES} lines):*\n"
  ALERT_TEXT+="• Announce requests (sample): ${ANNOUNCE_REQUESTS}\n"
  ALERT_TEXT+="• Unique IPs hitting announce (sample): ${ANNOUNCE_UNIQUE_IPS}\n"
  ALERT_TEXT+="• HTTP 429 in sample: ${ANNOUNCE_429}\n"

  curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
    -d chat_id="${CHAT_ID}" \
    -d text="$ALERT_TEXT"
fi
