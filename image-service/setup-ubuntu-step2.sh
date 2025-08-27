#!/bin/bash

echo "🚀 UNIT3D Image Service - Instalación Ubuntu (Paso 2)"
echo "====================================================="
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
CURRENT_DIR=$(pwd)
SERVICE_NAME="unit3d-image-service"

# Verificar que estamos en el directorio correcto
if [ ! -f "app.js" ] || [ ! -f "package.json" ]; then
    print_error "No se encontraron los archivos del servicio (app.js, package.json)"
    print_error "Asegúrate de estar en el directorio image-service/"
    exit 1
fi

print_status "Directorio actual: $CURRENT_DIR"
print_success "Archivos del servicio encontrados"
echo ""

# PASO 1: Instalar dependencias de Node.js
print_status "📦 Instalando dependencias de Node.js..."
echo ""

if [ ! -d "node_modules" ]; then
    print_status "Ejecutando npm install..."
    if npm install; then
        print_success "Dependencias instaladas correctamente"
    else
        print_error "Error instalando dependencias con npm"
        echo ""
        echo "Intentando solucionar problemas comunes:"
        
        # Limpiar cache de npm
        print_status "Limpiando cache de npm..."
        npm cache clean --force
        
        # Intentar instalar con --no-optional para evitar problemas con canvas u otras deps opcionales
        print_status "Reintentando instalación sin dependencias opcionales..."
        if npm install --no-optional; then
            print_success "Dependencias instaladas (sin opcionales)"
        else
            print_error "No se pudieron instalar las dependencias"
            echo ""
            echo "Verifica que tengas:"
            echo "- Node.js >= 16.0.0"
            echo "- Python 3"
            echo "- Build tools (gcc, g++, make)"
            echo ""
            echo "Instalar con: sudo apt install nodejs npm python3 build-essential"
            exit 1
        fi
    fi
else
    print_success "node_modules ya existe, saltando instalación"
fi
echo ""

# PASO 2: Crear directorios necesarios
print_status "📁 Creando estructura de directorios..."

directories=(
    "storage"
    "storage/images" 
    "storage/temp"
    "storage/thumbs"
    "logs"
)

for dir in "${directories[@]}"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        print_success "Creado: $dir"
    else
        print_success "Ya existe: $dir"
    fi
done
echo ""

# PASO 3: Configurar permisos
print_status "🔒 Configurando permisos..."

# Obtener el usuario actual
CURRENT_USER=$(whoami)
print_status "Usuario actual: $CURRENT_USER"

