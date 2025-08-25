#!/bin/bash

# Script completo de pruebas para Telegram Notifier
# Verifica todos los aspectos del funcionamiento

echo "🧪 SUITE COMPLETA DE PRUEBAS - Telegram Notifier"
echo "=================================================="

BASE_URL="http://localhost:3001"
FAILED_TESTS=0
TOTAL_TESTS=0

# Función para hacer requests con timeout
make_request() {
    local method=$1
    local endpoint=$2
    local data=$3
    local timeout=10
    
    if [ -n "$data" ]; then
        timeout $timeout curl -s -X $method "$BASE_URL$endpoint" \
             -H "Content-Type: application/json" \
             -d "$data" 2>/dev/null
    else
        timeout $timeout curl -s -X $method "$BASE_URL$endpoint" 2>/dev/null
    fi
}

# Función para verificar resultado
check_result() {
    local test_name=$1
    local result=$2
    local expected=$3
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if echo "$result" | grep -q "$expected"; then
        echo "   ✅ PASS: $test_name"
        return 0
    else
        echo "   ❌ FAIL: $test_name"
        echo "      Respuesta: $result"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

# Función para esperar un momento
wait_moment() {
    echo "   ⏳ Esperando $1 segundos..."
    sleep $1
}

echo ""
echo "🔍 FASE 1: VERIFICACIONES BÁSICAS"
echo "=================================="

# Test 1: Verificar que el servicio esté corriendo
echo "1. 🏥 Verificando estado del servicio..."
if systemctl is-active --quiet telegram-notifier; then
    echo "   ✅ Servicio systemd está activo"
else
    echo "   ❌ Servicio systemd no está corriendo"
    echo "   Iniciando servicio..."
    sudo systemctl start telegram-notifier
    sleep 3
fi

# Test 2: Health Check
echo ""
echo "2. 💓 Health Check..."
HEALTH_RESULT=$(make_request GET "/health")
check_result "Health endpoint responde" "$HEALTH_RESULT" '"status":"OK"'

# Test 3: Verificar puerto
echo ""
echo "3. 🔌 Verificando puerto 3001..."
if netstat -tlnp 2>/dev/null | grep -q ":3001.*LISTEN"; then
    echo "   ✅ Puerto 3001 está abierto y escuchando"
else
    echo "   ❌ Puerto 3001 no está disponible"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi

echo ""
echo "📊 FASE 2: API ENDPOINTS"
echo "========================"

# Test 4: Stats endpoint
echo "4. 📈 Endpoint de estadísticas..."
STATS_RESULT=$(make_request GET "/stats")
check_result "Stats endpoint" "$STATS_RESULT" '"service":"telegram-notifier"'

# Test 5: Config reload
echo ""
echo "5. 🔄 Recarga de configuración..."
RELOAD_RESULT=$(make_request POST "/config/reload")
check_result "Config reload" "$RELOAD_RESULT" '"success":true'

echo ""
echo "📱 FASE 3: TELEGRAM INTEGRATION"
echo "==============================="

# Test 6: Mensaje de prueba
echo "6. 💬 Enviando mensaje de prueba a Telegram..."
echo "   (Revisa tu canal de Telegram para verificar)"
TEST_TELEGRAM_RESULT=$(make_request POST "/test-telegram")
check_result "Mensaje de prueba" "$TEST_TELEGRAM_RESULT" '"success":true'

wait_moment 2

# Test 7: Simulación de torrent básico
echo ""
echo "7. 🎬 Simulación de torrent aprobado (básico)..."
BASIC_TORRENT='{
  "torrent_id": 100001,
  "name": "Test.Movie.Basic.2024.1080p.BluRay.x264-TEST",
  "user": "test_user",
  "category": "Movies",
  "size": "8.5 GB"
}'

BASIC_RESULT=$(make_request POST "/torrent-approved" "$BASIC_TORRENT")
check_result "Notificación básica" "$BASIC_RESULT" '"success":true'

wait_moment 2

# Test 8: Simulación de torrent completo con metadata
echo ""
echo "8. 🎭 Simulación de torrent con metadata completa..."
FULL_TORRENT='{
  "torrent_id": 100002,
  "name": "Avatar.The.Way.of.Water.2022.2160p.UHD.BluRay.x265-EXAMPLE",
  "user": "uploader_pro",
  "category": "Movies",
  "size": "25.4 GB",
  "imdb": 1630029,
  "tmdb_movie_id": 76600
}'

FULL_RESULT=$(make_request POST "/torrent-approved" "$FULL_TORRENT")
check_result "Notificación con metadata" "$FULL_RESULT" '"success":true'

wait_moment 2

