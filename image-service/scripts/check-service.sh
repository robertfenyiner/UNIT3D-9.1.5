#!/bin/bash

# Script de verificación rápida del estado del servicio image-service
# Ejecutar después del setup para verificar que todo funciona correctamente

echo "🔍 Verificación rápida del servicio UNIT3D Image Service"
echo "Servidor: $(hostname -f)"
echo "Fecha: $(date)"
echo ""

# Función de colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    local status=$1
    local message=$2
    if [ "$status" = "ok" ]; then
        echo -e "${GREEN}✅${NC} $message"
    elif [ "$status" = "warning" ]; then
        echo -e "${YELLOW}⚠️${NC} $message"
    else
        echo -e "${RED}❌${NC} $message"
    fi
}

# 1. Verificar servicios systemd
echo "1. Verificando servicios systemd..."
if sudo systemctl is-active --quiet rclone-onedrive.service; then
    print_status "ok" "Servicio rclone-onedrive activo"
else
    print_status "error" "Servicio rclone-onedrive inactivo"
fi

if sudo systemctl is-active --quiet image-service.service; then
    print_status "ok" "Servicio image-service activo"
else
    print_status "error" "Servicio image-service inactivo"
fi

# 2. Verificar mount point
echo ""
echo "2. Verificando mount point..."
if mountpoint -q /var/www/html/storage/images; then
    print_status "ok" "Mount de OneDrive activo en /var/www/html/storage/images"
else
    print_status "error" "Mount de OneDrive no encontrado"
fi

# 3. Verificar conectividad con OneDrive
echo ""
echo "3. Verificando conectividad con OneDrive..."
if rclone lsd imagenes: >/dev/null 2>&1; then
    print_status "ok" "Conectividad con OneDrive OK"
else
    print_status "error" "Error de conectividad con OneDrive"
fi

# 4. Verificar servicio web
echo ""
echo "4. Verificando servicio web..."
if curl -s http://localhost:3002/health >/dev/null; then
    print_status "ok" "Servicio web responde correctamente"
else
    print_status "error" "Servicio web no responde"
fi

# 5. Verificar permisos de escritura
echo ""
echo "5. Verificando permisos de escritura..."
TEST_FILE="/var/www/html/storage/images/.check_$(date +%s)"
if echo "test" > "$TEST_FILE" 2>/dev/null; then
    rm "$TEST_FILE"
    print_status "ok" "Permisos de escritura OK"
else
    print_status "error" "Error de permisos de escritura"
fi

# 6. Verificar uso de espacio (opcional)
echo ""
echo "6. Información del sistema..."
if mountpoint -q /var/www/html/storage/images; then
    USAGE=$(df -h /var/www/html/storage/images 2>/dev/null | tail -1 | awk '{print $5}')
    if [ -n "$USAGE" ]; then
        echo "   📊 Uso de espacio: $USAGE"
    fi
fi

# 7. Verificar archivos de log
echo ""
echo "7. Verificando archivos de log..."
if [ -f "/var/log/rclone-images.log" ]; then
    print_status "ok" "Log de rclone encontrado"
else
    print_status "warning" "Log de rclone no encontrado"
fi

if [ -f "/var/www/html/image-service/logs/image-service.log" ]; then
    print_status "ok" "Log del servicio encontrado"
else
    print_status "warning" "Log del servicio no encontrado"
fi

# 8. URLs del servicio
echo ""
echo "8. URLs del servicio:"
echo "   🌐 Web: http://216.9.226.186:3002/"
echo "   💚 Health: http://216.9.226.186:3002/health"
echo "   📤 Upload: http://216.9.226.186:3002/upload"

echo ""
echo "🔧 Comandos útiles para troubleshooting:"
echo "   - Ver logs detallados: sudo journalctl -u image-service.service -f"
echo "   - Reiniciar servicios: sudo systemctl restart rclone-onedrive.service image-service.service"
echo "   - Ver estado detallado: sudo systemctl status rclone-onedrive.service image-service.service"
echo "   - Probar subida: curl -X POST -F 'images=@/path/to/image.jpg' http://216.9.226.186:3002/upload"

echo ""
echo "✨ Verificación completada"</content>
<parameter name="filePath">d:\Onedrive Robert Personal\OneDrive\Documents\GitHub\UNIT3D-9.1.5\image-service\scripts\check-service.sh
