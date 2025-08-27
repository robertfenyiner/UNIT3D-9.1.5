#!/bin/bash

echo "🎯 UNIT3D Image Service - Configuración Final (Paso 4)"
echo "======================================================"
echo ""

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Variables
SERVICE_NAME="unit3d-image-service"
SERVICE_DIR=$(pwd)
SERVICE_USER="www-data"

# Verificar que estamos en el directorio correcto
if [ ! -f "app.js" ]; then
    print_error "No se encontró app.js. Ejecuta desde el directorio del servicio."
    exit 1
fi

echo "🎯 Configuración final del servicio UNIT3D Image Service"
echo "Directorio: $SERVICE_DIR"
echo ""

# PASO 1: Verificar instalación previa
print_status "🔍 Verificando instalación previa..."

required_files=(
    "app.js"
    "package.json"
    "config/config.dev.json"
    "start-dev.sh"
    "test-quick.sh"
)

all_files_exist=true
for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        print_success "✓ $file"
    else
        print_error "✗ $file - FALTANTE"
        all_files_exist=false
    fi
done

if [ "$all_files_exist" != true ]; then
    print_error "Archivos faltantes. Ejecuta setup-ubuntu-step2.sh primero"
    exit 1
fi

print_success "Archivos básicos verificados"
echo ""

# PASO 2: Configurar servicio systemd
print_status "⚙️ Configurando servicio systemd..."

echo -n "¿Quieres configurar el servicio systemd para producción? (y/N): "
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    configure_systemd=true
else
    configure_systemd=false
    print_warning "Saltando configuración systemd (solo modo desarrollo)"
fi

if [ "$configure_systemd" = true ]; then
    print_status "Creando archivo de servicio systemd..."
    
    # Crear archivo de servicio
    sudo tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null << EOF
[Unit]
Description=UNIT3D Image Service
Documentation=https://github.com/your-repo/unit3d-image-service
After=network.target
Wants=network.target

[Service]
Type=simple
User=$SERVICE_USER
Group=$SERVICE_USER
WorkingDirectory=$SERVICE_DIR
ExecStart=/usr/bin/node app.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production
Environment=PORT=3002

# Security settings
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/var/www/html/storage /var/log/image-service $SERVICE_DIR/logs $SERVICE_DIR/storage

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=unit3d-image-service

# Resource limits
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOF
    
    print_success "Archivo de servicio systemd creado"
    
    # Configurar el servicio
    print_status "Configurando servicio systemd..."
    sudo systemctl daemon-reload
    sudo systemctl enable $SERVICE_NAME
    print_success "Servicio habilitado para inicio automático"
    
    # Configurar directorios de producción
    print_status "Configurando directorios de producción..."
    sudo mkdir -p /var/www/html/storage/images
    sudo mkdir -p /var/log/image-service
    
    # Configurar permisos
    sudo chown -R $SERVICE_USER:$SERVICE_USER "$SERVICE_DIR"
    sudo chown -R $SERVICE_USER:$SERVICE_USER /var/www/html/storage
    sudo chown -R $SERVICE_USER:$SERVICE_USER /var/log/image-service
    
    print_success "Directorios y permisos configurados"
fi
echo ""

# PASO 3: Crear scripts de gestión
print_status "📜 Creando scripts de gestión..."

# Script para iniciar en producción
if [ "$configure_systemd" = true ]; then
    cat > start-production.sh << 'EOF'
#!/bin/bash

echo "🚀 Iniciando UNIT3D Image Service en modo PRODUCCIÓN..."
echo ""

SERVICE_NAME="unit3d-image-service"

# Verificar que systemd esté configurado
if ! systemctl is-enabled $SERVICE_NAME &>/dev/null; then
    echo "❌ Servicio systemd no configurado"
    echo "Ejecuta: sudo ./setup-ubuntu-step4.sh"
    exit 1
fi

# Verificar OneDrive (si está configurado)
MOUNT_POINT="/var/www/html/storage/images"
if [ -f "mount-onedrive.sh" ]; then
    if ! mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
        echo "⚠️ OneDrive no está montado"
        echo -n "¿Montar OneDrive ahora? (Y/n): "
        read -r response
        if [[ ! "$response" =~ ^[Nn]$ ]]; then
            ./mount-onedrive.sh
        fi
    fi
fi

# Iniciar servicio
echo "🔄 Iniciando servicio systemd..."
sudo systemctl start $SERVICE_NAME

