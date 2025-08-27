#!/bin/bash

echo "☁️ UNIT3D Image Service - Configuración OneDrive (Paso 3)"
echo "========================================================="
echo ""

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Variables
RCLONE_CONFIG_DIR="$HOME/.config/rclone"
RCLONE_CONFIG_FILE="$RCLONE_CONFIG_DIR/rclone.conf"
MOUNT_POINT="/var/www/html/storage/images"
REMOTE_NAME="onedrive-images"

echo "🎯 Este script configurará OneDrive con rclone para almacenamiento en la nube"
echo ""

# PASO 1: Verificar/Instalar rclone
print_status "🔍 Verificando rclone..."

if command -v rclone &> /dev/null; then
    rclone_version=$(rclone --version | head -1)
    print_success "rclone encontrado: $rclone_version"
else
    print_warning "rclone no instalado. Instalando..."
    
    # Descargar e instalar rclone
    print_status "Descargando rclone..."
    if curl -O https://downloads.rclone.org/rclone-current-linux-amd64.zip; then
        print_status "Descomprimiendo..."
        unzip -q rclone-current-linux-amd64.zip
        
        print_status "Instalando..."
        cd rclone-*-linux-amd64
        sudo cp rclone /usr/bin/
        sudo chown root:root /usr/bin/rclone
        sudo chmod 755 /usr/bin/rclone
        
        # Crear directorio para manual
        sudo mkdir -p /usr/local/share/man/man1
        sudo cp rclone.1 /usr/local/share/man/man1/
        sudo mandb &>/dev/null || true
        
        # Limpiar
        cd ..
        rm -rf rclone-*-linux-amd64 rclone-current-linux-amd64.zip
        
        if command -v rclone &> /dev/null; then
            print_success "rclone instalado correctamente"
        else
            print_error "Error instalando rclone"
            exit 1
        fi
    else
        print_error "Error descargando rclone"
        echo "Instala manualmente con: curl https://rclone.org/install.sh | sudo bash"
        exit 1
    fi
fi
echo ""

# PASO 2: Verificar configuración existente
print_status "📋 Verificando configuración existente de OneDrive..."

mkdir -p "$RCLONE_CONFIG_DIR"

if [ -f "$RCLONE_CONFIG_FILE" ] && rclone listremotes | grep -q "^${REMOTE_NAME}:$"; then
    print_success "Configuración de OneDrive '$REMOTE_NAME' encontrada"
    
    echo -n "¿Quieres reconfigurar OneDrive? (y/N): "
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        print_status "Usando configuración existente"
        skip_config=true
    else
        skip_config=false
    fi
else
    print_warning "No se encontró configuración de OneDrive"
    skip_config=false
fi
echo ""

# PASO 3: Configurar OneDrive (si es necesario)
if [ "$skip_config" != true ]; then
    print_status "🔧 Configurando OneDrive con rclone..."
    echo ""
    echo "IMPORTANTE: Necesitarás:"
    echo "- Una cuenta de OneDrive/Microsoft"
    echo "- Acceso a un navegador web para autorizar"
    echo ""
    
    echo -n "¿Continuar con la configuración? (Y/n): "
    read -r response
    if [[ "$response" =~ ^[Nn]$ ]]; then
        print_warning "Configuración cancelada"
        echo "Puedes configurar OneDrive manualmente después con:"
        echo "rclone config"
        exit 0
    fi
    
    print_status "Iniciando configuración interactiva de rclone..."
    echo ""
    echo "Instrucciones para la configuración:"
    echo "1. Elige 'n' para crear un nuevo remote"
    echo "2. Nombre: $REMOTE_NAME"
    echo "3. Tipo: Busca 'Microsoft OneDrive' (número ~23)"
    echo "4. client_id: Presiona Enter (vacío)"
    echo "5. client_secret: Presiona Enter (vacío)" 
    echo "6. región: 1 para OneDrive global"
    echo "7. Autorización: Sigue las instrucciones del navegador"
    echo "8. Configuración avanzada: n"
    echo "9. Confirmar: y"
    echo "10. Salir: q"
    echo ""
    echo "Presiona Enter para continuar..."
    read -r
    
    # Ejecutar configuración de rclone
    if rclone config; then
        if rclone listremotes | grep -q "^${REMOTE_NAME}:$"; then
            print_success "OneDrive configurado correctamente como '$REMOTE_NAME'"
        else
            print_error "OneDrive no se configuró con el nombre esperado '$REMOTE_NAME'"
            print_status "Remotes disponibles:"
            rclone listremotes
            echo ""
            echo -n "¿Cuál es el nombre correcto del remote de OneDrive? "
            read -r REMOTE_NAME
        fi
    else
        print_error "Error en la configuración de OneDrive"
        exit 1
    fi
fi
echo ""

