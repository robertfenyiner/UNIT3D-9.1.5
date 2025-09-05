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

# Check if any thresholds exceeded
ALERT_NEEDED=false
ALERT_TEXT=""

if [[ "$USED_SWAP" -gt "$MAX_SWAP_MB" ]]; then
  ALERT_NEEDED=true
  ALERT_TEXT+=$'🚨 SWAP ALTA: '"${USED_SWAP}"$'MB > '"${MAX_SWAP_MB}"$'MB\n'
fi

if [[ "$DISK_USAGE" -gt "$MAX_DISK_PCT" ]]; then
  ALERT_NEEDED=true
  ALERT_TEXT+=$'🚨 DISCO LLENO: '"${DISK_USAGE}"$'% > '"${MAX_DISK_PCT}"$'%\n'
fi

if [[ "$MEM_USAGE" -gt "$MAX_MEM_PCT" ]]; then
  ALERT_NEEDED=true
  ALERT_TEXT+=$'🚨 RAM ALTA: '"${MEM_USAGE}"$'% > '"${MAX_MEM_PCT}"$'%\n'
fi

if [[ "$CPU_USAGE_INT" -gt "$MAX_CPU_PCT" ]]; then
  ALERT_NEEDED=true
  ALERT_TEXT+=$'🚨 CPU ALTA: '"${CPU_USAGE_INT}"$'% > '"${MAX_CPU_PCT}"$'%\n'
fi

# Tracker analysis
if [[ -f "$ACCESS_LOG" ]]; then
  ANNOUNCE_REQUESTS=$(tail -n "$TAIL_LINES" "$ACCESS_LOG" | grep -c "$ANNOUNCE_PATH" || echo "0")
  ANNOUNCE_429_COUNT=$(tail -n "$TAIL_LINES" "$ACCESS_LOG" | grep "$ANNOUNCE_PATH" | grep -c ' 429 ' || echo "0")
  
  # High 429 rate (>10% of requests)
  if [[ "$ANNOUNCE_REQUESTS" -gt 100 && "$ANNOUNCE_429_COUNT" -gt 0 ]]; then
    PCT_429=$(awk "BEGIN {printf \"%.1f\", ($ANNOUNCE_429_COUNT/$ANNOUNCE_REQUESTS)*100}")
    if (( $(awk "BEGIN {print ($PCT_429 > 10.0)}") )); then
      ALERT_NEEDED=true
      ALERT_TEXT+=$'🚨 TRACKER 429s: '"${ANNOUNCE_429_COUNT}"$'/'"${ANNOUNCE_REQUESTS}"$' ('"${PCT_429}"$'%)\n'
    fi
  fi

  # Extract analysis data for context
  ANNOUNCE_UNIQUE_IPS=$(tail -n "$TAIL_LINES" "$ACCESS_LOG" | grep "$ANNOUNCE_PATH" | awk '{print $1}' | sort -u | wc -l || echo "0")
  
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
  
  # Top passkeys (extract from announce URLs)
  TOP_PASSKEYS_RAW=$(tail -n "$TAIL_LINES" "$ACCESS_LOG" | grep "$ANNOUNCE_PATH" | grep -oE 'passkey=[a-f0-9]{32}' | cut -d= -f2 | sort | uniq -c | sort -nr | head -n 3)
  if [[ -n "$TOP_PASSKEYS_RAW" ]]; then
    TOP_PASSKEYS=$(echo "$TOP_PASSKEYS_RAW" | awk '{print "🔸 " substr($2, 1, 8) "...: " $1 " reqs"}')
  else
    TOP_PASSKEYS="(none)"
  fi
else
  ANNOUNCE_REQUESTS="(log not found)"
  ANNOUNCE_UNIQUE_IPS="(log not found)"
  ANNOUNCE_429_COUNT="(log not found)"
  TOP_IPS="(no data)"
  TOP_UAS="(no data)"
  TOP_PASSKEYS="(no data)"
fi

# Only send alert if thresholds exceeded
if [[ "$ALERT_NEEDED" == "true" ]]; then
  HOSTNAME=$(hostname)
  
  # Build full alert message
  FULL_MSG=$'🔥 ALERTA DEL SERVIDOR - '"${HOSTNAME}"$'\n'
  FULL_MSG+=$'━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
  FULL_MSG+=$'📆 '"${DATE}"$'\n\n'
  FULL_MSG+="${ALERT_TEXT}"$'\n'
  
  FULL_MSG+=$'📊 CONTEXTO DEL SISTEMA\n'
  FULL_MSG+=$'─────────────────────\n'
  FULL_MSG+=$'💾 RAM: '"${MEM_USAGE}"$'%\n'
  FULL_MSG+=$'📦 Swap: '"${USED_SWAP}"$'MB\n'
  FULL_MSG+=$'🗃️ Disco: '"${DISK_USAGE}"$'%\n'
  FULL_MSG+=$'⚙️ CPU: '"${CPU_USAGE_INT}"$'%\n'
  FULL_MSG+=$'🌐 Conexiones: '"${ACTIVE_CONNS}"$'\n\n'
  
  FULL_MSG+=$'🔍 TOP PROCESOS CPU\n'
  FULL_MSG+=$'──────────────────\n'
  FULL_MSG+="${TOP_CPU}"$'\n\n'
  
  FULL_MSG+=$'🧠 TOP PROCESOS RAM\n'
  FULL_MSG+=$'──────────────────\n'
  FULL_MSG+="${TOP_MEM}"$'\n\n'
  
  if [[ "$ANNOUNCE_REQUESTS" != "(log not found)" ]]; then
    FULL_MSG+=$'🛰️ TRACKER (últimas '"${TAIL_LINES}"$' líneas)\n'
    FULL_MSG+=$'────────────────────────────────\n'
    FULL_MSG+=$'📈 Announces: '"${ANNOUNCE_REQUESTS}"$'\n'
    FULL_MSG+=$'🌍 IPs únicas: '"${ANNOUNCE_UNIQUE_IPS}"$'\n'
    FULL_MSG+=$'⚠️ HTTP 429: '"${ANNOUNCE_429_COUNT}"$'\n\n'
    
    if [[ "$TOP_IPS" != "(none)" && "$TOP_IPS" != "(no data)" ]]; then
      FULL_MSG+=$'🥇 TOP IPs:\n'"${TOP_IPS}"$'\n'
    fi
    if [[ "$TOP_UAS" != "(none)" && "$TOP_UAS" != "(no data)" ]]; then
      FULL_MSG+=$'🤖 TOP User-Agents:\n'"${TOP_UAS}"$'\n'
    fi
    if [[ "$TOP_PASSKEYS" != "(none)" && "$TOP_PASSKEYS" != "(no data)" ]]; then
      FULL_MSG+=$'🔑 TOP Passkeys:\n'"${TOP_PASSKEYS}"$'\n'
    fi
  fi
  
  # Send alert to Telegram
  curl -s -X POST \
    "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
    -d "chat_id=${CHAT_ID}" \
    -d "text=${FULL_MSG}" \
    -d "parse_mode=HTML" >/dev/null
  
  echo "Alert sent to Telegram: thresholds exceeded."
else
  echo "No alerts needed - all metrics within thresholds."
fi
