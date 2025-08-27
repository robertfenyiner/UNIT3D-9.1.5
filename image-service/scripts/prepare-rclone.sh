#!/bin/bash

# Script para preparar y verificar la configuración de rclone
# antes de ejecu# Verificar contenido de la configuración# Probar configuración
echo ""
echo # Probar conexión con OneDrive
echo ""
echo "7. Probando conexión con OneDrive..."
if rclone lsd imagenes: >/dev/null 2>&1; then
    echo "✅ Conexión con OneDrive exitosa"
else
    echo "❌ Error conectando con OneDrive"
    echo ""
    echo "Posibles causas:"
    echo "1. Token expirado - necesitas reautenticar"
    echo "2. Problemas de red"
    echo "3. Configuración incorrecta"
    echo ""
    echo "Para reautenticar:"
    echo "   rclone config reconnect imagenes:"
    echo ""
    echo "Para ver detalles del error:"
    echo "   rclone lsd imagenes:"
    exit 1
firación de rclone..."
if ! rclone listremotes | grep -q "imagenes:"; then
    echo "❌ Error: rclone no puede leer la configuración"
    echo ""
    echo "Posibles soluciones:"
    echo "1. Verifica que el archivo esté en /etc/rclone/rclone.conf"
    echo "2. Verifica que la sintaxis del archivo sea correcta"
    echo "3. Verifica que tengas permisos para leer el archivo"
    echo ""
    echo "Contenido actual del archivo:"
    echo "---"
    cat /etc/rclone/rclone.conf
    echo "---"
    exit 1
else
    echo "✅ Configuración de rclone válida"
fierificando contenido de la configuración..."
if ! grep -q "\[imagenes\]" /etc/rclone/rclone.conf; then
    echo "❌ No se encontró la sección [imagenes] en rclone.conf"
    echo ""
    echo "El archivo debe contener algo como:"
    echo "[imagenes]"
    echo "type = onedrive"
    echo "client_id ="
    echo "client_secret ="
    echo "region = global"
    echo "token = {\"access_token\":\"...\"}"
    echo ""
    echo "Tu configuración actual:"
    echo "---"
    cat /etc/rclone/rclone.conf
    echo "---"
    exit 1
else
    echo "✅ Sección [imagenes] encontrada"
fish

set -e

echo "🔍 Verificación previa para configuración de rclone"
echo "Servidor: $(hostname -f)"
echo "Fecha: $(date)"
echo ""

# Función para verificar si un comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 1. Verificar instalación de rclone
echo "1. Verificando instalación de rclone..."
if ! command_exists rclone; then
    echo "❌ rclone no está instalado."
    echo ""
    echo "📦 Instalando rclone..."
    curl https://rclone.org/install.sh | sudo bash

    if command_exists rclone; then
        echo "✅ rclone instalado correctamente"
    else
        echo "❌ Error instalando rclone"
        exit 1
    fi
else
    echo "✅ rclone está instalado"
fi

# 2. Crear directorio de configuración si no existe
echo ""
echo "2. Preparando directorio de configuración..."
sudo mkdir -p /etc/rclone

# 3. Verificar archivo de configuración
echo ""
echo "3. Verificando archivo de configuración..."

if [ ! -f "/etc/rclone/rclone.conf" ]; then
    echo "❌ No se encontró /etc/rclone/rclone.conf"
    echo ""
    echo "📋 Instrucciones para configurar rclone.conf:"
    echo ""
    echo "Opción A - Configurar automáticamente:"
    echo "   rclone config"
    echo "   - Nombre: imagenes"
    echo "   - Tipo: Microsoft OneDrive (opción 26)"
    echo "   - client_id: (presiona Enter)"
    echo "   - client_secret: (presiona Enter)"
    echo "   - region: global"
    echo "   - Edit advanced config: No"
    echo "   - Use auto config: Yes"
    echo "   - Choose drive: 0"
    echo "   - Confirm: Yes"
    echo ""
    echo "Opción B - Copiar configuración existente:"
    echo "   sudo cp /ruta/a/tu/rclone.conf /etc/rclone/rclone.conf"
    echo "   sudo chown root:root /etc/rclone/rclone.conf"
    echo "   sudo chmod 600 /etc/rclone/rclone.conf"
    echo ""
    read -p "¿Ya tienes el archivo rclone.conf listo? (s/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        echo "Por favor prepara el archivo rclone.conf y vuelve a ejecutar este script."
        exit 1
    fi
