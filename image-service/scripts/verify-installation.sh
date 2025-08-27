#!/bin/bash

# VERIFICACIÓN COMPLETA DEL SERVICIO LAT-TEAM IMAGE SERVICE
# Script para verificar que todos los componentes estén funcionando correctamente

set -e

echo "🔍 VERIFICACIÓN COMPLETA - Lat-team Image Service"
echo "Servidor: $(hostname -f)"
echo "Fecha: $(date)"
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
    echo -e "${BLUE}[VERIFICACIÓN $1]${NC} $2"
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

# Función para verificar conectividad
check_connectivity() {
    echo "  🌐 Verificando conectividad a internet..."
    if ping -c 1 google.com >/dev/null 2>&1; then
        print_success "Conectividad a internet OK"
    else
        print_error "Sin conectividad a internet"
        return 1
    fi
}

# Función para verificar servicios systemd
check_systemd_services() {
    echo "  🔧 Verificando servicios systemd..."

    local services=("rclone-onedrive.service" "image-service.service")
    local all_active=true

    for service in "${services[@]}"; do
        if sudo systemctl is-active --quiet "$service" 2>/dev/null; then
            print_success "Servicio $service activo"
        else
            print_error "Servicio $service inactivo"
            all_active=false
        fi
    done

    return $([ "$all_active" = true ])
}

# Función para verificar montaje rclone
check_rclone_mount() {
    echo "  📁 Verificando montaje rclone..."

    if mountpoint -q /var/www/html/storage/images; then
        print_success "Montaje OneDrive activo en /var/www/html/storage/images"

        # Verificar escritura
        echo "  ✏️  Verificando escritura..."
        if echo "test-$(date +%s)" | sudo tee /var/www/html/storage/images/verification-test.txt >/dev/null; then
            if [ -f "/var/www/html/storage/images/verification-test.txt" ]; then
                print_success "Escritura en OneDrive funciona"
                sudo rm /var/www/html/storage/images/verification-test.txt
            else
                print_error "Archivo de prueba no encontrado"
                return 1
            fi
        else
            print_error "Error al escribir archivo de prueba"
            return 1
        fi

        # Verificar espacio disponible
        echo "  📊 Verificando espacio disponible..."
        local space_info=$(df -h /var/www/html/storage/images | tail -1)
        print_success "Espacio disponible: $space_info"

    else
        print_error "Montaje OneDrive no encontrado"
        return 1
    fi
}

# Función para verificar servicio web
check_web_service() {
    echo "  🌐 Verificando servicio web..."

    local url="http://localhost:3002"

    # Verificar que el puerto esté abierto
    if sudo netstat -tlnp | grep :3002 >/dev/null; then
        print_success "Puerto 3002 abierto"
    else
        print_error "Puerto 3002 cerrado"
        return 1
    fi

    # Verificar endpoint de health
    echo "  💚 Verificando health check..."
    if curl -s "$url/health" >/dev/null; then
        print_success "Health check OK"
    else
        print_error "Health check fallido"
        return 1
    fi

    # Verificar respuesta del health check
    local health_response=$(curl -s "$url/health")
    if echo "$health_response" | grep -q "ok\|OK\|healthy"; then
        print_success "Respuesta del health check: $health_response"
    else
        print_warning "Respuesta del health check: $health_response"
    fi
}

# Función para verificar archivos del proyecto
check_project_files() {
    echo "  📁 Verificando archivos del proyecto..."

    local project_dir="/var/www/html/image-service"
    local required_files=("app.js" "package.json" "config/config.json")
    local all_files_present=true

    for file in "${required_files[@]}"; do
        if [ -f "$project_dir/$file" ]; then
            print_success "Archivo $file encontrado"
        else
            print_error "Archivo $file no encontrado"
            all_files_present=false
        fi
    done

    # Verificar node_modules
    if [ -d "$project_dir/node_modules" ]; then
        print_success "Dependencias de Node.js instaladas"
    else
        print_error "Dependencias de Node.js no instaladas"
        all_files_present=false
    fi

    return $([ "$all_files_present" = true ])
}

# Función para verificar configuración de rclone
check_rclone_config() {
    echo "  🔧 Verificando configuración de rclone..."

    if ! command_exists rclone; then
        print_error "rclone no está instalado"
        return 1
    fi

    # Verificar remote 'imagenes'
    if rclone listremotes | grep -q "imagenes:"; then
        print_success "Remote 'imagenes' configurado"
    else
        print_error "Remote 'imagenes' no encontrado"
        return 1
    fi

    # Verificar acceso al remote
    echo "  🔍 Verificando acceso al remote..."
    if rclone lsd imagenes: >/dev/null 2>&1; then
        print_success "Acceso al remote 'imagenes' OK"
    else
        print_error "Error al acceder al remote 'imagenes'"
        return 1
    fi

    # Verificar directorio Lat-team-Images
    if rclone lsd imagenes:Lat-team-Images >/dev/null 2>&1; then
        print_success "Directorio Lat-team-Images existe en OneDrive"
    else
        print_warning "Directorio Lat-team-Images no encontrado (se creará automáticamente)"
    fi
}

