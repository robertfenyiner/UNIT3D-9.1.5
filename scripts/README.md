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

Detalles operativos (muy detallado)

Este apartado documenta exactamente cómo está planteado el sistema, qué se ejecuta, cuándo y por qué se envían notificaciones, así como cómo interpretar y ajustar cada parte.

1) Flujo general y frecuencia

- Orquestación: `metrics_alerts.timer` (systemd) invoca `metrics_alerts.service` cada X tiempo. Por defecto el timer contiene:
  - OnBootSec=2min — primer disparo 2 minutos después del arranque del sistema
  - OnUnitActiveSec=5min — repite la ejecución cada 5 minutos
- Comportamiento: cada vez que se ejecuta el servicio, se lanza `/bin/bash /var/www/html/scripts/server_alerts_tracker.sh`. El script realiza comprobaciones y solo envía un mensaje a Telegram si detecta al menos una condición crítica.

2) Condiciones que disparan una alerta (detalladas)

El script mantiene una variable `SEND_ALERT` inicializada a false y la pone a true si se cumple alguna de las condiciones siguientes:

- Swap usada > `MAX_SWAP_MB` (por defecto 2048 MB). Ver variable `MAX_SWAP_MB` en `server_alerts_tracker.sh`.
- Uso de disco en `/` > `MAX_DISK_PCT` (por defecto 90%). Variable: `MAX_DISK_PCT`.
- Uso de memoria RAM (porcentaje) > `MAX_MEM_PCT` (por defecto 85%). Variable: `MAX_MEM_PCT`.
- Uso de CPU (porcentaje) > `MAX_CPU_PCT` (por defecto 85%). Variable: `MAX_CPU_PCT`.
- Servicios inactivos: el array `SERVICIOS=("nginx" "mysql" "redis" "php-fpm" "meilisearch")` se verifica con `systemctl is-active`. Si alguno no devuelve `active`, se marca alerta. (Sugerido: añade `php8.4-fpm` si tu sistema usa ese nombre.)
- Heurística del tracker (announces): el script toma un "sample" de las últimas `TAIL_LINES` líneas del `access.log` (por defecto 20000). A partir de ese sample calcula:
  - `ANNOUNCE_REQUESTS`: número de líneas que contienen `/announce/`.
  - `ANNOUNCE_429`: número de líneas que contienen el código `429` (busca la subcadena ` 429 ` en la línea).
  - `ANNOUNCE_UNIQUE_IPS`: número de IPs distintas que han llamado a `/announce/` en el sample.
  - Si `ANNOUNCE_REQUESTS > spike_threshold` (por defecto 1000) → disparo de alerta.
  - Si `ANNOUNCE_429 > 0` → disparo de alerta.

Nota: los valores de `TAIL_LINES` y `spike_threshold` son heurísticos y deben ajustarse a la carga normal de tu tracker. Para trackers con mucho tráfico sube `spike_threshold`.

3) Qué contiene la alerta enviada (estructura)

Cuando se dispara una alerta, el script envía un mensaje con (campos relevantes):
- Host y timestamp
- Razones (ej.: "High announce rate: 19006 announces in sample", "Servicio caído: php-fpm")
- Top procesos por CPU y por RAM (3 entradas)
- Conexiones activas y sesiones SSH
- Tracker quick stats (sobre el sample):
  - Announce requests (sample)
  - Unique IPs hitting announce (sample)
  - HTTP 429 in sample
- Top 10 IPs que llaman a `/announce/`, formato: `IP (count)`
- Top 10 User-Agents asociados a requests a `/announce/`, formato: `User-Agent (count)`
- Top 10 passkeys extraídos de la ruta `/announce/{passkey}`, formato: `passkey (count)`
- Resumen de Redis (si `redis-cli` disponible): algunas líneas de `INFO` y conteo de keys que contengan `announce`.
- PHP-FPM pools y `pm.max_children` sumados, número de procesos php-fpm y avg RSS por proceso.

4) Cómo se parsea el `access.log` (detalles técnicos)

- Lectura acotada: `tail -n ${TAIL_LINES} ${ACCESS_LOG}` usa el final del archivo para limitar I/O. Ajusta `TAIL_LINES` si tu log es enorme o si quieres una ventana menor.
- Identificación de announce: el script usa `grep -F "/announce/"` para buscar la ruta en la línea del access log. Asegúrate de que tu `access.log` contenga la ruta pública usada por el tracker.
- Extracción de IP: se asume que la IP es el primer campo de la línea (`awk '{print $1}'`). Si tu formato es distinto, adapta la extracción.
- Extracción de user-agent: usa `awk -F '"' '{print $6}'` suponiendo el formato combinado común de nginx: `IP - - [date] "GET /announce/... HTTP/1.1" status size "referrer" "user-agent"`.
- Extracción de passkey: se extrae con una expresión que toma la porción entre `/announce/` y el siguiente `?` o `/` en la URL (awk+sed). Ejemplo de extracción: de `/announce/abcd1234?info_hash=...` extrae `abcd1234`.

