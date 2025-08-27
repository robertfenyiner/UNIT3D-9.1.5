# 🖼️ UNIT3D Image Service

Sistema de gestión de imágenes personalizado para reemplazar imgbb.com en UNIT3D Community Edition. 

Utiliza almacenamiento en la nube (OneDrive) mediante rclone y proporciona una API compatible con imgbb para una integración transparente.

## ✨ Características

- **🔄 Reemplazo directo de imgbb.js** - Compatible con la API existente
- **☁️ Almacenamiento en OneDrive** - Via rclone mount para escalabilidad
- **🖼️ Procesamiento de imágenes** - Redimensionado, compresión y thumbnails automáticos
- **🚀 Frontend moderno** - Interfaz drag & drop con vista previa
- **🔒 Seguro** - Rate limiting, validación de archivos y headers de seguridad
- **📊 Monitoreo** - Logs detallados y endpoint de health check
- **⚙️ Configurable** - Configuración flexible por archivo JSON

## 📁 Estructura del Proyecto

```
image-service/
├── app.js                 # Servidor principal Express
├── config/
│   ├── config.json        # Configuración de producción
│   └── config.dev.json    # Configuración de desarrollo
├── routes/
│   ├── upload.js          # API de subida de imágenes
│   ├── images.js          # Servir imágenes estáticas
│   ├── manage.js          # Panel de gestión y estadísticas
│   └── health.js          # Health check
├── services/
│   ├── imageProcessor.js  # Procesamiento con Sharp
│   └── logger.js          # Sistema de logging
├── middleware/
│   ├── rateLimit.js       # Limitación de requests
│   └── upload.js          # Configuración Multer
├── public/
│   └── uploader.html      # Interfaz web standalone
├── scripts/
│   ├── install.sh         # Script de instalación Linux
│   ├── setup-rclone.sh    # Configuración OneDrive
│   └── test-service.sh    # Pruebas del sistema
└── storage/
    ├── images/            # Imágenes montadas de OneDrive
    └── temp/              # Archivos temporales
```

## 🚀 Instalación Rápida (Windows - Desarrollo)

1. **Clonar e instalar dependencias:**
   ```bash
   cd image-service
   npm install
   ```

2. **Ejecutar en modo desarrollo:**
   ```bash
   # Opción 1: Batch script
   debug-windows.bat
   
   # Opción 2: Node directamente
   node app.js
   ```

3. **Abrir interfaz web:**
   ```
   http://localhost:3002
   ```

## 🐧 Instalación Producción (Linux)

1. **Ejecutar script de instalación:**
   ```bash
   sudo bash scripts/install.sh
   ```

2. **Configurar OneDrive:**
   ```bash
   sudo bash scripts/setup-rclone.sh
   ```

3. **Iniciar servicio:**
   ```bash
   sudo systemctl start image-service
   sudo systemctl enable image-service
   ```

4. **Verificar funcionamiento:**
   ```bash
   bash scripts/test-service.sh
   ```

## ⚙️ Configuración

### Desarrollo (config.dev.json)
```json
{
  "server": {
    "port": 3002,
    "host": "localhost"
  },
  "storage": {
    "path": "./storage/images",
    "tempPath": "./storage/temp",
    "publicUrl": "http://localhost:3002/image"
  },
  "security": {
    "allowedOrigins": ["http://localhost", "http://127.0.0.1"]
  }
}
```

### Producción (config.json)
```json
{
  "server": {
    "port": 3002,
    "host": "localhost"
  },
  "storage": {
    "path": "/var/www/html/storage/images",
    "publicUrl": "https://tu-dominio.com/img",
    "rclone": {
      "remote": "onedrive-images",
      "path": "UNIT3D-Images"
    }
  },
  "security": {
    "allowedOrigins": ["https://tu-dominio.com"]
  }
}
```

## 🔗 Integración con UNIT3D

El sistema reemplaza automáticamente imgbb.js en UNIT3D:

1. **Archivo modificado:**
   ```php
   resources/views/torrent/create.blade.php
   ```

