#!/bin/bash

# Script completo para verificar y solucionar problemas con rclone y el image-service
# Ejecutar en el servidor donde está corriendo el servicio

echo "🔍 Verificando estado del sistema..."

# 1. Verificar servicios systemd
echo ""
echo "📊 Estado de servicios:"
sudo systemctl status rclone-onedrive.service --no-pager -l
echo "---"
sudo systemctl status image-service.service --no-pager -l

# 2. Verificar mount de rclone
echo ""
echo "💾 Verificando mount de rclone:"
mount | grep rclone || echo "❌ No se encontró mount de rclone"
ls -la /var/www/html/storage/images/ | head -10

# 3. Verificar conectividad de rclone
echo ""
echo "🔗 Probando conectividad de rclone:"
rclone lsd onedrive-images: || echo "❌ Error conectando con rclone"

# 4. Verificar logs
echo ""
echo "📝 Últimas líneas de logs:"
echo "Logs de rclone:"
sudo tail -10 /var/log/rclone-images.log 2>/dev/null || echo "No se encontró log de rclone"
echo ""
echo "Logs del image-service:"
sudo tail -10 /var/www/html/image-service/logs/image-service.log 2>/dev/null || echo "No se encontró log del servicio"

# 5. Verificar permisos
echo ""
echo "🔐 Verificando permisos:"
ls -ld /var/www/html/storage/images/
ls -ld /var/www/html/image-service/logs/

# 6. Probar escritura
echo ""
echo "✏️ Probando escritura:"
echo "Test $(date)" > /tmp/test_write.txt
sudo mv /tmp/test_write.txt /var/www/html/storage/images/
if [ -f "/var/www/html/storage/images/test_write.txt" ]; then
    echo "✅ Escritura exitosa"
    sudo rm /var/www/html/storage/images/test_write.txt
else
    echo "❌ Error de escritura"
fi

# 7. Verificar configuración del servicio
echo ""
echo "⚙️ Configuración del servicio:"
curl -s http://localhost:3002/health | head -20

echo ""
echo "🏁 Verificación completada"</content>
<parameter name="filePath">d:\Onedrive Robert Personal\OneDrive\Documents\GitHub\UNIT3D-9.1.5\image-service\scripts\check-service.sh
