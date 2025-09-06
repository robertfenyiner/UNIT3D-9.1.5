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

# Config
ACCESS_LOG="/var/log/nginx/access.log"
ANNOUNCE_PATH="/announce/"
TAIL_LINES=20000

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

# Thresholds (tune for your environment)
LOAD_THRESHOLD=10.0
CPU_THRESHOLD=80
MEM_THRESHOLD=85
SWAP_THRESHOLD=50
DISK_THRESHOLD=85
ANNOUNCE_429_THRESHOLD=50

# Get current metrics
LOAD_1MIN=$(uptime | awk -F'load average:' '{ print $2 }' | awk -F', ' '{ print $1 }' | tr -d ' ')
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}' 2>/dev/null || echo "0")
MEM_USAGE=$(free | awk '/Mem:/ {printf "%.0f", ($3/$2)*100}' 2>/dev/null || echo "0")
SWAP_USAGE=$(free | awk '/Swap:/ {if($2>0) printf "%.0f", ($3/$2)*100; else print "0"}' 2>/dev/null || echo "0")
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%' 2>/dev/null || echo "0")

# Check 429 errors in announce requests
ANNOUNCE_429_COUNT=0
if [[ -f "$ACCESS_LOG" ]]; then
  ANNOUNCE_429_COUNT=$(tail -n "$TAIL_LINES" "$ACCESS_LOG" | grep "$ANNOUNCE_PATH" | grep -c ' 429 ' || echo "0")
fi

# Clean variables
LOAD_1MIN=$(echo "$LOAD_1MIN" | tr -d '\n\r' | awk '{print $1}')
CPU_USAGE=$(echo "$CPU_USAGE" | tr -d '\n\r' | awk '{print $1}')
MEM_USAGE=$(echo "$MEM_USAGE" | tr -d '\n\r' | awk '{print $1}')
SWAP_USAGE=$(echo "$SWAP_USAGE" | tr -d '\n\r' | awk '{print $1}')
DISK_USAGE=$(echo "$DISK_USAGE" | tr -d '\n\r' | awk '{print $1}')
ANNOUNCE_429_COUNT=$(echo "$ANNOUNCE_429_COUNT" | tr -d '\n\r' | awk '{print $1}')

# Check thresholds
ALERT_NEEDED=false
ALERT_MESSAGES=""

# Load check
if (( $(echo "$LOAD_1MIN > $LOAD_THRESHOLD" | bc -l) )); then
  ALERT_NEEDED=true
  ALERT_MESSAGES+="🚨 LOAD HIGH: $LOAD_1MIN (threshold: $LOAD_THRESHOLD)\n"
fi

# CPU check
if [[ "$CPU_USAGE" =~ ^[0-9]+$ ]] && (( CPU_USAGE > CPU_THRESHOLD )); then
  ALERT_NEEDED=true
  ALERT_MESSAGES+="🚨 CPU HIGH: ${CPU_USAGE}% (threshold: ${CPU_THRESHOLD}%)\n"
fi

# Memory check
if [[ "$MEM_USAGE" =~ ^[0-9]+$ ]] && (( MEM_USAGE > MEM_THRESHOLD )); then
  ALERT_NEEDED=true
  ALERT_MESSAGES+="🚨 MEMORY HIGH: ${MEM_USAGE}% (threshold: ${MEM_THRESHOLD}%)\n"
fi

# Swap check
if [[ "$SWAP_USAGE" =~ ^[0-9]+$ ]] && (( SWAP_USAGE > SWAP_THRESHOLD )); then
  ALERT_NEEDED=true
  ALERT_MESSAGES+="🚨 SWAP HIGH: ${SWAP_USAGE}% (threshold: ${SWAP_THRESHOLD}%)\n"
fi

# Disk check
if [[ "$DISK_USAGE" =~ ^[0-9]+$ ]] && (( DISK_USAGE > DISK_THRESHOLD )); then
  ALERT_NEEDED=true
  ALERT_MESSAGES+="🚨 DISK HIGH: ${DISK_USAGE}% (threshold: ${DISK_THRESHOLD}%)\n"
fi

# 429 errors check
if [[ "$ANNOUNCE_429_COUNT" =~ ^[0-9]+$ ]] && (( ANNOUNCE_429_COUNT > ANNOUNCE_429_THRESHOLD )); then
  ALERT_NEEDED=true
  ALERT_MESSAGES+="🚨 TRACKER 429 ERRORS: $ANNOUNCE_429_COUNT (threshold: $ANNOUNCE_429_THRESHOLD)\n"
