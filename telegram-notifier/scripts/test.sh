#!/bin/bash

# Script para probar Telegram Notifier
# Verifica que todo esté funcionando correctamente

echo "🧪 Probando Telegram Notifier..."

BASE_URL="http://localhost:3001"

# Función para hacer requests
make_request() {
    local method=$1
    local endpoint=$2
    local data=$3
    
    if [ -n "$data" ]; then
        curl -s -X $method "$BASE_URL$endpoint" \
             -H "Content-Type: application/json" \
             -d "$data"
    else
        curl -s -X $method "$BASE_URL$endpoint"
    fi
}

# Verificar que el servicio esté corriendo
echo "1. 🏥 Verificando salud del servicio..."
HEALTH=$(make_request GET "/health")
if echo "$HEALTH" | grep -q '"status":"OK"'; then
    echo "   ✅ Servicio funcionando correctamente"
else
    echo "   ❌ Servicio no responde o tiene problemas"
    echo "   Respuesta: $HEALTH"
    exit 1
fi

echo ""
echo "2. 📊 Obteniendo estadísticas..."
STATS=$(make_request GET "/stats")
echo "$STATS" | python3 -m json.tool 2>/dev/null || echo "$STATS"

echo ""
echo "3. 💬 Enviando mensaje de prueba a Telegram..."
TEST_RESULT=$(make_request POST "/test-telegram")
if echo "$TEST_RESULT" | grep -q '"success":true'; then
    echo "   ✅ Mensaje de prueba enviado exitosamente"
else
    echo "   ❌ Error enviando mensaje de prueba"
    echo "   Respuesta: $TEST_RESULT"
    echo ""
    echo "   🔍 Posibles causas:"
    echo "   - Bot token incorrecto en config/config.json"
    echo "   - Chat ID incorrecto"
    echo "   - Bot no agregado al canal/grupo"
fi

echo ""
echo "4. 🎬 Simulando notificación de torrent..."
TORRENT_DATA='{
  "torrent_id": 999999,
  "name": "Test.Movie.2024.1080p.BluRay.x264-TEST",
  "user": "testuser",
  "category": "Movies",
  "size": "8.5 GB",
  "imdb": 1234567,
  "tmdb_movie_id": 98765
}'

TORRENT_RESULT=$(make_request POST "/torrent-approved" "$TORRENT_DATA")
if echo "$TORRENT_RESULT" | grep -q '"success":true'; then
    echo "   ✅ Notificación de torrent simulada exitosamente"
else
    echo "   ❌ Error en notificación de torrent"
    echo "   Respuesta: $TORRENT_RESULT"
fi

echo ""
echo "🏁 Pruebas completadas"
echo ""
echo "💡 Consejos:"
echo "   - Si las pruebas fallan, revisa los logs: tail -f logs/error.log"
echo "   - Verifica la configuración: cat config/config.json"
echo "   - Asegúrate de que el bot esté correctamente configurado en Telegram"