# 📱 TELEGRAM NOTIFIER - INSTALACIÓN COMPLETA

## 🎯 Descripción
Microservicio Node.js que envía notificaciones automáticas a Telegram cuando se aprueban torrents en UNIT3D.

---

## 🔧 PASO 1: REQUISITOS PREVIOS

### **En tu sistema Linux:**
```bash
# Verificar Node.js (necesario 14+)
node --version

# Si no tienes Node.js, instalarlo:
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verificar npm
npm --version
```

---

## 🤖 PASO 2: CONFIGURAR BOT DE TELEGRAM

### **2.1 Crear el Bot:**
1. **Hablar con @BotFather en Telegram:**
   - Enviar: `/newbot`
   - Elegir nombre del bot: `Mi Tracker Bot`
   - Elegir username: `mi_tracker_bot` (debe terminar en '_bot')

2. **Guardar el Token:**
   - BotFather te dará un token como: `1234567890:ABCdefGHIjklMNOpqrsTUVwxyz`
   - **¡GUÁRDALO!** Lo necesitarás en el config

### **2.2 Obtener Chat ID:**

**Para Canal:**
```bash
# 1. Crear canal en Telegram
# 2. Agregar tu bot como administrador al canal
# 3. Enviar un mensaje de prueba al canal
# 4. Usar este comando para obtener el chat_id:
curl "https://api.telegram.org/bot<TU_BOT_TOKEN>/getUpdates"

# El chat_id será negativo, ejemplo: -1001234567890
```

**Para Grupo:**
```bash
# 1. Crear grupo en Telegram
# 2. Agregar tu bot al grupo
# 3. Agregar @userinfobot al grupo
# 4. Enviar cualquier mensaje
# 5. @userinfobot te dará el chat_id del grupo
```

---

## 🚀 PASO 3: INSTALAR EL SERVICIO

### **3.1 Navegar al directorio:**
```bash
cd /var/www/html/telegram-notifier
```

### **3.2 Instalar dependencias:**
```bash
# Hacer ejecutable el script
chmod +x scripts/install.sh

# Ejecutar instalación
./scripts/install.sh
```

**Esto instalará:**
- ✅ Dependencias npm
- ✅ Creará directorios de logs
- ✅ Copiará archivo de configuración ejemplo

---

## ⚙️ PASO 4: CONFIGURAR EL SERVICIO

### **4.1 Editar configuración:**
```bash
nano config/config.json
```

### **4.2 Configuración básica requerida:**
```json
{
  "telegram": {
    "bot_token": "1234567890:ABCdefGHIjklMNOpqrsTUVwxyz",  ← TU TOKEN
    "chat_id": "-1001234567890",                          ← TU CHAT ID
    "parse_mode": "HTML"
  },
  "tracker": {
    "base_url": "https://tu-dominio.com",                 ← TU TRACKER URL
    "name": "Mi Tracker"                                  ← NOMBRE DE TU TRACKER
  },
  "server": {
    "port": 3001,
    "host": "localhost"
  }
}
```

### **4.3 Configuración avanzada (opcional):**
```json
{
  "features": {
    "include_imdb_link": true,        ← Incluir enlaces IMDB
    "include_tmdb_info": true,        ← Incluir info de TMDB
    "include_poster_images": true,    ← Incluir imágenes de pósters
    "poster_size": "w185",           ← Tamaño de póster
    "mention_uploader": true         ← Mencionar usuario que subió
  },
  "tmdb": {
    "api_key": "TU_TMDB_API_KEY"    ← API Key de TheMovieDB (gratis)
  }
}
```

---

## 🧪 PASO 5: PROBAR EL SERVICIO

### **5.1 Probar en modo desarrollo:**
```bash
# Iniciar en modo desarrollo
./scripts/start.sh dev

# En otra terminal, probar:
curl http://localhost:3001/health
curl -X POST http://localhost:3001/test-telegram
```

**Deberías ver:**
- ✅ Servidor iniciado en puerto 3001
- ✅ Mensaje "Sistema funcionando" en terminal
- ✅ Mensaje de prueba en tu canal de Telegram

