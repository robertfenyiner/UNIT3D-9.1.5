#!/bin/bash

# Script de instalación completa para UNIT3D Image Service
# Ejecutar como root: sudo bash install.sh

set -e

echo "🚀 Instalando UNIT3D Image Service..."

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
SERVICE_DIR="/var/www/html/image-service"
SERVICE_NAME="image-service"
SERVICE_USER="www-data"

# Función para imprimir mensajes
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar que se ejecuta como root
if [[ $EUID -ne 0 ]]; then
   print_error "Este script debe ejecutarse como root (sudo)"
   exit 1
fi

print_status "Iniciando instalación de UNIT3D Image Service"

# 1. Verificar dependencias del sistema
print_status "Verificando dependencias del sistema..."

# Verificar Node.js
if ! command -v node &> /dev/null; then
    print_warning "Node.js no encontrado, instalando..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs
else
    NODE_VERSION=$(node --version)
    print_success "Node.js encontrado: $NODE_VERSION"
fi

# Verificar npm
if ! command -v npm &> /dev/null; then
    print_error "npm no encontrado, instalando Node.js completo..."
    apt-get update
    apt-get install -y nodejs npm
fi

# 2. Crear directorios necesarios
print_status "Creando estructura de directorios..."

mkdir -p "$SERVICE_DIR"
mkdir -p "/var/www/html/storage/images"
mkdir -p "/var/www/html/storage/images/thumbs"
mkdir -p "/var/log/image-service"

