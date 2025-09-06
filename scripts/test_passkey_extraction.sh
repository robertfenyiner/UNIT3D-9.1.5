#!/bin/bash
# Script para probar la nueva extracción de passkeys

echo "=== PRUEBA DE EXTRACCIÓN DE PASSKEYS ==="
echo ""

echo "1. Método anterior (buscando passkey= en parámetros):"
tail -n 100 /var/log/nginx/access.log | grep "/announce/" | grep -oE 'passkey=[a-f0-9]{32}' | cut -d= -f2 | sort | uniq -c | sort -nr | head -3
echo ""

echo "2. Método nuevo (extrayendo del path /announce/PASSKEY):"
tail -n 100 /var/log/nginx/access.log | grep "/announce/" | sed -n 's|.*GET /announce/\([a-f0-9]\{32\}\).*|\1|p' | sort | uniq -c | sort -nr | head -3
echo ""

echo "3. Verificando algunos passkeys extraídos:"
SAMPLE_PASSKEYS=$(tail -n 100 /var/log/nginx/access.log | grep "/announce/" | sed -n 's|.*GET /announce/\([a-f0-9]\{32\}\).*|\1|p' | head -3)

# Cargar configuración de base de datos
source /etc/default/metrics_bot_env

echo "Buscando usuarios para estos passkeys:"
for passkey in $SAMPLE_PASSKEYS; do
    echo "Passkey: $passkey"
    username=$(mysql -h "$DB_HOST" -u "$DB_USERNAME" -p"$DB_PASSWORD" "$DB_DATABASE" -se "SELECT username FROM users WHERE passkey='$passkey' LIMIT 1;" 2>/dev/null)
    echo "Usuario: '$username'"
    echo ""
done

echo "4. Estadísticas rápidas:"
echo "Total de peticiones de announce en últimas 1000 líneas:"
tail -n 1000 /var/log/nginx/access.log | grep -c "/announce/"

echo "Passkeys únicos en últimas 1000 líneas:"
tail -n 1000 /var/log/nginx/access.log | grep "/announce/" | sed -n 's|.*GET /announce/\([a-f0-9]\{32\}\).*|\1|p' | sort -u | wc -l