### **5.2 Probar notificación completa:**
```bash
# Simular torrent aprobado
curl -X POST http://localhost:3001/torrent-approved \
  -H "Content-Type: application/json" \
  -d '{
    "torrent_id": 999,
    "name": "Avatar.2024.1080p.BluRay.x264",
    "user": "testuser", 
    "category": "Movies",
    "size": "8.5 GB",
    "imdb_id": "tt0114709"
  }'
```

---

## 🔧 PASO 6: INSTALAR COMO SERVICIO SYSTEMD

### **6.1 Configurar servicio del sistema:**
```bash
# Detener el modo desarrollo (Ctrl+C si está corriendo)
# Configurar servicio systemd
sudo ./scripts/setup-service.sh
```

### **6.2 Iniciar servicio:**
```bash
# Iniciar servicio
sudo systemctl start telegram-notifier

# Verificar estado
sudo systemctl status telegram-notifier

# Habilitar inicio automático (opcional)
sudo systemctl enable telegram-notifier
```

### **6.3 Comandos de gestión:**
```bash
# Ver logs en tiempo real
sudo journalctl -u telegram-notifier -f

# Reiniciar servicio
sudo systemctl restart telegram-notifier

# Parar servicio
sudo systemctl stop telegram-notifier

# Ver últimos logs
sudo journalctl -u telegram-notifier -n 50
```

---

## 🔗 PASO 7: INTEGRAR CON UNIT3D

### **7.1 El webhook ya está configurado en UNIT3D:**
- ✅ Al aprobar torrents, UNIT3D enviará webhook a `localhost:3001`
- ✅ El telegram-notifier procesará y enviará a Telegram
- ✅ **No necesitas configurar nada más en UNIT3D**

### **7.2 Verificar integración:**
1. Aprobar cualquier torrent en tu UNIT3D
2. Verificar que llegue notificación a Telegram
3. Si no llega, revisar logs: `sudo journalctl -u telegram-notifier -f`

---

## 📊 PASO 8: VERIFICACIÓN FINAL

### **8.1 Health Check:**
```bash
curl http://localhost:3001/health
# Respuesta esperada: {"status":"healthy","service":"telegram-notifier"}
```

### **8.2 Verificar que el servicio esté corriendo:**
```bash
sudo systemctl status telegram-notifier
# Estado esperado: Active (running)
```

### **8.3 Verificar puerto:**
```bash
netstat -tlnp | grep 3001
# Debería mostrar que el puerto 3001 está ocupado por node
```

---

## 🚨 SOLUCIÓN DE PROBLEMAS

### **❌ Bot no envía mensajes:**
```bash
# Verificar token y chat_id
cat config/config.json | grep -A 5 "telegram"

# Probar bot manualmente
curl "https://api.telegram.org/bot<TU_TOKEN>/getMe"
```

### **❌ Servicio no arranca:**
```bash
# Ver logs detallados
sudo journalctl -u telegram-notifier -n 50

# Verificar puerto libre
netstat -tlnp | grep 3001

# Probar manualmente
cd /var/www/html/telegram-notifier
node app.js
```

### **❌ UNIT3D no conecta:**
```bash
# Verificar que el webhook esté configurado en UNIT3D
# Verificar logs de Laravel
tail -f /var/www/html/storage/logs/laravel.log

# Probar conexión manual
curl -X POST http://localhost:3001/torrent-approved \
  -H "Content-Type: application/json" \
  -d '{"torrent_id":1,"name":"Test","user":"test","category":"Movies"}'
```

### **⚠️ Permisos:**
```bash
# Corregir permisos
sudo chown -R www-data:www-data /var/www/html/telegram-notifier
sudo chmod +x /var/www/html/telegram-notifier/scripts/*.sh
```

---

## 🎉 ¡LISTO!

**Una vez completados todos los pasos:**

✅ **Telegram-notifier corriendo como servicio systemd**  
✅ **Bot de Telegram configurado y funcionando**  
✅ **UNIT3D integrado y enviando webhooks**  
✅ **Notificaciones automáticas cuando apruebes torrents**  

### **Mensaje de ejemplo que recibirás:**
```
🎬 NUEVO TORRENT APROBADO

📁 Avatar.The.Way.of.Water.2022.1080p.BluRay.x264
👤 Uploader: @usuario123
📂 Categoría: Movies  
💾 Tamaño: 15.2 GB

🔗 Ver Torrent | 🎭 IMDB
```

**¡Disfruta tus notificaciones automáticas!** 🚀