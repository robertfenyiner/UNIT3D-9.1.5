#!/bin/bash

# LIMPIEZA MANUAL DE RESIDUOS - Lat-team Image Service
# Script para limpiar manualmente cualquier residuo que quede después de la instalación

set -e

echo "🧹 LIMPIEZA MANUAL DE RESIDUOS - Lat-team Image Service"
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
    echo -e "${BLUE}[LIMPIEZA $1]${NC} $2"
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

# Función para eliminar procesos que usen un directorio
kill_processes_using_dir() {
    local dir="$1"
    if command_exists fuser; then
        echo "  🔪 Matando procesos que usan $dir..."
        sudo fuser -k "$dir" 2>/dev/null || true
        sleep 2
    fi
}

# Función para desmontar sistemas de archivos
unmount_filesystems() {
    echo "  🔌 Desmontando sistemas de archivos..."
    local mount_points=(
        "/var/www/html/storage/images"
        "/var/www/html/image-service/storage"
        "/mnt/onedrive"
        "/mnt/rclone"
    )

    for mount_point in "${mount_points[@]}"; do
        if mountpoint -q "$mount_point" 2>/dev/null; then
            echo "    🔌 Desmontando $mount_point..."
            sudo umount "$mount_point" 2>/dev/null || true
            sudo fusermount -uz "$mount_point" 2>/dev/null || true
        fi
    done
}

# Función para limpiar servicios systemd
clean_systemd_services() {
    echo "  🔧 Limpiando servicios systemd..."

    local services=(
        "rclone-onedrive.service"
        "rclone-onedrive-images.service"
        "rclone-images.service"
        "onedrive-mount.service"
        "rclone-mount.service"
        "image-service.service"
        "lat-team-image-service.service"
    )

    for service in "${services[@]}"; do
        if sudo systemctl is-active --quiet "$service" 2>/dev/null; then
            echo "    🛑 Deteniendo $service..."
            sudo systemctl stop "$service" 2>/dev/null || true
        fi

        if sudo systemctl is-enabled --quiet "$service" 2>/dev/null; then
            echo "    🔧 Deshabilitando $service..."
            sudo systemctl disable "$service" 2>/dev/null || true
        fi

        if [ -f "/etc/systemd/system/$service" ]; then
            echo "    🗑️ Eliminando archivo de servicio $service..."
            sudo rm -f "/etc/systemd/system/$service" 2>/dev/null || true
        fi
    done

    sudo systemctl daemon-reload 2>/dev/null || true
}

# Función para limpiar directorios problemáticos
clean_problematic_directories() {
    echo "  📁 Limpiando directorios problemáticos..."

    local dirs=(
        "/var/www/html/storage"
        "/var/www/html/image-service"
        "/etc/rclone"
    )

    for dir in "${dirs[@]}"; do
        if [ -e "$dir" ]; then
            echo "    🗑️ Procesando $dir..."

            # Matar procesos
            kill_processes_using_dir "$dir"

            # Desmontar si es necesario
            if [[ "$dir" == "/var/www/html/storage" ]]; then
                unmount_filesystems
            fi

            # Cambiar permisos
            sudo chmod -R 777 "$dir" 2>/dev/null || true
            sudo find "$dir" -type f -exec chmod 666 {} \; 2>/dev/null || true

            # Intentar eliminación completa
            if sudo rm -rf "$dir" 2>/dev/null; then
                print_success "$dir eliminado correctamente"
            else
                echo "    🔄 Intentando eliminación archivo por archivo..."

                # Eliminar archivos uno por uno
                sudo find "$dir" -type f -delete 2>/dev/null || true
                sudo find "$dir" -type l -delete 2>/dev/null || true
                sudo find "$dir" -type d -empty -delete 2>/dev/null || true

                # Verificar si quedó vacío
                if [ -z "$(sudo ls -A "$dir" 2>/dev/null)" ]; then
                    sudo rmdir "$dir" 2>/dev/null && print_success "$dir eliminado completamente" || true
                else
                    print_warning "Algunos archivos en $dir no se pudieron eliminar"
                    echo "    Contenido restante:"
                    sudo ls -la "$dir" 2>/dev/null || true
                fi
            fi
        fi
    done
}

# Función para limpiar archivos de log
clean_log_files() {
    echo "  📋 Limpiando archivos de log..."

    local log_files=(
        "/var/log/rclone-images.log"
        "/var/www/html/image-service/logs/app.log"
        "/var/www/html/image-service/logs/error.log"
    )

    for log_file in "${log_files[@]}"; do
        if [ -f "$log_file" ]; then
            echo "    🗑️ Eliminando $log_file..."
            sudo rm -f "$log_file" 2>/dev/null && print_success "$log_file eliminado" || true
        fi
    done
}

# Función para limpiar crontab
clean_crontab() {
    echo "  ⏰ Limpiando crontab..."

    if command_exists crontab; then
        sudo crontab -l 2>/dev/null | grep -v "image-service\|monitor-rclone\|rclone" | sudo crontab - 2>/dev/null || true
        print_success "Crontab limpiado"
    fi
}

# Función para verificar limpieza
verify_cleanup() {
    echo "  🔍 Verificando limpieza..."

    local dirs_to_check=(
        "/var/www/html/storage"
        "/var/www/html/image-service"
        "/etc/rclone"
    )

    local all_clean=true

    for dir in "${dirs_to_check[@]}"; do
        if [ -e "$dir" ]; then
            print_warning "$dir aún existe"
            all_clean=false
        else
            print_success "$dir eliminado correctamente"
        fi
    done

    if $all_clean; then
        print_success "¡Limpieza completada exitosamente!"
    else
        print_warning "Algunos directorios no se pudieron eliminar completamente"
        echo "Puedes intentar eliminarlos manualmente o ejecutar este script nuevamente."
    fi
}

# Función principal
main() {
    local step=1

    print_step "$step" "Deteniendo servicios"
    clean_systemd_services
    ((step++))

    print_step "$step" "Desmontando sistemas de archivos"
    unmount_filesystems
    ((step++))

    print_step "$step" "Limpiando directorios problemáticos"
    clean_problematic_directories
    ((step++))

    print_step "$step" "Limpiando archivos de log"
    clean_log_files
    ((step++))

    print_step "$step" "Limpiando crontab"
    clean_crontab
    ((step++))

    print_step "$step" "Verificando limpieza"
    verify_cleanup

    echo ""
    echo "🎉 ¡LIMPIEZA MANUAL COMPLETADA!"
    echo ""
    echo "💡 Si aún quedan archivos, puedes eliminarlos manualmente:"
    echo "   sudo rm -rf /var/www/html/storage"
    echo "   sudo rm -rf /var/www/html/image-service"
    echo "   sudo rm -rf /etc/rclone"
    echo ""
    echo "🔄 Después de la limpieza, puedes ejecutar la instalación nuevamente:"
    echo "   sudo bash scripts/install-complete.sh"
}

# Ejecutar limpieza
main "$@"</content>
<parameter name="filePath">d:\Onedrive Robert Personal\OneDrive\Documents\GitHub\UNIT3D-9.1.5\image-service\scripts\cleanup-manual.sh
