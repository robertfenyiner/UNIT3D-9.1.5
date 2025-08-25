#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

console.log('🔧 Reparando formato de mensajes de Telegram...\n');

const appJsPath = path.join(__dirname, '..', 'app.js');

try {
  let content = fs.readFileSync(appJsPath, 'utf8');
  
  // Buscar y reemplazar la función formatMessage
  const oldFormatFunction = /function formatMessage\(torrent\) \{[\s\S]*?return message;\s*\}/;
  
  const newFormatFunction = `function formatMessage(torrent) {
    const categoryEmoji = getCategoryEmoji(torrent.category);
    
    // Usar formato simple sin caracteres problemáticos de Markdown
    let message = categoryEmoji + ' NUEVO TORRENT APROBADO\\n\\n';
    message += '📁 Nombre: ' + torrent.name + '\\n';
    message += '👤 Uploader: ' + torrent.user + '\\n';
    message += '📂 Categoría: ' + torrent.category + '\\n';
    message += '💾 Tamaño: ' + torrent.size + '\\n\\n';
    
    // Agregar enlaces
    message += '🔗 Ver Torrent: ' + config.tracker.base_url + '/torrents/' + torrent.torrent_id;
    
    if (config.features.include_imdb_link && torrent.imdb && torrent.imdb > 0) {
        message += '\\n🎭 IMDB: https://imdb.com/title/tt' + String(torrent.imdb).padStart(7, '0');
    }
    
    if (config.features.include_tmdb_info && torrent.tmdb_movie_id && torrent.tmdb_movie_id > 0) {
        message += '\\n🎬 TMDB: https://www.themoviedb.org/movie/' + torrent.tmdb_movie_id;
    }
    
    // Agregar timestamp
    message += '\\n\\n🕒 ' + new Date().toLocaleString('es-ES', { timeZone: 'America/Mexico_City' });
    
    return message;
}`;

  if (oldFormatFunction.test(content)) {
    content = content.replace(oldFormatFunction, newFormatFunction);
    
    // También cambiar parse_mode a 'HTML' o null para evitar problemas de Markdown
    content = content.replace(
      /parse_mode: config\.telegram\.parse_mode/g,
      'parse_mode: null'
    );
    
    fs.writeFileSync(appJsPath, content, 'utf8');
    
    console.log('✅ Función formatMessage actualizada exitosamente');
    console.log('✅ Parse mode cambiado a formato simple');
    console.log('');
    console.log('🔄 Reinicia el servicio para aplicar los cambios:');
    console.log('   sudo systemctl restart telegram-notifier');
    console.log('');
    console.log('🧪 Luego prueba con:');
    console.log('   curl -X POST http://localhost:3001/test-telegram');
    
  } else {
    console.log('❌ No se pudo encontrar la función formatMessage');
    console.log('El archivo puede haber sido modificado previamente');
  }
  
} catch (error) {
  console.error('❌ Error reparando formato:', error.message);
  process.exit(1);
}