2. **Cambio realizado:**
   ```php
   <!-- Antes -->
   <script src="{{ asset('build/unit3d/imgbb.js') }}"></script>
   
   <!-- Después -->
   <script src="{{ asset('js/vendor/unit3d-uploader.js') }}"></script>
   ```

3. **JavaScript personalizado:**
   ```javascript
   // resources/js/vendor/unit3d-uploader.js
   var UNIT3DUploader = {
     defaultSettings: {
       url: 'http://localhost:3002'  // Tu servidor de imágenes
     }
   };
   ```

## 📊 API Endpoints

### POST /upload
Subida de múltiples imágenes (compatible con imgbb)

**Request:**
```javascript
FormData: {
  images: [File, File, ...] // Múltiples archivos
}
```

**Response:**
```json
{
  "success": true,
  "data": [{
    "file": {
      "original": "imagen.jpg",
      "filename": "abc123.jpg",
      "size": 1024000
    },
    "urls": {
      "image": "http://localhost:3002/image/abc123.jpg",
      "thumbnail": "http://localhost:3002/image/thumbs/abc123.jpg",
      "bbcode": "[img]http://localhost:3002/image/abc123.jpg[/img]",
      "bbcode_full": "[img=350]http://localhost:3002/image/abc123.jpg[/img]"
    }
  }]
}
```

### POST /upload/url
Subida desde URL

**Request:**
```json
{
  "url": "https://ejemplo.com/imagen.jpg"
}
```

### GET /image/:filename
Servir imagen estática

### GET /health
Health check del servicio

## 🧪 Pruebas y Depuración

### Prueba completa del sistema:
```bash
node test-complete.js
```

### Prueba de integración:
```bash
node test-integration.js
```

### Verificar logs:
```bash
# Development
tail -f logs/image-service.log

# Production (systemd)
journalctl -u image-service -f
```

## 🔧 Comandos Útiles

```bash
# Modo desarrollo
NODE_ENV=development node app.js

# Modo producción
NODE_ENV=production node app.js

# Prueba rápida del servicio
curl http://localhost:3002/health

# Verificar OneDrive mount
mountpoint /var/www/html/storage/images

# Reiniciar servicio (Linux)
sudo systemctl restart image-service
```

## 📈 Características Técnicas

- **Framework:** Express.js + Node.js
- **Procesamiento:** Sharp (imagen), Multer (uploads)
- **Seguridad:** Helmet, CORS, Rate Limiting
- **Storage:** OneDrive via rclone mount
- **Logging:** Winston con rotación automática
- **Monitoring:** Health checks y métricas

## 🚨 Solución de Problemas

### Error: Puerto 3002 en uso
```bash
# Encontrar proceso usando el puerto
netstat -ano | findstr :3002  # Windows
lsof -i :3002                 # Linux

# Cambiar puerto en config
"port": 3003
```

### Error: Directorio storage no existe
```bash
mkdir -p storage/images storage/temp
```

### Error: OneDrive no montado
```bash
sudo bash scripts/setup-rclone.sh
```

### Error: Permisos de archivo
```bash
sudo chown -R www-data:www-data /var/www/html/storage
sudo chmod -R 755 /var/www/html/storage
```

## 📋 Estado del Proyecto

✅ **COMPLETADO** - Sistema funcional y listo para producción

### Implementado:
- ✅ Servidor Express con todas las rutas
- ✅ Procesamiento de imágenes con Sharp
- ✅ Frontend drag & drop completamente funcional
- ✅ Integración con UNIT3D (reemplazo de imgbb.js)
- ✅ Scripts de instalación y configuración
- ✅ Sistema de pruebas automatizadas
- ✅ Documentación completa

### Próximos pasos para producción:
1. Configurar OneDrive con rclone
2. Actualizar configuración con tu dominio
3. Instalar como servicio systemd
4. Configurar proxy reverso (nginx)
5. Configurar SSL/HTTPS

## 📞 Soporte

Para problemas o consultas, revisar:
1. Logs del servicio
2. Scripts de prueba incluidos
3. Configuración de red y permisos
4. Estado del mount de OneDrive

---

**¡Sistema listo para reemplazar imgbb.com en UNIT3D!** 🎉