#!/bin/bash
# Script de diagnóstico para el bot de Telegram

echo "=== DIAGNÓSTICO DEL BOT DE TELEGRAM ==="
echo "Fecha: $(date)"
echo

# 1. Verificar archivo de configuración
echo "1. Verificando archivo de configuración..."
ENV_FILE="/etc/default/metrics_bot_env"
if [[ -f "$ENV_FILE" ]]; then
    echo "✅ Archivo de configuración encontrado: $ENV_FILE"
    echo "Contenido (sin mostrar tokens):"
    cat "$ENV_FILE" | sed 's/=.*/=***HIDDEN***/'
else
    echo "❌ Archivo de configuración NO encontrado: $ENV_FILE"
    echo "   Necesitas crear este archivo con:"
    echo "   TELEGRAM_BOT_TOKEN=\"tu_token\""
    echo "   TELEGRAM_CHAT_ID=\"tu_chat_id\""
fi
echo

# 2. Cargar variables si existen
if [[ -f "$ENV_FILE" ]]; then
    source "$ENV_FILE"
fi

# 3. Verificar variables de entorno
echo "2. Verificando variables de entorno..."
if [[ -n "$TELEGRAM_BOT_TOKEN" ]]; then
    echo "✅ TELEGRAM_BOT_TOKEN está configurado"
else
    echo "❌ TELEGRAM_BOT_TOKEN NO está configurado"
fi

if [[ -n "$TELEGRAM_CHAT_ID" ]]; then
    echo "✅ TELEGRAM_CHAT_ID está configurado"
else
    echo "❌ TELEGRAM_CHAT_ID NO está configurado"
fi
echo

# 4. Verificar scripts
echo "3. Verificando scripts de monitoreo..."
SCRIPTS=(
    "/root/server_info_tracker.sh"
    "/home/*/server_info_tracker.sh"
    "/opt/*/server_info_tracker.sh"
    "./server_info_tracker.sh"
)

for script in "${SCRIPTS[@]}"; do
    if [[ -f "$script" ]]; then
        echo "✅ Script encontrado: $script"
        echo "   Permisos: $(ls -la "$script" | awk '{print $1}')"
        echo "   Último modificado: $(stat -c %y "$script")"
    fi
done
echo

# 5. Verificar crontab
echo "4. Verificando crontab..."
if crontab -l 2>/dev/null | grep -q "server_info\|server_alert"; then
    echo "✅ Crontab configurado:"
    crontab -l 2>/dev/null | grep -E "server_info|server_alert"
else
    echo "❌ No se encontraron entradas de cron para los scripts"
fi
echo

# 6. Probar conexión a Telegram (si las variables están configuradas)
echo "5. Probando conexión a Telegram..."
if [[ -n "$TELEGRAM_BOT_TOKEN" && -n "$TELEGRAM_CHAT_ID" ]]; then
    echo "Enviando mensaje de prueba..."
    
    RESPONSE=$(curl -s -X POST \
        "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d "chat_id=${TELEGRAM_CHAT_ID}" \
        -d "text=🔧 Prueba de diagnóstico - $(date)")
    
    if echo "$RESPONSE" | grep -q '"ok":true'; then
        echo "✅ Mensaje de prueba enviado correctamente"
    else
        echo "❌ Error enviando mensaje:"
        echo "$RESPONSE"
    fi
else
    echo "⚠️  No se puede probar - faltan variables de entorno"
fi
echo

# 7. Verificar logs recientes
echo "6. Verificando logs recientes..."
echo "Logs de cron (últimas 10 líneas):"
if [[ -f "/var/log/cron" ]]; then
    tail -n 10 /var/log/cron | grep -E "server_info|server_alert" || echo "No hay entradas recientes"
elif [[ -f "/var/log/syslog" ]]; then
    tail -n 50 /var/log/syslog | grep -E "CRON.*server_info|CRON.*server_alert" | tail -n 10 || echo "No hay entradas recientes"
else
    echo "No se encontraron logs de cron"
fi
echo

# 8. Verificar conectividad de red
echo "7. Verificando conectividad..."
if ping -c 1 api.telegram.org >/dev/null 2>&1; then
    echo "✅ Conectividad a api.telegram.org OK"
else
    echo "❌ No hay conectividad a api.telegram.org"
fi
echo

echo "=== FIN DEL DIAGNÓSTICO ==="
echo
echo "📋 RESUMEN DE ACCIONES SUGERIDAS:"
echo "1. Si faltan variables: crear/editar $ENV_FILE"
echo "2. Si faltan scripts: subir los archivos .sh al servidor"
echo "3. Si falta crontab: configurar con 'crontab -e'"
echo "4. Si hay errores de conexión: verificar firewall/proxy"
echo "5. Si el bot no responde: verificar el token en @BotFather"
