# Telegram Notifier para UNIT3D

Microservicio que envía notificaciones a Telegram cuando se aprueban torrents en UNIT3D.

## 🚀 Instalación

### 1. Instalar dependencias
```bash
cd telegram-notifier
npm install
```

### 2. Configurar el Bot de Telegram

1. **Crear Bot:**
   - Habla con [@BotFather](https://t.me/BotFather) en Telegram
   - Usa `/newbot` y sigue las instrucciones
   - Guarda el **Bot Token** que te proporciona

2. **Obtener Chat ID:**
   - **Para Canal:** Agrega el bot como administrador y usa el ID del canal (negativo)
   - **Para Grupo:** Agrega el bot al grupo y usa [@userinfobot](https://t.me/userinfobot) para obtener el ID

### 3. Configurar el servicio

```bash
# Copiar configuración de ejemplo
cp config/config.example.json config/config.json

# Editar configuración
nano config/config.json
```

**Configuración mínima requerida:**
```json
{
  "telegram": {
    "bot_token": "1234567890:TU_BOT_TOKEN_AQUI",
    "chat_id": "-1001234567890"
  },
  "tracker": {
    "base_url": "https://tu-tracker.com"
  }
}
```

## 🎮 Uso

### Iniciar el servicio
```bash
# Modo desarrollo (con recarga automática)
npm run dev

# Modo producción
npm start
```

### Probar el servicio
```bash
# Health check
curl http://localhost:3001/health

# Probar envío a Telegram
curl -X POST http://localhost:3001/test-telegram

# Simular notificación de torrent
curl -X POST http://localhost:3001/torrent-approved \
  -H "Content-Type: application/json" \
  -d '{
    "torrent_id": 123,
    "name": "Movie.2024.1080p.BluRay.x264",
    "user": "testuser",
    "category": "Movies",
    "size": "8.5 GB",
    "imdb": 1234567
  }'
```

## 🔧 API Endpoints

| Endpoint | Método | Descripción |
|----------|--------|-------------|
| `/health` | GET | Estado del servicio |
| `/torrent-approved` | POST | Recibir notificación de torrent aprobado |
| `/test-telegram` | POST | Enviar mensaje de prueba |
| `/config/reload` | POST | Recargar configuración |
| `/stats` | GET | Estadísticas del servicio |

## 📁 Estructura de Archivos

```
telegram-notifier/
├── app.js                 # Aplicación principal
├── package.json          # Dependencias
├── README.md             # Esta documentación
├── config/
│   ├── config.json       # Configuración (crear desde example)
│   └── config.example.json # Ejemplo de configuración
├── logs/                 # Logs del sistema (auto-creado)
├── services/             # Para futuros servicios adicionales
└── scripts/              # Scripts de deployment
```

## 🐛 Solución de Problemas

### El bot no envía mensajes
1. Verifica que el `bot_token` sea correcto
2. Asegúrate de que el bot esté agregado al canal/grupo
3. Confirma que el `chat_id` sea correcto (negativo para canales)

### Error de conexión
1. Verifica que el puerto 3001 esté disponible
2. Revisa los logs en `logs/error.log`
3. Comprueba que no haya firewall bloqueando la conexión

### Notificaciones no llegan desde UNIT3D
1. Verifica que UNIT3D pueda hacer HTTP requests a localhost:3001
2. Revisa los logs de Laravel en `storage/logs/`
3. Confirma que el código esté agregado en `TorrentHelper.php`

## 📊 Logs

Los logs se guardan automáticamente en:
- `logs/combined.log` - Todos los logs
- `logs/error.log` - Solo errores
- Consola - Logs en tiempo real durante desarrollo

## 🔒 Seguridad

- El servicio solo acepta conexiones desde localhost por defecto
- No almacena tokens en logs
- Timeout de 5 segundos en requests HTTP
- Validación de datos entrantes

## 🔄 Deployment en Producción

Ver archivos en la carpeta `scripts/` para systemd service y PM2 deployment.