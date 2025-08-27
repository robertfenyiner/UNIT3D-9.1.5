#!/bin/bash

# INSTALADOR PORTABLE - Lat-team Image Service
# Ejecuta la instalación desde cualquier ubicación

set -e

echo "🚀 INSTALADOR PORTABLE - Lat-team Image Service"
echo "Servidor: $(hostname -f)"
echo "Fecha: $(date)"
echo ""

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

# Función para verificar si un comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Determinar la ubicación del script y el proyecto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "📂 Ubicación del script: $SCRIPT_DIR"
echo "📂 Ubicación del proyecto: $PROJECT_DIR"
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -f "$PROJECT_DIR/package.json" ] || [ ! -f "$PROJECT_DIR/app.js" ]; then
    print_error "No se encontraron los archivos del proyecto en: $PROJECT_DIR"
    echo "Asegúrate de ejecutar este script desde el directorio scripts/ del proyecto image-service"
    exit 1
fi

print_success "Archivos del proyecto encontrados correctamente"

# Crear directorio temporal para el script modificado
TEMP_SCRIPT="/tmp/install-complete-modified.sh"

# Copiar el script original y modificarlo
cp "$SCRIPT_DIR/install-complete.sh" "$TEMP_SCRIPT"

# Reemplazar la lógica de copia de archivos en el script temporal
# Primero, reemplazar el comentario
sed -i 's|# Copiar archivos del proyecto.*|# Copiar archivos del proyecto|g' "$TEMP_SCRIPT"

# Reemplazar la condición del primer if
sed -i 's|if \[ -f "package\.json" \] \&\& \[ -f "app\.js" \]; then|if [ -f "'"$PROJECT_DIR"'/package.json" ] \&\& [ -f "'"$PROJECT_DIR"'/app.js" ]; then|g' "$TEMP_SCRIPT"

# Reemplazar SOURCE_DIR en el primer bloque
sed -i 's|SOURCE_DIR="\$(pwd)"|SOURCE_DIR="'"$PROJECT_DIR"'"|g' "$TEMP_SCRIPT"

# Reemplazar el elif existente para que use PROJECT_DIR también
sed -i 's|elif \[ -f "\.\./package\.json" \] \&\& \[ -f "\.\./app\.js" \]; then|elif [ -f "'"$PROJECT_DIR"'/package.json" ] \&\& [ -f "'"$PROJECT_DIR"'/app.js" ]; then|g' "$TEMP_SCRIPT"

# Reemplazar SOURCE_DIR en el elif bloque
sed -i 's|SOURCE_DIR="\$(dirname \$(pwd))"|SOURCE_DIR="'"$PROJECT_DIR"'"|g' "$TEMP_SCRIPT"

# Eliminar el else y su bloque, ya que ahora siempre usamos PROJECT_DIR
sed -i '/else/,/fi/d' "$TEMP_SCRIPT"

# Ajustar el cp command
sed -i 's|sudo cp -r "\$SOURCE_DIR"/\* /var/www/html/image-service/|sudo cp -r "'"$PROJECT_DIR"'"/* /var/www/html/image-service/|g' "$TEMP_SCRIPT"

print_step "1" "Ejecutando instalación completa..."

# Ejecutar el script modificado
bash "$TEMP_SCRIPT"

# Limpiar archivo temporal
rm -f "$TEMP_SCRIPT"

print_success "Instalación completada desde ubicación portable"
echo ""
echo "🎉 ¡El servicio Lat-team Image Service está instalado y listo!"
echo ""
echo "📋 Información del servicio:"
echo "🌐 URL: http://216.9.226.186:3002/"
echo "💚 Health: http://216.9.226.186:3002/health"
echo "📤 Upload: http://216.9.226.186:3002/upload"</content>
<parameter name="filePath">d:\Onedrive Robert Personal\OneDrive\Documents\GitHub\UNIT3D-9.1.5\image-service\scripts\install-portable.sh
