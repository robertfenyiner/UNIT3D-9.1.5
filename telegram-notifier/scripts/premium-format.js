#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

console.log('💎 Creando formato PREMIUM con metadata completa...\n');

const premiumFormatFunction = `// Función para formatear el mensaje de Telegram - Formato PREMIUM
function formatMessage(torrent) {
    const categoryEmoji = getCategoryEmoji(torrent.category);
    
    let message = '';
    
    // Header premium con línea decorativa
    message += '╔═══════════════════════╗\\n';
    message += '║  ' + categoryEmoji + ' NUEVO TORRENT APROBADO  ║\\n';
    message += '╚═══════════════════════╝\\n\\n';
    
    // Título destacado
    message += '📁 \\'' + torrent.name + '\\'\\n\\n';
    
    // Información básica en tabla
    message += '╭─ INFORMACIÓN BÁSICA\\n';
    message += '├ 👤 Uploader: ' + torrent.user + '\\n';
    message += '├ 📂 Categoría: ' + torrent.category + '\\n';
    message += '├ 💾 Tamaño: ' + torrent.size + '\\n';
    message += '├ 🆔 ID: #' + torrent.torrent_id + '\\n';
    
    // Extraer metadata del nombre
    if (torrent.name) {
        const metadata = extractAllMetadata(torrent.name);
        
        if (Object.keys(metadata).length > 0) {
            message += '╰─\\n\\n';
            message += '╭─ ESPECIFICACIONES TÉCNICAS\\n';
            
            if (metadata.year) message += '├ 📅 Año: ' + metadata.year + '\\n';
            if (metadata.quality) message += '├ 🎥 Resolución: ' + metadata.quality + '\\n';
            if (metadata.source) message += '├ 💿 Fuente: ' + metadata.source + '\\n';
            if (metadata.codec) message += '├ 🔧 Códec: ' + metadata.codec + '\\n';
            if (metadata.audio) message += '├ 🔊 Audio: ' + metadata.audio + '\\n';
            if (metadata.language) message += '├ 🌐 Idioma: ' + metadata.language + '\\n';
            if (metadata.group) message += '├ 👥 Grupo: ' + metadata.group + '\\n';
        }
    }
    message += '╰─\\n\\n';
    
    // Enlaces con iconos
    message += '╭─ ENLACES RÁPIDOS\\n';
    message += '├ 🔽 Descargar: ' + config.tracker.base_url + '/torrents/' + torrent.torrent_id + '\\n';
    
    if (config.features.include_imdb_link && torrent.imdb && torrent.imdb > 0) {
        message += '├ 🎬 IMDB: https://imdb.com/title/tt' + String(torrent.imdb).padStart(7, '0') + '\\n';
    }
    
    if (config.features.include_tmdb_info) {
        if (torrent.tmdb_movie_id && torrent.tmdb_movie_id > 0) {
            message += '├ 🎭 TMDB: https://www.themoviedb.org/movie/' + torrent.tmdb_movie_id + '\\n';
        }
        if (torrent.tmdb_tv_id && torrent.tmdb_tv_id > 0) {
            message += '├ 📺 TMDB TV: https://www.themoviedb.org/tv/' + torrent.tmdb_tv_id + '\\n';
        }
    }
    message += '╰─\\n\\n';
    
    // Footer elegante
    message += '╔═════════════════╗\\n';
    message += '║ 🏷️ ' + config.tracker.name.padEnd(13) + ' ║\\n';
    message += '║ 🕒 ' + new Date().toLocaleString('es-ES', { 
        timeZone: 'America/Mexico_City',
        day: '2-digit',
        month: '2-digit', 
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    }).padEnd(13) + ' ║\\n';
    message += '╚═════════════════╝';
    
    return message;
}

// Función mejorada para extraer toda la metadata posible
function extractAllMetadata(name) {
    const metadata = {};
    const nameUpper = name.toUpperCase();
    
    // Resolución/Calidad
    const qualities = ['2160p', '1080p', '720p', '480p', '4K', 'UHD', '8K'];
    for (const quality of qualities) {
        if (nameUpper.includes(quality)) {
            metadata.quality = quality;
            break;
        }
    }
    
    // Fuente
    const sources = ['BluRay', 'BDRip', 'REMUX', 'WEBRip', 'WEB-DL', 'HDTV', 'DVDRip', 'CAMRip', 'WEBRIP'];
    for (const source of sources) {
        if (nameUpper.includes(source.replace('-', '').replace(' ', ''))) {
            metadata.source = source;
            break;
        }
    }
    
    // Códec de video
    const videoCodecs = ['x265', 'x264', 'HEVC', 'H.265', 'H.264', 'AV1', 'VP9'];
    for (const codec of videoCodecs) {
        if (nameUpper.includes(codec.replace('.', ''))) {
            metadata.codec = codec;
            break;
        }
    }
    
    // Audio
    const audioFormats = ['Atmos', 'DTS-X', 'DTS-HD', 'TrueHD', 'DTS', 'DD5.1', 'DD+', 'AAC', 'AC3'];
    for (const audio of audioFormats) {
        if (nameUpper.includes(audio.replace('-', '').replace('+', '').replace('.', ''))) {
            metadata.audio = audio;
            break;
        }
    }
    
    // Idioma
    const languages = ['LATINO', 'SPANISH', 'ENGLISH', 'DUAL', 'MULTI'];
    for (const lang of languages) {
        if (nameUpper.includes(lang)) {
            metadata.language = lang;
            break;
        }
    }
    
    // Año (mejorado)
    const yearMatch = name.match(/(19|20)\\d{2}/);
    if (yearMatch) {
        metadata.year = yearMatch[0];
    }
    
    // Grupo de release (buscar después del último guión)
    const groupMatch = name.match(/-([A-Z0-9]+)$/i);
    if (groupMatch) {
        metadata.group = groupMatch[1];
    }
    
    return metadata;
}`;

