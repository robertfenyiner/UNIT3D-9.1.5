# Sistema de Gestión de Imágenes para UNIT3D

Sistema propio de subida y gestión de imágenes para reemplazar imgbb, con almacenamiento en OneDrive via rclone.

## 🎯 Características

- ✅ **Almacenamiento en OneDrive** con rclone mount
- ✅ **API REST** para subida y gestión de imágenes  
- ✅ **Optimización automática** (redimensionar, comprimir)
- ✅ **URLs públicas** compatibles con BBCode
- ✅ **Integración perfecta** con formulario de UNIT3D
- ✅ **Rate limiting** y validaciones de seguridad
- ✅ **Gestión de cuotas** y limpieza automática

## 🏗️ Arquitectura

```
UNIT3D Form ──▶ Image API ──▶ OneDrive (rclone)
     │              │              │
  Upload UI     Process &      Store Files
  BBCode Gen    Optimize      Public URLs
```

## 📁 Estructura

```
image-service/
├── app.js                    # API principal Express
├── package.json             # Dependencias Node.js
├── config/
│   └── config.json         # Configuración del servicio
├── middleware/
│   ├── auth.js             # Autenticación con UNIT3D
│   ├── upload.js           # Multer para archivos
│   ├── validation.js       # Validación de imágenes
│   └── rateLimit.js        # Rate limiting
├── services/
│   ├── imageProcessor.js   # Sharp para optimizar
│   ├── storageManager.js   # Gestión de archivos
│   └── urlGenerator.js     # URLs públicas
├── routes/
│   ├── upload.js           # POST /upload
│   ├── images.js           # GET /image/:id
│   ├── manage.js           # DELETE, cleanup
│   └── health.js           # Health checks
├── public/
│   └── uploader.html       # Interfaz de subida
├── logs/                   # Logs del servicio
└── storage/
    └── temp/              # Archivos temporales
```

## 🚀 Instalación

### 1. Configurar rclone con OneDrive
```bash
# Instalar rclone (como root)
curl https://rclone.org/install.sh | sudo bash

# Configurar OneDrive
rclone config
```

### 2. Crear mount point y montar OneDrive
```bash
# Crear directorio
sudo mkdir -p /var/www/html/storage/images

# Montar OneDrive
sudo mount -t rclone onedrive-images:/UNIT3D-Images /var/www/html/storage/images -o allow_other,vfs-cache-mode=writes

# Agregar a fstab para mount automático
echo "onedrive-images:/UNIT3D-Images /var/www/html/storage/images rclone rw,allow_other,vfs-cache-mode=writes,_netdev 0 0" | sudo tee -a /etc/fstab
```

### 3. Instalar el servicio
```bash
cd /var/www/html/image-service
npm install
sudo systemctl enable image-service
sudo systemctl start image-service
```

## 🔧 Configuración

### config/config.json
```json
{
  "server": {
    "port": 3002,
    "host": "localhost"
  },
  "storage": {
    "path": "/var/www/html/storage/images",
    "tempPath": "/var/www/html/image-service/storage/temp",
    "publicUrl": "https://tu-tracker.com/img"
  },
  "images": {
    "maxSize": "10MB",
    "allowedTypes": ["image/jpeg", "image/png", "image/gif", "image/webp"],
    "maxWidth": 2000,
    "maxHeight": 2000,
    "quality": 85
  },
  "security": {
    "rateLimit": {
      "windowMs": 900000,
      "max": 50
    },
    "auth": {
      "enabled": true,
      "unit3dUrl": "https://tu-tracker.com"
    }
  }
}
```

## 📡 API Endpoints

| Endpoint | Método | Descripción |
|----------|--------|-------------|
| `POST /upload` | POST | Subir imagen(es) |
| `GET /image/:id` | GET | Servir imagen |
| `DELETE /image/:id` | DELETE | Eliminar imagen |
| `GET /health` | GET | Health check |
| `GET /stats` | GET | Estadísticas |

## 🧪 Testing

```bash
# Health check
curl http://localhost:3002/health

# Subir imagen
curl -X POST -F "image=@test.jpg" http://localhost:3002/upload

# Ver estadísticas
curl http://localhost:3002/stats
```

## 🔒 Seguridad

- ✅ Rate limiting por IP
- ✅ Validación de tipos de archivo
- ✅ Sanitización de nombres de archivo
- ✅ Límites de tamaño
- ✅ Autenticación con UNIT3D (opcional)
- ✅ URLs seguras con tokens

---

**🎉 Sistema de imágenes propio para UNIT3D listo!**