else
    echo "✅ Archivo /etc/rclone/rclone.conf encontrado"
fi

# 4. Verificar permisos del archivo
echo ""
echo "4. Verificando permisos del archivo..."
CONFIG_PERMS=$(stat -c "%a" /etc/rclone/rclone.conf 2>/dev/null || echo "no-file")
CONFIG_OWNER=$(stat -c "%U:%G" /etc/rclone/rclone.conf 2>/dev/null || echo "no-file")

if [ "$CONFIG_PERMS" != "600" ] || [ "$CONFIG_OWNER" != "root:root" ]; then
    echo "🔧 Ajustando permisos del archivo de configuración..."
    sudo chown root:root /etc/rclone/rclone.conf
    sudo chmod 600 /etc/rclone/rclone.conf
    echo "✅ Permisos ajustados"
else
    echo "✅ Permisos correctos"
fi

# 5. Verificar contenido de la configuración
echo ""
echo "5. Verificando contenido de la configuración..."
if ! grep -q "\[imagenes\]" /etc/rclone/rclone.conf; then
    echo "❌ No se encontró la sección [imagenes] en rclone.conf"
    echo ""
    echo "El archivo debe contener algo como:"
    echo "[imagenes]"
    echo "type = onedrive"
    echo "client_id ="
    echo "client_secret ="
    echo "region = global"
    echo "token = {\"access_token\":\"...\"}"
    echo ""
    echo "Tu configuración actual:"
    echo "---"
    cat /etc/rclone/rclone.conf
    echo "---"
    exit 1
else
    echo "✅ Sección [imagenes] encontrada"
fi

# 6. Probar configuración
echo ""
echo "6. Probando configuración de rclone..."
if ! rclone listremotes | grep -q "imagenes:"; then
    echo "❌ Error: rclone no puede leer la configuración"
    echo ""
    echo "Posibles soluciones:"
    echo "1. Verifica que el archivo esté en /etc/rclone/rclone.conf"
    echo "2. Verifica que la sintaxis del archivo sea correcta"
    echo "3. Verifica que tengas permisos para leer el archivo"
    echo ""
    echo "Contenido actual del archivo:"
    echo "---"
    cat /etc/rclone/rclone.conf
    echo "---"
    exit 1
else
    echo "✅ Configuración de rclone válida"
fi

# 7. Probar conexión con OneDrive
echo ""
echo "7. Probando conexión con OneDrive..."
if rclone lsd imagenes: >/dev/null 2>&1; then
    echo "✅ Conexión con OneDrive exitosa"
else
    echo "❌ Error conectando con OneDrive"
    echo ""
    echo "Posibles causas:"
    echo "1. Token expirado - necesitas reautenticar"
    echo "2. Problemas de red"
    echo "3. Configuración incorrecta"
    echo ""
    echo "Para reautenticar:"
    echo "   rclone config reconnect imagenes:"
    echo ""
    echo "Para ver detalles del error:"
    echo "   rclone lsd imagenes:"
    exit 1
fi

# 8. Verificar FUSE
echo ""
echo "8. Verificando configuración de FUSE..."
if ! grep -q "user_allow_other" /etc/fuse.conf 2>/dev/null; then
    echo "⚠️ FUSE no está configurado para permitir mounts de usuario"
    echo "   Esto se configurará automáticamente en el setup"
else
    echo "✅ FUSE configurado correctamente"
fi

echo ""
echo "🎉 ¡Todo está listo para ejecutar setup-complete.sh!"
echo ""
echo "📋 Resumen de verificación:"
echo "✅ rclone instalado"
echo "✅ Archivo de configuración presente"
echo "✅ Permisos correctos"
echo "✅ Configuración válida"
echo "✅ Conexión con OneDrive exitosa"
echo ""
echo "🚀 Ahora puedes ejecutar:"
echo "   sudo bash scripts/setup-complete.sh"
echo ""
echo "✨ Verificación completada"</content>
<parameter name="filePath">d:\Onedrive Robert Personal\OneDrive\Documents\GitHub\UNIT3D-9.1.5\image-service\scripts\prepare-rclone.sh
