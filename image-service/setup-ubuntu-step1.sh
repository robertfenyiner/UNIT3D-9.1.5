#!/bin/bash

echo "🐧 UNIT3D Image Service - Verificación del Sistema Ubuntu"
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
    echo -e "${GREEN}[OK]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Función para verificar comando
check_command() {
    local cmd=$1
    local name=$2
    
    echo -n "Verificando $name... "
    if command -v "$cmd" &> /dev/null; then
        local version=$($cmd --version 2>/dev/null | head -1)
        echo -e "${GREEN}✅ Instalado${NC} - $version"
        return 0
    else
        echo -e "${RED}❌ No encontrado${NC}"
        return 1
    fi
}

echo "🔍 VERIFICANDO DEPENDENCIAS DEL SISTEMA:"
echo ""

# Sistema operativo
print_status "Sistema operativo:"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "   Distribución: $NAME $VERSION"
    echo "   Kernel: $(uname -r)"
else
    echo "   Sistema: $(uname -a)"
fi
echo ""

# Verificar dependencias críticas
print_status "Verificando herramientas esenciales:"
check_command "curl" "cURL"
check_command "wget" "wget" 
check_command "git" "Git"
check_command "unzip" "unzip"
check_command "sudo" "sudo"
echo ""

# Verificar Node.js y npm
print_status "Verificando Node.js y NPM:"
node_installed=false
if check_command "node" "Node.js"; then
    node_version=$(node --version | sed 's/v//')
    if [ "$(printf '%s\n' "16.0.0" "$node_version" | sort -V | head -n1)" = "16.0.0" ]; then
        print_success "Node.js versión compatible: $node_version"
        node_installed=true
    else
        print_warning "Node.js versión muy antigua: $node_version (se necesita >= 16.0.0)"
    fi
else
    print_error "Node.js no instalado"
fi

if check_command "npm" "NPM"; then
    print_success "NPM disponible"
else
    print_error "NPM no instalado"
    node_installed=false
fi
echo ""

# Verificar Python (necesario para algunas dependencias de npm)
print_status "Verificando Python (necesario para compilar Sharp):"
if check_command "python3" "Python 3"; then
    print_success "Python 3 disponible"
else
    print_warning "Python 3 no encontrado (puede causar problemas con Sharp)"
fi
echo ""

# Verificar herramientas de compilación
print_status "Verificando herramientas de compilación:"
if command -v gcc &> /dev/null && command -v g++ &> /dev/null && command -v make &> /dev/null; then
    print_success "Build tools disponibles (gcc, g++, make)"
else
    print_warning "Build tools no completos (pueden ser necesarios para Sharp)"
fi
echo ""

# Verificar espacio en disco
print_status "Verificando espacio en disco:"
df -h . | tail -1 | while read filesystem size used avail percent mountpoint; do
    echo "   Disponible: $avail en $mountpoint"
    if [ "${percent%\%}" -lt 90 ]; then
        print_success "Espacio suficiente disponible"
    else
        print_warning "Poco espacio disponible ($percent usado)"
    fi
done
echo ""

# Verificar permisos
print_status "Verificando permisos de escritura:"
if [ -w . ]; then
    print_success "Permisos de escritura OK en directorio actual"
else
    print_error "Sin permisos de escritura en directorio actual"
fi

# Verificar si podemos crear directorios en /var/www/html
if [ -d "/var/www/html" ]; then
    if sudo -n test -w /var/www/html 2>/dev/null; then
        print_success "Permisos de escritura OK en /var/www/html"
    else
        print_warning "Se necesitará sudo para escribir en /var/www/html"
    fi
else
    print_warning "/var/www/html no existe (se creará durante la instalación)"
fi
echo ""

# Verificar puertos
print_status "Verificando puertos disponibles:"
if netstat -tuln 2>/dev/null | grep -q ":3002 "; then
    print_warning "Puerto 3002 ya en uso"
    echo "   Procesos usando el puerto:"
    sudo netstat -tulpn 2>/dev/null | grep ":3002 " || echo "   No se pudo determinar el proceso"
else
    print_success "Puerto 3002 disponible"
fi
echo ""

# Verificar rclone (opcional)
print_status "Verificando rclone (para OneDrive):"
if check_command "rclone" "rclone"; then
    print_success "rclone ya instalado"
else
    print_warning "rclone no instalado (se configurará después)"
fi
echo ""

# Resumen y recomendaciones
echo "========================================================="
echo "📋 RESUMEN Y PRÓXIMOS PASOS:"
echo ""

if [ "$node_installed" = true ]; then
    print_success "✅ Sistema listo para instalar UNIT3D Image Service"
    echo ""
    echo "Ejecuta los siguientes pasos:"
    echo "1. ./setup-ubuntu-step2.sh  # Instalar el servicio"
    echo "2. ./setup-ubuntu-step3.sh  # Configurar rclone y OneDrive"
    echo "3. ./setup-ubuntu-step4.sh  # Probar e iniciar el servicio"
else
    print_warning "⚠️ Necesitas instalar Node.js primero"
    echo ""
    echo "Para instalar Node.js 18 LTS:"
    echo "curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -"
    echo "sudo apt-get install -y nodejs"
    echo ""
    echo "Luego ejecuta este script nuevamente."
fi

echo ""
echo "Para instalar dependencias faltantes:"
echo "sudo apt update"
echo "sudo apt install -y curl wget git unzip python3 build-essential"
echo ""

exit 0