# Verificar estado
sleep 2
if systemctl is-active $SERVICE_NAME &>/dev/null; then
    echo "✅ Servicio iniciado exitosamente"
    echo ""
    echo "📊 Estado del servicio:"
    systemctl status $SERVICE_NAME --no-pager -l
    echo ""
    echo "🌐 URLs:"
    echo "   Health check: http://localhost:3002/health"
    echo "   Interfaz web: http://localhost:3002"
    echo ""
    echo "📜 Ver logs: sudo journalctl -u $SERVICE_NAME -f"
else
    echo "❌ Error iniciando el servicio"
    echo ""
    echo "Ver logs de error:"
    echo "sudo journalctl -u $SERVICE_NAME --no-pager -l"
    exit 1
fi
EOF
    chmod +x start-production.sh
    print_success "Script de producción creado: start-production.sh"
fi

# Script de status
cat > status.sh << 'EOF'
#!/bin/bash

echo "📊 UNIT3D Image Service - Estado del Sistema"
echo "============================================="
echo ""

SERVICE_NAME="unit3d-image-service"

# Verificar si systemd está configurado
if systemctl is-enabled $SERVICE_NAME &>/dev/null 2>&1; then
    echo "🔧 MODO: Producción (systemd)"
    echo ""
    
    # Estado del servicio
    echo "📋 Estado del servicio:"
    if systemctl is-active $SERVICE_NAME &>/dev/null; then
        echo "   ✅ Estado: ACTIVO"
    else
        echo "   ❌ Estado: INACTIVO"
    fi
    
    echo "   🔄 Habilitado: $(systemctl is-enabled $SERVICE_NAME 2>/dev/null || echo 'No')"
    echo ""
    
    # PID y recursos
    if systemctl is-active $SERVICE_NAME &>/dev/null; then
        main_pid=$(systemctl show $SERVICE_NAME --property=MainPID --value 2>/dev/null)
        if [ "$main_pid" != "0" ] && [ -n "$main_pid" ]; then
            echo "🆔 PID principal: $main_pid"
            if ps -p $main_pid -o pid,ppid,%cpu,%mem,cmd --no-headers 2>/dev/null; then
                echo ""
            fi
        fi
    fi
    
else
    echo "🔧 MODO: Desarrollo (manual)"
    echo ""
    
    # Buscar proceso manual
    if pgrep -f "node app.js" > /dev/null; then
        echo "   ✅ Estado: CORRIENDO (manual)"
        echo "   🆔 PIDs: $(pgrep -f 'node app.js' | tr '\n' ' ')"
    else
        echo "   ❌ Estado: NO CORRIENDO"
    fi
fi

# Verificar puerto
echo ""
echo "🌐 Conectividad:"
if netstat -tuln 2>/dev/null | grep -q ":3002 "; then
    echo "   ✅ Puerto 3002: ABIERTO"
    
    # Probar health check
    if curl -s http://localhost:3002/health > /dev/null 2>&1; then
        echo "   ✅ Health check: OK"
    else
        echo "   ❌ Health check: ERROR"
    fi
else
    echo "   ❌ Puerto 3002: CERRADO"
fi

# Verificar OneDrive
MOUNT_POINT="/var/www/html/storage/images"
echo ""
echo "☁️ OneDrive:"
if mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
    echo "   ✅ Montado en: $MOUNT_POINT"
    
    # Verificar escritura
    test_file="$MOUNT_POINT/.write_test_$$"
    if echo "test" > "$test_file" 2>/dev/null; then
        rm -f "$test_file" 2>/dev/null
        echo "   ✅ Escritura: OK"
    else
        echo "   ❌ Escritura: ERROR"
    fi
else
    echo "   ❌ No montado"
    if [ -f "mount-onedrive.sh" ]; then
        echo "   💡 Para montar: ./mount-onedrive.sh"
    fi
fi

# Verificar logs recientes
echo ""
echo "📜 Logs recientes:"
if systemctl is-enabled $SERVICE_NAME &>/dev/null 2>&1; then
    echo "   Systemd journal (últimas 3 líneas):"
    sudo journalctl -u $SERVICE_NAME --no-pager -n 3 2>/dev/null | sed 's/^/   /' || echo "   (No disponible)"
else
    if [ -f "logs/image-service.log" ]; then
        echo "   Archivo de log (últimas 3 líneas):"
        tail -n 3 logs/image-service.log 2>/dev/null | sed 's/^/   /' || echo "   (Vacío)"
    else
        echo "   (No hay logs disponibles)"
    fi
fi

echo ""
echo "============================================="
EOF

chmod +x status.sh
print_success "Script de estado creado: status.sh"

# Script de stop
cat > stop.sh << 'EOF'
#!/bin/bash

echo "🛑 Deteniendo UNIT3D Image Service..."

SERVICE_NAME="unit3d-image-service"