# PASO 4: Probar conexión con OneDrive
print_status "🧪 Probando conexión con OneDrive..."

if rclone lsd "${REMOTE_NAME}:" 2>/dev/null | head -5; then
    print_success "Conexión con OneDrive exitosa"
else
    print_error "Error conectando con OneDrive"
    echo ""
    echo "Verifica:"
    echo "1. La configuración de rclone: rclone config"
    echo "2. Conexión a internet"
    echo "3. Permisos de la aplicación en tu cuenta Microsoft"
    exit 1
fi
echo ""

# PASO 5: Crear directorio en OneDrive
print_status "📁 Creando directorio para imágenes en OneDrive..."

ONEDRIVE_DIR="UNIT3D-Images"
if rclone mkdir "${REMOTE_NAME}:${ONEDRIVE_DIR}" 2>/dev/null; then
    print_success "Directorio '$ONEDRIVE_DIR' creado en OneDrive"
else
    # Puede que ya exista
    if rclone lsd "${REMOTE_NAME}:" | grep -q "$ONEDRIVE_DIR"; then
        print_success "Directorio '$ONEDRIVE_DIR' ya existe en OneDrive"
    else
        print_warning "No se pudo crear el directorio en OneDrive"
    fi
fi
echo ""

# PASO 6: Configurar mount point
print_status "🗂️ Configurando punto de montaje..."

# Crear directorio de montaje si no existe
if [ ! -d "$MOUNT_POINT" ]; then
    print_status "Creando directorio de montaje: $MOUNT_POINT"
    sudo mkdir -p "$MOUNT_POINT"
fi

# Configurar permisos
sudo chown $(whoami):$(whoami) "$MOUNT_POINT" 2>/dev/null || true
print_success "Punto de montaje configurado: $MOUNT_POINT"
echo ""

# PASO 7: Crear script de montaje
print_status "📜 Creando script de montaje..."

cat > mount-onedrive.sh << EOF
#!/bin/bash

echo "☁️ Montando OneDrive para UNIT3D Image Service..."

# Variables
REMOTE="${REMOTE_NAME}:${ONEDRIVE_DIR}"
MOUNT_POINT="$MOUNT_POINT"

# Verificar si ya está montado
if mountpoint -q "\$MOUNT_POINT" 2>/dev/null; then
    echo "✅ OneDrive ya está montado en \$MOUNT_POINT"
    exit 0
fi

# Verificar que el directorio existe
if [ ! -d "\$MOUNT_POINT" ]; then
    echo "📁 Creando directorio de montaje..."
    sudo mkdir -p "\$MOUNT_POINT"
    sudo chown \$(whoami):\$(whoami) "\$MOUNT_POINT"
fi

# Montar OneDrive
echo "🔄 Montando OneDrive..."
if rclone mount "\$REMOTE" "\$MOUNT_POINT" --daemon --allow-other --allow-non-empty --vfs-cache-mode writes; then
    echo "✅ OneDrive montado exitosamente"
    echo "📁 Punto de montaje: \$MOUNT_POINT"
    
    # Verificar montaje
    sleep 2
    if mountpoint -q "\$MOUNT_POINT"; then
        echo "✅ Verificación de montaje exitosa"
    else
        echo "❌ Error: El montaje no se verificó correctamente"
        exit 1
    fi
else
    echo "❌ Error montando OneDrive"
    echo ""
    echo "Posibles soluciones:"
    echo "1. Verificar configuración: rclone config"
    echo "2. Probar conexión: rclone ls $REMOTE_NAME:"
    echo "3. Verificar permisos en \$MOUNT_POINT"
    exit 1
fi
EOF

chmod +x mount-onedrive.sh
print_success "Script de montaje creado: mount-onedrive.sh"
echo ""

# PASO 8: Crear script de desmontaje
cat > unmount-onedrive.sh << EOF
#!/bin/bash

echo "🔄 Desmontando OneDrive..."

MOUNT_POINT="$MOUNT_POINT"

if mountpoint -q "\$MOUNT_POINT" 2>/dev/null; then
    if fusermount -u "\$MOUNT_POINT" 2>/dev/null || umount "\$MOUNT_POINT" 2>/dev/null; then
        echo "✅ OneDrive desmontado"
    else
        echo "⚠️ Forzando desmontaje..."
        sudo fusermount -uz "\$MOUNT_POINT" || sudo umount -f "\$MOUNT_POINT"
        echo "✅ Desmontaje forzado completado"
    fi
else
    echo "ℹ️ OneDrive no estaba montado"
fi
EOF

chmod +x unmount-onedrive.sh
print_success "Script de desmontaje creado: unmount-onedrive.sh"
echo ""

# PASO 9: Configurar el servicio para usar OneDrive
print_status "⚙️ Actualizando configuración del servicio..."

if [ -f "config/config.json" ]; then
    # Backup de la configuración actual
    cp config/config.json config/config.json.backup
    print_status "Backup de configuración creado"
