#!/bin/bash

# Script para configurar el servicio systemd
# Debe ejecutarse como root o con sudo

set -e

if [ "$EUID" -ne 0 ]; then
    echo "❌ Este script debe ejecutarse como root"
    echo "   Usa: sudo ./setup-service.sh"
    exit 1
fi

CURRENT_DIR=$(pwd)
SERVICE_NAME="telegram-notifier"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"
USER_NAME=${1:-www-data}

echo "🔧 Configurando servicio systemd para Telegram Notifier..."

# Verificar que Node.js esté instalado
if ! command -v node &> /dev/null; then
    echo "❌ Node.js no está instalado"
    exit 1
fi

NODE_PATH=$(which node)
echo "✅ Node.js encontrado en: $NODE_PATH"

# Crear archivo de servicio
echo "📝 Creando archivo de servicio..."
cat > $SERVICE_FILE << EOF
[Unit]
Description=Telegram Notifier for UNIT3D
Documentation=file://$CURRENT_DIR/README.md
After=network.target

[Service]
Type=simple
User=$USER_NAME
WorkingDirectory=$CURRENT_DIR
Environment=NODE_ENV=production
ExecStart=$NODE_PATH app.js
Restart=on-failure
RestartSec=10
KillMode=mixed
KillSignal=SIGINT
TimeoutStopSec=5
SyslogIdentifier=$SERVICE_NAME

# Logging
StandardOutput=journal
StandardError=journal

# Security
NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=$CURRENT_DIR/logs

[Install]
WantedBy=multi-user.target
EOF

# Asegurar permisos correctos
echo "🔒 Configurando permisos..."
chown -R $USER_NAME:$USER_NAME $CURRENT_DIR
chmod +x $CURRENT_DIR/app.js

# Recargar systemd
echo "♻️ Recargando systemd..."
systemctl daemon-reload

# Habilitar el servicio
echo "✅ Habilitando servicio..."
systemctl enable $SERVICE_NAME

echo ""
echo "✅ Servicio configurado exitosamente!"
echo ""
echo "📋 Comandos útiles:"
echo "   sudo systemctl start $SERVICE_NAME    # Iniciar servicio"
echo "   sudo systemctl stop $SERVICE_NAME     # Detener servicio"
echo "   sudo systemctl restart $SERVICE_NAME  # Reiniciar servicio"
echo "   sudo systemctl status $SERVICE_NAME   # Ver estado"
echo "   journalctl -u $SERVICE_NAME -f        # Ver logs en tiempo real"
echo ""
echo "⚠️  Recuerda configurar config/config.json antes de iniciar"