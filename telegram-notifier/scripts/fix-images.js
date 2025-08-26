#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

console.log('🖼️ Reparando función de imágenes para usar Node.js nativo...\n');

const appJsPath = path.join(__dirname, '..', 'app.js');

try {
    let content = fs.readFileSync(appJsPath, 'utf8');
    
    // Hacer backup
    fs.writeFileSync(appJsPath + '.backup-images', content, 'utf8');
    console.log('💾 Backup creado: app.js.backup-images');
    
    // Agregar módulo https si no está
    if (!content.includes('const https = require(\'https\')')) {
        content = content.replace(
            'const path = require(\'path\');',
            'const path = require(\'path\');\nconst https = require(\'https\');'
        );
    }
    
    // Agregar función makeRequest si no está
    if (!content.includes('function makeRequest(url)')) {
        const makeRequestFunction = `
// Helper function para hacer requests HTTP
function makeRequest(url) {
    return new Promise((resolve, reject) => {
        const request = https.get(url, (response) => {
            let data = '';
            
            response.on('data', (chunk) => {
                data += chunk;
            });
            
            response.on('end', () => {
                try {
                    resolve(JSON.parse(data));
                } catch (error) {
                    reject(new Error('Error parsing JSON: ' + error.message));
                }
            });
        });
        
        request.on('error', (error) => {
            reject(error);
        });
        
        request.setTimeout(5000, () => {
            request.destroy();
            reject(new Error('Request timeout'));
        });
    });
}
`;
        
        // Insertar después de extractYear
        content = content.replace(
            /function extractYear\(name\) \{[\s\S]*?\n\}/,
            '$&\n' + makeRequestFunction
        );
    }
    
    // Reemplazar fetch con makeRequest en getPosterUrl
    content = content.replace(
        /const response = await fetch\(`([^`]+)`[^}]*\);[\s\S]*?if \(response\.ok\) \{[\s\S]*?const data = await response\.json\(\);/g,
        'const data = await makeRequest(`$1`);'
    );
    
    // Remover logs de response.status que no existen con makeRequest
    content = content.replace(
        /logger\.info\(`\[TMDB\] Respuesta para [^:]*: status \$\{response\.status\}\`\);\s*/g,
        ''
    );
    
    content = content.replace(
        /logger\.warn\(`\[TMDB\] Respuesta no OK para [^`]*`\);\s*/g,
        ''
    );
    
    // Remover else clause que verifica response.ok
    content = content.replace(
        /\} else \{\s*logger\.warn\([^}]*\);\s*\}/g,
        ''
    );
    
    // Escribir archivo corregido
    fs.writeFileSync(appJsPath, content, 'utf8');
    
    console.log('✅ Función de imágenes corregida para usar Node.js nativo');
    console.log('✅ Removida dependencia de fetch()');
    console.log('✅ Agregados logs de debugging');
    console.log('');
    console.log('🔄 Para aplicar los cambios:');
    console.log('   sudo systemctl restart telegram-notifier');
    console.log('');
    console.log('🧪 Probar con:');
    console.log(`   curl -X POST http://localhost:3001/torrent-approved \\
     -H "Content-Type: application/json" \\
     -d '{
       "torrent_id": 999999,
       "name": "Avatar.The.Way.of.Water.2022.2160p.UHD.BluRay.x265-EXAMPLE",
       "user": "uploader_pro",
       "category": "Movies",
       "size": "25.4 GB",
       "imdb": 1630029,
       "tmdb_movie_id": 76600
     }'`);
    
} catch (error) {
    console.error('❌ Error reparando imágenes:', error.message);
    process.exit(1);
}