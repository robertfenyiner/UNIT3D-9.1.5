#!/bin/bash

# Script maestro para configurar completamente rclone con OneDrive
## Verificar que la# Verificar que la configuración contiene imagenes
if ! grep -q "\[imagenes\]" /etc/rclone/rclone.conf; then
    echo "❌ No se encontró la configuración 'imagenes' en rclone.conf"
    echo "   Asegúrate de que tu configuración incluya:"
    echo "   [imagenes]"
    echo "   type = onedrive"
    echo "   ..."
    exit 1
fi

# Probar configuración
if ! rclone listremotes | grep -q "imagenes:"; then
    echo "❌ Error: rclone no puede leer la configuración imagenes"
    echo "   Verifica que el archivo /etc/rclone/rclone.conf tenga permisos correctos"
    rclone config show imagenes
    exit 1
fi

echo "✅ Configuración de rclone verificada correctamente"iene onedrive-images
if ! grep -q "\[imagenes\]" /etc/rclone/rclone.conf; then
    echo "❌ No se encontró la configuración 'imagenes' en rclone.conf"
    echo "   Asegúrate de que tu configuración incluya:"
    echo "   [imagenes]"
    echo "   type = onedrive"
    echo "   ..."
    exit 1
fi

# Probar configuración
if ! rclone listremotes | grep -q "imagenes:"; then
    echo "❌ Error: rclone no puede leer la configuración imagenes"
    echo "   Verifica que el archivo /etc/rclone/rclone.conf tenga permisos correctos"
    rclone config show imagenes
    exit 1
fi

echo "✅ Configuración de rclone verificada correctamente"e imágenes de Lat-team
# Asume que rclone.conf ya está configurado y disponible

set -e

echo "🚀 Configuración completa de rclone para Lat-team Image Service"
echo "Servidor: $(hostname -f)"
echo "Fecha: $(date)"
echo ""

# Función para verificar si un comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 0. Limpiar servicios rclone existentes para evitar conflictos
echo "🧹 Eliminando servicios rclone existentes..."

# Detener y eliminar servicios relacionados con rclone
SERVICES_TO_REMOVE=(
    "rclone-onedrive.service"
    "rclone-onedrive-images.service"
    "rclone-images.service"
    "onedrive-mount.service"
    "rclone-mount.service"
)

for service in "${SERVICES_TO_REMOVE[@]}"; do
    if sudo systemctl is-active --quiet "$service" 2>/dev/null; then
        echo "  🛑 Deteniendo $service..."
        sudo systemctl stop "$service" || true
    fi

    if sudo systemctl is-enabled --quiet "$service" 2>/dev/null; then
        echo "  � Deshabilitando $service..."
        sudo systemctl disable "$service" || true
    fi

    if [ -f "/etc/systemd/system/$service" ]; then
        echo "  🗑️ Eliminando archivo de servicio $service..."
        sudo rm -f "/etc/systemd/system/$service"
    fi
done

# Desmontar cualquier mount existente
echo "  🔌 Desmontando mounts existentes..."
sudo umount /var/www/html/storage/images 2>/dev/null || true
sudo fusermount -uz /var/www/html/storage/images 2>/dev/null || true

# Recargar systemd después de eliminar servicios
sudo systemctl daemon-reload

echo "✅ Limpieza de servicios rclone completada"

# 1. Verificar instalación de rclone
if ! command_exists rclone; then
    echo "❌ rclone no está instalado. Instálalo primero:"
    echo "   curl https://rclone.org/install.sh | sudo bash"
    exit 1
else
    echo "✅ rclone está instalado"
fi

# 2. Verificar configuración de rclone existente
echo "🔍 Verificando configuración de rclone..."

# Verificar que existe el archivo de configuración
if [ ! -f "/etc/rclone/rclone.conf" ]; then
    echo "❌ No se encontró /etc/rclone/rclone.conf"
    echo "   Asegúrate de que el archivo rclone.conf esté en /etc/rclone/rclone.conf"
    echo "   Puedes copiarlo desde tu configuración local:"
    echo "   sudo mkdir -p /etc/rclone"
    echo "   sudo cp /ruta/a/tu/rclone.conf /etc/rclone/rclone.conf"
    echo "   sudo chown root:root /etc/rclone/rclone.conf"
    echo "   sudo chmod 600 /etc/rclone/rclone.conf"
    exit 1
fi

# Verificar que la configuración contiene onedrive-images
if ! grep -q "\[onedrive-images\]" /etc/rclone/rclone.conf; then
    echo "❌ No se encontró la configuración 'onedrive-images' en rclone.conf"
    echo "   Asegúrate de que tu configuración incluya:"
    echo "   [onedrive-images]"
    echo "   type = onedrive"
    echo "   ..."
    exit 1
fi

# Probar configuración
if ! rclone listremotes | grep -q "onedrive-images:"; then
    echo "❌ Error: rclone no puede leer la configuración onedrive-images"
    echo "   Verifica que el archivo /etc/rclone/rclone.conf tenga permisos correctos"
    ls -la /etc/rclone/rclone.conf
    exit 1
fi

echo "✅ Configuración de rclone verificada correctamente"