# Función para verificar permisos
check_permissions() {
    echo "  🔒 Verificando permisos..."

    local dirs=("/var/www/html/storage" "/var/www/html/image-service")
    local all_permissions_ok=true

    for dir in "${dirs[@]}"; do
        if [ -d "$dir" ]; then
            local owner=$(stat -c '%U:%G' "$dir")
            if [ "$owner" = "www-data:www-data" ]; then
                print_success "Permisos correctos en $dir ($owner)"
            else
                print_error "Permisos incorrectos en $dir ($owner)"
                all_permissions_ok=false
            fi
        else
            print_error "Directorio $dir no existe"
            all_permissions_ok=false
        fi
    done

    return $([ "$all_permissions_ok" = true ])
}

# Función para verificar logs
check_logs() {
    echo "  📋 Verificando logs..."

    local log_files=("/var/log/rclone-images.log" "/var/www/html/image-service/logs/app.log")
    local all_logs_accessible=true

    for log_file in "${log_files[@]}"; do
        if [ -f "$log_file" ]; then
            if [ -r "$log_file" ]; then
                local size=$(du -h "$log_file" | cut -f1)
                print_success "Log $log_file accesible ($size)"
            else
                print_error "Log $log_file no legible"
                all_logs_accessible=false
            fi
        else
            print_warning "Log $log_file no existe aún"
        fi
    done

    return $([ "$all_logs_accessible" = true ])
}

# Función para generar reporte final
generate_report() {
    echo ""
    echo "📊 REPORTE FINAL DE VERIFICACIÓN"
    echo "========================================"

    local total_checks=8
    local passed_checks=0

    # Contar verificaciones exitosas
    if [ "${CONNECTIVITY_OK:-0}" = "1" ]; then ((passed_checks++)); fi
    if [ "${SERVICES_OK:-0}" = "1" ]; then ((passed_checks++)); fi
    if [ "${MOUNT_OK:-0}" = "1" ]; then ((passed_checks++)); fi
    if [ "${WEB_OK:-0}" = "1" ]; then ((passed_checks++)); fi
    if [ "${FILES_OK:-0}" = "1" ]; then ((passed_checks++)); fi
    if [ "${RCLONE_OK:-0}" = "1" ]; then ((passed_checks++)); fi
    if [ "${PERMISSIONS_OK:-0}" = "1" ]; then ((passed_checks++)); fi
    if [ "${LOGS_OK:-0}" = "1" ]; then ((passed_checks++)); fi

    local percentage=$((passed_checks * 100 / total_checks))

    echo "✅ Verificaciones exitosas: $passed_checks/$total_checks ($percentage%)"

    if [ $percentage -eq 100 ]; then
        print_success "¡Todas las verificaciones pasaron exitosamente!"
        echo ""
        echo "🎉 El servicio Lat-team Image Service está completamente funcional"
        echo ""
        echo "📋 Información del servicio:"
        echo "🌐 URL: http://216.9.226.186:3002/"
        echo "💚 Health: http://216.9.226.186:3002/health"
        echo "📤 Upload: http://216.9.226.186:3002/upload"
    elif [ $percentage -ge 75 ]; then
        print_warning "El servicio está mayormente funcional ($percentage%)"
        echo "Revisa las verificaciones fallidas arriba"
    else
        print_error "El servicio tiene problemas importantes ($percentage%)"
        echo "Revisa las verificaciones fallidas y soluciona los problemas"
    fi
}

# Función principal
main() {
    local step=1

    # Verificación 1: Conectividad
    print_step "$step" "Conectividad a internet"
    if check_connectivity; then
        CONNECTIVITY_OK=1
    fi
    ((step++))

    # Verificación 2: Configuración de rclone
    print_step "$step" "Configuración de rclone"
    if check_rclone_config; then
        RCLONE_OK=1
    fi
    ((step++))

    # Verificación 3: Archivos del proyecto
    print_step "$step" "Archivos del proyecto"
    if check_project_files; then
        FILES_OK=1
    fi
    ((step++))

    # Verificación 4: Permisos
    print_step "$step" "Permisos de directorios"
    if check_permissions; then
        PERMISSIONS_OK=1
    fi
    ((step++))

    # Verificación 5: Servicios systemd
    print_step "$step" "Servicios systemd"
    if check_systemd_services; then
        SERVICES_OK=1
    fi
    ((step++))

    # Verificación 6: Montaje rclone
    print_step "$step" "Montaje rclone/OneDrive"
    if check_rclone_mount; then
        MOUNT_OK=1
    fi
    ((step++))

    # Verificación 7: Servicio web
    print_step "$step" "Servicio web"
    if check_web_service; then
        WEB_OK=1
    fi
    ((step++))

    # Verificación 8: Logs
    print_step "$step" "Logs del sistema"
    if check_logs; then
        LOGS_OK=1
    fi

    # Generar reporte final
    generate_report
}

# Ejecutar verificación principal
main "$@"</content>
<parameter name="filePath">d:\Onedrive Robert Personal\OneDrive\Documents\GitHub\UNIT3D-9.1.5\image-service\scripts\verify-installation.sh
