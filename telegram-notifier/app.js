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
        'Peliculas': '🎬',
        'TV Series': '📺',
        'Anime': '🎌',
        'Asiáticas & Turcas': '🏮',
        'Telenovelas': '📺',
        'Musica': '🎵',
        'Conciertos': '🎤',
        'Eventos Deportivos': '⚽',
        'Playlist_Collection': '🎵',
        'Categoría PROHIBIDA': '🚫',
        'XXX': '🔞',
        'E-Books': '📚',
        'Audiolibros': '🎧',
        'Juegos': '🎮',
        'Cursos': '🎓',
        'Revistas & Periódicos': '📰',
        'Comics & Manga': '📚',
        // Soporte legacy para nombres en inglés
        'Movies': '🎬',
        'TV': '📺',
        'TV Shows': '📺',
        'Series': '📺',
        'Music': '🎵',
        'Games': '🎮',
        'Books': '📚'
    };
    return emojis[category] || '📦';
}

// Función para obtener nombre legible de categoría
function getCategoryName(category) {
    const names = {
        'Peliculas': 'PELÍCULAS',
        'TV Series': 'SERIES DE TV',
        'Anime': 'ANIME',
        'Asiáticas & Turcas': 'ASIÁTICAS & TURCAS',
        'Telenovelas': 'TELENOVELAS',
        'Musica': 'MÚSICA',
        'Conciertos': 'CONCIERTOS',
        'Eventos Deportivos': 'EVENTOS DEPORTIVOS',
        'Playlist_Collection': 'COLECCIÓN PLAYLIST',
        'Categoría PROHIBIDA': 'CATEGORÍA PROHIBIDA',
        'XXX': 'XXX',
        'E-Books': 'E-BOOKS',
        'Audiolibros': 'AUDIOLIBROS',
        'Juegos': 'JUEGOS',
        'Cursos': 'CURSOS',
        'Revistas & Periódicos': 'REVISTAS & PERIÓDICOS',
        'Comics & Manga': 'COMICS & MANGA',
        // Soporte legacy para nombres en inglés
        'Movies': 'PELÍCULAS',
        'TV': 'SERIES',
        'TV Shows': 'SERIES',
        'Series': 'SERIES',
        'Music': 'MÚSICA',
        'Games': 'JUEGOS',
        'Books': 'LIBROS'
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

// Función para buscar en TMDB por título cuando no hay ID
async function searchTMDBByTitle(torrent) {
    try {
        // Extraer título limpio del nombre del torrent
        const cleanTitle = cleanTorrentTitle(torrent.name);
        if (!cleanTitle) {
            logger.warn(`❌ No se pudo extraer título limpio de: ${torrent.name}`);
            return null;
        }
        
        logger.info(`🔍 Buscando en TMDB por título: "${cleanTitle}"`);
        
        let searchUrl;
        const movieCategories = ['Movies', 'Peliculas'];
        const tvCategories = ['TV', 'TV Shows', 'Series', 'Series de TV', 'TV Series', 'Anime', 'Asiáticas & Turcas', 'Telenovelas'];
        
        if (movieCategories.includes(torrent.category)) {
            searchUrl = `https://api.themoviedb.org/3/search/movie?api_key=${config.tmdb.api_key}&query=${encodeURIComponent(cleanTitle)}`;
        } else if (tvCategories.includes(torrent.category)) {
            searchUrl = `https://api.themoviedb.org/3/search/tv?api_key=${config.tmdb.api_key}&query=${encodeURIComponent(cleanTitle)}`;
        } else {
            return null;
        }
        
        const searchData = await makeRequest(searchUrl);
        logger.info(`🔍 Resultados de búsqueda TMDB: ${searchData.results?.length || 0} encontrados`);
        
        if (searchData.results && searchData.results.length > 0) {
            const firstResult = searchData.results[0];
            if (firstResult.poster_path) {
                const imageUrl = `https://image.tmdb.org/t/p/w300${firstResult.poster_path}`;
                logger.info(`✅ Imagen encontrada por búsqueda: ${imageUrl}`);
                return imageUrl;
            }
        }
        
        return null;
        
    } catch (error) {
        logger.warn(`⚠️ Error en búsqueda por título: ${error.message}`);
        return null;
    }
}

// Función para limpiar el título del torrent
function cleanTorrentTitle(torrentName) {
    try {
        // Remover extensiones y información técnica común
        let title = torrentName
            .replace(/\.(mkv|mp4|avi|mov|wmv|flv|webm)$/i, '') // extensiones
            .replace(/\b(720p|1080p|2160p|4K|UHD|BluRay|WEBRip|WEB-DL|HDTV|DVDRip|BDRip|REMUX)\b/gi, '') // calidades
            .replace(/\b(x264|x265|HEVC|H\.264|H\.265|AV1)\b/gi, '') // codecs
            .replace(/\b(AAC|DTS|AC3|TrueHD|Atmos)\b/gi, '') // audio
            .replace(/\.-\w+$/g, '') // grupos de release
            .replace(/\[.*?\]/g, '') // corchetes
            .replace(/\(.*?\)/g, '') // paréntesis
            .replace(/-+/g, ' ') // guiones múltiples
            .replace(/\.+/g, ' ') // puntos múltiples
            .replace(/\s+/g, ' ') // espacios múltiples
            .trim();
        
        // Extraer solo hasta el año si está presente
        const yearMatch = title.match(/^(.+?)\s+(19|20)\d{2}/);
        if (yearMatch) {
            title = yearMatch[1].trim();
        }
        
        return title;
        
    } catch (error) {
        logger.warn(`Error limpiando título: ${error.message}`);
        return null;
    }
}

// Función para obtener imagen genérica por categoría
function getGenericCategoryImage(category) {
    // URLs de imágenes genéricas para todas las categorías de tu tracker
    const genericImages = {
        'Peliculas': 'https://picsum.photos/500/750',
        'TV Series': 'https://picsum.photos/500/750',
        'Anime': 'https://picsum.photos/500/750',
        'Asiáticas & Turcas': 'https://picsum.photos/500/750',
        'Telenovelas': 'https://picsum.photos/500/750',
        'Musica': 'https://picsum.photos/500/750',
        'Conciertos': 'https://picsum.photos/500/750',
        'Eventos Deportivos': 'https://picsum.photos/500/750',
        'Playlist_Collection': 'https://picsum.photos/500/750',
        'XXX': 'https://picsum.photos/500/750',
        'E-Books': 'https://picsum.photos/500/750',
        'Audiolibros': 'https://picsum.photos/500/750',
        'Juegos': 'https://picsum.photos/500/750',
        'Cursos': 'https://picsum.photos/500/750',
        'Revistas & Periódicos': 'https://picsum.photos/500/750',
        'Comics & Manga': 'https://picsum.photos/500/750',
        // Soporte legacy
        'Movies': 'https://picsum.photos/500/750',
        'TV': 'https://picsum.photos/500/750',
        'TV Shows': 'https://picsum.photos/500/750',
        'Music': 'https://picsum.photos/500/750',
        'Games': 'https://picsum.photos/500/750',
        'Books': 'https://picsum.photos/500/750'
    };
    
    return genericImages[category] || 'https://picsum.photos/500/750';
}

// Función para obtener URL del póster desde TMDB
async function getPosterUrl(torrent) {
    try {
        // Solo intentar obtener póster para películas y series (incluyendo todas las categorías de tu tracker)
        const supportedCategories = [
            'Movies', 'TV', 'TV Shows', 'Peliculas', 'Series', 'Series de TV',
            'TV Series', 'Anime', 'Asiáticas & Turcas', 'Telenovelas'
        ];
        if (!supportedCategories.includes(torrent.category)) {
            logger.info(`🚫 Categoría no soportada para imágenes: ${torrent.category}`);
            return null;
        }
        
        let imageUrl = null;
        
        // Verificar si las imágenes están habilitadas
        if (!config.features.include_poster_images) {
            logger.info(`🚫 Imágenes deshabilitadas en configuración`);
            return null;
        }
        
        // Verificar si tenemos API key de TMDB
        if (!config.tmdb || !config.tmdb.api_key || config.tmdb.api_key === 'TU_TMDB_API_KEY_AQUI') {
            logger.warn(`🚫 API key de TMDB no configurada`);
            return null;
        }
        
        // Logging detallado de datos de entrada
        logger.info(`🔍 ANÁLISIS DE TORRENT:
        - ID: ${torrent.torrent_id}
        - Nombre: ${torrent.name}
        - Categoría: ${torrent.category}
        - TMDB Movie ID: ${torrent.tmdb_movie_id || 'NULL/UNDEFINED'}
        - TMDB TV ID: ${torrent.tmdb_tv_id || 'NULL/UNDEFINED'}
        - IMDB: ${torrent.imdb || 'NULL/UNDEFINED'}`);
        
        // Para películas
        if (torrent.category === 'Movies' || torrent.category === 'Peliculas') {
            if (torrent.tmdb_movie_id && torrent.tmdb_movie_id > 0) {
                logger.info(`🎬 Buscando póster para película TMDB ID: ${torrent.tmdb_movie_id}`);
                const url = `https://api.themoviedb.org/3/movie/${torrent.tmdb_movie_id}?api_key=${config.tmdb.api_key}`;
                
                const data = await makeRequest(url);
                logger.info(`🎬 Datos recibidos de TMDB: ${JSON.stringify(data, null, 2)}`);
                
                if (data.poster_path) {
                    imageUrl = `https://image.tmdb.org/t/p/w300${data.poster_path}`;
                    logger.info(`✅ URL del póster construida: ${imageUrl}`);
                } else {
                    logger.warn(`⚠️ No se encontró poster_path para película ID ${torrent.tmdb_movie_id}`);
                }
            } else {
                logger.warn(`❌ PELÍCULA SIN TMDB_MOVIE_ID:
                - Torrent ID: ${torrent.torrent_id}
                - Nombre: ${torrent.name}
                - Valor tmdb_movie_id: ${torrent.tmdb_movie_id}
                - Razón: El torrent no tiene metadata de TMDB asignada
                - Solución: El uploader debe agregar el TMDB ID durante la subida`);
            }
        }

        // Para series (incluyendo todas las variantes de tu tracker)
        const seriesCategories = ['TV', 'TV Shows', 'Series', 'Series de TV', 'TV Series', 'Anime', 'Asiáticas & Turcas', 'Telenovelas'];
        if (seriesCategories.includes(torrent.category)) {
            if (torrent.tmdb_tv_id && torrent.tmdb_tv_id > 0) {
                logger.info(`📺 Buscando póster para serie TMDB ID: ${torrent.tmdb_tv_id}`);
                const url = `https://api.themoviedb.org/3/tv/${torrent.tmdb_tv_id}?api_key=${config.tmdb.api_key}`;
                
                const data = await makeRequest(url);
                logger.info(`📺 Datos recibidos de TMDB: ${JSON.stringify(data, null, 2)}`);
                
                if (data.poster_path) {
                    imageUrl = `https://image.tmdb.org/t/p/w300${data.poster_path}`;
                    logger.info(`✅ URL del póster construida: ${imageUrl}`);
                } else {
                    logger.warn(`⚠️ No se encontró poster_path para serie ID ${torrent.tmdb_tv_id}`);
                }
            } else {
                logger.warn(`❌ SERIE/TV SIN TMDB_TV_ID:
                - Torrent ID: ${torrent.torrent_id}
                - Nombre: ${torrent.name}
                - Categoría: ${torrent.category}
                - Valor tmdb_tv_id: ${torrent.tmdb_tv_id}
                - Razón: El torrent no tiene metadata de TMDB asignada
                - Solución: El uploader debe agregar el TMDB ID durante la subida`);
            }
        }

        // Fallback: Si no tenemos imagen y está habilitado el fallback
        if (!imageUrl && config.features.fallback_to_search) {
            logger.info(`🔍 Intentando fallback: búsqueda por título`);
            imageUrl = await searchTMDBByTitle(torrent);
        }
        
        // Fallback final: imagen genérica por categoría
        if (!imageUrl && config.features.fallback_generic_image) {
            imageUrl = getGenericCategoryImage(torrent.category);
            if (imageUrl) {
                logger.info(`🖼️ Usando imagen genérica para categoría ${torrent.category}: ${imageUrl}`);
            }
        }

        logger.info(`[TMDB] Valor final de imageUrl: ${imageUrl}`);
        return imageUrl;
        
    } catch (error) {
        logger.error(`⚠️ Error obteniendo imagen para torrent ${torrent.torrent_id}: ${error.message}`);
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
        logger.info(`🔍 Intentando obtener póster para torrent ID: ${torrent.torrent_id}`);
        const posterUrl = await getPosterUrl(torrent);
        logger.info(`🔍 Resultado getPosterUrl: ${posterUrl}`);
        
        // Enviar mensaje con imagen si está disponible
        if (posterUrl) {
            logger.info(`📸 Enviando mensaje con imagen: ${posterUrl}`);
            try {
                await bot.sendPhoto(config.telegram.chat_id, posterUrl, {
                    caption: message,
                    parse_mode: null
                });
                logger.info(`✅ Imagen enviada exitosamente`);
            } catch (photoError) {
                logger.error(`❌ Error enviando imagen: ${photoError.message}`);
                logger.info(`📝 Fallback: enviando solo texto`);
                await bot.sendMessage(config.telegram.chat_id, message, {
                    parse_mode: null,
                    disable_web_page_preview: false
                });
            }
        } else {
            logger.info(`📝 No hay imagen, enviando solo mensaje de texto`);
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