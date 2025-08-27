#!/bin/bash

# Script maestro para configurar completamente rclone con OneDrive
# para el servicio de imágenes de UNIT3D

set -e

echo "🚀 Configuración completa de rclone para UNIT3D Image Service"
echo "Servidor: $(hostname -f)"
echo "Fecha: $(date)"
echo ""

# Función para verificar si un comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 1. Instalar rclone si no está instalado
if ! command_exists rclone; then
    echo "📦 Instalando rclone..."
    curl https://rclone.org/install.sh | sudo bash
    echo "✅ rclone instalado"
else
    echo "✅ rclone ya está instalado"
fi

# 2. Configurar rclone si no está configurado
if ! rclone listremotes | grep -q "onedrive-images:"; then
    echo ""
    echo "⚙️ Configurando OneDrive..."
    echo "Sigue estas instrucciones:"
    echo "1. Nombre: onedrive-images"
    echo "2. Tipo: Microsoft OneDrive (opción 26)"
    echo "3. client_id: (presiona Enter)"
    echo "4. client_secret: (presiona Enter)"
    echo "5. region: global"
    echo "6. Edit advanced config: No"
    echo "7. Use auto config: Yes"
    echo "8. Type of connection: onedrive"
    echo "9. Choose drive: 0"
    echo "10. Confirm: Yes"
    echo ""
    read -p "Presiona Enter para continuar..."
    rclone config
else
    echo "✅ Configuración 'onedrive-images' ya existe"
fi

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
rclone mkdir onedrive-images:/UNIT3D-Images || echo "El directorio ya existe o se creó"

# 7. Probar conexión con OneDrive
echo "🧪 Probando conexión..."
if rclone lsd onedrive-images: >/dev/null 2>&1; then
    echo "✅ Conexión con OneDrive exitosa"
else
    echo "❌ Error conectando con OneDrive"
    echo "Verifica tu configuración de rclone:"
    rclone config show onedrive-images
    exit 1
fi

# 8. Instalar servicios systemd
echo "📋 Instalando servicios systemd..."

# Servicio para rclone mount
sudo tee /etc/systemd/system/rclone-onedrive.service > /dev/null <<EOF
[Unit]
Description=Rclone mount for OneDrive (UNIT3D Images)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
Group=root
ExecStart=/usr/bin/rclone mount onedrive-images:UNIT3D-Images /var/www/html/storage/images \\
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
Description=UNIT3D Image Service
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
echo "- Remote rclone: onedrive-images"
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
echo "✨ El servicio está listo para recibir imágenes y almacenarlas en OneDrive"</content>
<parameter name="filePath">d:\Onedrive Robert Personal\OneDrive\Documents\GitHub\UNIT3D-9.1.5\image-service\scripts\setup-complete.sh