# Detener servicio systemd si está configurado
if systemctl is-enabled $SERVICE_NAME &>/dev/null 2>&1; then
    echo "🔄 Deteniendo servicio systemd..."
    sudo systemctl stop $SERVICE_NAME
    
    if systemctl is-active $SERVICE_NAME &>/dev/null; then
        echo "⚠️ El servicio sigue activo, forzando detención..."
        sudo systemctl kill $SERVICE_NAME
    fi
    echo "✅ Servicio systemd detenido"
fi

# Buscar y matar procesos manuales
if pgrep -f "node app.js" > /dev/null; then
    echo "🔄 Deteniendo procesos manuales..."
    pkill -f "node app.js"
    sleep 2
    
    if pgrep -f "node app.js" > /dev/null; then
        echo "⚠️ Procesos aún ejecutándose, forzando terminación..."
        pkill -9 -f "node app.js"
    fi
    echo "✅ Procesos manuales detenidos"
fi

# Verificar que esté detenido
if ! pgrep -f "node app.js" > /dev/null && ! netstat -tuln 2>/dev/null | grep -q ":3002 "; then
    echo "✅ UNIT3D Image Service completamente detenido"
else
    echo "⚠️ Algunos procesos pueden seguir ejecutándose"
fi
EOF

chmod +x stop.sh
print_success "Script de detención creado: stop.sh"
echo ""

# PASO 4: Crear script de prueba completa
print_status "🧪 Creando script de prueba completa..."

cat > test-full.sh << 'EOF'
#!/bin/bash

echo "🧪 UNIT3D Image Service - Prueba Completa"
echo "=========================================="
echo ""

# Variables
SERVICE_NAME="unit3d-image-service"
BASE_URL="http://localhost:3002"
MOUNT_POINT="/var/www/html/storage/images"

test_count=0
passed_count=0

run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -n "🔍 $test_name... "
    ((test_count++))
    
    if eval "$test_command" &>/dev/null; then
        echo "✅ PASS"
        ((passed_count++))
    else
        echo "❌ FAIL"
    fi
}

echo "🔧 VERIFICACIONES DEL SISTEMA:"
echo ""

# Verificar archivos
run_test "Archivos del servicio" "[ -f app.js ] && [ -f package.json ]"
run_test "Dependencias instaladas" "[ -d node_modules ]"
run_test "Configuración disponible" "[ -f config/config.dev.json ] || [ -f config/config.json ]"

echo ""
echo "🌐 VERIFICACIONES DE CONECTIVIDAD:"
echo ""

# Verificar servidor
run_test "Servidor respondiendo" "curl -s $BASE_URL/health"
run_test "Health check válido" "curl -s $BASE_URL/health | grep -q '\"status\":\"healthy\"'"
run_test "Interfaz web cargando" "curl -s $BASE_URL/ | grep -q 'UNIT3D Image Uploader'"

echo ""
echo "☁️ VERIFICACIONES DE STORAGE:"
echo ""

# Verificar storage
if [ -d "$MOUNT_POINT" ] && mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
    run_test "OneDrive montado" "mountpoint -q $MOUNT_POINT"
    run_test "OneDrive escribible" "echo test > $MOUNT_POINT/.test.$$ && rm -f $MOUNT_POINT/.test.$$"
    storage_type="OneDrive"
else
    run_test "Storage local disponible" "[ -d storage/images ]"
    run_test "Storage local escribible" "echo test > storage/images/.test.$$ && rm -f storage/images/.test.$$"
    storage_type="Local"
fi

echo ""
echo "🎯 VERIFICACIÓN DE ENDPOINTS DE API:"
echo ""

# Verificar APIs específicas
run_test "Endpoint /health" "curl -s $BASE_URL/health | grep -q success"
run_test "Endpoint /manage/stats" "curl -s $BASE_URL/manage/stats"

echo ""
echo "=========================================="
echo "📊 RESUMEN DE PRUEBAS:"
echo ""
echo "✅ Pasadas: $passed_count/$test_count"
echo "❌ Fallidas: $((test_count - passed_count))/$test_count"
echo "💾 Storage: $storage_type"

if [ $passed_count -eq $test_count ]; then
    echo ""
    echo "🎉 TODAS LAS PRUEBAS PASARON"
    echo ""
    echo "🚀 El servicio está funcionando correctamente"
    echo "🌐 Interfaz web: $BASE_URL"
    echo "📊 Health check: $BASE_URL/health"
else
    echo ""
    echo "⚠️ ALGUNAS PRUEBAS FALLARON"
    echo ""
    echo "Verifica:"
    echo "1. Que el servidor esté corriendo (./start-dev.sh o ./start-production.sh)"
    echo "2. Configuración de red y firewall"
    echo "3. Permisos de archivos y directorios"
    echo "4. Estado de OneDrive si está configurado"
