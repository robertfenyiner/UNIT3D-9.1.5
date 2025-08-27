# Lat-team Image Service - Instalación Completa

## Descripción
Servicio de imágenes para Lat-team que sube automáticamente las imágenes a OneDrive usando rclone. Incluye procesamiento de imágenes, montaje FUSE, y servicios systemd para funcionamiento automático.

## Características
- ✅ **Instalación desde cero**: Script completo que incluye limpieza de instalaciones previas
- ✅ **Integración OneDrive**: Subida automática de imágenes usando rclone
- ✅ **Procesamiento de imágenes**: Optimización y redimensionamiento con Sharp
- ✅ **Montaje FUSE**: Acceso transparente al sistema de archivos
- ✅ **Servicios systemd**: Inicio automático y gestión de servicios
- ✅ **Monitoreo continuo**: Scripts de verificación y recuperación automática
- ✅ **Backup y recuperación**: Sistema completo de respaldo

## Requisitos Previos

### 1. Configuración de rclone
Debes tener rclone configurado con tu cuenta de OneDrive:

```bash
# Instalar rclone (si no está instalado)
curl https://rclone.org/install.sh | sudo bash

# Configurar rclone
rclone config
```

Durante la configuración:
- Nombre del remote: `imagenes`
- Tipo: Microsoft OneDrive (opción 26)
- Sigue las instrucciones para autenticar con tu cuenta Microsoft

### 2. Sistema operativo
- Ubuntu/Debian 18.04 o superior
- Acceso root/sudo

## Instalación Automática

### Opción 1: Instalación Completa (Recomendada)
Esta opción incluye limpieza completa de instalaciones previas y configuración desde cero:

```bash
# Opción A: Desde el directorio del proyecto (recomendado)
cd /path/to/your/image-service
chmod +x scripts/install-complete.sh
sudo bash scripts/install-complete.sh

# Opción B: Instalador portable (desde cualquier ubicación)
cd /path/to/your/image-service/scripts
chmod +x install-portable.sh
sudo bash install-portable.sh
```

### Opción 2: Instalación Manual
Si prefieres instalar manualmente:

```bash
# 1. Instalar dependencias del sistema
sudo apt update
sudo apt install -y nodejs npm curl fuse

# 2. Instalar dependencias del proyecto
npm install

# 3. Configurar FUSE
echo "user_allow_other" | sudo tee -a /etc/fuse.conf

# 4. Crear directorios
sudo mkdir -p /var/www/html/storage/images/thumbs
sudo mkdir -p /var/www/html/image-service/storage/temp
sudo mkdir -p /var/www/html/image-service/logs

# 5. Establecer permisos
sudo chown -R www-data:www-data /var/www/html/storage
sudo chown -R www-data:www-data /var/www/html/image-service

# 6. Copiar archivos de configuración systemd
sudo cp systemd/rclone-onedrive.service /etc/systemd/system/
sudo cp systemd/image-service.service /etc/systemd/system/

# 7. Recargar systemd y habilitar servicios
sudo systemctl daemon-reload
sudo systemctl enable rclone-onedrive.service image-service.service

# 8. Crear directorio en OneDrive
rclone mkdir imagenes:/Lat-team-Images

# 9. Iniciar servicios
sudo systemctl start rclone-onedrive.service
sudo systemctl start image-service.service
```

## Verificación de Instalación

Después de la instalación, ejecuta el script de verificación incluido:

```bash
# Verificar que todo esté funcionando correctamente
sudo bash scripts/verify-installation.sh
```

Este script verifica:
- ✅ Conectividad a internet
- ✅ Configuración de rclone
- ✅ Archivos del proyecto
- ✅ Permisos de directorios
- ✅ Servicios systemd
- ✅ Montaje rclone/OneDrive
- ✅ Servicio web
- ✅ Logs del sistema

## Scripts Incluidos

El proyecto incluye varios scripts para facilitar la gestión:

- `scripts/install-complete.sh`: **Instalación completa desde cero** (incluye limpieza)
- `scripts/verify-installation.sh`: **Verificación completa del sistema**
- `scripts/monitor-rclone.sh`: Monitoreo continuo del servicio rclone
- `scripts/backup-rclone.sh`: Backup de configuración de rclone
- `scripts/check-service.sh`: Verificación general del servicio
- `scripts/recovery-rclone.sh`: Recuperación automática de fallos

## Uso del Servicio

### Endpoints API
- **Health Check**: `GET /health`
- **Upload de imagen**: `POST /upload`
- **Ver imagen**: `GET /image/:filename`
- **Administrar imágenes**: `GET /manage`

