Scripts de métricas y alertas - instalación y configuración

Resumen

Esta carpeta contiene:
- `server_info_tracker.sh` — script informativo que envía un resumen del servidor y diagnósticos del tracker (announces, Redis, php-fpm, top IPs/UAs/passkeys).
- `server_alerts_tracker.sh` — script de alertas con thresholds y detección de spikes en announces; envía mensajes a Telegram cuando detecta condiciones críticas.
- `metrics_env.example` — ejemplo de archivo de entorno (no contiene secrets reales).
- `systemd/metrics_alerts.service` y `systemd/metrics_alerts.timer` — plantillas systemd para ejecutar `server_alerts_tracker.sh` periódicamente.

Importante de seguridad

No incluyas tokens ni credenciales directamente en el repositorio. En vez de eso coloca las credenciales en `/etc/default/metrics_bot_env` en el servidor y dale permisos restrictivos (600). Aunque el repositorio sea privado, almacenar secretos en git no es recomendable.

Paso a paso — instalación en el servidor (ejemplo path `/var/www/html`)

1) Copiar los scripts al servidor

Si ya estás en el servidor y tu repo está en `/var/www/html`, asegúrate de que los scripts existan en `/var/www/html/scripts`.

2) Crear el archivo que contendrá las credenciales (solo en el servidor)

- Copia el ejemplo a la ruta protegida y edítalo:

```bash
sudo cp /var/www/html/scripts/metrics_env.example /etc/default/metrics_bot_env
sudo nano /etc/default/metrics_bot_env
```

- En el archivo coloca (sustituye los valores por los reales):

```text
TELEGRAM_BOT_TOKEN="<pon_aqui_tu_token_de_bot>"
TELEGRAM_CHAT_ID="<pon_aqui_tu_chat_id>"
# Opcionales:
# ACCESS_LOG="/ruta/a/tu/access.log"
# PATH_TO_REPO="/var/www/html"
```

- Protege el archivo:

```bash
sudo chmod 600 /etc/default/metrics_bot_env
sudo chown root:root /etc/default/metrics_bot_env
```

3) Permisos de los scripts y pruebas manuales

```bash
sudo chmod +x /var/www/html/scripts/server_alerts_tracker.sh
sudo chmod +x /var/www/html/scripts/server_info_tracker.sh

# Ejecutar manualmente (con sudo para que el script cargue /etc/default/metrics_bot_env)
sudo /bin/bash /var/www/html/scripts/server_alerts_tracker.sh
sudo /bin/bash /var/www/html/scripts/server_info_tracker.sh
```

Si la ejecución falla con la advertencia "Please export TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID before running.", revisa que `/etc/default/metrics_bot_env` exista y tenga las variables definidas correctamente.

4) Instalar systemd unit + timer (para alertas periódicas)

- Edita la plantilla para usar la ruta correcta de tu repo (reemplaza `/var/www/html` si corresponde):

```bash
sudo sed -i 's|/path/to/repo|/var/www/html|g' /var/www/html/scripts/systemd/metrics_alerts.service
```

- Copia los unit files a systemd:

```bash
sudo cp /var/www/html/scripts/systemd/metrics_alerts.service /etc/systemd/system/
sudo cp /var/www/html/scripts/systemd/metrics_alerts.timer /etc/systemd/system/
```

- Recargar systemd, habilitar y arrancar el timer:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now metrics_alerts.timer
```

- Comprobar estado y logs:

```bash
systemctl list-timers --all | grep metrics_alerts
sudo systemctl status metrics_alerts.timer metrics_alerts.service --no-pager
sudo journalctl -u metrics_alerts.service -n 200 --no-pager
```

5) Ajustes y thresholds

- Los thresholds por defecto (swap, disco, mem, cpu y heurística de spike) están dentro de `server_alerts_tracker.sh`. Edita este archivo para ajustarlos a tus necesidades.
- `TAIL_LINES` controla cuántas líneas de `access.log` se analizan. Bajar este valor reduce I/O.

6) Qué reportan los scripts

- Conteo total de requests a `/announce/` en la muestra.
- Top 10 de IPs que llaman a `/announce/` con conteos.
- Top 10 de user-agents que llaman a `/announce/` con conteos.
- Top 10 de passkeys (parte de la URL `/announce/{passkey}`) con conteos.
- Redis INFO (si `redis-cli` está instalado) y longitudes de colas conocidas.
- PHP-FPM pools (lee `/etc/php/*/fpm/pool.d/*.conf`), suma de `pm.max_children`, conteo de procesos y avg RSS por proceso.

7) Cómo depurar problemas comunes

- Mensajes no llegan a Telegram:
  - Verifica `/etc/default/metrics_bot_env` y permisos.
  - Ejecuta `curl "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getMe"` desde el servidor para comprobar token.
  - Revisa `journalctl -u metrics_alerts.service`.

- El service falla al arrancar desde timer pero funciona manualmente:
  - Asegúrate de que el `EnvironmentFile` en el unit apunta a `/etc/default/metrics_bot_env` y que el unit tiene permisos para leerlo.

8) Rotación de token y seguridad

- Si sospechas que el token fue expuesto accidentalmente, revócalo desde @BotFather y genera uno nuevo. Actualiza `/etc/default/metrics_bot_env` con el token nuevo.
- Mantén `/etc/default/metrics_bot_env` fuera de cualquier control de versiones (`.gitignore`) si copias ejemplos en tu repo local.

9) Opciones avanzadas (siguientes pasos)

- Integrar con Prometheus / Pushgateway para métricas estructuradas.
- Añadir reglas fail2ban para bloquear IPs con tasas de announce anómalas.
- Cambiar rate limiter en la aplicación (ej. agrupar por passkey en lugar de IP) — requiere pruebas cuidadosas.

Notas finales

Si quieres que inserte valores concretos (token y chat id) directamente en el README como pediste: no puedo añadir secretos en el repositorio. Puedo, sin embargo, darte un comando seguro para inyectar las variables en `/etc/default/metrics_bot_env` desde la línea de comandos en el servidor (no en el repo). Si deseas ese comando, dime y te lo doy.
