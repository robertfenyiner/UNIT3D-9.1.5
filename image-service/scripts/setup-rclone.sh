#!/bin/bash

# Script para configurar rclone con OneDrive para UNIT3D Image Service
# Ejecutar como root: sudo bash setup-rclone.sh

set -e

echo "🚀 Configurando rclone con OneDrive para UNIT3D Image Service"

# Verificar si rclone está instalado
if ! command -v rclone &> /dev/null; then
    echo "📦 Instalando rclone..."
    curl https://rclone.org/install.sh | sudo bash
else
    echo "✅ rclone ya está instalado"
fi

# Verificar configuración existente
if rclone listremotes | grep -q "onedrive-images:"; then
    echo "✅ Configuración 'onedrive-images' ya existe"
else
    echo "⚙️ Configurando OneDrive..."
    echo ""
    echo "Sigue estas instrucciones:"
    echo "1. Nombre: onedrive-images"
    echo "2. Tipo: Microsoft OneDrive (opción 26 o similar)"
    echo "3. client_id: (deja en blanco - presiona Enter)"
    echo "4. client_secret: (deja en blanco - presiona Enter)" 
    echo "5. region: global"
    echo "6. Edit advanced config: No"
    echo "7. Use auto config: Yes (se abrirá el navegador para autenticar)"
    echo "8. Type of connection: onedrive"
    echo "9. Choose drive: 0 (OneDrive personal)"
    echo "10. Confirm: Yes"
    echo ""
    read -p "Presiona Enter para continuar con la configuración..."
    rclone config
fi

# Crear directorios necesarios
echo "📁 Creando directorios..."
sudo mkdir -p /var/www/html/storage/images
sudo mkdir -p /var/www/html/image-service/storage/temp
sudo mkdir -p /var/www/html/image-service/logs

# Establecer permisos
sudo chown -R www-data:www-data /var/www/html/storage/images
sudo chown -R www-data:www-data /var/www/html/image-service/storage
sudo chmod -R 755 /var/www/html/storage/images
sudo chmod -R 755 /var/www/html/image-service/storage

# Crear directorio en OneDrive
echo "📂 Creando directorio UNIT3D-Images en OneDrive..."
rclone mkdir onedrive-images:/UNIT3D-Images || echo "El directorio ya existe"

# Probar conexión
echo "🧪 Probando conexión con OneDrive..."
if rclone lsd onedrive-images: > /dev/null 2>&1; then
    echo "✅ Conexión con OneDrive exitosa"
else
    echo "❌ Error conectando con OneDrive"
    exit 1
fi

# Montar OneDrive
echo "💾 Montando OneDrive..."
if mountpoint -q /var/www/html/storage/images; then
    echo "⚠️ Ya hay algo montado en /var/www/html/storage/images"
    sudo umount /var/www/html/storage/images || true
fi

# Montar con opciones optimizadas
sudo rclone mount onedrive-images:/UNIT3D-Images /var/www/html/storage/images \
    --allow-other \
    --vfs-cache-mode writes \
    --vfs-write-back 5s \
    --daemon \
    --log-file /var/log/rclone-images.log \
    --log-level INFO

# Verificar mount
sleep 3
if mountpoint -q /var/www/html/storage/images; then
    echo "✅ OneDrive montado exitosamente en /var/www/html/storage/images"
else
    echo "❌ Error montando OneDrive"
    exit 1
fi

# Agregar a fstab para mount automático después de reinicio
FSTAB_LINE="onedrive-images:/UNIT3D-Images /var/www/html/storage/images rclone rw,allow_other,vfs-cache-mode=writes,vfs-write-back=5s,_netdev 0 0"
if ! grep -q "onedrive-images:/UNIT3D-Images" /etc/fstab; then
    echo "📝 Agregando mount automático a /etc/fstab..."
    echo "$FSTAB_LINE" | sudo tee -a /etc/fstab
else
    echo "✅ Mount automático ya configurado en /etc/fstab"
fi

# Crear archivo de prueba
echo "🧪 Probando escritura en OneDrive..."
echo "Test file created $(date)" | sudo tee /var/www/html/storage/images/test.txt
if [ -f "/var/www/html/storage/images/test.txt" ]; then
    echo "✅ Escritura en OneDrive exitosa"
    sudo rm /var/www/html/storage/images/test.txt
else
    echo "❌ Error escribiendo en OneDrive"
    exit 1
fi

echo ""
echo "🎉 ¡Configuración de rclone completada exitosamente!"
echo ""
echo "📊 Estado actual:"
echo "- Remote: onedrive-images"
echo "- Mount: /var/www/html/storage/images"
echo "- OneDrive Path: /UNIT3D-Images"
echo "- Auto-mount: Habilitado"
echo ""
echo "🔧 Comandos útiles:"
echo "- Ver archivos: ls -la /var/www/html/storage/images"
echo "- Ver logs: sudo tail -f /var/log/rclone-images.log"
echo "- Desmontar: sudo umount /var/www/html/storage/images"
echo "- Re-montar: sudo mount -a"
echo ""
echo "✨ Ahora puedes instalar el servicio de imágenes:"
echo "cd /var/www/html/image-service && npm install"