5) Ajustes recomendados para umbrales según capacidad (ejemplo basado en tu servidor)

- Tu servidor: 10 vCPU, ~8 GB RAM. Si `pm.max_children` por pool suma ~150 y avg RSS por proceso PHP es ~30–50 MB, la memoria consumida por PHP-FPM puede acercarse a 4.5–7.5 GB. Ajustes sugeridos:
  - Si avg RSS > 40 MB y sum(pm.max_children) > 120 → considera bajar `pm.max_children` por pool o aumentar memoria.
  - Para spike threshold: si tu tráfico normal es ~1k announces por sample, deja 5000; si normalmente es 100–500, deja 1000.

6) Cómo cambiar la frecuencia del envío

- Edita `/etc/systemd/system/metrics_alerts.timer` y cambia `OnUnitActiveSec=5min` por el intervalo que quieras (ej.: `1min`, `10min`, `1h`). Después ejecuta:

```bash
sudo systemctl daemon-reload
sudo systemctl restart metrics_alerts.timer
```

7) Reglas adicionales sugeridas (opcional)

- Alerta por única IP / passkey excesiva: si quieres que dispare cuando un único IP o passkey supere X requests en el sample, añade una comprobación como:

```bash
# ejemplo: chequear si el top IP tiene más de 1000 requests en el sample
TOP_IP_COUNT=$(echo "$SAMPLE" | grep -F "$ANNOUNCE_PATH" | awk '{print $1}' | sort | uniq -c | sort -rn | head -n1 | awk '{print $1}')
if [ "$TOP_IP_COUNT" -gt 1000 ]; then
  ALERT_MSG+="⚠️ IP abusive detected: $(echo "$SAMPLE" | grep -F "$ANNOUNCE_PATH" | awk '{print $1}' | sort | uniq -c | sort -rn | head -n1)\n"
  SEND_ALERT=true
fi
```

- Integración con fail2ban: crear una jail que bloquee IPs con demasiadas requests a `/announce` (requiere configurar un filtro y un action compatible con nginx access log).

8) Pruebas y depuración (comandos prácticos)

- Mostrar próximas ejecuciones del timer:
  ```bash
  systemctl list-timers --all | grep metrics_alerts
  ```

- Ver logs del último run y salida del script (útil para ver el JSON devuelto por Telegram):
  ```bash
  sudo journalctl -u metrics_alerts.service -n 200 --no-pager
  ```

- Ejecutar manualmente para depurar (recuerda que el script carga `/etc/default/metrics_bot_env`):
  ```bash
  sudo /bin/bash /var/www/html/scripts/server_alerts_tracker.sh
  ```

- Extraer top IPs y user-agents del access log (mismo método que usan los scripts):
  ```bash
  sudo tail -n 20000 /var/log/nginx/access.log | grep "/announce/" | awk '{print $1}' | sort | uniq -c | sort -rn | head -n 25
  sudo tail -n 20000 /var/log/nginx/access.log | grep "/announce/" | awk -F '"' '{print $6}' | sort | uniq -c | sort -rn | head -n 25
  ```

9) Formato de mensajes y limitaciones

- Mensajes se envían en texto plano. Evitamos `parse_mode=Markdown` por problemas con caracteres especiales en user-agents, passkeys o logs que rompen el parseo.
- Telegram limita la longitud de mensajes; por eso los tops están limitados a 10 entradas y concatenados en una sola línea por categoría. Si necesitas reportes más largos, la opción es subir un archivo (sendDocument) o publicar en un servicio de logs.

10) Rotación de token y seguridad

- Si el token fue expuesto, revócalo en @BotFather y genera uno nuevo. Luego actualiza `/etc/default/metrics_bot_env`.
- Mantén `/etc/default/metrics_bot_env` con permisos 600 y propietario root: `sudo chmod 600 /etc/default/metrics_bot_env && sudo chown root:root /etc/default/metrics_bot_env`.

11) Extensiones futuras (ideas)

- Enviar métricas a Prometheus Pushgateway en lugar de solo Telegram para tener gráficas y alertas más avanzadas.
- Exportar top offenders a un archivo CSV rotado y consumirlo con herramientas de BI.
- Implementar bloqueo automático (fail2ban) o reglas en nginx para throttling por passkey/IP.

Si quieres, puedo:
- añadir la comprobación por IP/passkey excesiva directamente al script ahora (disparo inmediato),
- crear un `systemd` timer para `server_info_tracker.sh` con ejecución diaria,
- preparar un ejemplo fail2ban filter + jail para bloquear IPs abusivas.

Indica cuál prefieres y lo implemento.
