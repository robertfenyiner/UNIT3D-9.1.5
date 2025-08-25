# 🚀 Instrucciones de Deployment en Servidor Linux

## 📍 Comandos exactos para tu servidor

### 1. Navegar al directorio del microservicio
```bash
cd /var/www/html/telegram-notifier
```

### 2. Verificar que los archivos estén ahí
```bash
ls -la
# Deberías ver: app.js, package.json, config/, scripts/, etc.
```

### 3. Configurar el servicio systemd
```bash
sudo ./scripts/setup-service.sh
```
**Nota:** Este comando creará el archivo de servicio en `/etc/systemd/system/telegram-notifier.service`

### 4. Iniciar el servicio
```bash
sudo systemctl start telegram-notifier
```

### 5. Verificar que esté funcionando
```bash
sudo systemctl status telegram-notifier
```

### 6. Habilitar inicio automático (opcional)
```bash
sudo systemctl enable telegram-notifier
```

### 7. Ver logs en tiempo real
```bash
journalctl -u telegram-notifier -f
```

## 🔧 Comandos de gestión del servicio

```bash
# Iniciar servicio
sudo systemctl start telegram-notifier

# Parar servicio  
sudo systemctl stop telegram-notifier

# Reiniciar servicio
sudo systemctl restart telegram-notifier

# Ver estado
sudo systemctl status telegram-notifier

# Ver logs
journalctl -u telegram-notifier -n 50

# Ver logs en tiempo real
journalctl -u telegram-notifier -f

# Habilitar inicio automático
sudo systemctl enable telegram-notifier

# Deshabilitar inicio automático
sudo systemctl disable telegram-notifier
```

## 🐛 Solución de problemas

### Si el servicio no inicia:

1. **Verificar logs:**
   ```bash
   journalctl -u telegram-notifier -n 50
   ```

2. **Verificar configuración:**
   ```bash
   cd /var/www/html/telegram-notifier
   node scripts/configure.js
   ```

3. **Probar manualmente:**
   ```bash
   cd /var/www/html/telegram-notifier
   npm start
   ```

4. **Verificar puertos:**
   ```bash
   netstat -tlnp | grep 3001
   ```

### Si hay problemas de permisos:

```bash
# Corregir permisos
sudo chown -R www-data:www-data /var/www/html/telegram-notifier
sudo chmod +x /var/www/html/telegram-notifier/scripts/*.sh
```

## ✅ Verificación final

Después de que el servicio esté corriendo, prueba:

```bash
# Health check
curl http://localhost:3001/health

# Mensaje de prueba
curl -X POST http://localhost:3001/test-telegram

# Simular torrent aprobado
curl -X POST http://localhost:3001/torrent-approved \
  -H "Content-Type: application/json" \
  -d '{
    "torrent_id": 999,
    "name": "Test.Movie.2024.1080p.BluRay.x264",
    "user": "testuser", 
    "category": "Movies",
    "size": "8.5 GB"
  }'
```

## 🎯 ¡Listo!

Una vez que el servicio esté corriendo, cuando apruebes torrents en UNIT3D deberías recibir notificaciones automáticas en Telegram.