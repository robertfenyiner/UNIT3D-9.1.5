#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

console.log('🔍 Validando JSON de configuración...\n');

const configPath = path.join(__dirname, '..', 'config', 'config.json');

try {
  // Leer archivo crudo
  const rawContent = fs.readFileSync(configPath, 'utf8');
  console.log('📄 Contenido del archivo:');
  console.log('---START---');
  console.log(rawContent);
  console.log('---END---');
  console.log(`📏 Longitud: ${rawContent.length} caracteres\n`);
  
  // Verificar caracteres especiales
  const hasNonPrintable = /[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F]/.test(rawContent);
  if (hasNonPrintable) {
    console.log('⚠️  Se encontraron caracteres no imprimibles');
  }
  
  // Intentar parsear JSON
  const config = JSON.parse(rawContent);
  console.log('✅ JSON válido');
  console.log('📋 Estructura parseada:');
  console.log(JSON.stringify(config, null, 2));
  
} catch (error) {
  console.error('❌ Error de JSON:', error.message);
  console.error('📍 Posición del error:', error.message.match(/position (\d+)/)?.[1] || 'desconocida');
  
  if (error.message.includes('position')) {
    const position = parseInt(error.message.match(/position (\d+)/)?.[1] || '0');
    const rawContent = fs.readFileSync(configPath, 'utf8');
    
    console.log('\n🔍 Contexto del error:');
    const start = Math.max(0, position - 50);
    const end = Math.min(rawContent.length, position + 50);
    console.log('...' + rawContent.slice(start, end) + '...');
    console.log(' '.repeat(Math.min(50, position - start) + 3) + '↑ ERROR AQUÍ');
  }
  
  console.log('\n🔧 Para reparar, ejecuta:');
  console.log('   node scripts/fix-config.js');
}