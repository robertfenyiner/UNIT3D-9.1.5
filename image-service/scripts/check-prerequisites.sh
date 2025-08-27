#!/bin/bash

# Script de verificación de prerrequisitos para UNIT3D Image Service

echo "🔍 Verificación de prerrequisitos para UNIT3D Image Service"
echo "Servidor: $(hostname -f)"
echo "Fecha: $(date)"
echo ""

# Función de colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_check() {
    local status=$1
    local message=$2
    if [ "$status" = "ok" ]; then
        echo -e "${GREEN}✅${NC} $message"
    elif [ "$status" = "warning" ]; then
        echo -e "${YELLOW}⚠️${NC} $message"
    else
        echo -e "${RED}❌${NC} $message"
    fi
}

checks_passed=0
total_checks=0

# 1. Sistema operativo
((total_checks++))
echo "🐧 Sistema operativo..."
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ "$ID" == "ubuntu" || "$ID" == "debian" ]]; then
        print_check "ok" "Sistema compatible: $PRETTY_NAME"
        ((checks_passed++))
    else
        print_check "warning" "Sistema no probado: $PRETTY_NAME (debería funcionar)"
        ((checks_passed++))
    fi
else
    print_check "error" "No se puede determinar el sistema operativo"
fi

# 2. Arquitectura
((total_checks++))
echo ""
echo "🏗️ Arquitectura del sistema..."
arch=$(uname -m)
if [[ "$arch" == "x86_64" || "$arch" == "amd64" ]]; then
    print_check "ok" "Arquitectura compatible: $arch"
    ((checks_passed++))
else
    print_check "warning" "Arquitectura no estándar: $arch"
fi

# 3. Memoria RAM
((total_checks++))
echo ""
echo "🧠 Memoria RAM..."
ram_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
ram_gb=$((ram_kb / 1024 / 1024))
if [ $ram_gb -ge 1 ]; then
    print_check "ok" "Memoria RAM suficiente: ${ram_gb}GB"
    ((checks_passed++))
else
    print_check "warning" "Memoria RAM baja: ${ram_gb}GB (mínimo recomendado: 1GB)"
fi

# 4. Espacio en disco
((total_checks++))
echo ""
echo "💾 Espacio en disco..."
disk_space=$(df /var/www/html 2>/dev/null | tail -1 | awk '{print $4}')
disk_gb=$((disk_space / 1024 / 1024))
if [ $disk_gb -ge 5 ]; then
    print_check "ok" "Espacio suficiente: ${disk_gb}GB disponibles"
    ((checks_passed++))
else
    print_check "warning" "Espacio limitado: ${disk_gb}GB (recomendado: 5GB+)"
fi

# 5. Conexión a internet
((total_checks++))
echo ""
echo "🌐 Conexión a internet..."
if ping -c 1 -W 2 google.com >/dev/null 2>&1; then
    print_check "ok" "Conexión a internet activa"
    ((checks_passed++))
else
    print_check "error" "Sin conexión a internet"
fi

# 6. Usuario actual
((total_checks++))
echo ""
echo "👤 Usuario actual..."
if [ "$EUID" -eq 0 ]; then
    print_check "ok" "Ejecutando como root (correcto para instalación)"
    ((checks_passed++))
else
    print_check "warning" "No ejecutando como root (algunos comandos requerirán sudo)"
fi

# 7. rclone instalado
((total_checks++))
echo ""
echo "📁 rclone..."
if command -v rclone >/dev/null 2>&1; then
    version=$(rclone --version | head -1)
    print_check "ok" "rclone instalado: $version"
    ((checks_passed++))
else
    print_check "warning" "rclone no instalado (se instalará automáticamente)"
fi

# 8. Configuración de rclone
((total_checks++))
echo ""
echo "🔧 Configuración de rclone..."
if [ -f /etc/rclone/rclone.conf ]; then
    if grep -q "\[imagenes\]" /etc/rclone/rclone.conf; then
        print_check "ok" "Configuración de rclone encontrada (remote: imagenes)"
        ((checks_passed++))
    else
        print_check "error" "Configuración de rclone encontrada pero sin remote 'imagenes'"
        echo "   Contenido actual:"
        grep "^\[" /etc/rclone/rclone.conf
    fi
