#!/bin/bash

# Hawke Minimal Theme Installation Script for UNIT3D 9.1.5
# Run this script to install and configure the Hawke Minimal theme

echo "🎬 Installing Hawke Minimal Theme for UNIT3D 9.1.5..."
echo "=================================================="

# Check if we're in the right directory
if [ ! -f "artisan" ]; then
    echo "❌ Error: This script must be run from the UNIT3D root directory"
    exit 1
fi

echo "✅ UNIT3D directory confirmed"

# Install npm dependencies
echo "📦 Installing npm dependencies..."
npm install --no-audit --no-fund

if [ $? -eq 0 ]; then
    echo "✅ npm dependencies installed successfully"
else
    echo "❌ Failed to install npm dependencies"
    exit 1
fi

# Build assets
echo "🔨 Building assets..."
npm run build

if [ $? -eq 0 ]; then
    echo "✅ Assets built successfully"
else
    echo "❌ Failed to build assets"
    exit 1
fi

# Clear Laravel caches
echo "🧹 Clearing Laravel caches..."
php artisan cache:clear
php artisan view:clear
php artisan config:clear

echo "✅ Caches cleared"

# Set permissions (if needed)
echo "🔐 Setting permissions..."
chmod -R 755 storage
chmod -R 755 bootstrap/cache

echo "✅ Permissions set"

echo ""
echo "🎉 Hawke Minimal Theme Installation Complete!"
echo "=================================================="
echo ""
echo "📋 Summary of changes:"
echo "  • Hawke Minimal theme files created"
echo "  • Home page updated with stats header"
echo "  • Navigation enhanced with Hawke styling"
echo "  • Assets compiled and cached"
echo ""
echo "🚀 Next steps:"
echo "  1. Start your Laravel server: php artisan serve"
echo "  2. Visit your site to see the new Hawke Minimal theme"
echo "  3. Customize colors in resources/sass/themes/_hawke-minimal.scss"
echo ""
echo "🎨 Theme features:"
echo "  • Cyan/teal color scheme inspired by Hawke-uno"
echo "  • Statistics dashboard in header"
echo "  • Glass morphism effects with backdrop blur"
echo "  • Enhanced navigation with user stats"
echo "  • Fully responsive design"
echo "  • Clean, minimalist interface"
echo ""
echo "Happy torrenting! 🌊"