# 3. Crear directorios necesarios
echo ""
echo "📁 Creando directorios..."
sudo mkdir -p /var/www/html/storage/images/thumbs
sudo mkdir -p /var/www/html/image-service/storage/temp
sudo mkdir -p /var/www/html/image-service/logs
sudo mkdir -p /var/log

# 4. Establecer permisos correctos
echo "🔐 Estableciendo permisos..."
sudo chown -R www-data:www-data /var/www/html/storage
sudo chown -R www-data:www-data /var/www/html/image-service/storage
sudo chown -R www-data:www-data /var/www/html/image-service/logs
sudo chmod -R 755 /var/www/html/storage
sudo chmod -R 755 /var/www/html/image-service/storage
sudo chmod -R 755 /var/www/html/image-service/logs

# 5. Configurar FUSE para permitir mounts de usuario
echo "🔧 Configurando FUSE..."
if ! grep -q "user_allow_other" /etc/fuse.conf; then
    echo "user_allow_other" | sudo tee -a /etc/fuse.conf
    echo "✅ FUSE configurado"
else
    echo "✅ FUSE ya configurado"
fi

# 6. Crear directorio en OneDrive
echo "📂 Creando directorio en OneDrive..."
rclone mkdir imagenes:/Lat-team-Images || echo "El directorio ya existe o se creó"

# 7. Probar conexión con OneDrive
echo "🧪 Probando conexión..."
if rclone lsd imagenes: >/dev/null 2>&1; then
    echo "✅ Conexión con OneDrive exitosa"
else
    echo "❌ Error conectando con OneDrive"
    echo "Verifica tu configuración de rclone:"
    rclone config show imagenes
    exit 1
fi

# 8. Instalar servicios systemd
echo "📋 Instalando servicios systemd..."

# Servicio para rclone mount
sudo tee /etc/systemd/system/rclone-onedrive.service > /dev/null <<EOF
[Unit]
Description=Rclone mount for OneDrive (Lat-team Images)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
Group=root
ExecStart=/usr/bin/rclone mount imagenes:Lat-team-Images /var/www/html/storage/images \\
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

# Servicio para image-service
sudo tee /etc/systemd/system/image-service.service > /dev/null <<EOF
[Unit]
Description=Lat-team Image Service
After=network.target rclone-onedrive.service
Requires=rclone-onedrive.service

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/var/www/html/image-service
ExecStart=/usr/bin/node app.js
Restart=on-failure
RestartSec=5s
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

# 9. Recargar systemd y habilitar servicios
echo "🔄 Configurando systemd..."
sudo systemctl daemon-reload
sudo systemctl enable rclone-onedrive.service
sudo systemctl enable image-service.service

# 10. Detener servicios si están corriendo
echo "🛑 Deteniendo servicios existentes..."
sudo systemctl stop rclone-onedrive.service || true
sudo systemctl stop image-service.service || true

# 11. Iniciar servicios
echo "▶️ Iniciando servicios..."
sudo systemctl start rclone-onedrive.service
sleep 5
sudo systemctl start image-service.service

# 12. Verificar estado
echo ""
echo "📊 Verificando estado..."
sudo systemctl status rclone-onedrive.service --no-pager
echo "---"
sudo systemctl status image-service.service --no-pager

# 13. Probar servicios
echo ""
echo "🧪 Probando servicios..."
sleep 3

# Verificar mount
if mountpoint -q /var/www/html/storage/images; then
    echo "✅ Mount de OneDrive activo"
else
    echo "❌ Error en mount de OneDrive"
fi

# Verificar servicio web
if curl -s http://localhost:3002/health > /dev/null; then
    echo "✅ Servicio web activo"
else
    echo "❌ Error en servicio web"
fi

# Probar escritura
echo "Test $(date)" | sudo tee /var/www/html/storage/images/test.txt > /dev/null
if [ -f "/var/www/html/storage/images/test.txt" ]; then
    echo "✅ Escritura en OneDrive exitosa"
    sudo rm /var/www/html/storage/images/test.txt
else
    echo "❌ Error escribiendo en OneDrive"
fi

echo ""
echo "🎉 ¡Configuración completada!"
echo ""
echo "📋 Resumen:"
echo "- Remote rclone: imagenes"
echo "- Mount point: /var/www/html/storage/images"
echo "- Servicio web: http://localhost:3002"
echo "- Logs rclone: /var/log/rclone-images.log"
echo "- Logs servicio: /var/www/html/image-service/logs/image-service.log"
echo ""
echo "🔧 Comandos útiles:"
echo "- Ver logs: sudo journalctl -u image-service.service -f"
echo "- Reiniciar servicios: sudo systemctl restart rclone-onedrive.service image-service.service"
echo "- Ver estado: sudo systemctl status rclone-onedrive.service image-service.service"
echo ""
echo "✨ El servicio está listo para recibir imágenes y almacenarlas en OneDrive"
echo ""
echo "🌐 URLs del servicio:"
echo "- Web: http://216.9.226.186:3002/"
echo "- Health check: http://216.9.226.186:3002/health"
echo "- Upload: http://216.9.226.186:3002/upload"</content>
<parameter name="filePath">d:\Onedrive Robert Personal\OneDrive\Documents\GitHub\UNIT3D-9.1.5\image-service\scripts\setup-complete.sh
