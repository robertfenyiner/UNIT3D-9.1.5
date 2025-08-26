# Telegram Notifier para UNIT3D

Microservicio que envía notificaciones automáticas a Telegram cuando se aprueban torrents en UNIT3D, con soporte para pósters de TMDB, categorías en español, y formato visual avanzado.

## 🎯 Características

- ✅ **Notificaciones automáticas** cuando se aprueban torrents
- ✅ **Pósters de películas/series** desde TMDB API
- ✅ **Categorías en español** completas de UNIT3D
- ✅ **Fallback inteligente** para torrents sin metadata
- ✅ **Formato visual avanzado** con emojis y separadores
- ✅ **Servicio permanente** con systemd
- ✅ **Logs detallados** para debugging
- ✅ **API endpoints** para testing y administración

## 🚀 Instalación Completa (Paso a Paso)

### Paso 1: Preparación del Sistema
```bash
# En tu servidor como root o con sudo
cd /var/www/html
git clone <tu-repositorio> telegram-notifier
cd telegram-notifier

# Instalar Node.js si no está instalado
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verificar instalación
node --version
npm --version
```

### Paso 2: Instalación de Dependencias
```bash
# Instalar dependencias del proyecto
npm install

# Dar permisos a scripts
chmod +x scripts/*.sh
```

### Paso 3: Configuración de Telegram

