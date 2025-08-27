#!/bin/bash

# Script de prueba completa para UNIT3D Image Service
# Verifica que todos los componentes funcionen correctamente

set -e

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

SERVICE_URL="http://localhost:3002"
TEST_IMAGE_URL="https://via.placeholder.com/500x300/0066CC/FFFFFF.png?text=Test+Image"

echo "🧪 Iniciando pruebas del UNIT3D Image Service"
echo "================================================"

# Función para verificar respuesta HTTP
check_endpoint() {
    local endpoint=$1
    local expected_status=$2
    local description=$3
    
    echo -n "🔍 $description... "
    
    if response=$(curl -s -w "%{http_code}" -o /tmp/test_response.json "$SERVICE_URL$endpoint"); then
        status_code="${response: -3}"
        
        if [ "$status_code" -eq "$expected_status" ]; then
            echo -e "${GREEN}✅ OK (HTTP $status_code)${NC}"
            return 0
        else
            echo -e "${RED}❌ Error (HTTP $status_code, esperado $expected_status)${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ Error de conexión${NC}"
        return 1
    fi
}

# Función para verificar servicio systemd
check_service() {
    echo -n "🔧 Verificando servicio systemd... "
    
    if systemctl is-active image-service >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Servicio activo${NC}"
    elif systemctl is-enabled image-service >/dev/null 2>&1; then
        echo -e "${RED}⚠️ Servicio habilitado pero no activo${NC}"
        echo "   Iniciando servicio..."
        sudo systemctl start image-service
        sleep 3
        if systemctl is-active image-service >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Servicio iniciado correctamente${NC}"
        else
            echo -e "${RED}❌ No se pudo iniciar el servicio${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ Servicio no encontrado o no habilitado${NC}"
        return 1
    fi
}

# Función para verificar directorios
check_directories() {
    echo "📁 Verificando estructura de directorios:"
    
    directories=(
        "/var/www/html/image-service"
        "/var/www/html/storage/images"
        "/var/www/html/storage/images/thumbs"
        "/var/www/html/image-service/storage/temp"
        "/var/www/html/image-service/logs"
    )
    
    for dir in "${directories[@]}"; do
        echo -n "   $dir... "
        if [ -d "$dir" ]; then
            if [ -w "$dir" ]; then
                echo -e "${GREEN}✅ Existe y escribible${NC}"
            else
                echo -e "${RED}⚠️ Existe pero no escribible${NC}"
            fi
        else
            echo -e "${RED}❌ No existe${NC}"
        fi
    done
}

# Función para verificar OneDrive mount
check_onedrive() {
    echo -n "☁️ Verificando mount de OneDrive... "
    
    if mountpoint -q /var/www/html/storage/images; then
        echo -e "${GREEN}✅ OneDrive montado${NC}"
        
        # Verificar escritura
        echo -n "   Probando escritura... "
        test_file="/var/www/html/storage/images/.test_$(date +%s).txt"
        if echo "test" > "$test_file" 2>/dev/null; then
            rm -f "$test_file"
            echo -e "${GREEN}✅ Escritura OK${NC}"
        else
            echo -e "${RED}❌ Error de escritura${NC}"
        fi
    else
        echo -e "${RED}❌ OneDrive no montado${NC}"
        echo "   Ejecuta: sudo bash scripts/setup-rclone.sh"
    fi
}

