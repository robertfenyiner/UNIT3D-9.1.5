#!/bin/bash

# INSTALACIÓN COMPLETA DESDE CERO - Lat-team Image Service
# Incluye limpieza completa de instalaciones previas

set -e

echo "🚀 INSTALACIÓN COMPLETA DESDE CERO - Lat-team Image Service"
echo "Servidor: $(hostname -f)"
echo "Fecha: $(date)"
echo ""
echo "⚠️  Este script incluye limpieza completa de instalaciones previas"
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

# Función de limpieza completa
cleanup_previous_installation() {
    echo ""
    echo "🧹 Iniciando limpieza completa de instalaciones previas..."
    
    # 1. Detener y eliminar servicios systemd
    echo "  🔧 Eliminando servicios systemd..."
    
    # Lista de servicios a eliminar
    SERVICES_TO_REMOVE=(
        "rclone-onedrive.service"
        "rclone-onedrive-images.service" 
        "rclone-images.service"
        "onedrive-mount.service"
        "rclone-mount.service"
        "image-service.service"
        "lat-team-image-service.service"
    )
    
    for service in "${SERVICES_TO_REMOVE[@]}"; do
        if sudo systemctl is-active --quiet "$service" 2>/dev/null; then
            echo "    🛑 Deteniendo $service..."
            sudo systemctl stop "$service" || true
        fi
        
        if sudo systemctl is-enabled --quiet "$service" 2>/dev/null; then
            echo "    🔧 Deshabilitando $service..."
            sudo systemctl disable "$service" || true
        fi
        
        if [ -f "/etc/systemd/system/$service" ]; then
            echo "    🗑️ Eliminando archivo de servicio $service..."
            sudo rm -f "/etc/systemd/system/$service"
        fi
    done
    
    # Recargar systemd después de eliminar servicios
    sudo systemctl daemon-reload
    
    # 2. Desmontar sistemas de archivos
    echo "  🔌 Desmontando sistemas de archivos..."
    MOUNT_POINTS=(
        "/var/www/html/storage/images"
        "/var/www/html/image-service/storage"
        "/mnt/onedrive"
        "/mnt/rclone"
    )
    
    for mount_point in "${MOUNT_POINTS[@]}"; do
        if mountpoint -q "$mount_point" 2>/dev/null; then
            echo "    🔌 Desmontando $mount_point..."
            sudo umount "$mount_point" || true
            sudo fusermount -uz "$mount_point" || true
        fi
    done
    
    # 3. Eliminar directorios y archivos del proyecto
    echo "  📁 Eliminando directorios y archivos del proyecto..."
    DIRECTORIES_TO_REMOVE=(
        "/var/www/html/storage"
        "/var/www/html/image-service"
        "/var/log/rclone-images.log"
        "/etc/rclone"
    )
    
    for dir in "${DIRECTORIES_TO_REMOVE[@]}"; do
        if [ -e "$dir" ]; then
            echo "    🗑️ Eliminando $dir..."
            sudo rm -rf "$dir"
        fi
    done
    
    # 4. Limpiar configuración de rclone (opcional)
    if [ -f "/etc/rclone/rclone.conf" ]; then
        echo "  📄 Eliminando configuración de rclone..."
        sudo rm -f "/etc/rclone/rclone.conf"
    fi
    
    # 5. Limpiar crontab
    echo "  ⏰ Limpiando crontab..."
    if command_exists crontab; then
        # Remover líneas relacionadas con image-service
        sudo crontab -l 2>/dev/null | grep -v "image-service\|monitor-rclone\|rclone" | sudo crontab - 2>/dev/null || true
    fi
    
    # 6. Limpiar paquetes npm globales relacionados (opcional)
    echo "  📦 Verificando paquetes npm..."
    if command_exists npm; then
        # No eliminamos npm globales ya que pueden ser usados por otros proyectos
        echo "    ⏭️  Saltando limpieza de npm globales (preservar otros proyectos)"
    fi
    
    print_success "Limpieza completa finalizada"
    echo ""
}

# Preguntar si hacer limpieza
echo "🔍 Verificando instalaciones previas..."
if [ -d "/var/www/html/image-service" ] || [ -f "/etc/systemd/system/rclone-onedrive.service" ] || [ -f "/etc/systemd/system/image-service.service" ]; then
    print_warning "Se detectaron instalaciones previas del servicio"
    echo ""
    read -p "¿Deseas eliminar completamente las instalaciones previas? (recomendado) [S/n]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        cleanup_previous_installation
    else
        print_warning "Continuando sin limpieza (pueden ocurrir conflictos)"
        echo ""
    fi
else
    print_success "No se detectaron instalaciones previas"
    echo ""
fi

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

# PASO 2: Preparar entorno desde cero
print_step "2" "Preparando entorno desde cero..."

# Crear directorio del proyecto si no existe
if [ ! -d "/var/www/html/image-service" ]; then
    echo "  📁 Creando directorio del proyecto..."
    sudo mkdir -p /var/www/html/image-service
    print_success "Directorio del proyecto creado"
else
    print_success "Directorio del proyecto ya existe"
fi

# Copiar archivos del proyecto (asumiendo que están en el directorio actual)
if [ -f "package.json" ] && [ -f "app.js" ]; then
    echo "  📋 Copiando archivos del proyecto..."
    # Copiar todos los archivos necesarios
    sudo cp -r . /var/www/html/image-service/
    print_success "Archivos del proyecto copiados"
else
    print_error "No se encontraron los archivos del proyecto (package.json, app.js)"
    echo "Asegúrate de ejecutar este script desde el directorio del proyecto image-service"
    exit 1
fi

print_success "Entorno preparado"

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

# PASO 5: Preparar directorios y permisos
print_step "5" "Preparando directorios y permisos..."

# Crear directorios necesarios
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

# PASO 6: Configurar FUSE
print_step "6" "Configurando FUSE para rclone..."

if ! grep -q "user_allow_other" /etc/fuse.conf; then
    echo "user_allow_other" | sudo tee -a /etc/fuse.conf
    print_success "FUSE configurado"
else
    print_success "FUSE ya configurado"
fi

# PASO 7: Crear servicios systemd
print_step "7" "Creando servicios systemd..."

# Servicio rclone
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

# Servicio image-service
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

print_success "Servicios systemd creados"

# PASO 8: Configurar systemd
print_step "8" "Configurando systemd..."

sudo systemctl daemon-reload
sudo systemctl enable rclone-onedrive.service
sudo systemctl enable image-service.service

print_success "Servicios habilitados"

# PASO 9: Crear directorio en OneDrive
print_step "9" "Creando directorio en OneDrive..."

rclone mkdir imagenes:/Lat-team-Images || echo "El directorio ya existe o se creó"
print_success "Directorio Lat-team-Images creado/verificado en OneDrive"

# PASO 10: Iniciar servicios
print_step "10" "Iniciando servicios..."

sudo systemctl start rclone-onedrive.service
sleep 5
sudo systemctl start image-service.service

print_success "Servicios iniciados"

# PASO 11: Verificar instalación
print_step "11" "Verificando instalación..."

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
echo "  Ver archivos en OneDrive: rclone lsd imagenes:Lat-team-Images"
echo "  Ver uso de espacio: df -h /var/www/html/storage/images"
echo ""
echo "✨ ¡El servicio está listo para recibir imágenes!"
<parameter name="filePath">d:\Onedrive Robert Personal\OneDrive\Documents\GitHub\UNIT3D-9.1.5\image-service\scripts\install-complete.sh
