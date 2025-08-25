const express = require('express');
const TelegramBot = require('node-telegram-bot-api');
const cors = require('cors');
const winston = require('winston');
const fs = require('fs');
const path = require('path');

// Configurar logging
const logger = winston.createLogger({
    level: 'info',
    format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.errors({ stack: true }),
        winston.format.json()
    ),
    defaultMeta: { service: 'telegram-notifier' },
    transports: [
        new winston.transports.File({ filename: 'logs/error.log', level: 'error' }),
        new winston.transports.File({ filename: 'logs/combined.log' }),
        new winston.transports.Console({
            format: winston.format.simple()
        })
    ]
});

const app = express();

// Cargar configuración
let config;
try {
    config = JSON.parse(fs.readFileSync('./config/config.json', 'utf8'));
    logger.info('✅ Configuración cargada correctamente');
} catch (error) {
    logger.error('❌ Error cargando configuración:', error.message);
    process.exit(1);
}

// Inicializar bot de Telegram
let bot;
try {
    bot = new TelegramBot(config.telegram.bot_token, {
        polling: false // Solo enviamos mensajes, no recibimos
    });
    logger.info('✅ Bot de Telegram inicializado');
} catch (error) {
    logger.error('❌ Error inicializando bot de Telegram:', error.message);
    process.exit(1);
}

// Middleware
app.use(express.json({ limit: '10mb' }));
app.use(cors());
app.use((req, res, next) => {
    logger.info(`${req.method} ${req.path} - ${req.ip}`);
    next();
});

// Función para obtener emoji por categoría
function getCategoryEmoji(category) {
    const emojis = {
        'Movies': '🎬',
        'TV': '📺',
        'TV Shows': '📺', 
        'Music': '🎵',
        'Games': '🎮',
        'Software': '💿',
        'Books': '📚',
        'Apps': '📱',
        'Anime': '🎌',
        'Documentary': '🎭',
        'XXX': '🔞'
    };
    return emojis[category] || '📦';
}

// Función para formatear el mensaje de Telegram
function formatMessage(torrent) {
    const categoryEmoji = getCategoryEmoji(torrent.category);
    
    // Usar formato simple sin caracteres problemáticos de Markdown
    let message = categoryEmoji + ' NUEVO TORRENT APROBADO\n\n';
    message += '📁 Nombre: ' + torrent.name + '\n';
    message += '👤 Uploader: ' + torrent.user + '\n';
    message += '📂 Categoría: ' + torrent.category + '\n';
    message += '💾 Tamaño: ' + torrent.size + '\n\n';
    
    // Agregar enlaces sin formato Markdown
    message += '🔗 Ver Torrent: ' + config.tracker.base_url + '/torrents/' + torrent.torrent_id;
    
    if (config.features.include_imdb_link && torrent.imdb && torrent.imdb > 0) {
        message += '\n🎭 IMDB: https://imdb.com/title/tt' + String(torrent.imdb).padStart(7, '0');
    }
    
    if (config.features.include_tmdb_info && torrent.tmdb_movie_id && torrent.tmdb_movie_id > 0) {
        message += '\n🎬 TMDB: https://www.themoviedb.org/movie/' + torrent.tmdb_movie_id;
    }
    
    // Agregar timestamp
    message += '\n\n🕒 ' + new Date().toLocaleString('es-ES', { timeZone: 'America/Mexico_City' });
    
    return message;
}

// Función para verificar si debe notificarse según filtros
function shouldNotify(torrent) {
    // Filtrar por categorías si está configurado
    if (config.features.filter_categories && config.features.filter_categories.length > 0) {
        return config.features.filter_categories.includes(torrent.category);
    }
    
    // Por defecto, notificar todo
    return true;
}

// ENDPOINTS

// Health check
app.get('/health', (req, res) => {
    res.status(200).json({
        status: 'OK',
        service: 'telegram-notifier',
        version: '1.0.0',
        timestamp: new Date().toISOString(),
        uptime: process.uptime()
    });
});

