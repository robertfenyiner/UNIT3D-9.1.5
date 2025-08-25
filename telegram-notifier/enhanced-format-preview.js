// Función para formatear el mensaje de Telegram con formato avanzado
function formatMessage(torrent) {
    const categoryEmoji = getCategoryEmoji(torrent.category);
    
    // Crear mensaje con formato rico
    let message = '';
    
    // Header con emoji de categoría
    message += categoryEmoji + ' NUEVO TORRENT APROBADO\n';
    message += '━━━━━━━━━━━━━━━━━━━━━━━\n\n';
    
    // Información principal del torrent
    message += '📁 ' + torrent.name + '\n\n';
    
    // Metadata en formato tabla
    message += '👤 Uploader: ' + torrent.user + '\n';
    message += '📂 Categoría: ' + torrent.category + '\n';
    message += '💾 Tamaño: ' + torrent.size + '\n';
    
    // Agregar información de calidad y resolución si está disponible
    if (torrent.name) {
        const quality = extractQuality(torrent.name);
        const source = extractSource(torrent.name);
        const codec = extractCodec(torrent.name);
        const year = extractYear(torrent.name);
        
        if (quality) message += '🎥 Calidad: ' + quality + '\n';
        if (source) message += '💿 Fuente: ' + source + '\n';
        if (codec) message += '🔧 Códec: ' + codec + '\n';
        if (year) message += '📅 Año: ' + year + '\n';
    }
    
    message += '\n━━━━━━━━━━━━━━━━━━━━━━━\n';
    
    // Enlaces externos
    message += '🔗 ENLACES:\n';
    message += '• Descargar: ' + config.tracker.base_url + '/torrents/' + torrent.torrent_id + '\n';
    
    if (config.features.include_imdb_link && torrent.imdb && torrent.imdb > 0) {
        message += '• IMDB: https://imdb.com/title/tt' + String(torrent.imdb).padStart(7, '0') + '\n';
    }
    
    if (config.features.include_tmdb_info && torrent.tmdb_movie_id && torrent.tmdb_movie_id > 0) {
        message += '• TMDB: https://www.themoviedb.org/movie/' + torrent.tmdb_movie_id + '\n';
    }
    
    // Footer con timestamp y tracker info
    message += '\n━━━━━━━━━━━━━━━━━━━━━━━\n';
    message += '🏷️ ' + config.tracker.name + '\n';
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
    const yearMatch = name.match(/(19|20)\d{2}/);
    return yearMatch ? yearMatch[0] : null;
}