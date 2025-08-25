# 🚀 Guía Rápida - Telegram Notifier

**¡Notificaciones de torrents aprobados en Telegram en 5 minutos!**

## 📋 Requisitos Previos
- Node.js 14+ instalado
- Bot de Telegram creado
- Acceso al servidor donde está UNIT3D

## ⚡ Instalación Rápida

### 1. Crear Bot de Telegram (2 minutos)
```
1. Habla con @BotFather en Telegram
2. Envía: /newbot
3. Sigue las instrucciones
4. Guarda el BOT_TOKEN que te da
5. Agrega el bot a tu canal/grupo como administrador
```

### 2. Obtener Chat ID (1 minuto)
```
Para canal: El ID será negativo, ej: -1001234567890
Para grupo: Usa @userinfobot para obtener el ID
```

### 3. Instalar el Microservicio (2 minutos)
```bash
cd telegram-notifier
./scripts/install.sh
```

### 4. Configurar (30 segundos)
```bash
nano config/config.json
```
```json
{
  "telegram": {
    "bot_token": "TU_BOT_TOKEN_AQUI",
    "chat_id": "TU_CHAT_ID_AQUI"
  },
  "tracker": {
    "base_url": "https://tu-tracker.com"
  }
}
```

### 5. Probar (30 segundos)
```bash
./scripts/start.sh dev
```

En otra terminal:
```bash
./scripts/test.sh
```

## 🎯 ¡Ya está funcionando!

Cuando apruebes un torrent en UNIT3D, deberías recibir una notificación en Telegram como esta:

```
🎬 NUEVO TORRENT APROBADO

📁 Nombre: Movie.2024.1080p.BluRay.x264
👤 Uploader: username
📂 Categoría: Movies
💾 Tamaño: 8.5 GB

🔗 Ver Torrent
🎭 IMDB
```

## 🔧 Para Producción

```bash
# Configurar como servicio del sistema
sudo ./scripts/setup-service.sh

# Iniciar servicio
sudo systemctl start telegram-notifier

# Ver logs
journalctl -u telegram-notifier -f
```

## 🆘 Problemas Comunes

**❌ Bot no envía mensajes**
- Verifica bot_token y chat_id
- Asegúrate de que el bot esté en el canal como admin

**❌ Servicio no arranca**
- Verifica que el puerto 3001 esté libre
- Revisa logs: `tail -f logs/error.log`

**❌ UNIT3D no conecta**
- Verifica que localhost:3001 sea accesible
- Revisa logs de Laravel en storage/logs/

## 📞 Soporte

- Revisa el README.md completo
- Usa el script test.sh para diagnosticar
- Verifica logs en la carpeta logs/

¡Disfruta tus notificaciones automáticas! 🎉