// Endpoint principal para recibir notificaciones de torrents aprobados
app.post('/torrent-approved', async (req, res) => {
    try {
        const torrent = req.body;
        
        // Validar datos requeridos
        if (!torrent.torrent_id || !torrent.name || !torrent.user) {
            logger.warn('❌ Datos incompletos en notificación:', torrent);
            return res.status(400).json({ 
                error: 'Datos incompletos. Se requieren: torrent_id, name, user' 
            });
        }
        
        // Verificar filtros
        if (!shouldNotify(torrent)) {
            logger.info(`⚠️ Torrent filtrado - Categoría: ${torrent.category}, Nombre: ${torrent.name}`);
            return res.status(200).json({ 
                success: true, 
                message: 'Torrent filtrado según configuración' 
            });
        }
        
        // Formatear mensaje
        const message = formatMessage(torrent);
        
        // Enviar mensaje a Telegram
        await bot.sendMessage(config.telegram.chat_id, message, {
            parse_mode: null,
            disable_web_page_preview: false
        });
        
        logger.info(`✅ Notificación enviada exitosamente - ID: ${torrent.torrent_id}, Nombre: ${torrent.name}`);
        
        res.status(200).json({ 
            success: true, 
            message: 'Notificación enviada correctamente',
            torrent_id: torrent.torrent_id
        });
        
    } catch (error) {
        logger.error(`❌ Error enviando notificación: ${error.message}`, { 
            error: error.stack,
            torrent: req.body 
        });
        
        res.status(500).json({ 
            error: 'Error interno del servidor',
            message: error.message
        });
    }
});

// Endpoint para probar la conexión con Telegram
app.post('/test-telegram', async (req, res) => {
    try {
        const testMessage = '🧪 MENSAJE DE PRUEBA\n\nEl bot de Telegram está funcionando correctamente.\n\n🕒 ' + new Date().toLocaleString();
        
        await bot.sendMessage(config.telegram.chat_id, testMessage, {
            parse_mode: null
        });
        
        logger.info('✅ Mensaje de prueba enviado exitosamente');
        res.status(200).json({ 
            success: true, 
            message: 'Mensaje de prueba enviado correctamente' 
        });
        
    } catch (error) {
        logger.error(`❌ Error en mensaje de prueba: ${error.message}`);
        res.status(500).json({ 
            error: 'Error enviando mensaje de prueba',
            message: error.message
        });
    }
});

// Endpoint para recargar configuración
app.post('/config/reload', (req, res) => {
    try {
        config = JSON.parse(fs.readFileSync('./config/config.json', 'utf8'));
        logger.info('✅ Configuración recargada');
        res.status(200).json({ 
            success: true, 
            message: 'Configuración recargada correctamente' 
        });
    } catch (error) {
        logger.error(`❌ Error recargando configuración: ${error.message}`);
        res.status(500).json({ 
            error: 'Error recargando configuración',
            message: error.message
        });
    }
});

// Endpoint para obtener estadísticas
app.get('/stats', (req, res) => {
    res.status(200).json({
        service: 'telegram-notifier',
        version: '1.0.0',
        uptime: Math.floor(process.uptime()),
        memory: process.memoryUsage(),
        config: {
            chat_id: config.telegram.chat_id,
            tracker_url: config.tracker.base_url,
            features: config.features
        }
    });
});

// Manejo de errores global
app.use((error, req, res, next) => {
    logger.error('Error no manejado:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
});

// Manejo de rutas no encontradas
app.use('*', (req, res) => {
    res.status(404).json({ error: 'Endpoint no encontrado' });
});

// Iniciar servidor
const server = app.listen(config.server.port, config.server.host, () => {
    logger.info(`🚀 Telegram Notifier corriendo en ${config.server.host}:${config.server.port}`);
    logger.info(`📱 Chat ID configurado: ${config.telegram.chat_id}`);
    logger.info(`🌐 Tracker URL: ${config.tracker.base_url}`);
});

// Manejo graceful shutdown
process.on('SIGTERM', () => {
    logger.info('🛑 Recibida señal SIGTERM, cerrando servidor...');
    server.close(() => {
        logger.info('✅ Servidor cerrado correctamente');
        process.exit(0);
    });
});

process.on('SIGINT', () => {
    logger.info('🛑 Recibida señal SIGINT, cerrando servidor...');
    server.close(() => {
        logger.info('✅ Servidor cerrado correctamente');
        process.exit(0);
    });
});

// Manejo de errores no capturados
process.on('uncaughtException', (error) => {
    logger.error('💥 Excepción no capturada:', error);
    process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
    logger.error('💥 Promesa rechazada no manejada:', reason);
    process.exit(1);
});