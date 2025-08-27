@echo off
echo 🧪 UNIT3D Image Service - Depurador Windows
echo =============================================
echo.

:: Verificar Node.js
echo 🔍 Verificando dependencias...
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Node.js no encontrado
    echo    Descarga: https://nodejs.org/
    pause
    exit /b 1
) else (
    echo ✅ Node.js encontrado
)

npm --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ NPM no encontrado
    pause
    exit /b 1
) else (
    echo ✅ NPM encontrado
)

echo.
echo 📦 Verificando dependencias del proyecto...

:: Instalar dependencias si no existen
if not exist "node_modules" (
    echo 📥 Instalando dependencias npm...
    npm install
    if %errorlevel% neq 0 (
        echo ❌ Error instalando dependencias
        pause
        exit /b 1
    )
) else (
    echo ✅ Dependencias encontradas
)

echo.
echo 📁 Verificando directorios...

if not exist "storage" mkdir storage
if not exist "storage\temp" mkdir storage\temp
if not exist "logs" mkdir logs

echo ✅ Directorios creados

echo.
echo 🔧 Verificando archivo de configuración...

if not exist "config\config.json" (
    echo ⚠️ config.json no encontrado, creando archivo de desarrollo...
    echo {> config\config.json
    echo   "server": {>> config\config.json
    echo     "port": 3002,>> config\config.json
    echo     "host": "localhost",>> config\config.json
    echo     "name": "UNIT3D Image Service">> config\config.json
    echo   },>> config\config.json
    echo   "storage": {>> config\config.json
    echo     "path": "./storage/images",>> config\config.json
    echo     "tempPath": "./storage/temp",>> config\config.json
    echo     "publicUrl": "http://localhost:3002/image">> config\config.json
    echo   },>> config\config.json
    echo   "images": {>> config\config.json
    echo     "maxSize": "10MB",>> config\config.json
    echo     "maxSizeBytes": 10485760,>> config\config.json
    echo     "allowedTypes": ["image/jpeg", "image/png", "image/gif", "image/webp"],>> config\config.json
    echo     "allowedExtensions": [".jpg", ".jpeg", ".png", ".gif", ".webp"],>> config\config.json
    echo     "maxWidth": 2000,>> config\config.json
    echo     "maxHeight": 2000,>> config\config.json
    echo     "quality": 85>> config\config.json
    echo   },>> config\config.json
    echo   "security": {>> config\config.json
    echo     "rateLimit": {>> config\config.json
    echo       "windowMs": 900000,>> config\config.json
    echo       "max": 50>> config\config.json
    echo     },>> config\config.json
    echo     "allowedOrigins": ["http://localhost", "http://127.0.0.1"]>> config\config.json
    echo   },>> config\config.json
    echo   "features": {>> config\config.json
    echo     "enableCompression": true,>> config\config.json
    echo     "enableThumbnails": true,>> config\config.json
    echo     "enableStats": true>> config\config.json
    echo   },>> config\config.json
    echo   "logging": {>> config\config.json
    echo     "level": "info",>> config\config.json
    echo     "file": "./logs/image-service.log">> config\config.json
    echo   }>> config\config.json
    echo }>> config\config.json
    echo ✅ Configuración de desarrollo creada
) else (
    echo ✅ config.json encontrado
)

echo.
echo 🚀 Iniciando servidor de desarrollo...
echo.
echo 💡 El servidor se iniciará en: http://localhost:3002
echo 💡 Interfaz web: http://localhost:3002
echo 💡 Health check: http://localhost:3002/health
echo.
echo 🛑 Para detener el servidor presiona Ctrl+C
echo.

:: Iniciar servidor
node app.js

echo.
echo 🔚 Servidor detenido
pause