# 3. Copiar archivos del servicio (asumiendo que están en el directorio actual)
if [ -d "$(pwd)/config" ]; then
    print_status "Copiando archivos del servicio..."
    cp -r . "$SERVICE_DIR/"
    
    # Remover archivos no necesarios
    rm -f "$SERVICE_DIR"/*.md
    rm -rf "$SERVICE_DIR/.git" 2>/dev/null || true
else
    print_warning "Archivos del servicio no encontrados en directorio actual"
    print_status "Creando estructura básica..."
    
    # Crear estructura mínima si no existe
    mkdir -p "$SERVICE_DIR/config"
    mkdir -p "$SERVICE_DIR/routes"
    mkdir -p "$SERVICE_DIR/services"
    mkdir -p "$SERVICE_DIR/middleware"
    mkdir -p "$SERVICE_DIR/public"
    mkdir -p "$SERVICE_DIR/logs"
    mkdir -p "$SERVICE_DIR/storage/temp"
fi

# 4. Establecer permisos correctos
print_status "Configurando permisos..."

chown -R $SERVICE_USER:$SERVICE_USER "$SERVICE_DIR"
chown -R $SERVICE_USER:$SERVICE_USER "/var/www/html/storage"
chown -R $SERVICE_USER:$SERVICE_USER "/var/log/image-service"

chmod -R 755 "$SERVICE_DIR"
chmod -R 755 "/var/www/html/storage"
chmod +x "$SERVICE_DIR/scripts"/*.sh 2>/dev/null || true

# 5. Instalar dependencias npm
print_status "Instalando dependencias npm..."

cd "$SERVICE_DIR"

if [ -f "package.json" ]; then
    # Instalar como www-data para evitar problemas de permisos
    sudo -u $SERVICE_USER npm install --production
    print_success "Dependencias instaladas"
else
    print_warning "package.json no encontrado, creando configuración básica..."
    
    # Crear package.json básico
    cat > package.json << 'EOF'
{
  "name": "unit3d-image-service",
  "version": "1.0.0",
  "main": "app.js",
  "scripts": {
    "start": "node app.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "multer": "^1.4.5-lts.1",
    "sharp": "^0.32.6",
    "express-rate-limit": "^7.1.5",
    "helmet": "^7.1.0",
    "cors": "^2.8.5",
    "uuid": "^9.0.1",
    "mime-types": "^2.1.35",
    "winston": "^3.11.0",
    "express-validator": "^7.0.1",
    "compression": "^1.7.4",
    "morgan": "^1.10.0"
  }
}
EOF
    
    sudo -u $SERVICE_USER npm install --production
fi

# 6. Crear archivo de configuración si no existe
if [ ! -f "$SERVICE_DIR/config/config.json" ]; then
    print_status "Creando archivo de configuración..."
    
    mkdir -p "$SERVICE_DIR/config"
    cat > "$SERVICE_DIR/config/config.json" << 'EOF'
{
  "server": {
    "port": 3002,
    "host": "localhost",
    "name": "UNIT3D Image Service"
  },
  "storage": {
    "path": "/var/www/html/storage/images",
    "tempPath": "/var/www/html/image-service/storage/temp",
    "publicUrl": "https://your-domain.com/img"
  },
  "images": {
    "maxSize": "10MB",
    "maxSizeBytes": 10485760,
    "allowedTypes": ["image/jpeg", "image/png", "image/gif", "image/webp"],
    "allowedExtensions": [".jpg", ".jpeg", ".png", ".gif", ".webp"],
    "maxWidth": 2000,
    "maxHeight": 2000,
    "quality": 85
  },
  "security": {
    "rateLimit": {
      "windowMs": 900000,
      "max": 50
    },
    "allowedOrigins": ["https://your-domain.com", "http://localhost"]
  },
  "features": {
    "enableCompression": true,
    "enableThumbnails": true,
    "enableStats": true
  },
  "logging": {
    "level": "info",
    "file": "/var/log/image-service/image-service.log"
  }
}
EOF
    
    print_warning "Configuración creada con valores por defecto"
    print_warning "Edita $SERVICE_DIR/config/config.json con tus valores reales"
fi

# 7. Crear servicio systemd
print_status "Creando servicio systemd..."

cat > /etc/systemd/system/$SERVICE_NAME.service << EOF
[Unit]
Description=UNIT3D Image Service
Documentation=https://github.com/your-repo/unit3d-image-service
After=network.target

[Service]
Type=simple
User=$SERVICE_USER
Group=$SERVICE_USER
WorkingDirectory=$SERVICE_DIR
ExecStart=/usr/bin/node app.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production
Environment=PORT=3002

# Security settings
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/var/www/html/storage /var/log/image-service $SERVICE_DIR/logs $SERVICE_DIR/storage

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=image-service

# Resource limits
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOF

# 8. Habilitar y configurar el servicio
print_status "Configurando servicio systemd..."

systemctl daemon-reload
systemctl enable $SERVICE_NAME

# 9. Configurar logrotate
print_status "Configurando logrotate..."

cat > /etc/logrotate.d/image-service << 'EOF'
/var/log/image-service/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    copytruncate
    su www-data www-data
}
EOF

# 10. Crear script de backup
print_status "Creando script de backup..."

cat > "$SERVICE_DIR/scripts/backup.sh" << 'EOF'
#!/bin/bash
# Script de backup para imágenes
BACKUP_DIR="/var/backups/image-service"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p "$BACKUP_DIR"

echo "Creando backup de imágenes..."
tar -czf "$BACKUP_DIR/images_$DATE.tar.gz" -C /var/www/html/storage images/

echo "Limpiando backups antiguos (>7 días)..."
find "$BACKUP_DIR" -name "images_*.tar.gz" -mtime +7 -delete

echo "Backup completado: $BACKUP_DIR/images_$DATE.tar.gz"
EOF

chmod +x "$SERVICE_DIR/scripts/backup.sh"

# 11. Verificar instalación
print_status "Verificando instalación..."

if systemctl is-enabled $SERVICE_NAME &>/dev/null; then
    print_success "Servicio habilitado correctamente"
else
    print_error "Error habilitando el servicio"
fi

if [ -f "$SERVICE_DIR/app.js" ]; then
    print_success "Archivos del servicio encontrados"
else
    print_warning "app.js no encontrado, verifica los archivos del servicio"
fi

# 12. Mostrar instrucciones finales
print_success "✅ Instalación completada!"
echo ""
print_status "📋 Próximos pasos:"
echo ""
echo "1. Configurar rclone con OneDrive:"
echo "   sudo bash $SERVICE_DIR/scripts/setup-rclone.sh"
echo ""
echo "2. Editar configuración:"
echo "   nano $SERVICE_DIR/config/config.json"
echo ""
echo "3. Iniciar el servicio:"
echo "   sudo systemctl start $SERVICE_NAME"
echo ""
echo "4. Ver logs:"
echo "   sudo journalctl -u $SERVICE_NAME -f"
echo ""
echo "5. Verificar estado:"
echo "   curl http://localhost:3002/health"
echo ""
echo "🌐 Interfaz web: http://localhost:3002"
echo "📁 Directorio del servicio: $SERVICE_DIR"
echo "🗂️ Directorio de imágenes: /var/www/html/storage/images"
echo "📜 Logs: /var/log/image-service/"
echo ""
print_warning "⚠️ Recuerda configurar tu dominio en config.json y setup rclone!"
echo ""

exit 0