fi

echo ""
echo "Para más información: ./status.sh"
echo "=========================================="
EOF

chmod +x test-full.sh
print_success "Script de prueba completa creado: test-full.sh"
echo ""

# PASO 5: Crear documentación rápida
print_status "📚 Creando documentación de uso..."

cat > USAGE.md << 'EOF'
# 🚀 UNIT3D Image Service - Guía de Uso

## 🎯 Comandos Principales

### Desarrollo
```bash
# Iniciar en modo desarrollo
./start-dev.sh

# Prueba rápida
./test-quick.sh
```

### Producción (si systemd está configurado)
```bash
# Iniciar en modo producción
./start-production.sh

# Detener servicio
./stop.sh

# Ver estado
./status.sh
```

### OneDrive (si está configurado)
```bash
# Montar OneDrive
./mount-onedrive.sh

# Desmontar OneDrive
./unmount-onedrive.sh

# Probar OneDrive
./test-onedrive.sh
```

### Pruebas y Diagnóstico
```bash
# Prueba completa del sistema
./test-full.sh

# Estado detallado del servicio
./status.sh

# Ver logs (producción)
sudo journalctl -u unit3d-image-service -f

# Ver logs (desarrollo)
tail -f logs/image-service.log
```

## 🌐 URLs Importantes

- **Interfaz web**: http://localhost:3002
- **Health check**: http://localhost:3002/health
- **Estadísticas**: http://localhost:3002/manage/stats
- **API upload**: http://localhost:3002/upload

## 🔧 Configuración

### Desarrollo
- Archivo: `config/config.dev.json`
- Storage: `./storage/images` (local)
- Logs: `./logs/image-service.log`

### Producción
- Archivo: `config/config.json`
- Storage: `/var/www/html/storage/images` (OneDrive montado)
- Logs: systemd journal + `/var/log/image-service/`

## 🚨 Solución de Problemas

### Servidor no inicia
```bash
# Verificar puerto
netstat -tuln | grep 3002

# Ver logs de error
./status.sh
```

### OneDrive no funciona
```bash
# Verificar configuración de rclone
rclone config

# Probar conexión
rclone ls onedrive-images:

# Remontar
./unmount-onedrive.sh && ./mount-onedrive.sh
```

### Permisos de archivo
```bash
# Arreglar permisos básicos
chmod -R 755 storage/
chmod +x *.sh

# Arreglar permisos de producción (requiere sudo)
sudo chown -R www-data:www-data /var/www/html/storage
```

## 📋 Integración con UNIT3D

1. El archivo `resources/views/torrent/create.blade.php` ya está modificado
2. Usa `resources/js/vendor/unit3d-uploader.js` en lugar de imgbb.js
3. Compatible con la API existente de imgbb

¡El servicio está listo para usar! 🎉
EOF

print_success "Documentación creada: USAGE.md"
echo ""

# RESUMEN FINAL
echo "========================================================="
echo "🎯 CONFIGURACIÓN FINAL COMPLETADA"
echo "========================================================="
echo ""

if [ "$configure_systemd" = true ]; then
    print_success "✅ Servicio systemd configurado"
    echo "   Servicio: $SERVICE_NAME"
    echo "   Usuario: $SERVICE_USER"
    echo "   Directorio: $SERVICE_DIR"
else
    print_success "✅ Modo desarrollo configurado"
fi

print_success "✅ Scripts de gestión creados:"
echo "   - status.sh          (estado del sistema)"
echo "   - stop.sh           (detener servicio)"
echo "   - test-full.sh      (prueba completa)"
if [ "$configure_systemd" = true ]; then
    echo "   - start-production.sh (iniciar producción)"
fi

print_success "✅ Documentación lista: USAGE.md"
echo ""

echo "🚀 PRÓXIMOS PASOS RECOMENDADOS:"
echo ""
echo "1. Verificar el estado actual:"
echo "   ./status.sh"
echo ""
echo "2. Iniciar el servicio:"
if [ "$configure_systemd" = true ]; then
    echo "   ./start-production.sh    (producción)"
else
    echo "   ./start-dev.sh          (desarrollo)"
fi
echo ""
echo "3. Ejecutar prueba completa:"
echo "   ./test-full.sh"
echo ""
echo "4. Abrir en navegador:"
echo "   http://localhost:3002"
echo ""

if [ -f "mount-onedrive.sh" ]; then
    print_warning "⚠️ Si configuraste OneDrive, asegúrate de montarlo:"
    echo "   ./mount-onedrive.sh"
    echo ""
fi

print_success "🎉 ¡UNIT3D Image Service está listo para usar!"
echo ""

exit 0