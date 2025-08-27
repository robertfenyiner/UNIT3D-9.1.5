#!/bin/bash

# INSTALACIÓN COMPLETA - UNIT3D Image Service con OneDrive
# Paso a paso automatizado

set -e

echo "🚀 INSTALACIÓN COMPLETA - UNIT3D Image Service"
echo "Servidor: $(hostname -f)"
echo "Fecha: $(date)"
echo ""
echo "Este script instalará todo lo necesario para el servicio de imágenes"
echo ""

# Función para verificar si un comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Función de colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${BLUE}[PASO $1]${NC} $2"
}

print_success() {
    echo -e "${GREEN}✅${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

# PASO 1: Verificar configuración de rclone existente
print_step "1" "Verificando configuración de rclone existente..."

if ! command_exists rclone; then
    print_error "rclone no está instalado"
    echo "Instalando rclone..."
    curl https://rclone.org/install.sh | sudo bash
    print_success "rclone instalado"
fi

# Verificar configuración
if ! rclone listremotes | grep -q "imagenes:"; then
    print_error "No se encontró la configuración 'imagenes' en rclone"
    echo ""
    echo "Para configurar rclone:"
    echo "1. Ejecuta: rclone config"
    echo "2. Selecciona 'n' para nuevo remote"
    echo "3. Nombre: imagenes"
    echo "4. Tipo: Microsoft OneDrive (opción 26)"
    echo "5. Sigue las instrucciones para autenticar"
    echo ""
    read -p "¿Ya configuraste rclone? (s/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        echo "Por favor configura rclone primero."
        exit 1
    fi
fi

print_success "Configuración de rclone verificada"

# PASO 2: Preparar directorios y permisos
print_step "2" "Preparando directorios y permisos..."

# Crear directorios
sudo mkdir -p /var/www/html/storage/images/thumbs
sudo mkdir -p /var/www/html/image-service/storage/temp
sudo mkdir -p /var/www/html/image-service/logs
sudo mkdir -p /etc/rclone

# Establecer permisos
sudo chown -R www-data:www-data /var/www/html/storage
sudo chown -R www-data:www-data /var/www/html/image-service/storage
sudo chown -R www-data:www-data /var/www/html/image-service/logs
sudo chmod -R 755 /var/www/html/storage
sudo chmod -R 755 /var/www/html/image-service/storage
sudo chmod -R 755 /var/www/html/image-service/logs

print_success "Directorios y permisos preparados"

# PASO 3: Instalar Node.js y npm
print_step "3" "Instalando Node.js y npm..."

if ! command_exists node; then
    # Instalar Node.js 18.x LTS
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
    print_success "Node.js instalado"
else
    print_success "Node.js ya está instalado"
fi

if ! command_exists npm; then
    print_error "npm no está instalado"
    exit 1
fi

print_success "Node.js $(node --version) y npm $(npm --version) listos"

# PASO 4: Instalar dependencias del proyecto
print_step "4" "Instalando dependencias del proyecto..."

cd /var/www/html/image-service

if [ ! -d "node_modules" ]; then
    npm install
    print_success "Dependencias instaladas"
else
    print_success "Dependencias ya instaladas"
fi

# PASO 5: Configurar FUSE
print_step "5" "Configurando FUSE para rclone..."

if ! grep -q "user_allow_other" /etc/fuse.conf; then
    echo "user_allow_other" | sudo tee -a /etc/fuse.conf
    print_success "FUSE configurado"
else
    print_success "FUSE ya configurado"
fi

# PASO 6: Crear servicios systemd
print_step "6" "Creando servicios systemd..."

# Servicio rclone
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

# Servicio image-service
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

print_success "Servicios systemd creados"

# PASO 7: Configurar systemd
print_step "7" "Configurando systemd..."

sudo systemctl daemon-reload
sudo systemctl enable rclone-onedrive.service
sudo systemctl enable image-service.service

print_success "Servicios habilitados"

# PASO 8: Crear directorio en OneDrive
print_step "8" "Creando directorio en OneDrive..."

rclone mkdir imagenes:/UNIT3D-Images || echo "El directorio ya existe o se creó"
print_success "Directorio UNIT3D-Images creado/verificado en OneDrive"

# PASO 9: Iniciar servicios
print_step "9" "Iniciando servicios..."

sudo systemctl start rclone-onedrive.service
sleep 5
sudo systemctl start image-service.service

print_success "Servicios iniciados"

# PASO 10: Verificar instalación
print_step "10" "Verificando instalación..."

echo ""
echo "🔍 Verificando servicios..."

# Verificar rclone
if sudo systemctl is-active --quiet rclone-onedrive.service; then
    print_success "Servicio rclone-onedrive activo"
else
    print_error "Servicio rclone-onedrive inactivo"
fi

# Verificar mount
if mountpoint -q /var/www/html/storage/images; then
    print_success "Mount de OneDrive activo"
else
    print_error "Mount de OneDrive no encontrado"
fi

# Verificar servicio web
if curl -s http://localhost:3002/health >/dev/null; then
    print_success "Servicio web activo"
else
    print_error "Servicio web no responde"
fi

# Probar escritura
echo "Test $(date)" | sudo tee /var/www/html/storage/images/test.txt >/dev/null
if [ -f "/var/www/html/storage/images/test.txt" ]; then
    print_success "Escritura en OneDrive funciona"
    sudo rm /var/www/html/storage/images/test.txt
else
    print_error "Error de escritura en OneDrive"
fi

# PASO 11: Información final
print_step "11" "Instalación completada!"

echo ""
echo "🎉 ¡INSTALACIÓN COMPLETADA EXITOSAMENTE!"
echo ""
echo "📋 Información del servicio:"
echo "🌐 URL del servicio: http://216.9.226.186:3002/"
echo "💚 Health check: http://216.9.226.186:3002/health"
echo "📤 Upload endpoint: http://216.9.226.186:3002/upload"
echo ""
echo "📁 Directorio de imágenes: /var/www/html/storage/images"
echo "📁 Logs del servicio: /var/www/html/image-service/logs/"
echo "📁 Logs de rclone: /var/log/rclone-images.log"
echo ""
echo "🔧 Comandos útiles:"
echo "  Ver estado: sudo systemctl status rclone-onedrive.service image-service.service"
echo "  Ver logs: sudo journalctl -u image-service.service -f"
echo "  Reiniciar: sudo systemctl restart rclone-onedrive.service image-service.service"
echo ""
echo "📊 Monitoreo:"
echo "  Ver archivos en OneDrive: rclone lsd imagenes:UNIT3D-Images"
echo "  Ver uso de espacio: df -h /var/www/html/storage/images"
echo ""
echo "✨ ¡El servicio está listo para recibir imágenes!"</content>
<parameter name="filePath">d:\Onedrive Robert Personal\OneDrive\Documents\GitHub\UNIT3D-9.1.5\image-service\scripts\install-complete.sh
