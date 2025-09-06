#!/bin/bash
# Script simple para probar la conexión DB y buscar usuarios

# Cargar configuración
source /etc/default/metrics_bot_env

echo "Probando conexión a base de datos..."
echo "Host: $DB_HOST"
echo "Database: $DB_DATABASE"  
echo "Username: $DB_USERNAME"
echo ""

# Verificar mysql
if ! command -v mysql &> /dev/null; then
    echo "ERROR: mysql no está instalado"
    exit 1
fi

# Probar conexión básica
echo "1. Probando conexión básica:"
mysql -h "$DB_HOST" -u "$DB_USERNAME" -p"$DB_PASSWORD" "$DB_DATABASE" -e "SELECT 'Conexión OK' as status;" 2>&1
echo ""

# Verificar tabla users
echo "2. Verificando tabla users:"
mysql -h "$DB_HOST" -u "$DB_USERNAME" -p"$DB_PASSWORD" "$DB_DATABASE" -e "SELECT COUNT(*) as total_users FROM users;" 2>&1
echo ""

# Verificar columna passkey
echo "3. Verificando columna passkey:"
mysql -h "$DB_HOST" -u "$DB_USERNAME" -p"$DB_PASSWORD" "$DB_DATABASE" -e "SHOW COLUMNS FROM users LIKE 'passkey';" 2>&1
echo ""

# Mostrar algunos usuarios con passkey
echo "4. Usuarios con passkey (primeros 3):"
mysql -h "$DB_HOST" -u "$DB_USERNAME" -p"$DB_PASSWORD" "$DB_DATABASE" -e "SELECT id, username, LEFT(passkey, 8) as passkey_preview FROM users WHERE passkey IS NOT NULL AND passkey != '' LIMIT 3;" 2>&1
echo ""

# Probar búsqueda específica
echo "5. Probando búsqueda por passkey:"
SAMPLE_PASSKEY=$(mysql -h "$DB_HOST" -u "$DB_USERNAME" -p"$DB_PASSWORD" "$DB_DATABASE" -se "SELECT passkey FROM users WHERE passkey IS NOT NULL AND passkey != '' LIMIT 1;" 2>/dev/null)

if [[ -n "$SAMPLE_PASSKEY" ]]; then
    echo "Passkey de prueba: $SAMPLE_PASSKEY"
    USERNAME=$(mysql -h "$DB_HOST" -u "$DB_USERNAME" -p"$DB_PASSWORD" "$DB_DATABASE" -se "SELECT username FROM users WHERE passkey='$SAMPLE_PASSKEY' LIMIT 1;" 2>/dev/null)
    echo "Usuario encontrado: '$USERNAME'"
else
    echo "No se encontraron passkeys válidos"
fi

echo ""
echo "6. Verificando logs de nginx para passkeys:"
if [[ -f "/var/log/nginx/access.log" ]]; then
    PASSKEY_COUNT=$(tail -n 1000 /var/log/nginx/access.log | grep "/announce/" | grep -oE 'passkey=[a-f0-9]{32}' | wc -l)
    echo "Passkeys encontrados en logs recientes: $PASSKEY_COUNT"
    
    if [[ $PASSKEY_COUNT -gt 0 ]]; then
        echo "Primer passkey de ejemplo:"
        tail -n 1000 /var/log/nginx/access.log | grep "/announce/" | grep -oE 'passkey=[a-f0-9]{32}' | head -1
    fi
else
    echo "Log de nginx no encontrado"
fi
