#!/bin/bash
# Script de prueba para verificar la conexión a la base de datos

# Cargar variables de entorno
if [[ -f /etc/default/metrics_bot_env ]]; then
    source /etc/default/metrics_bot_env
fi

echo "=== Prueba de Conexión a Base de Datos ==="
echo "Host: $DB_HOST"
echo "Database: $DB_DATABASE"
echo "Username: $DB_USERNAME"
echo "Password: [OCULTO]"
echo ""

# Verificar que mysql esté disponible
MYSQL_CMD="$(command -v mysql || true)"
if [[ -z "$MYSQL_CMD" || ! -x "$MYSQL_CMD" ]]; then
    echo "❌ ERROR: MySQL client no encontrado"
    exit 1
fi

echo "✅ MySQL client encontrado: $MYSQL_CMD"
echo ""

# Probar conexión básica
echo "🔍 Probando conexión básica..."
mysql -h "$DB_HOST" -u "$DB_USERNAME" -p"$DB_PASSWORD" "$DB_DATABASE" -e "SELECT 'Conexión exitosa' as status;" 2>&1

echo ""
echo "🔍 Verificando estructura de tabla users..."
mysql -h "$DB_HOST" -u "$DB_USERNAME" -p"$DB_PASSWORD" "$DB_DATABASE" -e "DESCRIBE users;" 2>&1

echo ""
echo "🔍 Contando usuarios en la tabla..."
mysql -h "$DB_HOST" -u "$DB_USERNAME" -p"$DB_PASSWORD" "$DB_DATABASE" -e "SELECT COUNT(*) as total_users FROM users;" 2>&1

echo ""
echo "🔍 Mostrando algunos passkeys de ejemplo..."
mysql -h "$DB_HOST" -u "$DB_USERNAME" -p"$DB_PASSWORD" "$DB_DATABASE" -e "SELECT username, LEFT(passkey, 8) as passkey_preview FROM users WHERE passkey IS NOT NULL LIMIT 5;" 2>&1

echo ""
echo "🔍 Probando función de búsqueda con passkey específico..."
# Obtener un passkey real para probar
SAMPLE_PASSKEY=$(mysql -h "$DB_HOST" -u "$DB_USERNAME" -p"$DB_PASSWORD" "$DB_DATABASE" -se "SELECT passkey FROM users WHERE passkey IS NOT NULL LIMIT 1;" 2>/dev/null)

if [[ -n "$SAMPLE_PASSKEY" ]]; then
    echo "Passkey de prueba: $SAMPLE_PASSKEY"
    USERNAME_RESULT=$(mysql -h "$DB_HOST" -u "$DB_USERNAME" -p"$DB_PASSWORD" "$DB_DATABASE" -se "SELECT username FROM users WHERE passkey='$SAMPLE_PASSKEY' LIMIT 1;" 2>/dev/null)
    echo "Usuario encontrado: $USERNAME_RESULT"
else
    echo "❌ No se encontraron passkeys en la base de datos"
fi

echo ""
echo "=== Fin de pruebas ==="
