#!/bin/bash

# Script de monitoreo y mantenimiento para rclone mount
# Ejecutar cada 5 minutos via cron: */5 * * * * /path/to/monitor-rclone.sh

LOG_FILE="/var/log/rclone-monitor.log"
MOUNT_POINT="/var/www/html/storage/images"
REMOTE="imagenes:UNIT3D-Images"

# Función de logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" | tee -a "$LOG_FILE"
}

log "🔍 Iniciando monitoreo de rclone mount"

# Verificar si el mount está activo
if ! mountpoint -q "$MOUNT_POINT"; then
    log "❌ Mount point no está montado: $MOUNT_POINT"

    # Intentar desmontar por si acaso
    fusermount -uz "$MOUNT_POINT" 2>/dev/null || true

    # Remontar
    log "🔄 Remontando OneDrive..."
    rclone mount "$REMOTE" "$MOUNT_POINT" \
        --config=/etc/rclone/rclone.conf \
        --allow-other \
        --vfs-cache-mode writes \
        --vfs-write-back 5s \
        --uid=33 \
        --gid=33 \
        --log-file /var/log/rclone-images.log \
        --log-level INFO \
        --daemon

    sleep 3

    if mountpoint -q "$MOUNT_POINT"; then
        log "✅ Mount remontado exitosamente"
    else
        log "❌ Error remontando OneDrive"
    fi
else
    log "✅ Mount point activo: $MOUNT_POINT"
fi

# Verificar conectividad
if ! rclone lsd "$REMOTE" >/dev/null 2>&1; then
    log "❌ Error de conectividad con OneDrive"

    # Reiniciar el servicio systemd
    log "🔄 Reiniciando servicio rclone-onedrive..."
    sudo systemctl restart rclone-onedrive.service

    sleep 5

    if rclone lsd "$REMOTE" >/dev/null 2>&1; then
        log "✅ Conectividad restaurada"
    else
        log "❌ Error persistente de conectividad"
    fi
else
    log "✅ Conectividad con OneDrive OK"
fi

# Verificar permisos de escritura
TEST_FILE="$MOUNT_POINT/.rclone_test_$(date +%s)"
if echo "test" > "$TEST_FILE" 2>/dev/null; then
    rm "$TEST_FILE"
    log "✅ Permisos de escritura OK"
else
    log "❌ Error de permisos de escritura"
fi

# Verificar uso de espacio (opcional)
if command -v df >/dev/null 2>&1; then
    USAGE=$(df -h "$MOUNT_POINT" 2>/dev/null | tail -1 | awk '{print $5}')
    if [ -n "$USAGE" ]; then
        log "📊 Uso de espacio: $USAGE"
    fi
fi

log "🏁 Monitoreo completado"</content>
<parameter name="filePath">d:\Onedrive Robert Personal\OneDrive\Documents\GitHub\UNIT3D-9.1.5\image-service\scripts\monitor-rclone.sh
