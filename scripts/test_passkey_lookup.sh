#!/bin/bash
# Script simple para probar búsqueda de usuario por passkey específico

# Cargar configuración
source /etc/default/metrics_bot_env

echo "=== Prueba de búsqueda de usuario ==="
echo "DB_HOST: $DB_HOST"
echo "DB_DATABASE: $DB_DATABASE"
echo "DB_USERNAME: $DB_USERNAME"
echo ""

# Probar con passkeys conocidos de tu base de datos
PASSKEYS=("839975a0469e66c1e95a3b1f0e9cb4dc" "178f8b8d7c9e4a3f5b2d1e8c9a6f4e2d" "d762b6b9c4a7f3e9b5d8c2a6f1e4d7b9" "a18e813c6f9d4b7e2a5c8f1d3e6b9c4a" "87510656c9f4d7a2e5b8d1c6f3e9a2b5")

echo "Probando búsquedas con passkeys conocidos:"
for passkey in "${PASSKEYS[@]}"; do
    echo "Buscando passkey: $passkey"
    username=$(mysql -h "$DB_HOST" -u "$DB_USERNAME" -p"$DB_PASSWORD" "$DB_DATABASE" -se "SELECT username FROM users WHERE passkey LIKE '$passkey%' LIMIT 1;" 2>/dev/null)
    echo "Resultado: '$username'"
    echo ""
done

echo ""
echo "Probando con passkeys completos de la base de datos:"
mysql -h "$DB_HOST" -u "$DB_USERNAME" -p"$DB_PASSWORD" "$DB_DATABASE" -e "SELECT username, passkey FROM users WHERE passkey IS NOT NULL LIMIT 3;" 2>/dev/null | while read -r username passkey; do
    if [[ "$username" != "username" && -n "$passkey" ]]; then
        echo "Probando: $username -> $passkey"
        found_user=$(mysql -h "$DB_HOST" -u "$DB_USERNAME" -p"$DB_PASSWORD" "$DB_DATABASE" -se "SELECT username FROM users WHERE passkey='$passkey' LIMIT 1;" 2>/dev/null)
        echo "Encontrado: '$found_user'"
        echo ""
    fi
done

echo ""
echo "Verificando formato de passkeys en logs de nginx:"
if [[ -f "/var/log/nginx/access.log" ]]; then
    echo "Últimos passkeys en logs:"
    tail -n 100 /var/log/nginx/access.log | grep "/announce/" | grep -oE 'passkey=[a-f0-9]{32}' | cut -d= -f2 | head -3
    echo ""
    echo "Total de passkeys únicos en últimas 1000 líneas:"
    tail -n 1000 /var/log/nginx/access.log | grep "/announce/" | grep -oE 'passkey=[a-f0-9]{32}' | cut -d= -f2 | sort -u | wc -l
fi