else
    print_check "warning" "No se encontró /etc/rclone/rclone.conf"
    echo "   Se creará durante la instalación"
fi

# 9. Node.js
((total_checks++))
echo ""
echo "🟢 Node.js..."
if command -v node >/dev/null 2>&1; then
    version=$(node --version)
    print_check "ok" "Node.js instalado: $version"
    ((checks_passed++))
else
    print_check "warning" "Node.js no instalado (se instalará automáticamente)"
fi

# 10. npm
((total_checks++))
echo ""
echo "📦 npm..."
if command -v npm >/dev/null 2>&1; then
    version=$(npm --version)
    print_check "ok" "npm instalado: $version"
    ((checks_passed++))
else
    print_check "warning" "npm no instalado (se instalará con Node.js)"
fi

# 11. Git
((total_checks++))
echo ""
echo "📚 Git..."
if command -v git >/dev/null 2>&1; then
    version=$(git --version)
    print_check "ok" "Git instalado: $version"
    ((checks_passed++))
else
    print_check "warning" "Git no instalado (opcional)"
fi

# 12. Curl
((total_checks++))
echo ""
echo "🌐 Curl..."
if command -v curl >/dev/null 2>&1; then
    version=$(curl --version | head -1)
    print_check "ok" "Curl instalado: $version"
    ((checks_passed++))
else
    print_check "error" "Curl no instalado (requerido)"
fi

# 13. Wget
((total_checks++))
echo ""
echo "📥 Wget..."
if command -v wget >/dev/null 2>&1; then
    version=$(wget --version | head -1)
    print_check "ok" "Wget instalado: $version"
    ((checks_passed++))
else
    print_check "warning" "Wget no instalado (opcional)"
fi

# 14. Sudo
((total_checks++))
echo ""
echo "🔑 Sudo..."
if command -v sudo >/dev/null 2>&1; then
    print_check "ok" "Sudo disponible"
    ((checks_passed++))
else
    print_check "warning" "Sudo no disponible"
fi

# 15. Systemd
((total_checks++))
echo ""
echo "⚙️ Systemd..."
if command -v systemctl >/dev/null 2>&1; then
    print_check "ok" "Systemd disponible"
    ((checks_passed++))
else
    print_check "error" "Systemd no disponible (requerido)"
fi

# 16. FUSE
((total_checks++))
echo ""
echo "🔗 FUSE..."
if [ -f /etc/fuse.conf ]; then
    if grep -q "user_allow_other" /etc/fuse.conf; then
        print_check "ok" "FUSE configurado correctamente"
        ((checks_passed++))
    else
        print_check "warning" "FUSE instalado pero no configurado (se configurará automáticamente)"
        ((checks_passed++))
    fi
else
    print_check "warning" "FUSE no encontrado (se instalará si es necesario)"
fi

# Resumen final
echo ""
echo "📊 RESUMEN DE VERIFICACIÓN"
echo "=========================="
echo "Checks superados: $checks_passed/$total_checks"

if [ $checks_passed -eq $total_checks ]; then
    echo ""
    print_check "ok" "¡Todos los prerrequisitos están OK!"
    echo ""
    echo "🚀 Puedes proceder con la instalación:"
    echo "   sudo bash scripts/install-complete.sh"
elif [ $checks_passed -ge $(($total_checks * 80 / 100)) ]; then
    echo ""
    print_check "warning" "La mayoría de prerrequisitos están OK"
    echo ""
    echo "🚀 Puedes proceder con la instalación (algunos componentes se instalarán automáticamente):"
    echo "   sudo bash scripts/install-complete.sh"
else
    echo ""
    print_check "error" "Varios prerrequisitos faltan"
    echo ""
    echo "🔧 Revisa los errores arriba antes de continuar"
fi

echo ""
echo "💡 Nota: Los componentes marcados como 'warning' se instalarán automáticamente durante el proceso de instalación."</content>
<parameter name="filePath">d:\Onedrive Robert Personal\OneDrive\Documents\GitHub\UNIT3D-9.1.5\image-service\scripts\check-prerequisites.sh
