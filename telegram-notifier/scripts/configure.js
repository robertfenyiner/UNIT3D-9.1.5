#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

console.log('🔧 Configurador de Telegram Notifier\n');

// Leer configuración actual
const configPath = path.join(__dirname, '..', 'config', 'config.json');
let config;

try {
    config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
} catch (error) {
    console.error('❌ Error leyendo configuración:', error.message);
    process.exit(1);
}

// Función para validar bot token
function isValidBotToken(token) {
    return /^\d{8,10}:[A-Za-z0-9_-]{35}$/.test(token);
}

// Función para validar chat ID
function isValidChatId(chatId) {
    // Puede ser positivo (chat privado) o negativo (grupo/canal)
    return /^-?\d+$/.test(chatId.toString());
}

// Verificar configuración actual
console.log('📋 Configuración actual:');
console.log(`Bot Token: ${config.telegram.bot_token}`);
console.log(`Chat ID: ${config.telegram.chat_id}`);
console.log(`Tracker URL: ${config.tracker.base_url}\n`);

// Validaciones
let hasErrors = false;

// Validar bot token
if (config.telegram.bot_token === 'TU_BOT_TOKEN_AQUI') {
    console.log('❌ Bot token no configurado');
    console.log('   1. Habla con @BotFather en Telegram');
    console.log('   2. Crea un nuevo bot con /newbot');
    console.log('   3. Copia el token que te proporciona');
    console.log('   4. Pégalo en config/config.json\n');
    hasErrors = true;
} else if (!isValidBotToken(config.telegram.bot_token)) {
    console.log('❌ Bot token inválido');
    console.log('   Formato esperado: 123456789:ABCdefGHIjklMNOpqrsTUVwxyz\n');
    hasErrors = true;
} else {
    console.log('✅ Bot token tiene formato válido');
}

// Validar chat ID
if (config.telegram.chat_id === 'TU_CHAT_ID_AQUI') {
    console.log('❌ Chat ID no configurado');
    console.log('   Para canal: ID negativo como -1001234567890');
    console.log('   Para grupo: Usa @userinfobot para obtener el ID');
    console.log('   Para chat privado: ID positivo\n');
    hasErrors = true;
} else if (!isValidChatId(config.telegram.chat_id)) {
    console.log('❌ Chat ID inválido');
    console.log('   Debe ser un número (positivo o negativo)\n');
    hasErrors = true;
} else {
    console.log('✅ Chat ID tiene formato válido');
}

// Validar tracker URL
if (config.tracker.base_url === 'https://tu-tracker.com') {
    console.log('⚠️  URL del tracker no configurada');
    console.log('   Cambia https://tu-tracker.com por la URL real de tu tracker\n');
} else {
    console.log('✅ URL del tracker configurada');
}

if (hasErrors) {
    console.log('🔴 Hay errores en la configuración que deben corregirse\n');
    console.log('💡 Para configurar:');
    console.log('   nano config/config.json');
    console.log('\n📖 Ejemplo de configuración válida:');
    console.log(`{
  "telegram": {
    "bot_token": "123456789:ABCdefGHIjklMNOpqrsTUVwxyz",
    "chat_id": "-1001234567890",
    "parse_mode": "Markdown"
  },
  "tracker": {
    "base_url": "https://mi-tracker.com",
    "name": "Mi Tracker"
  }
}`);
    process.exit(1);
} else {
    console.log('\n🎉 ¡Configuración válida! El servicio debería funcionar correctamente.');
    console.log('\n🚀 Próximos pasos:');
    console.log('   npm run dev    # Iniciar en modo desarrollo');
    console.log('   npm start      # Iniciar en modo producción');
}