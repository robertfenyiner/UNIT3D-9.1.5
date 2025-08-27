#!/bin/bash

# Script de backup y recuperación para configuración de rclone
# Útil para migraciones o recuperación de desastres

set -e

BACKUP_DIR="/var/backups/rclone"
DATE=$(date +%Y%m%d_%H%M%S)

# Función de logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $*"
}

# Crear directorio de backup
sudo mkdir -p "$BACKUP_DIR"

case "$1" in
    "backup")
        log "📦 Creando backup de configuración rclone..."

        # Backup de configuración
        sudo cp /etc/rclone/rclone.conf "$BACKUP_DIR/rclone.conf.$DATE"

        # Backup de servicios systemd
        sudo cp /etc/systemd/system/rclone-onedrive.service "$BACKUP_DIR/rclone-onedrive.service.$DATE"
        sudo cp /etc/systemd/system/image-service.service "$BACKUP_DIR/image-service.service.$DATE"

        # Backup de configuración del servicio
        sudo cp /var/www/html/image-service/config/config.json "$BACKUP_DIR/config.json.$DATE"

        # Crear archivo de información del backup
        cat > "$BACKUP_DIR/backup_info.$DATE.txt" << EOF
Backup creado: $DATE
Servidor: $(hostname -f)
Usuario: $(whoami)

Archivos incluidos:
- rclone.conf
- rclone-onedrive.service
- image-service.service
- config.json

Para restaurar: $0 restore $DATE
EOF

        # Comprimir backup
        cd "$BACKUP_DIR"
        sudo tar -czf "rclone_backup_$DATE.tar.gz" \
            "rclone.conf.$DATE" \
            "rclone-onedrive.service.$DATE" \
            "image-service.service.$DATE" \
            "config.json.$DATE" \
            "backup_info.$DATE.txt"

        # Limpiar archivos individuales
        sudo rm "rclone.conf.$DATE" \
               "rclone-onedrive.service.$DATE" \
               "image-service.service.$DATE" \
               "config.json.$DATE" \
               "backup_info.$DATE.txt"

        log "✅ Backup completado: rclone_backup_$DATE.tar.gz"
        log "📁 Ubicación: $BACKUP_DIR"
        ;;

    "restore")
        if [ -z "$2" ]; then
            echo "Uso: $0 restore <fecha_backup>"
            echo "Backups disponibles:"
            ls -la "$BACKUP_DIR"/*.tar.gz | awk '{print $9}' | sed 's/.*backup_\(.*\)\.tar\.gz/\1/'
            exit 1
        fi

        BACKUP_DATE="$2"
        BACKUP_FILE="$BACKUP_DIR/rclone_backup_$BACKUP_DATE.tar.gz"

        if [ ! -f "$BACKUP_FILE" ]; then
            echo "❌ Backup no encontrado: $BACKUP_FILE"
            exit 1
        fi

        log "🔄 Restaurando backup: $BACKUP_DATE"

        # Detener servicios
        sudo systemctl stop rclone-onedrive.service image-service.service || true

        # Extraer backup
        cd "$BACKUP_DIR"
        sudo tar -xzf "$BACKUP_FILE"

        # Restaurar archivos
        sudo cp "rclone.conf.$BACKUP_DATE" /etc/rclone/rclone.conf
        sudo cp "rclone-onedrive.service.$BACKUP_DATE" /etc/systemd/system/rclone-onedrive.service
        sudo cp "image-service.service.$BACKUP_DATE" /etc/systemd/system/image-service.service
        sudo cp "config.json.$BACKUP_DATE" /var/www/html/image-service/config/config.json

        # Limpiar archivos extraídos
        sudo rm "rclone.conf.$BACKUP_DATE" \
               "rclone-onedrive.service.$BACKUP_DATE" \
               "image-service.service.$BACKUP_DATE" \
               "config.json.$BACKUP_DATE" \
               "backup_info.$BACKUP_DATE.txt"

        # Recargar systemd
        sudo systemctl daemon-reload

        # Reiniciar servicios
        sudo systemctl start rclone-onedrive.service
        sleep 5
        sudo systemctl start image-service.service

        log "✅ Restauración completada"
        ;;

    "list")
        echo "📋 Backups disponibles:"
        if [ -d "$BACKUP_DIR" ]; then
            ls -la "$BACKUP_DIR"/*.tar.gz 2>/dev/null | while read line; do
                if [[ $line == *backup_* ]]; then
                    filename=$(echo $line | awk '{print $9}')
                    date=$(echo $filename | sed 's/.*backup_\(.*\)\.tar\.gz/\1/')
                    size=$(echo $line | awk '{print $5}')
                    echo "  $date - $size bytes"
                fi
            done
        else
            echo "  No hay backups disponibles"
        fi
        ;;

    *)
        echo "Uso: $0 {backup|restore|list}"
        echo ""
        echo "Comandos:"
        echo "  backup  - Crear un nuevo backup"
        echo "  restore <fecha> - Restaurar backup específico"
        echo "  list    - Listar backups disponibles"
        exit 1
        ;;
esac</content>
<parameter name="filePath">d:\Onedrive Robert Personal\OneDrive\Documents\GitHub\UNIT3D-9.1.5\image-service\scripts\backup-rclone.sh
