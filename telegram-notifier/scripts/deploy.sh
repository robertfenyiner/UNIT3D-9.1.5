#!/bin/bash

# Script completo de deployment para servidor Linux
# Ejecutar como: sudo bash deploy.sh

set -e

echo "🚀 Deploying Telegram Notifier en producción..."

# Verificar que somos root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Este script debe ejecutarse como root (usa sudo)"
    exit 1
fi

# Obtener directorio actual
CURRENT_DIR=$(pwd)
echo "📍 Directorio de trabajo: $CURRENT_DIR"

# Verificar que estamos en el directorio correcto
if [ ! -f "app.js" ] || [ ! -f "package.json" ]; then
    echo "❌ Error: No estás en el directorio de telegram-notifier"
    echo "   Ejecuta: cd /var/www/html/telegram-notifier"
    exit 1
fi

# Verificar Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js no está instalado"
    echo "   Instala Node.js 14+ primero"
    exit 1
fi

NODE_PATH=$(which node)
echo "✅ Node.js encontrado: $NODE_PATH"

# Verificar configuración
echo "🔧 Verificando configuración..."
if ! node scripts/configure.js > /dev/null 2>&1; then
    echo "❌ Error en configuración. Ejecuta: node scripts/configure.js"
    exit 1
fi
echo "✅ Configuración válida"

# Instalar dependencias si es necesario
if [ ! -d "node_modules" ]; then
    echo "📦 Instalando dependencias..."
    npm install
fi

# Crear directorio de logs
mkdir -p logs

# Configurar permisos
echo "🔒 Configurando permisos..."
chown -R www-data:www-data .
chmod +x scripts/*.sh
chmod +x app.js

# Crear archivo de servicio systemd
SERVICE_FILE="/etc/systemd/system/telegram-notifier.service"
echo "📝 Creando servicio systemd..."

cat > $SERVICE_FILE << EOF
[Unit]
Description=Telegram Notifier for UNIT3D
Documentation=file://$CURRENT_DIR/README.md
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=$CURRENT_DIR
Environment=NODE_ENV=production
ExecStart=$NODE_PATH app.js
Restart=on-failure
RestartSec=10
KillMode=mixed
KillSignal=SIGINT
TimeoutStopSec=5
SyslogIdentifier=telegram-notifier

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

# Recargar systemd
echo "♻️ Recargando systemd..."
systemctl daemon-reload

# Habilitar servicio
echo "✅ Habilitando servicio..."
systemctl enable telegram-notifier

# Parar servicio si ya está corriendo
if systemctl is-active --quiet telegram-notifier; then
    echo "⏹️ Parando servicio existente..."
    systemctl stop telegram-notifier
fi

# Iniciar servicio
echo "🚀 Iniciando servicio..."
systemctl start telegram-notifier

# Verificar estado
sleep 2
if systemctl is-active --quiet telegram-notifier; then
    echo "✅ Servicio iniciado exitosamente"
    
    # Mostrar estado
    systemctl status telegram-notifier --no-pager -l
    
    echo ""
    echo "🎉 ¡Deployment completado!"
    echo ""
    echo "📋 Comandos útiles:"
    echo "   systemctl status telegram-notifier     # Ver estado"
    echo "   journalctl -u telegram-notifier -f     # Ver logs"
    echo "   systemctl restart telegram-notifier    # Reiniciar"
    echo ""
    echo "🧪 Probar funcionamiento:"
    echo "   curl http://localhost:3001/health"
    echo "   curl -X POST http://localhost:3001/test-telegram"
    
else
    echo "❌ Error iniciando servicio"
    echo "Ver logs: journalctl -u telegram-notifier -n 20"
    exit 1
fi