#### 3.1 Crear Bot de Telegram
1. Habla con [@BotFather](https://t.me/BotFather) en Telegram
2. Ejecuta `/newbot` y sigue las instrucciones
3. Guarda el **Bot Token** (formato: `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`)

#### 3.2 Obtener Chat ID
- **Canal:** Agrega el bot como administrador, el ID será negativo (ej: `-1002354465967`)
- **Grupo:** Agrega el bot al grupo y usa [@userinfobot](https://t.me/userinfobot)

#### 3.3 Obtener API Key de TMDB (Opcional pero recomendado)
1. Ve a [https://www.themoviedb.org/settings/api](https://www.themoviedb.org/settings/api)
2. Registra una cuenta gratuita
3. Solicita una API key
4. Guarda la API key para pósters automáticos

### Paso 4: Configuración del Servicio
```bash
# Crear archivo de configuración
cp config/config.example.json config/config.json

# Editar con tus datos reales
nano config/config.json
```

Configuración mínima en `config/config.json`:
```json
{
  "telegram": {
    "bot_token": "TU_BOT_TOKEN_AQUI",
    "chat_id": "TU_CHAT_ID_AQUI",
    "parse_mode": "Markdown"
  },
  "tracker": {
    "base_url": "https://tu-tracker.com",
    "name": "TU-TRACKER"
  },
  "server": {
    "port": 3001,
    "host": "localhost"
  },
  "features": {
    "include_imdb_link": true,
    "include_tmdb_info": true,
    "include_poster_images": true,
    "mention_uploader": true,
    "filter_categories": [],
    "fallback_to_search": true,
    "fallback_generic_image": false
  },
  "tmdb": {
    "api_key": "TU_TMDB_API_KEY_AQUI"
  }
}
```

### Paso 5: Configurar Servicio Permanente (systemd)
```bash
# Crear archivo de servicio systemd
sudo nano /etc/systemd/system/telegram-notifier.service
```

Contenido del archivo:
```ini
[Unit]
Description=Telegram Notifier for UNIT3D
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/var/www/html/telegram-notifier
ExecStart=/usr/bin/node app.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production

# Logging
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=telegram-notifier

[Install]
WantedBy=multi-user.target
```

```bash
# Habilitar y iniciar el servicio
sudo systemctl daemon-reload
sudo systemctl enable telegram-notifier
sudo systemctl start telegram-notifier

# Verificar estado
sudo systemctl status telegram-notifier
```

### Paso 6: Verificar Funcionamiento
```bash
# 1. Health check
curl http://localhost:3001/health

# 2. Mensaje de prueba a Telegram
curl -X POST http://localhost:3001/test-telegram

# 3. Simular notificación de torrent
curl -X POST http://localhost:3001/torrent-approved \
  -H "Content-Type: application/json" \
  -d '{
    "torrent_id": 123456,
    "name": "Test.Movie.2024.1080p.BluRay.x264-TEST",
    "user": "testuser",
    "category": "Peliculas",
    "size": "8.5 GB",
    "imdb": 1234567,
    "tmdb_movie_id": 550
  }'
```

### Paso 7: Verificar Integración con UNIT3D
La integración ya debería estar en `app/Helpers/TorrentHelper.php` en la línea 152+:
```php
try {
    \Http::timeout(5)->post('http://localhost:3001/torrent-approved', [
        'torrent_id' => $torrent->id,
        'name' => $torrent->name,
        'user' => $torrent->user->username,
        'category' => $torrent->category->name ?? 'Unknown',
        'size' => $torrent->getSize(),
        'imdb' => $torrent->imdb,
        'tmdb_movie_id' => $torrent->tmdb_movie_id,
        'tmdb_tv_id' => $torrent->tmdb_tv_id,
    ]);
} catch (\Exception $e) {
    \Log::warning('Telegram notification failed: ' . $e->getMessage());
}
```

## 🔧 Comandos de Mantenimiento

### Después de Hacer Cambios en el Código
```bash
# 1. Ir al directorio del proyecto
cd /var/www/html/telegram-notifier

# 2. Reiniciar el servicio para aplicar cambios
sudo systemctl restart telegram-notifier

# 3. Verificar que esté funcionando
sudo systemctl status telegram-notifier

# 4. Ver logs en tiempo real
sudo journalctl -u telegram-notifier -f
```

### Comandos Útiles de Desarrollo
```bash
# Parar el servicio temporalmente
sudo systemctl stop telegram-notifier

# Ejecutar manualmente para debugging (modo desarrollo)
node app.js

# Recargar configuración sin reiniciar
curl -X POST http://localhost:3001/config/reload

# Ver logs recientes
sudo journalctl -u telegram-notifier -n 50

# Ver estadísticas del servicio
curl -s http://localhost:3001/stats
```

### Gestión de Logs
```bash
# Logs en tiempo real
sudo journalctl -u telegram-notifier -f

# Logs históricos con filtro
sudo journalctl -u telegram-notifier --since "1 hour ago"

# Logs locales de la aplicación
tail -f /var/www/html/telegram-notifier/logs/combined.log

# Limpiar logs antiguos
sudo journalctl --vacuum-time=7d
```

## 📱 Formato de Mensaje Final

```
🎬 NUEVO TORRENT EN PELÍCULAS
━━━━━━━━━━━━━━━

📁 Avatar The Way of Water 2022 2160p UHD BluRay x265

👤 Uploader: uploader_pro
📂 Categoría: Peliculas
💾 Tamaño: 25.4 GB
🎥 Calidad: 2160p
💿 Fuente: BluRay
🔧 Códec: x265
📅 Año: 2022

━━━━━━━━━━━━━━━
🔗 ENLACES:
• Descargar: 
https://lat-team.xyz/torrents/123456
• IMDB: https://imdb.com/title/tt1630029
• TMDB: https://www.themoviedb.org/movie/76600
```
*+ Póster de la película automáticamente*

## 🗂️ Categorías Soportadas

El sistema reconoce todas las categorías de tu tracker:

- 🎬 **Peliculas** → API de TMDB Movies
- 📺 **TV Series** → API de TMDB TV
- 🎌 **Anime** → API de TMDB TV
- 🏮 **Asiáticas & Turcas** → API de TMDB TV  
- 📺 **Telenovelas** → API de TMDB TV
- 🎵 **Musica**
- 🎤 **Conciertos**
- ⚽ **Eventos Deportivos**
- 🔞 **XXX**
- 📚 **E-Books**
- 🎧 **Audiolibros**
- 🎮 **Juegos**
- 🎓 **Cursos**
- 📰 **Revistas & Periódicos**
- 📚 **Comics & Manga**

## 🎭 Funcionalidades TMDB

### Pósters Automáticos
- ✅ **Con TMDB ID**: Póster directo desde TMDB
- 🔍 **Sin TMDB ID**: Búsqueda automática por título
- 🖼️ **Sin resultados**: Imagen genérica por categoría (opcional)
- 📏 **Tamaño**: 185px de ancho (compacto para Telegram)

### Tamaño del póster (poster_size)
Puedes ajustar el ancho del póster que se descargará desde TMDB para reducir el espacio que ocupa en los clientes de Telegram. Hay dos formas de configurarlo:

- En `config/config.json` dentro de `features.poster_size`.
- O mediante la variable de ejemplo en `.env.example` (si tu despliegue usa variables de entorno).

Valores válidos de TMDB (ancho): `w92`, `w154`, `w185`, `w342`, `w500`, `w780`, `original`.
Recomendado para chats móviles: `w92` o `w154`.

### Fallback Inteligente
```json
{
  "features": {
    "fallback_to_search": true,      // Buscar por título si no hay TMDB ID
    "fallback_generic_image": false  // Imagen genérica si no encuentra nada
  }
}
```

## 🐛 Solución de Problemas Comunes

### El servicio no inicia
```bash
# Verificar logs
sudo journalctl -u telegram-notifier -n 20

# Verificar archivo de configuración
node -e "console.log(JSON.parse(require('fs').readFileSync('config/config.json')))"

# Verificar puerto ocupado
sudo netstat -tlnp | grep 3001
```

### Las imágenes no aparecen
```bash
# Verificar logs detallados
sudo journalctl -u telegram-notifier -f

# Verificar API key de TMDB
curl "https://api.themoviedb.org/3/configuration?api_key=TU_API_KEY"

# Probar con torrent que tenga TMDB ID
```

### No llegan notificaciones desde UNIT3D
```bash
# Verificar integración en TorrentHelper.php
grep -n "telegram" /var/www/html/app/Helpers/TorrentHelper.php

# Verificar logs de Laravel
tail -f /var/www/html/storage/logs/laravel.log

# Probar conexión local
curl http://localhost:3001/health
```

## 🔒 Seguridad y Rendimiento

- ✅ Servicio solo acepta conexiones desde localhost
- ✅ Timeout de 5 segundos en requests HTTP  
- ✅ Rate limiting automático para API de TMDB
- ✅ Validación de datos de entrada
- ✅ Logs sin información sensible
- ✅ Manejo robusto de errores
- ✅ Reinicio automático en caso de fallos

## 📊 Monitoreo

### Verificar Estado del Servicio
```bash
# Estado general
sudo systemctl status telegram-notifier

# Uso de memoria
ps aux | grep "node app.js"

# Estadísticas detalladas
curl -s http://localhost:3001/stats | python3 -m json.tool
```

### Alertas Automáticas
El servicio registra errores en syslog. Puedes configurar alertas:
```bash
# Monitorear errores críticos
sudo journalctl -u telegram-notifier -p err -f
```

## 🚀 Después de Reinicio del Servidor

El servicio está configurado para iniciarse automáticamente, pero puedes verificar:
```bash
# Verificar que esté corriendo después del reinicio
sudo systemctl status telegram-notifier

# Si no está corriendo, iniciarlo
sudo systemctl start telegram-notifier

# Ver logs del inicio
sudo journalctl -u telegram-notifier --since "10 minutes ago"
```

## ✅ Lista de Verificación Completa

- [ ] Node.js 16+ instalado
- [ ] Dependencias npm instaladas
- [ ] Bot de Telegram creado
- [ ] Chat ID obtenido correctamente  
- [ ] TMDB API key configurada (opcional)
- [ ] `config/config.json` configurado
- [ ] Servicio systemd creado y habilitado
- [ ] Servicio corriendo en puerto 3001
- [ ] Health check responde OK
- [ ] Mensaje de prueba enviado a Telegram
- [ ] Integración en `TorrentHelper.php` presente
- [ ] Torrent real aprobado genera notificación
- [ ] Pósters aparecen para torrents con TMDB
- [ ] Logs sin errores críticos

---

**🎉 ¡Tu notificador de Telegram está listo y funcionando!**

Para soporte, revisar logs con: `sudo journalctl -u telegram-notifier -f`