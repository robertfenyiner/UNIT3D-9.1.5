const express = require('express');
const TelegramBot = require('node-telegram-bot-api');
const cors = require('cors');
const winston = require('winston');
const fs = require('fs');
const path = require('path');
const https = require('https');

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

// Función para obtener nombre legible de categoría
function getCategoryName(category) {
    const names = {
        'Movies': 'PELÍCULAS',
        'TV': 'SERIES',
        'TV Shows': 'SERIES', 
        'Music': 'MÚSICA',
        'Games': 'JUEGOS',
        'Software': 'SOFTWARE',
        'Books': 'LIBROS',
        'Apps': 'APLICACIONES',
        'Anime': 'ANIME',
        'Documentary': 'DOCUMENTALES',
        'XXX': 'XXX'
    };
    return names[category] || category.toUpperCase();
}

// Función para formatear el mensaje de Telegram con formato avanzado
function formatMessage(torrent) {
    const categoryEmoji = getCategoryEmoji(torrent.category);
    const categoryName = getCategoryName(torrent.category);
    
    // Crear mensaje con formato rico
    let message = '';
    
    // Header con emoji de categoría y nombre de categoría
    message += categoryEmoji + ' NUEVO TORRENT EN ' + categoryName.toUpperCase() + '\n';
    message += '━━━━━━━━━━━━━━━━━━━━━━━\n\n\n\n\n';
    
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
    message += '• Descargar: \n' + config.tracker.base_url + '/torrents/' + torrent.torrent_id + '\n';
    
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

// Función para obtener URL del póster desde TMDB
async function getPosterUrl(torrent) {
    try {
        // Solo intentar obtener póster para películas y series
        const supportedCategories = ['Movies', 'TV', 'TV Shows'];
        if (!supportedCategories.includes(torrent.category)) {
            return null;
        }
        
        let imageUrl = null;
        
        // Verificar si las imágenes están habilitadas
        if (!config.features.include_poster_images) {
            return null;
        }
        
        // Verificar si tenemos API key de TMDB
        if (!config.tmdb || !config.tmdb.api_key || config.tmdb.api_key === 'TU_TMDB_API_KEY_AQUI') {
            return null;
        }
        
        // Para películas
        if (torrent.category === 'Movies' && torrent.tmdb_movie_id) {
            const response = await fetch(`https://api.themoviedb.org/3/movie/${torrent.tmdb_movie_id}?api_key=${config.tmdb.api_key}`, {
                timeout: 5000
            });
            logger.info(`[TMDB] Respuesta para película ID ${torrent.tmdb_movie_id}: status ${response.status}`);
            if (response.ok) {
                const data = await response.json();
                logger.info(`[TMDB] Datos recibidos para película: ${JSON.stringify(data)}`);
                if (data.poster_path) {
                    imageUrl = `https://image.tmdb.org/t/p/w500${data.poster_path}`;
                    logger.info(`[TMDB] URL del póster construida: ${imageUrl}`);
                } else {
                    logger.warn(`[TMDB] No se encontró poster_path para película ID ${torrent.tmdb_movie_id}`);
                }
            } else {
                logger.warn(`[TMDB] Respuesta no OK para película ID ${torrent.tmdb_movie_id}`);
            }
        }

        // Para series
        if ((torrent.category === 'TV' || torrent.category === 'TV Shows') && torrent.tmdb_tv_id) {
            const response = await fetch(`https://api.themoviedb.org/3/tv/${torrent.tmdb_tv_id}?api_key=${config.tmdb.api_key}`, {
                timeout: 5000
            });
            logger.info(`[TMDB] Respuesta para serie ID ${torrent.tmdb_tv_id}: status ${response.status}`);
            if (response.ok) {
                const data = await response.json();
                logger.info(`[TMDB] Datos recibidos para serie: ${JSON.stringify(data)}`);
                if (data.poster_path) {
                    imageUrl = `https://image.tmdb.org/t/p/w500${data.poster_path}`;
                    logger.info(`[TMDB] URL del póster construida: ${imageUrl}`);
                } else {
                    logger.warn(`[TMDB] No se encontró poster_path para serie ID ${torrent.tmdb_tv_id}`);
                }
            } else {
                logger.warn(`[TMDB] Respuesta no OK para serie ID ${torrent.tmdb_tv_id}`);
            }
        }

        logger.info(`[TMDB] Valor final de imageUrl: ${imageUrl}`);
        return imageUrl;
        
    } catch (error) {
        logger.warn(`⚠️ No se pudo obtener imagen para torrent ${torrent.torrent_id}: ${error.message}`);
        return null;
    }
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
        
        // Obtener URL de imagen del póster si está disponible
        const posterUrl = await getPosterUrl(torrent);
        
        // Enviar mensaje con imagen si está disponible
        if (posterUrl) {
            await bot.sendPhoto(config.telegram.chat_id, posterUrl, {
                caption: message,
                parse_mode: null
            });
        } else {
            // Enviar solo mensaje de texto si no hay imagen
            await bot.sendMessage(config.telegram.chat_id, message, {
                parse_mode: null,
                disable_web_page_preview: false
            });
        }
        
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