fi

# Send alert if needed
if [[ "$ALERT_NEEDED" == "true" ]]; then
  HOSTNAME=$(hostname)
  DATE=$(date '+%Y-%m-%d %H:%M:%S')
  
  FULL_MSG=$'⚠️ ALERTA SERVIDOR: '"${HOSTNAME}"$' - '"${DATE}"$'\n\n'
  FULL_MSG+="$ALERT_MESSAGES"
  FULL_MSG+=$'\n📊 Métricas actuales:\n'
  FULL_MSG+=$'• Load: '"$LOAD_1MIN"$'\n'
  FULL_MSG+=$'• CPU: '"$CPU_USAGE"$'%\n'
  FULL_MSG+=$'• RAM: '"$MEM_USAGE"$'%\n'
  FULL_MSG+=$'• Swap: '"$SWAP_USAGE"$'%\n'
  FULL_MSG+=$'• Disco: '"$DISK_USAGE"$'%\n'
  FULL_MSG+=$'• Tracker 429s: '"$ANNOUNCE_429_COUNT"$'\n'
  
  # Add tracker analysis if there are announce requests
  if [[ -f "$ACCESS_LOG" ]]; then
    ANNOUNCE_REQUESTS=$(tail -n "$TAIL_LINES" "$ACCESS_LOG" | grep -c "$ANNOUNCE_PATH" || echo "0")
    ANNOUNCE_UNIQUE_IPS=$(tail -n "$TAIL_LINES" "$ACCESS_LOG" | grep "$ANNOUNCE_PATH" | awk '{print $1}' | sort -u | wc -l || echo "0")
    
    FULL_MSG+=$'\n🛰️ TRACKER INFO:\n'
    FULL_MSG+=$'• Announces: '"$ANNOUNCE_REQUESTS"$'\n'
    FULL_MSG+=$'• Unique IPs: '"$ANNOUNCE_UNIQUE_IPS"$'\n'
    
    # Top IPs
    TOP_IPS_RAW=$(tail -n "$TAIL_LINES" "$ACCESS_LOG" | grep "$ANNOUNCE_PATH" | awk '{print $1}' | sort | uniq -c | sort -nr | head -n 3)
    if [[ -n "$TOP_IPS_RAW" ]]; then
      TOP_IPS=$(echo "$TOP_IPS_RAW" | awk '{printf "%s(%d) ", $2, $1}')
      FULL_MSG+=$'🥇 TOP IPs:\n'"${TOP_IPS}"$'\n'
    fi
    
    # Top passkeys (extract from announce URLs - FIXED for UNIT3D format)
    TOP_PASSKEYS_RAW=$(tail -n "$TAIL_LINES" "$ACCESS_LOG" | grep "/announce/" | sed -n 's|.*GET /announce/\([a-f0-9]\{32\}\).*|\1|p' | sort | uniq -c | sort -nr | head -n 3)
    if [[ -n "$TOP_PASSKEYS_RAW" ]]; then
      TOP_PASSKEYS=""
      while read -r count passkey; do
        if [[ -n "$count" && -n "$passkey" ]]; then
          username=$(get_username_from_passkey "$passkey")
          if [[ "$username" != "unknown" && -n "$username" ]]; then
            TOP_PASSKEYS+="$username($count) "
          else
            TOP_PASSKEYS+="$(echo $passkey | cut -c1-6)($count) "
          fi
        fi
      done <<< "$TOP_PASSKEYS_RAW"
      
      if [[ -n "$TOP_PASSKEYS" ]]; then
        FULL_MSG+=$'👤 TOP USUARIOS:\n'"${TOP_PASSKEYS}"$'\n'
      fi
    fi
    
    # Add explanation for alerts
    FULL_MSG+=$'\n📖 *Explicación de la alerta:*\n'
    FULL_MSG+=$'• 🚨 Valores por encima de lo normal\n'
    FULL_MSG+=$'• 📊 Load alto: servidor sobrecargado\n'
    FULL_MSG+=$'• ⚙️ CPU/RAM alto: recursos limitados\n'
    FULL_MSG+=$'• 🛰️ 429 errors: tracker rechazando peticiones\n'
    FULL_MSG+=$'• 👤 Usuarios más activos en este momento'
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
