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
```markdown
# Sistema de Gestión de Imágenes para UNIT3D

Este servicio proporciona una API para subir, procesar y servir imágenes optimizadas, almacenadas mediante un mount rclone (OneDrive en nuestras pruebas). El README ha sido actualizado para reflejar cambios recientes realizados durante la puesta en marcha y despliegue.

## Resumen de cambios / decisiones recientes
- Se normalizaron rutas de producción en `config/config.json` para usar rutas absolutas (por ejemplo `storage.path` → `/var/www/html/storage/images`) para evitar errores de "directorio no existe".
- El middleware de subida espera el campo multipart `images` (array) — la ruta `POST /upload` usa `upload.array('images', 10)`. Hay también una utilidad `upload/url` para subir desde una URL.
- Se añadió manejo de logs y `logging.file` ahora apunta a `logs/image-service.log` y se recomienda que el servicio se ejecute como `www-data` para que pueda escribir en los directorios montados.
- Para montajes con rclone como servicio se usó un `rclone` config en `/etc/rclone/rclone.conf` con permisos `root:www-data 640` y `/etc/fuse.conf` debe contener `user_allow_other`.

## 🎯 Características

- Almacenamiento en OneDrive con rclone mount
- API REST para subida y gestión de imágenes
- Optimización automática (sharp) — redimensionado, compresión y thumbnails
- URLs públicas compatibles con BBCode
- Rate limiting y validaciones de seguridad

## 📁 Estructura (resumen)

```
image-service/
├── app.js                    # API principal Express
├── package.json              # Dependencias Node.js
├── config/
│   └── config.json          # Configuración del servicio (producción)
├── middleware/
│   └── upload.js            # Multer para archivos (campo: images[])
├── services/
│   └── imageProcessor.js    # Sharp para optimizar
├── routes/
│   └── upload.js            # POST /upload and POST /upload/url
├── public/
│   └── uploader.html        # Interfaz de subida (opcional)
├── logs/                    # Logs del servicio (ej. logs/image-service.log)
└── storage/
    └── temp/                # Archivos temporales antes de procesar