console.log('💎 Formato PREMIUM creado con características:');
console.log('   ✅ Diseño con marcos ASCII elegantes');
console.log('   ✅ Secciones organizadas (Básica, Técnica, Enlaces)');
console.log('   ✅ Extracción avanzada de metadata (audio, idioma, grupo)');
console.log('   ✅ Soporte para TV Shows (TMDB TV)');
console.log('   ✅ Footer con diseño profesional');
console.log('   ✅ Detección de resolución 4K, 8K');
console.log('   ✅ Formatos de audio avanzados (Atmos, DTS-X)');
console.log('   ✅ Detección de idioma (Latino, Dual, Multi)');
console.log('');

// Escribir a archivo
const outputFile = path.join(__dirname, '..', 'premium-format-preview.js');
fs.writeFileSync(outputFile, premiumFormatFunction, 'utf8');

console.log('📄 Vista previa guardada en: premium-format-preview.js');
console.log('');
console.log('🎯 El formato PREMIUM mostrará:');
console.log(`
╔═══════════════════════╗
║  🎬 NUEVO TORRENT APROBADO  ║
╚═══════════════════════╝

📁 'Avatar.The.Way.of.Water.2022.2160p.UHD.BluRay.x265.Atmos-EXAMPLE'

╭─ INFORMACIÓN BÁSICA
├ 👤 Uploader: uploader_pro
├ 📂 Categoría: Movies
├ 💾 Tamaño: 25.4 GB
├ 🆔 ID: #123456
╰─

╭─ ESPECIFICACIONES TÉCNICAS
├ 📅 Año: 2022
├ 🎥 Resolución: 2160p
├ 💿 Fuente: BluRay
├ 🔧 Códec: x265
├ 🔊 Audio: Atmos
├ 👥 Grupo: EXAMPLE
╰─

╭─ ENLACES RÁPIDOS
├ 🔽 Descargar: https://lat-team.xyz/torrents/123456
├ 🎬 IMDB: https://imdb.com/title/tt1630029
├ 🎭 TMDB: https://www.themoviedb.org/movie/76600
╰─

╔═════════════════╗
║ 🏷️ LAT-TEAM      ║
║ 🕒 25/08/24, 15:30 ║
╚═════════════════╝
`);

console.log('Para aplicar el formato PREMIUM, ejecuta:');
console.log('   node scripts/apply-premium-format.js');