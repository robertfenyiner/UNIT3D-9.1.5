#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

console.log('🔧 Reparando archivo de configuración...\n');

// Configuración limpia
const cleanConfig = {
  "telegram": {
    "bot_token": "8447822656:AAG2OTaTBtfTcVsLLH7Wqivm1N8B82tiDaM",
    "chat_id": "-1002354465967",
    "parse_mode": "Markdown"
  },
  "tracker": {
    "base_url": "https://lat-team.xyz",
    "name": "LAT-TEAM"
  },
  "server": {
    "port": 3001,
    "host": "localhost"
  },
  "features": {
    "include_imdb_link": true,
    "include_tmdb_info": true,
    "mention_uploader": true,
    "filter_categories": []
  }
};

const configPath = path.join(__dirname, '..', 'config', 'config.json');

try {
  // Escribir archivo limpio
  fs.writeFileSync(configPath, JSON.stringify(cleanConfig, null, 2), 'utf8');
  console.log('✅ Archivo config.json regenerado exitosamente');
  
  // Verificar que se puede leer
  const testRead = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  console.log('✅ Archivo verificado - JSON válido');
  
  console.log('\n📋 Configuración actual:');
  console.log(`Bot Token: ${testRead.telegram.bot_token}`);
  console.log(`Chat ID: ${testRead.telegram.chat_id}`);
  console.log(`Tracker URL: ${testRead.tracker.base_url}`);
  
  console.log('\n🎉 ¡Configuración reparada exitosamente!');
  console.log('\n🚀 Ahora puedes ejecutar:');
  console.log('   sudo bash scripts/deploy.sh');
  
} catch (error) {
  console.error('❌ Error reparando configuración:', error.message);
  process.exit(1);
}