# Test 9: Torrent de TV
echo ""
echo "9. 📺 Simulación de torrent de TV..."
TV_TORRENT='{
  "torrent_id": 100003,
  "name": "The.Last.of.Us.S01E01.2160p.WEB.H265-EXAMPLE",
  "user": "tv_uploader",
  "category": "TV",
  "size": "4.2 GB",
  "imdb": 1392214,
  "tmdb_tv_id": 100088
}'

TV_RESULT=$(make_request POST "/torrent-approved" "$TV_TORRENT")
check_result "Notificación TV" "$TV_RESULT" '"success":true'

wait_moment 2

# Test 10: Diferentes categorías
echo ""
echo "10. 🎵 Probando diferentes categorías..."

# Música
MUSIC_TORRENT='{
  "torrent_id": 100004,
  "name": "Artist - Album (2024) [FLAC]",
  "user": "music_lover",
  "category": "Music",
  "size": "750 MB"
}'

MUSIC_RESULT=$(make_request POST "/torrent-approved" "$MUSIC_TORRENT")
check_result "Notificación Music" "$MUSIC_RESULT" '"success":true'

wait_moment 1

# Games
GAME_TORRENT='{
  "torrent_id": 100005,
  "name": "Game.Title.Complete.Edition.v1.0-EXAMPLE",
  "user": "gamer_pro",
  "category": "Games",
  "size": "45.2 GB"
}'

GAME_RESULT=$(make_request POST "/torrent-approved" "$GAME_TORRENT")
check_result "Notificación Games" "$GAME_RESULT" '"success":true'

echo ""
echo "🔍 FASE 4: VERIFICACIONES DE ERROR"
echo "=================================="

# Test 11: Datos inválidos
echo "11. ❓ Probando datos inválidos..."
INVALID_DATA='{"invalid": "data"}'
INVALID_RESULT=$(make_request POST "/torrent-approved" "$INVALID_DATA")
check_result "Manejo de datos inválidos" "$INVALID_RESULT" '"error"'

# Test 12: Endpoint inexistente
echo ""
echo "12. 🚫 Probando endpoint inexistente..."
NOT_FOUND_RESULT=$(make_request GET "/nonexistent")
check_result "Endpoint inexistente" "$NOT_FOUND_RESULT" '"error"'

echo ""
echo "📋 FASE 5: INFORMACIÓN DEL SISTEMA"
echo "=================================="

echo "13. 🖥️  Información del sistema:"
echo "   📍 Directorio: $(pwd)"
echo "   🐧 Usuario: $(whoami)"
echo "   🔧 Node.js: $(node --version)"
echo "   💾 Memoria usada: $(ps -p $(pgrep -f "node app.js") -o pid,vsz,rss,comm --no-headers 2>/dev/null || echo "N/A")"
echo "   🕒 Uptime del servicio: $(systemctl show telegram-notifier --property=ActiveEnterTimestamp --value 2>/dev/null || echo "N/A")"

echo ""
echo "📊 FASE 6: LOGS RECIENTES"
echo "========================="

echo "14. 📝 Últimos logs del servicio:"
journalctl -u telegram-notifier -n 5 --no-pager 2>/dev/null || echo "   No se pueden acceder a los logs de systemd"

echo ""
echo "=================================================="
echo "🏁 RESUMEN DE PRUEBAS"
echo "=================================================="

PASSED_TESTS=$((TOTAL_TESTS - FAILED_TESTS))

echo "✅ Pruebas exitosas: $PASSED_TESTS"
echo "❌ Pruebas fallidas: $FAILED_TESTS"
echo "📊 Total de pruebas: $TOTAL_TESTS"

if [ $FAILED_TESTS -eq 0 ]; then
    echo ""
    echo "🎉 ¡TODAS LAS PRUEBAS PASARON!"
    echo ""
    echo "✅ Tu Telegram Notifier está funcionando perfectamente"
    echo "✅ Las notificaciones deberían llegar automáticamente cuando apruebes torrents"
    echo "✅ El servicio está configurado para inicio automático"
    echo ""
    echo "🔗 Próximos pasos:"
    echo "   • Aprueba un torrent real en tu tracker para probar la integración"
    echo "   • Revisa tu canal de Telegram para las notificaciones de prueba"
    echo "   • Configura filtros en config/config.json si es necesario"
    exit 0
else
    echo ""
    echo "⚠️  ALGUNAS PRUEBAS FALLARON"
    echo ""
    echo "🔧 Para diagnosticar:"
    echo "   journalctl -u telegram-notifier -f    # Ver logs en tiempo real"
    echo "   systemctl status telegram-notifier    # Ver estado del servicio"
    echo "   curl http://localhost:3001/health     # Verificar conectividad"
    echo ""
    echo "📞 Si necesitas ayuda, revisa:"
    echo "   • README.md - Documentación completa"
    echo "   • logs/ - Archivos de log locales"
    echo "   • config/config.json - Configuración actual"
    exit 1
fi