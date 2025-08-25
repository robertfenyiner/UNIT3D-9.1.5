#!/bin/bash

# Script de instalación para Telegram Notifier
# Autor: Tu Nombre
# Versión: 1.0

set -e

echo "🚀 Instalando Telegram Notifier..."

# Verificar que Node.js esté instalado
if ! command -v node &> /dev/null; then
    echo "❌ Node.js no está instalado. Por favor instala Node.js 14+ primero."
    exit 1
fi

# Verificar versión de Node.js
NODE_VERSION=$(node -v | sed 's/v//')
REQUIRED_VERSION="14.0.0"

if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$NODE_VERSION" | sort -V | head -n1)" = "$REQUIRED_VERSION" ]; then
    echo "✅ Node.js $NODE_VERSION detectado"
else
    echo "❌ Se requiere Node.js 14.0.0 o superior. Versión actual: $NODE_VERSION"
    exit 1
fi

# Instalar dependencias
echo "📦 Instalando dependencias..."
npm install

# Crear directorio de logs
echo "📁 Creando directorios necesarios..."
mkdir -p logs

# Crear archivo de configuración si no existe
if [ ! -f "config/config.json" ]; then
    echo "📝 Creando archivo de configuración..."
    cp config/config.example.json config/config.json
    echo "⚠️  IMPORTANTE: Edita config/config.json con tus datos de Telegram"
    echo "   - bot_token: Token de @BotFather"
    echo "   - chat_id: ID del canal/grupo"
    echo "   - base_url: URL de tu tracker"
fi

# Hacer ejecutables los scripts
chmod +x scripts/*.sh

echo ""
echo "✅ Instalación completada!"
echo ""
echo "📋 Próximos pasos:"
echo "   1. Editar config/config.json con tus datos"
echo "   2. Probar con: npm run dev"
echo "   3. Verificar salud: curl http://localhost:3001/health"
echo ""
echo "📚 Ver README.md para más instrucciones"