# Establecer permisos
chmod -R 755 storage/
chmod -R 755 logs/
chmod +x scripts/*.sh 2>/dev/null || true

print_success "Permisos configurados"
echo ""

# PASO 4: Crear configuración de desarrollo
print_status "⚙️ Configurando archivo de configuración para desarrollo..."

if [ ! -f "config/config.dev.json" ]; then
    mkdir -p config
    
    cat > config/config.dev.json << 'EOF'
{
  "server": {
    "port": 3002,
    "host": "0.0.0.0",
    "name": "UNIT3D Image Service (Development)"
  },
  "storage": {
    "path": "./storage/images",
    "tempPath": "./storage/temp",
    "publicUrl": "http://localhost:3002/image"
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
      "max": 100,
      "message": "Demasiadas subidas. Intenta de nuevo en 15 minutos."
    },
    "auth": {
      "enabled": false
    },
    "allowedOrigins": [
      "http://localhost",
      "http://127.0.0.1",
      "http://localhost:8000"
    ]
  },
  "features": {
    "enableCompression": true,
    "enableThumbnails": true,
    "enableWatermark": false,
    "enableStats": true,
    "enableCleanup": false
  },
  "logging": {
    "level": "debug",
    "file": "./logs/image-service.log",
    "maxSize": "20MB",
    "maxFiles": 5
  }
}
EOF
    print_success "Configuración de desarrollo creada"
else
    print_success "Configuración de desarrollo ya existe"
fi
echo ""

# PASO 5: Crear script de inicio rápido
print_status "🎯 Creando script de inicio rápido..."

cat > start-dev.sh << 'EOF'
#!/bin/bash

echo "🚀 Iniciando UNIT3D Image Service en modo desarrollo..."
echo ""

# Verificar que las dependencias estén instaladas
if [ ! -d "node_modules" ]; then
    echo "❌ Dependencias no instaladas. Ejecuta: npm install"
    exit 1
fi

# Crear directorios si no existen
mkdir -p storage/images storage/temp logs

# Establecer modo desarrollo
export NODE_ENV=development

# Mostrar información
echo "🌐 Servidor se iniciará en: http://localhost:3002"
echo "📁 Directorio de imágenes: ./storage/images"
echo "📊 Health check: http://localhost:3002/health"
echo "🖼️ Interfaz web: http://localhost:3002"
echo ""
echo "🛑 Para detener presiona Ctrl+C"
echo ""

# Iniciar servidor
node app.js
EOF

chmod +x start-dev.sh
print_success "Script de inicio creado: start-dev.sh"
echo ""

# PASO 6: Crear script de prueba rápida
print_status "🧪 Creando script de prueba rápida..."

cat > test-quick.sh << 'EOF'
#!/bin/bash

echo "🧪 Prueba Rápida - UNIT3D Image Service"
echo "======================================"
echo ""

# Verificar que el servidor esté corriendo
echo -n "🔍 Verificando servidor... "
if curl -s http://localhost:3002/health > /dev/null 2>&1; then
    echo "✅ Servidor respondiendo"
else
    echo "❌ Servidor no responde"
    echo ""
    echo "Inicia el servidor con: ./start-dev.sh"
    exit 1
fi

# Probar health check
echo -n "🏥 Probando health check... "
health_response=$(curl -s http://localhost:3002/health)
if echo "$health_response" | grep -q '"status":"healthy"'; then
    echo "✅ OK"
else
    echo "❌ Error"
    echo "Respuesta: $health_response"
fi

# Probar interfaz web
echo -n "🌐 Probando interfaz web... "
if curl -s http://localhost:3002/ | grep -q "UNIT3D Image Uploader"; then
    echo "✅ OK"
else
    echo "❌ Error"
fi

echo ""
echo "🎉 Pruebas completadas"
echo "🌐 Abrir en navegador: http://localhost:3002"
EOF

chmod +x test-quick.sh
print_success "Script de prueba creado: test-quick.sh"
echo ""

# PASO 7: Verificar instalación
print_status "✅ Verificando instalación..."

# Verificar archivos críticos
critical_files=(
    "app.js"
    "package.json"
    "config/config.dev.json"
    "start-dev.sh"
    "test-quick.sh"
)

all_good=true
for file in "${critical_files[@]}"; do
    if [ -f "$file" ]; then
        print_success "✓ $file"
    else
        print_error "✗ $file"
        all_good=false
    fi
done

# Verificar directorios
for dir in "${directories[@]}"; do
    if [ -d "$dir" ]; then
        print_success "✓ $dir/"
    else
        print_error "✗ $dir/"
        all_good=false
    fi
done
echo ""

# RESUMEN FINAL
echo "========================================================="
echo "📋 INSTALACIÓN COMPLETADA"
echo "========================================================="
echo ""

if [ "$all_good" = true ]; then
    print_success "✅ Instalación exitosa"
    echo ""
    echo "🚀 PRÓXIMOS PASOS:"
    echo ""
    echo "1. Iniciar el servidor:"
    echo "   ./start-dev.sh"
    echo ""
    echo "2. En otra terminal, probar el servicio:"
    echo "   ./test-quick.sh"
    echo ""
    echo "3. Abrir en navegador:"
    echo "   http://localhost:3002"
    echo ""
    echo "4. Configurar OneDrive (opcional):"
    echo "   ./setup-ubuntu-step3.sh"
    echo ""
else
    print_error "❌ Algunos archivos no se crearon correctamente"
    echo "Revisa los errores anteriores y ejecuta el script nuevamente"
fi

print_warning "💡 NOTA: Este es el modo desarrollo. Para producción usa setup-ubuntu-step3.sh"
echo ""

exit 0