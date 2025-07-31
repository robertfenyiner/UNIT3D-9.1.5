@echo off
REM Hawke Minimal Theme Installation Script for UNIT3D 9.1.5
REM Run this script to install and configure the Hawke Minimal theme

echo 🎬 Installing Hawke Minimal Theme for UNIT3D 9.1.5...
echo ==================================================

REM Check if we're in the right directory
if not exist "artisan" (
    echo ❌ Error: This script must be run from the UNIT3D root directory
    pause
    exit /b 1
)

echo ✅ UNIT3D directory confirmed

REM Install npm dependencies
echo 📦 Installing npm dependencies...
call npm install --no-audit --no-fund

if %ERRORLEVEL% neq 0 (
    echo ❌ Failed to install npm dependencies
    pause
    exit /b 1
)

echo ✅ npm dependencies installed successfully

REM Build assets
echo 🔨 Building assets...
call npm run build

if %ERRORLEVEL% neq 0 (
    echo ❌ Failed to build assets
    pause
    exit /b 1
)

echo ✅ Assets built successfully

REM Clear Laravel caches (if PHP is available)
echo 🧹 Clearing Laravel caches...
where php >nul 2>nul
if %ERRORLEVEL% equ 0 (
    php artisan cache:clear
    php artisan view:clear
    php artisan config:clear
    echo ✅ Caches cleared
) else (
    echo ⚠️  PHP not found in PATH. Please run these commands manually:
    echo    php artisan cache:clear
    echo    php artisan view:clear
    echo    php artisan config:clear
)

echo.
echo 🎉 Hawke Minimal Theme Installation Complete!
echo ==================================================
echo.
echo 📋 Summary of changes:
echo   • Hawke Minimal theme files created
echo   • Home page updated with stats header
echo   • Navigation enhanced with Hawke styling
echo   • Assets compiled and cached
echo.
echo 🚀 Next steps:
echo   1. Start your Laravel server: php artisan serve
echo   2. Visit your site to see the new Hawke Minimal theme
echo   3. Customize colors in resources/sass/themes/_hawke-minimal.scss
echo.
echo 🎨 Theme features:
echo   • Cyan/teal color scheme inspired by Hawke-uno
echo   • Statistics dashboard in header
echo   • Glass morphism effects with backdrop blur
echo   • Enhanced navigation with user stats
echo   • Fully responsive design
echo   • Clean, minimalist interface
echo.
echo Happy torrenting! 🌊
echo.
pause