fi

# Crear configuración de producción con OneDrive
cat > config/config.json << EOF
{
  "server": {
    "port": 3002,
    "host": "0.0.0.0",
    "name": "UNIT3D Image Service"
  },
  "storage": {
    "path": "$MOUNT_POINT",
    "tempPath": "./storage/temp",
    "publicUrl": "https://tu-dominio.com/img",
    "rclone": {
      "remote": "$REMOTE_NAME",
      "path": "$ONEDRIVE_DIR"
    }
  },
  "images": {
    "maxSize": "10MB",
    "maxSizeBytes": 10485760,
    "allowedTypes": ["image/jpeg", "image/png", "image/gif", "image/webp"],
    "allowedExtensions": [".jpg", ".jpeg", ".png", ".gif", ".webp"],
    "maxWidth": 2000,
    "maxHeight": 2000,
    "quality": 85,
    "thumbnailWidth": 350,
    "thumbnailQuality": 75
  },
  "security": {
    "rateLimit": {
      "windowMs": 900000,
      "max": 50,
      "message": "Demasiadas subidas. Intenta de nuevo en 15 minutos."
    },
    "auth": {
      "enabled": false,
      "unit3dUrl": "https://tu-dominio.com",
      "apiKey": "tu-api-key-aqui"
    },
    "allowedOrigins": [
      "https://tu-dominio.com",
      "http://localhost",
      "http://127.0.0.1"
    ]
  },
  "features": {
    "enableCompression": true,
    "enableThumbnails": true,
    "enableWatermark": false,
    "enableStats": true,
    "enableCleanup": true,
    "cleanupDays": 30
  },
  "logging": {
    "level": "info",
    "file": "./logs/image-service.log",
    "maxSize": "20MB",
    "maxFiles": 5
  }
}
EOF

print_success "Configuración de producción creada"
echo ""

# PASO 10: Crear script de prueba con OneDrive
print_status "🧪 Creando script de prueba con OneDrive..."

cat > test-onedrive.sh << 'EOF'
#!/bin/bash

echo "🧪 Prueba de OneDrive - UNIT3D Image Service"
echo "============================================"
echo ""

MOUNT_POINT="/var/www/html/storage/images"

# Verificar que OneDrive esté montado
echo -n "☁️ Verificando montaje de OneDrive... "
if mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
    echo "✅ Montado"
else
    echo "❌ No montado"
    echo ""
    echo "Para montar OneDrive ejecuta: ./mount-onedrive.sh"
    exit 1
fi

# Probar escritura
echo -n "✏️ Probando escritura... "
test_file="$MOUNT_POINT/.test_$(date +%s).txt"
if echo "test" > "$test_file" 2>/dev/null; then
    rm -f "$test_file" 2>/dev/null
    echo "✅ OK"
else
    echo "❌ Error"
    echo "Verifica permisos en $MOUNT_POINT"
    exit 1
fi

# Verificar espacio
echo -n "💾 Verificando espacio disponible... "
if df -h "$MOUNT_POINT" 2>/dev/null | tail -1; then
    echo "✅ Información de espacio obtenida"
else
    echo "⚠️ No se pudo obtener información de espacio"
fi

echo ""
echo "🎉 OneDrive funcionando correctamente"
echo "📁 Montado en: $MOUNT_POINT"
EOF

chmod +x test-onedrive.sh
print_success "Script de prueba creado: test-onedrive.sh"
echo ""

# RESUMEN FINAL
echo "========================================================="
echo "☁️ CONFIGURACIÓN DE ONEDRIVE COMPLETADA"
echo "========================================================="
echo ""
print_success "✅ OneDrive configurado exitosamente"
echo ""
echo "🚀 COMANDOS IMPORTANTES:"
echo ""
echo "Montar OneDrive:"
echo "   ./mount-onedrive.sh"
echo ""
echo "Desmontar OneDrive:"
echo "   ./unmount-onedrive.sh"
echo ""
echo "Probar OneDrive:"
echo "   ./test-onedrive.sh"
echo ""
echo "Ver archivos en OneDrive:"
echo "   rclone ls $REMOTE_NAME:$ONEDRIVE_DIR"
echo ""
echo "📝 CONFIGURACIÓN:"
echo "- Remote: $REMOTE_NAME"
echo "- Directorio OneDrive: $ONEDRIVE_DIR"
echo "- Punto de montaje: $MOUNT_POINT"
echo "- Configuración: config/config.json"
echo ""
print_warning "⚠️ IMPORTANTE: Ejecuta './mount-onedrive.sh' antes de usar el servicio"
echo ""
echo "📋 PRÓXIMO PASO:"
echo "   ./setup-ubuntu-step4.sh  # Configurar servicio systemd y pruebas finales"
echo ""

exit 0