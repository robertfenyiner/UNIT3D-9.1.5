#!/bin/bash

# Script para iniciar Telegram Notifier
# Uso: ./start.sh [dev|prod]

MODE=${1:-prod}

echo "🚀 Iniciando Telegram Notifier en modo: $MODE"

# Verificar que existe la configuración
if [ ! -f "config/config.json" ]; then
    echo "❌ Error: No existe config/config.json"
    echo "   Copia config/config.example.json y configúralo"
    exit 1
fi

# Crear directorio de logs si no existe
mkdir -p logs

# Verificar dependencias
if [ ! -d "node_modules" ]; then
    echo "📦 Instalando dependencias..."
    npm install
fi

# Iniciar según el modo
case $MODE in
    "dev")
        echo "🔧 Modo desarrollo - Recarga automática activada"
        npm run dev
        ;;
    "prod")
        echo "🏭 Modo producción"
        npm start
        ;;
    *)
        echo "❌ Modo inválido: $MODE"
        echo "   Usa: ./start.sh [dev|prod]"
        exit 1
        ;;
esac