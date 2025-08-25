# Telegram Notifier para UNIT3D

Microservicio que envía notificaciones automáticas a Telegram cuando se aprueban torrents en UNIT3D.

## 🚀 Instalación Rápida

### Opción A: Instalación Automática (Recomendada)
```bash
# 1. Navegar al directorio
cd /var/www/html/telegram-notifier

# 2. Configurar con tus datos reales
node scripts/fix-config.js

# 3. Desplegar automáticamente
sudo bash scripts/deploy.sh

# 4. Probar funcionamiento
bash scripts/test-complete.sh
```

### Opción B: Instalación Manual
```bash
# 1. Instalar dependencias
npm install

# 2. Configurar
cp config/config.example.json config/config.json
nano config/config.json  # Agregar tu bot_token y chat_id

# 3. Iniciar en desarrollo
npm run dev
```

## 📱 Configuración de Telegram

### 1. Crear Bot de Telegram
1. Habla con [@BotFather](https://t.me/BotFather) en Telegram
2. Ejecuta `/newbot` y sigue las instrucciones
3. Guarda el **Bot Token** (formato: `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`)

### 2. Obtener Chat ID
- **Canal:** Agrega el bot como administrador, el ID será negativo (ej: `-1002354465967`)
- **Grupo:** Agrega el bot al grupo y usa [@userinfobot](https://t.me/userinfobot)
- **Chat privado:** ID positivo del usuario

### 3. Configuración Mínima
Edita `config/config.json`:
```json
{
  "telegram": {
    "bot_token": "8447822656:AAG2OTaTBtfTcVsLLH7Wqivm1N8B82tiDaM",
    "chat_id": "-1002354465967"
  },
  "tracker": {
    "base_url": "https://lat-team.xyz"
  }
}
```

## 🎯 Integración con UNIT3D

El sistema ya está integrado automáticamente. Cuando apruebes un torrent en tu panel de staff, el código en `app/Helpers/TorrentHelper.php` enviará automáticamente una notificación al microservicio.

**Ubicación de la integración:** `TorrentHelper.php` líneas 155-170

## 🧪 Pruebas y Verificación

### Suite Completa de Pruebas
```bash
# Ejecutar todas las pruebas automáticamente
bash scripts/test-complete.sh
```

### Pruebas Individuales
```bash
# 1. Health check
curl http://localhost:3001/health

# 2. Mensaje de prueba a Telegram
curl -X POST http://localhost:3001/test-telegram

# 3. Simular torrent aprobado básico
curl -X POST http://localhost:3001/torrent-approved \
  -H "Content-Type: application/json" \
  -d '{
    "torrent_id": 123456,
    "name": "Test.Movie.2024.1080p.BluRay.x264-TEST",
    "user": "testuser",
    "category": "Movies",
    "size": "8.5 GB"
  }'

# 4. Simular torrent con metadata completa
curl -X POST http://localhost:3001/torrent-approved \
  -H "Content-Type: application/json" \
  -d '{
    "torrent_id": 789012,
    "name": "Avatar.The.Way.of.Water.2022.2160p.UHD.BluRay.x265",
    "user": "uploader_pro",
    "category": "Movies", 
    "size": "25.4 GB",
    "imdb": 1630029,
    "tmdb_movie_id": 76600
  }'

# 5. Probar diferentes categorías
curl -X POST http://localhost:3001/torrent-approved \
  -H "Content-Type: application/json" \
  -d '{
    "torrent_id": 345678,
    "name": "The.Last.of.Us.S01E01.2160p.WEB.H265",
    "user": "tv_uploader",
    "category": "TV",
    "size": "4.2 GB"
  }'
```

## 🔧 API Endpoints

| Endpoint | Método | Descripción | Ejemplo |
|----------|--------|-------------|---------|
| `/health` | GET | Estado del servicio | Verificar que esté corriendo |
| `/torrent-approved` | POST | Notificación de torrent aprobado | Llamado por UNIT3D automáticamente |
| `/test-telegram` | POST | Mensaje de prueba | Verificar conexión con Telegram |
| `/config/reload` | POST | Recargar configuración | Sin reiniciar el servicio |
| `/stats` | GET | Estadísticas del servicio | Uptime, memoria, configuración |

### Formato de Notificación de Torrent
```json
{
  "torrent_id": 123456,
  "name": "Movie.Name.2024.1080p.BluRay.x264",
  "user": "uploader_username",
  "category": "Movies",
  "size": "8.5 GB",
  "imdb": 1234567,
  "tmdb_movie_id": 98765,
  "tmdb_tv_id": null
}
```

## 📋 Gestión del Servicio (Producción)

### Comandos de systemd
```bash
# Ver estado
systemctl status telegram-notifier

# Iniciar/Parar/Reiniciar
sudo systemctl start telegram-notifier
sudo systemctl stop telegram-notifier
sudo systemctl restart telegram-notifier

# Logs en tiempo real
journalctl -u telegram-notifier -f

# Logs históricos
journalctl -u telegram-notifier -n 50

# Habilitar inicio automático
sudo systemctl enable telegram-notifier
```

### Scripts Útiles
```bash
# Configurar servicio systemd
sudo ./scripts/setup-service.sh

# Validar configuración
node scripts/configure.js

# Reparar archivo config.json
node scripts/fix-config.js

# Deployment completo
sudo bash scripts/deploy.sh

# Suite de pruebas
bash scripts/test-complete.sh
```

## 📁 Estructura del Proyecto

```
telegram-notifier/
├── 📄 app.js                    # Aplicación principal Node.js
├── 📄 package.json             # Dependencias y scripts npm
├── 📄 README.md                # Esta documentación
├── 📄 QUICK_START.md           # Guía rápida de instalación
├── 📄 DEPLOY_INSTRUCTIONS.md   # Instrucciones específicas de servidor
├── 📄 .gitignore              # Archivos a ignorar en git
├── 📄 .env.example            # Variables de entorno de ejemplo
│
├── 📁 config/
│   ├── config.json            # ⚠️ Configuración actual (no versionar)
│   └── config.example.json    # Plantilla de configuración
│
├── 📁 scripts/
│   ├── install.sh             # Instalación inicial
│   ├── deploy.sh              # Deployment completo a producción
│   ├── setup-service.sh       # Configurar servicio systemd
│   ├── start.sh               # Iniciar en dev/prod
│   ├── test-complete.sh       # ⭐ Suite completa de pruebas
│   ├── configure.js           # Validar configuración
│   ├── fix-config.js          # Reparar config.json
│   ├── validate-json.js       # Diagnosticar JSON
│   └── telegram-notifier.service # Template de systemd
│
├── 📁 logs/                    # Logs del servicio (auto-creado)
│   ├── combined.log           # Todos los logs
│   └── error.log              # Solo errores
│
├── 📁 services/               # Para extensiones futuras
└── 📁 routes/                 # Para módulos de rutas adicionales
```

## 💬 Formato de Mensajes en Telegram

Los mensajes aparecerán en tu canal así:

```
🎬 NUEVO TORRENT APROBADO

📁 Nombre: Avatar.The.Way.of.Water.2022.2160p.UHD.BluRay.x265
👤 Uploader: uploader_pro
📂 Categoría: Movies
💾 Tamaño: 25.4 GB

🔗 Ver Torrent
🎭 IMDB
🎬 TMDB

🕒 25/8/2025, 15:57:13
```

### Emojis por Categoría
- 🎬 Movies
- 📺 TV / TV Shows  
- 🎵 Music
- 🎮 Games
- 💿 Software
- 📚 Books
- 📱 Apps
- 🎌 Anime
- 🎭 Documentary
- 🔞 XXX
- 📦 Otros

## ⚙️ Configuración Avanzada

### Filtros por Categoría
En `config/config.json`:
```json
{
  "features": {
    "filter_categories": ["Movies", "TV Shows"],  // Solo estas categorías
    "filter_categories": [],                      // Todas las categorías
    "include_imdb_link": true,
    "include_tmdb_info": true,
    "mention_uploader": true
  }
}
```

### Variables de Entorno (Alternativa)
Puedes usar `.env` en lugar de `config.json`:
```bash
TELEGRAM_BOT_TOKEN=8447822656:AAG2OTaTBtfTcVsLLH7Wqivm1N8B82tiDaM
TELEGRAM_CHAT_ID=-1002354465967
TRACKER_BASE_URL=https://lat-team.xyz
SERVER_PORT=3001
```

## 🐛 Solución de Problemas

### El servicio no inicia
```bash
# Verificar logs
journalctl -u telegram-notifier -n 20

# Probar manualmente
cd /var/www/html/telegram-notifier
npm start

# Verificar configuración
node scripts/configure.js

# Verificar puerto
netstat -tlnp | grep 3001
```

### Bot no envía mensajes
```bash
# Verificar configuración
node scripts/configure.js

# Probar conexión manualmente
curl -X POST http://localhost:3001/test-telegram

# Verificar que el bot esté en el canal
# Verificar que el chat_id sea correcto (negativo para canales)
```

### Notificaciones no llegan desde UNIT3D
1. Verificar que UNIT3D pueda conectar a localhost:3001
2. Revisar logs de Laravel: `storage/logs/laravel.log`
3. Verificar que el código esté en `TorrentHelper.php`
4. Probar manualmente la aprobación de un torrent

### Problemas de permisos
```bash
sudo chown -R www-data:www-data /var/www/html/telegram-notifier
sudo chmod +x /var/www/html/telegram-notifier/scripts/*.sh
```

## 📊 Monitoreo y Logs

### Logs del Sistema
```bash
# Logs en tiempo real
journalctl -u telegram-notifier -f

# Logs históricos
journalctl -u telegram-notifier --since "1 hour ago"

# Logs con filtro
journalctl -u telegram-notifier | grep ERROR
```

### Logs de la Aplicación
```bash
# Ver logs locales
tail -f logs/combined.log
tail -f logs/error.log

# Logs con timestamp
cat logs/combined.log | grep "$(date +%Y-%m-%d)"
```

### Métricas
```bash
# Estadísticas del servicio
curl -s http://localhost:3001/stats | python3 -m json.tool

# Uso de memoria
ps aux | grep "node app.js"

# Conexiones de red
netstat -an | grep 3001
```

## 🔒 Seguridad

- ✅ Solo acepta conexiones desde localhost por defecto
- ✅ No almacena tokens sensibles en logs
- ✅ Timeout de 5 segundos en requests HTTP
- ✅ Validación de datos entrantes
- ✅ Manejo seguro de errores
- ✅ Logs con niveles de verbosidad

## 🚀 Extensibilidad

### Agregar más plataformas
El diseño modular permite agregar fácilmente:
- Discord notifications
- Slack integration  
- Email notifications
- Webhook notifications

### Personalizar mensajes
Editar la función `formatMessage()` en `app.js` para cambiar:
- Formato de los mensajes
- Campos mostrados
- Estilo de los emojis
- Enlaces adicionales

## ✅ Lista de Verificación de Funcionamiento

- [ ] Node.js 14+ instalado
- [ ] Bot de Telegram creado y configurado
- [ ] Chat ID obtenido correctamente
- [ ] Configuración en `config/config.json` válida
- [ ] Servicio systemd corriendo
- [ ] Puerto 3001 accesible
- [ ] Health check responde OK
- [ ] Mensaje de prueba enviado exitosamente
- [ ] Simulación de torrent funciona
- [ ] Código agregado en `TorrentHelper.php`
- [ ] Logs del servicio sin errores
- [ ] Torrent real aprobado genera notificación

## 📞 Soporte

Si tienes problemas:

1. **Ejecuta las pruebas:** `bash scripts/test-complete.sh`
2. **Revisa logs:** `journalctl -u telegram-notifier -f`
3. **Verifica configuración:** `node scripts/configure.js`
4. **Consulta documentación:** `README.md`, `QUICK_START.md`
5. **Validar integración:** Aprobar torrent real en UNIT3D

---

**🎉 ¡Disfruta tus notificaciones automáticas de Telegram!**