# Función para probar subida de imagen
test_upload() {
    echo "📤 Probando subida de imagen desde URL..."
    
    # Crear archivo de prueba temporal
    temp_image="/tmp/test_image_$(date +%s).png"
    
    # Generar imagen de prueba simple (requiere ImageMagick)
    if command -v convert >/dev/null 2>&1; then
        convert -size 200x200 xc:blue -pointsize 20 -fill white -gravity center \
                -annotate +0+0 "TEST\n$(date +%H:%M)" "$temp_image"
    elif command -v wget >/dev/null 2>&1; then
        wget -q -O "$temp_image" "$TEST_IMAGE_URL" || {
            echo "❌ No se pudo descargar imagen de prueba"
            return 1
        }
    else
        echo "⚠️ No se puede crear imagen de prueba (falta ImageMagick o wget)"
        return 1
    fi
    
    # Probar subida
    echo -n "   Subiendo imagen... "
    
    if response=$(curl -s -X POST -F "images=@$temp_image" "$SERVICE_URL/upload"); then
        if echo "$response" | jq -e '.success' >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Subida exitosa${NC}"
            
            # Extraer URL de la imagen
            image_url=$(echo "$response" | jq -r '.data.url // .data.image.url // empty' 2>/dev/null)
            
            if [ -n "$image_url" ]; then
                echo "   URL: $image_url"
                
                # Verificar que la imagen es accesible
                echo -n "   Verificando acceso a imagen... "
                if curl -s -I "$image_url" | grep -q "200 OK"; then
                    echo -e "${GREEN}✅ Imagen accesible${NC}"
                else
                    echo -e "${RED}❌ Imagen no accesible${NC}"
                fi
            fi
        else
            echo -e "${RED}❌ Error en la subida${NC}"
            echo "$response" | jq '.error // .message // .' 2>/dev/null || echo "$response"
        fi
    else
        echo -e "${RED}❌ Error de conexión en subida${NC}"
    fi
    
    # Limpiar archivo temporal
    rm -f "$temp_image"
}

# Función para verificar dependencias
check_dependencies() {
    echo "🔧 Verificando dependencias:"
    
    deps=(
        "node:Node.js"
        "npm:NPM"
        "curl:cURL"
        "jq:jq (JSON processor)"
        "rclone:rclone"
    )
    
    for dep in "${deps[@]}"; do
        cmd="${dep%%:*}"
        name="${dep##*:}"
        
        echo -n "   $name... "
        if command -v "$cmd" >/dev/null 2>&1; then
            version=$($cmd --version 2>/dev/null | head -1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1 || echo "instalado")
            echo -e "${GREEN}✅ $version${NC}"
        else
            echo -e "${RED}❌ No encontrado${NC}"
            if [ "$cmd" = "jq" ]; then
                echo "      Instalar con: sudo apt-get install jq"
            fi
        fi
    done
}

# Función principal de pruebas
run_tests() {
    local failed=0
    
    # Verificar dependencias
    check_dependencies
    echo ""
    
    # Verificar servicio
    check_service || ((failed++))
    echo ""
    
    # Verificar directorios
    check_directories
    echo ""
    
    # Verificar OneDrive
    check_onedrive
    echo ""
    
    # Esperar a que el servicio esté listo
    echo -n "⏳ Esperando que el servicio esté listo... "
    for i in {1..10}; do
        if curl -s "$SERVICE_URL/health" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Listo${NC}"
            break
        fi
        sleep 1
        echo -n "."
    done
    echo ""
    
    # Verificar endpoints
    echo "🌐 Verificando endpoints:"
    check_endpoint "/health" 200 "Health check" || ((failed++))
    check_endpoint "/nonexistent" 404 "Manejo de 404" || ((failed++))
    check_endpoint "/" 200 "Interfaz web" || ((failed++))
    echo ""
    
    # Probar subida si todo lo anterior funciona
    if [ $failed -eq 0 ]; then
        test_upload || ((failed++))
    else
        echo "⚠️ Saltando prueba de subida debido a errores previos"
    fi
    
    echo ""
    echo "================================================"
    
    if [ $failed -eq 0 ]; then
        echo -e "${GREEN}🎉 Todas las pruebas pasaron exitosamente!${NC}"
        echo ""
        echo "✅ El servicio está funcionando correctamente"
        echo "🌐 Interfaz web: $SERVICE_URL"
        echo "📊 Estadísticas: $SERVICE_URL/manage/stats"
        echo "📋 Health check: $SERVICE_URL/health"
        echo ""
        return 0
    else
        echo -e "${RED}❌ $failed prueba(s) fallaron${NC}"
        echo ""
        echo "🔍 Para revisar logs:"
        echo "   sudo journalctl -u image-service -f"
        echo ""
        echo "🔧 Para reiniciar el servicio:"
        echo "   sudo systemctl restart image-service"
        echo ""
        return 1
    fi
}

# Ejecutar pruebas
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Uso: $0 [--quick]"
    echo ""
    echo "Opciones:"
    echo "  --quick    Ejecutar solo pruebas básicas"
    echo "  --help     Mostrar esta ayuda"
    exit 0
fi

if [ "$1" = "--quick" ]; then
    echo "🏃 Modo rápido: solo pruebas básicas"
    check_service
    check_endpoint "/health" 200 "Health check básico"
else
    run_tests
fi

exit $?