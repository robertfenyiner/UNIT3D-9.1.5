#!/bin/bash

# Script de recuperación rápida para el servicio UNIT3D Image Service
# Ejecutar cuando hay problemas después de la configuración

set -e

echo "🔧 Recuperación rápida del servicio UNIT3D Image Service"
echo "Servidor: $(hostname -f)"
echo "Fecha: $(date)"
echo ""

# 1. Crear directorios necesarios
echo "📁 Creando directorios..."
sudo mkdir -p /var/www/html/storage/images/thumbs
sudo mkdir -p /var/www/html/image-service/storage/temp
sudo mkdir -p /var/www/html/image-service/logs
sudo mkdir -p /var/log

# 2. Establecer permisos
echo "🔐 Estableciendo permisos..."
sudo chown -R www-data:www-data /var/www/html/storage
sudo chown -R www-data:www-data /var/www/html/image-service/storage
sudo chown -R www-data:www-data /var/www/html/image-service/logs
sudo chmod -R 755 /var/www/html/storage
sudo chmod -R 755 /var/www/html/image-service/storage
sudo chmod -R 755 /var/www/html/image-service/logs

# 3. Desmontar cualquier mount existente
echo "🔌 Desmontando mounts existentes..."
sudo umount /var/www/html/storage/images 2>/dev/null || true
sudo fusermount -uz /var/www/html/storage/images 2>/dev/null || true

# 4. Recrear servicio systemd
echo "📋 Recreando servicio systemd..."
sudo tee /etc/systemd/system/rclone-onedrive.service > /dev/null <<EOF
[Unit]
Description=Rclone mount for OneDrive (UNIT3D Images)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
Group=root
ExecStart=/usr/bin/rclone mount imagenes:UNIT3D-Images /var/www/html/storage/images \\
    --config=/etc/rclone/rclone.conf \\
    --allow-other \\
    --vfs-cache-mode writes \\
    --vfs-write-back 5s \\
    --uid=33 \\
    --gid=33 \\
    --log-file /var/log/rclone-images.log \\
    --log-level INFO
ExecStop=/bin/fusermount -uz /var/www/html/storage/images
Restart=on-failure
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOF

# 5. Recargar systemd
echo "🔄 Recargando systemd..."
sudo systemctl daemon-reload

# 6. Crear directorio en OneDrive
echo "📂 Creando directorio en OneDrive..."
rclone mkdir imagenes:/UNIT3D-Images || echo "El directorio ya existe"

# 7. Iniciar servicio
echo "▶️ Iniciando servicio..."
sudo systemctl start rclone-onedrive.service
sleep 5

# 8. Verificar estado
echo ""
echo "📊 Verificando estado..."
sudo systemctl status rclone-onedrive.service --no-pager

# 9. Verificar mount
echo ""
echo "💾 Verificando mount..."
if mountpoint -q /var/www/html/storage/images; then
    echo "✅ Mount de OneDrive activo"
else
    echo "❌ Error en mount de OneDrive"
    echo "Logs del servicio:"
    sudo journalctl -u rclone-onedrive.service -n 10 --no-pager
    exit 1
fi

# 10. Probar escritura
echo ""
echo "✏️ Probando escritura..."
echo "Test $(date)" | sudo tee /var/www/html/storage/images/test.txt > /dev/null
if [ -f "/var/www/html/storage/images/test.txt" ]; then
    echo "✅ Escritura exitosa"
    sudo rm /var/www/html/storage/images/test.txt
else
    echo "❌ Error de escritura"
fi

echo ""
echo "🎉 ¡Recuperación completada!"
echo ""
echo "📋 Estado actual:"
echo "- Servicio rclone-onedrive: $(sudo systemctl is-active rclone-onedrive.service)"
echo "- Mount point: $(mountpoint -q /var/www/html/storage/images && echo 'Activo' || echo 'Inactivo')"
echo "- Servicio web: $(curl -s http://localhost:3002/health >/dev/null && echo 'Activo' || echo 'Inactivo')"
echo ""
echo "🌐 URLs del servicio:"
echo "- Web: http://216.9.226.186:3002/"
echo "- Health: http://216.9.226.186:3002/health"
echo "- Upload: http://216.9.226.186:3002/upload"</content>
<parameter name="filePath">d:\Onedrive Robert Personal\OneDrive\Documents\GitHub\UNIT3D-9.1.5\image-service\scripts\recover-service.sh
