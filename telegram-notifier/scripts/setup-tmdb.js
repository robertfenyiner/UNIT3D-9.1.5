#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

console.log('🎬 Configuración de TMDB API para pósters de películas/series\n');

const configPath = path.join(__dirname, '..', 'config', 'config.json');

try {
    const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    
    console.log('📋 Estado actual:');
    if (config.tmdb && config.tmdb.api_key && config.tmdb.api_key !== 'TU_TMDB_API_KEY_AQUI') {
        console.log('✅ API Key de TMDB configurada');
        console.log('✅ Las imágenes de pósters están disponibles');
    } else {
        console.log('❌ API Key de TMDB no configurada');
        console.log('❌ Las notificaciones solo mostrarán texto');
    }
    
    console.log('\n🔧 Para habilitar imágenes de pósters:');
    console.log('\n1️⃣ Obtener API Key gratuita de TMDB:');
    console.log('   • Registrarse en: https://www.themoviedb.org/signup');
    console.log('   • Ir a configuración: https://www.themoviedb.org/settings/api');
    console.log('   • Solicitar API Key (aprobación inmediata)');
    console.log('   • Copiar la "API Key (v3 auth)"');
    
    console.log('\n2️⃣ Configurar en el archivo:');
    console.log('   nano config/config.json');
    console.log('   Buscar: "api_key": "TU_TMDB_API_KEY_AQUI"');
    console.log('   Cambiar por: "api_key": "tu_api_key_real"');
    
    console.log('\n3️⃣ Reiniciar servicio:');
    console.log('   sudo systemctl restart telegram-notifier');
    
    console.log('\n💡 Beneficios de las imágenes:');
    console.log('   ✅ Pósters de películas y series automáticos');
    console.log('   ✅ Mensajes más atractivos visualmente');
    console.log('   ✅ Mejor experiencia para usuarios');
    console.log('   ✅ Sin costo adicional (API gratuita)');
    
    console.log('\n🎯 Ejemplo de API Key válida:');
    console.log('   abc123def456ghi789jkl012mno345pq');
    
    if (!config.features.include_poster_images) {
        console.log('\n⚠️  NOTA: La opción "include_poster_images" está deshabilitada');
        console.log('   Cambiar a true en config/config.json para habilitar imágenes');
    }
    
} catch (error) {
    console.error('❌ Error leyendo configuración:', error.message);
    process.exit(1);
}