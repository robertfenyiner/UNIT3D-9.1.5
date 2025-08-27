# 🐧 INSTALACIÓN UBUNTU - UNIT3D Image Service

## 📋 PASOS DE INSTALACIÓN COMPLETA

Sigue estos pasos **en orden** en tu servidor Ubuntu:

### 📥 PASO 0: Preparación

1. **Subir archivos al servidor:**
   ```bash
   # Opción A: Clonar desde el repositorio UNIT3D
   cd /path/to/unit3d/
   
   # Opción B: Copiar la carpeta image-service a tu servidor
   scp -r image-service/ usuario@servidor:/home/usuario/
   ```

2. **Navegar al directorio:**
   ```bash
   cd image-service/
   ```

### 🔍 PASO 1: Verificar Sistema

```bash
# Hacer ejecutable y correr verificación
chmod +x setup-ubuntu-step1.sh
./setup-ubuntu-step1.sh
```

**Qué hace:**
- Verifica Ubuntu/Linux
- Chequea Node.js >= 16.0
- Verifica herramientas necesarias
- Revisa permisos y espacio

**Si Node.js falta:**
```bash
# Instalar Node.js 18 LTS
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Instalar herramientas adicionales
sudo apt update
sudo apt install -y curl wget git unzip python3 build-essential
```

### 🚀 PASO 2: Instalación Base

```bash
# Ejecutar instalación
./setup-ubuntu-step2.sh
```

**Qué hace:**
- Instala dependencias npm
- Crea directorios necesarios
- Configura permisos
- Crea configuración de desarrollo
- Genera scripts de inicio

**Resultado:** Servidor listo para modo desarrollo

### ☁️ PASO 3: Configurar OneDrive (OPCIONAL)

```bash
# Solo si quieres usar OneDrive
./setup-ubuntu-step3.sh
```

**Qué hace:**
- Instala rclone
- Configura OneDrive interactivamente
- Crea scripts de montaje
- Configura almacenamiento en nube

**Nota:** Necesitarás navegador web para autorizar OneDrive

### ⚙️ PASO 4: Configuración Final

```bash
# Configuración completa (desarrollo + producción)
./setup-ubuntu-step4.sh
```

**Qué hace:**
- Configura servicio systemd (opcional)
- Crea scripts de gestión
- Configura logs y monitoreo
- Genera documentación

## 🎯 COMANDOS DE USO

Una vez instalado, usa estos comandos:

### Desarrollo Rápido
```bash
# Iniciar servidor de desarrollo
./start-dev.sh

# En otra terminal, probar
./test-quick.sh

# Ver estado
./status.sh
```

### Producción Completa
```bash
# Si configuraste systemd
./start-production.sh

# Si configuraste OneDrive, montarlo primero
./mount-onedrive.sh

# Probar todo
./test-full.sh
```

## 🌐 ACCESO WEB

Una vez iniciado:
- **Interfaz web**: http://tu-servidor:3002
- **Health check**: http://tu-servidor:3002/health
- **API**: http://tu-servidor:3002/upload

## 🔗 INTEGRACIÓN CON UNIT3D

El servicio **YA ESTÁ INTEGRADO** con UNIT3D:

1. ✅ Archivo `create.blade.php` modificado
2. ✅ Script `unit3d-uploader.js` creado  
3. ✅ API compatible con imgbb

**Solo necesitas:**
1. Iniciar el servicio de imágenes
2. Usar UNIT3D normalmente - las imágenes se subirán a tu servicio

## 🚨 SOLUCIÓN DE PROBLEMAS

### Error: "Dependencias no instaladas"
```bash
npm install --no-optional
```

### Error: "Puerto 3002 en uso"
```bash
# Ver qué usa el puerto
sudo netstat -tulpn | grep 3002

# Cambiar puerto en config/config.dev.json
nano config/config.dev.json
```

### Error: "Permisos"
```bash
# Arreglar permisos básicos
chmod -R 755 storage/
sudo chown -R www-data:www-data /var/www/html/storage
```

### Error: "OneDrive no monta"
```bash
# Reconfigurar rclone
rclone config

# Verificar conexión
rclone ls onedrive-images:
```

## 📞 VERIFICACIÓN RÁPIDA

Para verificar que todo funcione:

```bash
# 1. Verificar instalación
./status.sh

# 2. Probar conectividad
curl http://localhost:3002/health

# 3. Abrir interfaz web
firefox http://localhost:3002 &
```

## ✅ LISTA DE VERIFICACIÓN

- [ ] Node.js >= 16.0 instalado
- [ ] Scripts ejecutables (`chmod +x *.sh`)
- [ ] Puerto 3002 disponible
- [ ] Servidor iniciado sin errores
- [ ] Health check responde OK
- [ ] Interfaz web carga correctamente
- [ ] OneDrive montado (si aplica)
- [ ] UNIT3D puede subir imágenes

---

## 🎉 ¡LISTO!

Tu servicio de imágenes personalizado está funcionando y reemplazando imgbb.com en UNIT3D.

**¡Disfruta de tu propio sistema de gestión de imágenes!** 🖼️