```

## � Configuración importante

Edítalo en `config/config.json`. claves relevantes (producción):

- `server`:
  - `port`: puerto (ej. 3002)
  - `host`: host (ej. `0.0.0.0` o `localhost`)

- `storage`:
  - `path`: ruta absoluta donde rclone monta el remote (ej. `/var/www/html/storage/images`). Debe existir y ser escribible por `www-data`.
  - `tempPath`: carpeta temporal dentro del servicio (ej. `/var/www/html/image-service/storage/temp`).
  - `publicUrl`: URL pública base usada para construir las URLs devueltas por la API.
  - `rclone.remote` y `rclone.path`: nombre del remote y subpath usados por rclone (informativo).

- `images`:
  - `maxSize`: legible (ej. `10MB`) y `maxSizeBytes` en bytes (ej. `10485760`).
  - `allowedTypes`: `image/jpeg`, `image/png`, `image/gif`, `image/webp`.
  - `allowedExtensions`: extensiones permitidas (`.jpg`, `.jpeg`, `.png`, `.gif`, `.webp`).
  - `maxWidth`, `maxHeight`, `quality`, `thumbnailWidth` y `thumbnailQuality` para control de procesamiento.

- `logging`:
  - `file`: `logs/image-service.log` (ruta relativa al servicio o absoluta si prefieres)
  - `level`, `maxSize`, `maxFiles` para rotación.

Ejemplo (extracto):

```json
{
  "storage": {
    "path": "/var/www/html/storage/images",
    "tempPath": "/var/www/html/image-service/storage/temp",
    "publicUrl": "http://tu-tracker.com/image",
    "rclone": { "remote": "onedrive-images", "path": "UNIT3D-Images" }
  },
  "images": {
    "maxSize": "10MB",
    "maxSizeBytes": 10485760,
    "allowedTypes": ["image/jpeg","image/png","image/gif","image/webp"]
  },
  "logging": { "file": "logs/image-service.log", "level": "info" }
}
```

## 📡 API Endpoints y ejemplos

- `GET /health` — Health check.

- `POST /upload` — Subida multipart/form-data (campo `images`). Soporta hasta 10 archivos por request.

Ejemplos (en la máquina que corre el servicio):

Subir un archivo existente en disco (campo correcto `images`):

```bash
curl -v -X POST -F "images=@/path/to/file.jpg" http://localhost:3002/upload
```

Subir múltiples archivos (repite el campo):

```bash
curl -v -X POST -F "images=@/file1.jpg" -F "images=@/file2.png" http://localhost:3002/upload
```

- `POST /upload/single` — Subida de un único archivo usando el campo `image`. Esta ruta es compatible con clientes que no envían arrays.

Ejemplo (single):

```bash
curl -v -X POST -F "image=@/path/to/file.jpg" http://localhost:3002/upload/single
```

- `POST /upload/url` — Subir imagen desde URL (JSON body `{ "url": "https://...", "filename": "name.jpg" }`). Útil si el servidor tiene acceso a Internet.

- `GET /image/:id` — Servir imagen procesada.

Respuesta para una sola imagen (compatibilidad con imgbb): contiene `data.image.url` y `thumb` si está disponible.

## 🧰 Logs, permisos y troubleshooting

- Logs: `tail -f /var/log/image-service/image-service.log` (según `config.logging.file`).
- Permisos recomendados: el usuario del servicio (`www-data`) debe poder escribir en `storage.path` y en `logs/`.

Ejemplos:

```bash
sudo chown -R www-data:www-data /var/www/html/storage
sudo chown -R www-data:www-data /var/www/html/image-service/logs
sudo chmod 750 /var/www/html/storage
```

Si ves errores de mount o rclone, revisa:

- `/etc/rclone/rclone.conf` debe existir y ser legible para el servicio (ej. `root:www-data 640`).
- `/etc/fuse.conf` debe contener la línea `user_allow_other` para permitir mounts con `allow_other`.

## ✅ Systemd (ejemplos usados en despliegue)

- `rclone-onedrive.service` (ejecuta el mount rclone). Asegúrate que su `ExecStart` apunte a la configuración correcta: `--config=/etc/rclone/rclone.conf`.
- `image-service.service` — unidad para ejecutar `node app.js` como `www-data`.

Ambas unidades se colocaron en `/etc/systemd/system/` en el despliegue de referencia. Después de crear las unidades:

```bash
sudo systemctl daemon-reload
sudo systemctl enable rclone-onedrive.service image-service.service
sudo systemctl start rclone-onedrive.service image-service.service
sudo journalctl -u image-service.service -f
```

## 🧪 Pruebas comunes y limpieza

- Health: `curl http://localhost:3002/health`
- Subida de prueba (campo `images`):

```bash
curl -v -X POST -F "images=@/var/www/html/storage/images/a03481c9-6815-41bc-b9eb-2fbcfcb830e5.jpg" http://localhost:3002/upload
```

- Borrar archivo de prueba (si quieres limpiar):

```bash
sudo rm /var/www/html/storage/images/<filename>.jpg
sudo rm /var/www/html/storage/images/thumbs/<filename>_thumb.jpg
```

## Notas finales / recomendaciones

- Mantén `config/config.json` con rutas absolutas en producción para evitar errores de "directorio no existe".
- Usa el campo `images` (array) para integraciones con formularios o scripts que suban múltiples archivos.
- Si necesitas soporte para `image` (single) se puede agregar fácilmente cambiando la ruta o exponiendo una ruta alternativa que use `upload.single('image')`.

Si quieres, actualizo el repositorio añadiendo ejemplos de `systemd` unit files y un script `scripts/deploy-image-service.sh` para reproducir el despliegue.

---

**Estado:** documentación actualizada para reflejar configuración y pasos usados en el despliegue.
```