### Ejemplo de uso con curl
```bash
# Subir una imagen
curl -X POST -F "image=@/path/to/your/image.jpg" http://216.9.226.186:3002/upload

# Ver una imagen
curl http://216.9.226.186:3002/image/imagen-procesada.jpg
```

## Configuración

### Variables de entorno
El servicio utiliza las siguientes variables de entorno (configurables en `config/config.json`):

- `PORT`: Puerto del servicio (por defecto: 3002)
- `NODE_ENV`: Entorno de ejecución (development/production)
- `UPLOAD_DIR`: Directorio de subida de imágenes
- `THUMB_DIR`: Directorio de miniaturas

### Configuración de rclone
El servicio está configurado para usar el remote `imagenes` de rclone. Si tienes un nombre diferente, actualiza:

1. Los archivos de configuración systemd
2. Los scripts de monitoreo
3. El archivo `config/config.json`

## Monitoreo y Mantenimiento

### Scripts incluidos
- `scripts/monitor-rclone.sh`: Monitoreo continuo del servicio rclone
- `scripts/backup-rclone.sh`: Backup de configuración de rclone
- `scripts/check-service.sh`: Verificación general del servicio
- `scripts/recovery-rclone.sh`: Recuperación automática de fallos

### Comandos útiles
```bash
# Ver logs del servicio
sudo journalctl -u image-service.service -f

# Ver logs de rclone
sudo journalctl -u rclone-onedrive.service -f
tail -f /var/log/rclone-images.log

# Reiniciar servicios
sudo systemctl restart rclone-onedrive.service
sudo systemctl restart image-service.service

# Ver archivos en OneDrive
rclone lsd imagenes:Lat-team-Images

# Verificar montaje
mount | grep rclone
```

## Solución de Problemas

### Servicio no inicia
```bash
# Ver logs detallados
sudo journalctl -u image-service.service -n 50

# Verificar dependencias
sudo systemctl list-dependencies image-service.service
```

### Problemas con rclone
```bash
# Verificar configuración
rclone listremotes
rclone lsd imagenes:

# Probar montaje manual
sudo rclone mount imagenes:Lat-team-Images /mnt/test --daemon
```

### Problemas de permisos
```bash
# Verificar permisos
ls -la /var/www/html/storage/
ls -la /var/www/html/image-service/

# Corregir permisos
sudo chown -R www-data:www-data /var/www/html/storage
sudo chown -R www-data:www-data /var/www/html/image-service
```

### Problemas de eliminación durante la instalación
Si encuentras errores como "Directory not empty" durante la instalación:

```bash
# Ejecutar limpieza manual
sudo bash scripts/cleanup-manual.sh

# Después ejecutar la instalación nuevamente
sudo bash scripts/install-complete.sh
```

### Error: "command_exists: command not found"
Este error ocurre cuando el script se ejecuta desde una ubicación incorrecta. Usa el instalador portable:

```bash
# Desde el directorio scripts del proyecto
sudo bash scripts/install-portable.sh
```

### Error: "No se encontraron los archivos del proyecto"
Asegúrate de ejecutar el script desde el directorio correcto o usa el instalador portable que detecta automáticamente la ubicación de los archivos.

## Backup y Recuperación

### Backup automático
El sistema incluye scripts para backup automático de:
- Configuración de rclone
- Archivos de configuración del servicio
- Logs importantes

### Recuperación de desastres
En caso de fallo completo:
1. Ejecuta la instalación completa nuevamente
2. Restaura la configuración de rclone desde backup
3. Verifica la integridad de los archivos en OneDrive

## Información del Servicio

Después de la instalación exitosa, tendrás:
- **URL del servicio**: http://216.9.226.186:3002/
- **Directorio de imágenes**: `/var/www/html/storage/images`
- **Logs del servicio**: `/var/www/html/image-service/logs/`
- **Logs de rclone**: `/var/log/rclone-images.log`

## Soporte

Si encuentras problemas:
1. Revisa los logs del servicio
2. Verifica la configuración de rclone
3. Ejecuta los scripts de verificación incluidos
4. Revisa la documentación de troubleshooting arriba

---

**Nota**: Este servicio está diseñado específicamente para Lat-team y asume una configuración específica de rclone con el remote llamado `imagenes`. Si tienes una configuración diferente, adapta los scripts correspondientes.</content>
<parameter name="filePath">d:\Onedrive Robert Personal\OneDrive\Documents\GitHub\UNIT3D-9.1.5\image-service\README-INSTALL.md
