#!/usr/bin/env node

// Script para actualizar el formato de mensajes a uno más avanzado con metadata rica

const fs = require('fs');
const path = require('path');

console.log('🎨 Creando formato avanzado de mensajes...\n');

const enhancedFormatFunction = `// Función para formatear el mensaje de Telegram con formato avanzado
function formatMessage(torrent) {
    const categoryEmoji = getCategoryEmoji(torrent.category);
    
    // Crear mensaje con formato rico
    let message = '';
    
    // Header con emoji de categoría
    message += categoryEmoji + ' NUEVO TORRENT APROBADO\\n';
    message += '━━━━━━━━━━━━━━━━━━━━━━━\\n\\n';
    
    // Información principal del torrent
    message += '📁 ' + torrent.name + '\\n\\n';
    
    // Metadata en formato tabla
    message += '👤 Uploader: ' + torrent.user + '\\n';
    message += '📂 Categoría: ' + torrent.category + '\\n';
    message += '💾 Tamaño: ' + torrent.size + '\\n';
    
    // Agregar información de calidad y resolución si está disponible
    if (torrent.name) {
        const quality = extractQuality(torrent.name);
        const source = extractSource(torrent.name);
        const codec = extractCodec(torrent.name);
        const year = extractYear(torrent.name);
        
        if (quality) message += '🎥 Calidad: ' + quality + '\\n';
        if (source) message += '💿 Fuente: ' + source + '\\n';
        if (codec) message += '🔧 Códec: ' + codec + '\\n';
        if (year) message += '📅 Año: ' + year + '\\n';
    }
    
    message += '\\n━━━━━━━━━━━━━━━━━━━━━━━\\n';
    
    // Enlaces externos
    message += '🔗 ENLACES:\\n';
    message += '• Descargar: ' + config.tracker.base_url + '/torrents/' + torrent.torrent_id + '\\n';
    
    if (config.features.include_imdb_link && torrent.imdb && torrent.imdb > 0) {
        message += '• IMDB: https://imdb.com/title/tt' + String(torrent.imdb).padStart(7, '0') + '\\n';
    }
    
    if (config.features.include_tmdb_info && torrent.tmdb_movie_id && torrent.tmdb_movie_id > 0) {
        message += '• TMDB: https://www.themoviedb.org/movie/' + torrent.tmdb_movie_id + '\\n';
    }
    
    // Footer con timestamp y tracker info
    message += '\\n━━━━━━━━━━━━━━━━━━━━━━━\\n';
    message += '🏷️ ' + config.tracker.name + '\\n';
    message += '🕒 ' + new Date().toLocaleString('es-ES', { 
        timeZone: 'America/Mexico_City',
        day: '2-digit',
        month: '2-digit', 
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });
    
    return message;
}

// Funciones auxiliares para extraer información del nombre del torrent
function extractQuality(name) {
    const qualities = ['2160p', '1080p', '720p', '480p', '4K', 'UHD'];
    for (const quality of qualities) {
        if (name.toUpperCase().includes(quality.toUpperCase())) {
            return quality;
        }
    }
    return null;
}

function extractSource(name) {
    const sources = ['BluRay', 'WEBRip', 'WEB-DL', 'HDTV', 'DVDRip', 'BDRip', 'REMUX'];
    const nameUpper = name.toUpperCase();
    for (const source of sources) {
        if (nameUpper.includes(source.toUpperCase())) {
            return source;
        }
    }
    return null;
}

function extractCodec(name) {
    const codecs = ['x265', 'x264', 'HEVC', 'H.265', 'H.264', 'AV1'];
    const nameUpper = name.toUpperCase();
    for (const codec of codecs) {
        if (nameUpper.includes(codec.toUpperCase())) {
            return codec;
        }
    }
    return null;
}

function extractYear(name) {
    const yearMatch = name.match(/(19|20)\\d{2}/);
    return yearMatch ? yearMatch[0] : null;
}`;

console.log('🎨 Formato avanzado creado con las siguientes características:');
console.log('   ✅ Header y footer con separadores visuales');
console.log('   ✅ Extracción automática de calidad (1080p, 4K, etc.)');
console.log('   ✅ Detección de fuente (BluRay, WEBRip, etc.)');
console.log('   ✅ Identificación de códec (x265, HEVC, etc.)');
console.log('   ✅ Extracción de año de la película');
console.log('   ✅ Formato de tabla para metadata');
console.log('   ✅ Enlaces organizados por secciones');
console.log('   ✅ Timestamp formateado para México');
console.log('');

// Escribir a un archivo temporal para revisión
const outputFile = path.join(__dirname, '..', 'enhanced-format-preview.js');
fs.writeFileSync(outputFile, enhancedFormatFunction, 'utf8');

console.log('📄 Vista previa guardada en: enhanced-format-preview.js');
console.log('');
console.log('🎯 El nuevo formato mostrará mensajes como:');
console.log(`
🎬 NUEVO TORRENT APROBADO
━━━━━━━━━━━━━━━━━━━━━━━

📁 Avatar.The.Way.of.Water.2022.2160p.UHD.BluRay.x265-EXAMPLE

👤 Uploader: uploader_pro
📂 Categoría: Movies  
💾 Tamaño: 25.4 GB
🎥 Calidad: 2160p
💿 Fuente: BluRay
🔧 Códec: x265
📅 Año: 2022

━━━━━━━━━━━━━━━━━━━━━━━
🔗 ENLACES:
• Descargar: https://lat-team.xyz/torrents/123456
• IMDB: https://imdb.com/title/tt1630029
• TMDB: https://www.themoviedb.org/movie/76600

━━━━━━━━━━━━━━━━━━━━━━━
🏷️ LAT-TEAM
🕒 25/08/2024, 15:30
`);

console.log('¿Deseas aplicar este formato? Ejecuta:');
console.log('   node scripts/apply-enhanced-format.js');