const express = require('express');
const TelegramBot = require('node-telegram-bot-api');
const cors = require('cors');
const winston = require('winston');
const fs = require('fs');
const path = require('path');
const https = require('https');
const sharp = require('sharp');

// Asegurar que exista el directorio de logs antes de inicializar winston
try {
    const logsDir = path.resolve(__dirname, 'logs');
    if (!fs.existsSync(logsDir)) {
        fs.mkdirSync(logsDir, { recursive: true });
    }
} catch (err) {
    console.error('No se pudo crear logs/:', err.message);
}

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

// (formatMessage reemplazado más abajo por la versión HTML/wrap para mejorar lectura móvil)
function formatMessage(torrent) {
    // Usar HTML para controlar estilo y forzar saltos de línea claros en móvil
    const categoryEmoji = getCategoryEmoji(torrent.category);
    const categoryName = getCategoryName(torrent.category);

    // Helper: wrap text a una longitud objetivo para mejorar lectura en móviles
    function wrap(text, maxLen = 40) {
        if (!text) return '';
        const words = text.split(/\s+/);
        let line = '';
        const lines = [];
        for (const w of words) {
            if ((line + ' ' + w).trim().length > maxLen) {
                lines.push(line.trim());
                line = w;
            } else {
                line = (line + ' ' + w).trim();
            }
        }
        if (line) lines.push(line.trim());
        return lines.join('<br/>');
    }

    // Construir mensaje en HTML
    let message = '';
    message += `<b>${categoryEmoji} NUEVO TORRENT EN ${escapeHtml(categoryName)}</b><br/><hr/>`;

    // Título envuelto para evitar líneas demasiado largas
    message += `<b>📁 ${wrap(escapeHtml(torrent.name), 36)}</b><br/><br/>`;

    // Metadata en líneas separadas
    message += `👤 <b>Uploader:</b> ${escapeHtml(torrent.user)}<br/>`;
    message += `📂 <b>Categoría:</b> ${escapeHtml(torrent.category)}<br/>`;
    message += `💾 <b>Tamaño:</b> ${escapeHtml(torrent.size)}<br/>`;

    if (torrent.name) {
        const quality = extractQuality(torrent.name);
        const source = extractSource(torrent.name);
        const codec = extractCodec(torrent.name);
        const year = extractYear(torrent.name);

        if (quality) message += `�️ <b>Calidad:</b> ${escapeHtml(quality)}<br/>`;
        if (source) message += `💿 <b>Fuente:</b> ${escapeHtml(source)}<br/>`;
        if (codec) message += `🔧 <b>Códec:</b> ${escapeHtml(codec)}<br/>`;
        if (year) message += `📅 <b>Año:</b> ${escapeHtml(year)}<br/>`;
    }

    message += `<br/><hr/>`;

    // Enlaces
    message += `<b>🔗 ENLACES:</b><br/>`;
    message += `• <b>Descargar:</b> ${escapeHtml(config.tracker.base_url)}/torrents/${escapeHtml(String(torrent.torrent_id))}<br/>`;

    if (config.features.include_imdb_link && torrent.imdb && torrent.imdb > 0) {
        message += `• <b>IMDB:</b> https://imdb.com/title/tt${String(torrent.imdb).padStart(7, '0')}<br/>`;
    }

    if (config.features.include_tmdb_info && torrent.tmdb_movie_id && torrent.tmdb_movie_id > 0) {
        // Usar TMDB según tipo (movie)
        message += `• <b>TMDB:</b> https://www.themoviedb.org/movie/${escapeHtml(String(torrent.tmdb_movie_id))}<br/>`;
    }

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

// Wrap simple para títulos en el caption (no HTML tags inside wrap)
function wrapPlain(text, maxLen = 60) {
    if (!text) return '';
    const words = String(text).split(/\s+/);
    let line = '';
    const lines = [];
    for (const w of words) {
        if ((line + ' ' + w).trim().length > maxLen) {
            lines.push(line.trim());
            line = w;
        } else {
            line = (line + ' ' + w).trim();
        }
    }
    if (line) lines.push(line.trim());
    return lines.join(' ');
}

// Construir el mensaje detallado en HTML sin <br/> ni <hr/> (usar saltos de línea \n)
function buildDetailsMessage(torrent) {
    let msg = '';
    msg += `👤 <b>Uploader:</b> ${escapeHtml(torrent.user)}\n`;
    msg += `📂 <b>Categoría:</b> ${escapeHtml(torrent.category)}\n`;
    msg += `💾 <b>Tamaño:</b> ${escapeHtml(torrent.size)}\n`;

    if (torrent.name) {
        const quality = extractQuality(torrent.name);
        const source = extractSource(torrent.name);
        const codec = extractCodec(torrent.name);
        const year = extractYear(torrent.name);

        if (quality) msg += `🎞️ <b>Calidad:</b> ${escapeHtml(quality)}\n`;
        if (source) msg += `💿 <b>Fuente:</b> ${escapeHtml(source)}\n`;
        if (codec) msg += `🔧 <b>Códec:</b> ${escapeHtml(codec)}\n`;
        if (year) msg += `📅 <b>Año:</b> ${escapeHtml(year)}\n`;
    }

    msg += `\n🔗 <b>ENLACES:</b>\n`;
    msg += `• <b>Descargar:</b> ${escapeHtml(config.tracker.base_url)}/torrents/${escapeHtml(String(torrent.torrent_id))}\n`;

    if (config.features.include_imdb_link && torrent.imdb && torrent.imdb > 0) {
        msg += `• <b>IMDB:</b> https://imdb.com/title/tt${String(torrent.imdb).padStart(7, '0')}\n`;
    }

    if (config.features.include_tmdb_info && torrent.tmdb_movie_id && torrent.tmdb_movie_id > 0) {
        msg += `• <b>TMDB:</b> https://www.themoviedb.org/movie/${escapeHtml(String(torrent.tmdb_movie_id))}\n`;
    }

    return msg;
}

// Construir caption único combinando header + detalles (HTML, usar \n para saltos)
function buildSingleCaption(torrent) {
    const categoryEmoji = getCategoryEmoji(torrent.category);
    const categoryName = getCategoryName(torrent.category);
    const shortTitle = wrapPlain(torrent.name, 60);

    let caption = '';
    caption += `<b>${escapeHtml(categoryEmoji + ' NUEVO TORRENT EN ' + categoryName)}</b>\n`;
    caption += `\n<b>📁 ${escapeHtml(shortTitle)}</b>\n\n`;

    // Agregar detalles en líneas
    caption += buildDetailsMessage(torrent);

    // Footer opcional (pequeño branding)
    caption += `\n<b>${escapeHtml(config.tracker.name || config.tracker.base_url)}</b>`;

    return caption;
}

function extractSource(name) {
    const sources = ['BluRay', 'WEBRip', 'WEB-DL', 'HDTV', 'DVDRip', 'BDRip', 'REMUX'];
    if (!name) return null;
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
    if (!name) return null;
    const nameUpper = name.toUpperCase();
    for (const codec of codecs) {
        if (nameUpper.includes(codec.toUpperCase())) {
            return codec;
        }
    }
    return null;
}

function extractYear(name) {
    if (!name) return null;
    const yearMatch = name.match(/(19|20)\d{2}/);
    return yearMatch ? yearMatch[0] : null;
}

// Función para limpiar el título del torrent
function cleanTorrentTitle(torrentName) {
    try {
        if (!torrentName) return null;
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


// Helper para escapar caracteres HTML básicos
function escapeHtml(str) {
    if (!str && str !== 0) return '';
    return String(str)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;');
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

// Verificar si una URL existe (HEAD request)
function urlExists(url) {
    return new Promise((resolve) => {
        try {
            const req = https.request(url, { method: 'HEAD' }, (res) => {
                resolve(res.statusCode >= 200 && res.statusCode < 400);
            });
            req.on('error', () => resolve(false));
            req.setTimeout(3000, () => { req.destroy(); resolve(false); });
            req.end();
        } catch (err) {
            resolve(false);
        }
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
                const size = (config.features && config.features.poster_size) ? config.features.poster_size : 'w154';
                const imageUrl = `https://image.tmdb.org/t/p/${size}${firstResult.poster_path}`;
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
        // No bloquear por categoría aquí: películas/series usan TMDB; otras categorías
        // pueden tener imágenes subidas manualmente en el tracker. Intentaremos
        // obtener póster vía TMDB cuando aplique y cuando la API key exista.
        let imageUrl = null;

        // Verificar si las imágenes están habilitadas
        if (!config.features.include_poster_images) {
            logger.info(`🚫 Imágenes deshabilitadas en configuración`);
            return null;
        }

        // Determinar si TMDB está configurado (pero no abortar si no lo está)
        const tmdbConfigured = !!(config.tmdb && config.tmdb.api_key && config.tmdb.api_key !== 'TU_TMDB_API_KEY_AQUI');
        
        // Logging detallado de datos de entrada
        logger.info(`🔍 ANÁLISIS DE TORRENT:
        - ID: ${torrent.torrent_id}
        - Nombre: ${torrent.name}
        - Categoría: ${torrent.category}
        - TMDB Movie ID: ${torrent.tmdb_movie_id || 'NULL/UNDEFINED'}
        - TMDB TV ID: ${torrent.tmdb_tv_id || 'NULL/UNDEFINED'}
        - IMDB: ${torrent.imdb || 'NULL/UNDEFINED'}`);
        
        // Para películas: usar TMDB solo si hay ID y la API key está configurada
        if (torrent.category === 'Movies' || torrent.category === 'Peliculas') {
            if (torrent.tmdb_movie_id && torrent.tmdb_movie_id > 0 && tmdbConfigured) {
                logger.info(`🎬 Buscando póster para película TMDB ID: ${torrent.tmdb_movie_id}`);
                const url = `https://api.themoviedb.org/3/movie/${torrent.tmdb_movie_id}?api_key=${config.tmdb.api_key}`;

                const data = await makeRequest(url);
                logger.info(`🎬 Datos recibidos de TMDB: ${JSON.stringify(data, null, 2)}`);

                if (data.poster_path) {
                    const size = (config.features && config.features.poster_size) ? config.features.poster_size : 'w154';
                    imageUrl = `https://image.tmdb.org/t/p/${size}${data.poster_path}`;
                    logger.info(`✅ URL del póster construida: ${imageUrl}`);
                } else {
                    logger.warn(`⚠️ No se encontró poster_path para película ID ${torrent.tmdb_movie_id}`);
                }
            } else {
                logger.info(`ℹ️ Película sin TMDB disponible o TMDB no configurado: tmdb_movie_id=${torrent.tmdb_movie_id} tmdbConfigured=${tmdbConfigured}`);
            }
        }

        // Para series (incluyendo todas las variantes de tu tracker)
        const seriesCategories = ['TV', 'TV Shows', 'Series', 'Series de TV', 'TV Series', 'Anime', 'Asiáticas & Turcas', 'Telenovelas'];
        if (seriesCategories.includes(torrent.category)) {
            if (torrent.tmdb_tv_id && torrent.tmdb_tv_id > 0 && tmdbConfigured) {
                logger.info(`📺 Buscando póster para serie TMDB ID: ${torrent.tmdb_tv_id}`);
                const url = `https://api.themoviedb.org/3/tv/${torrent.tmdb_tv_id}?api_key=${config.tmdb.api_key}`;

                const data = await makeRequest(url);
                logger.info(`📺 Datos recibidos de TMDB: ${JSON.stringify(data, null, 2)}`);

                if (data.poster_path) {
                        const size = (config.features && config.features.poster_size) ? config.features.poster_size : 'w154';
                        imageUrl = `https://image.tmdb.org/t/p/${size}${data.poster_path}`;
                        logger.info(`✅ URL del póster construida: ${imageUrl}`);
                } else {
                    logger.warn(`⚠️ No se encontró poster_path para serie ID ${torrent.tmdb_tv_id}`);
                }
            } else {
                logger.info(`ℹ️ Serie/TV sin TMDB disponible o TMDB no configurado: tmdb_tv_id=${torrent.tmdb_tv_id} tmdbConfigured=${tmdbConfigured}`);
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

        // Intentar usar imagen manual subida en el tracker (ruta pública)
        if (!imageUrl) {
            try {
                const base = (config.tracker && config.tracker.base_url) ? config.tracker.base_url.replace(/\/$/, '') : null;
                if (base) {
                    const categoryUrl = `${base}/public-category-images/${encodeURIComponent(torrent.category)}`;
                    // Comprobar existencia mediante HEAD
                    const exists = await urlExists(categoryUrl);
                    if (exists) {
                        imageUrl = categoryUrl;
                        logger.info(`🖼️ Imagen de categoría manual encontrada: ${imageUrl}`);
                    } else {
                        logger.info(`🖼️ No se encontró imagen manual en: ${categoryUrl}`);
                    }
                }
            } catch (err) {
                logger.warn(`⚠️ Error comprobando imagen manual: ${err.message}`);
            }
        }

        logger.info(`[TMDB] Valor final de imageUrl: ${imageUrl}`);
        return imageUrl;
        
    } catch (error) {
        logger.error(`⚠️ Error obteniendo imagen para torrent ${torrent.torrent_id}: ${error.message}`);
        return null;
    }
}

// Descargar una imagen como Buffer
function downloadImageBuffer(url) {
    return new Promise((resolve, reject) => {
        try {
            https.get(url, (res) => {
                const chunks = [];
                res.on('data', (chunk) => chunks.push(chunk));
                res.on('end', () => resolve(Buffer.concat(chunks)));
                res.on('error', (err) => reject(err));
            }).on('error', (err) => reject(err));
        } catch (err) {
            reject(err);
        }
    });
}

// Redimensionar buffer con sharp (ancho fijo, mantener aspect ratio)
async function resizeImageBuffer(buffer, width) {
    try {
        const resized = await sharp(buffer)
            .resize({ width: width, withoutEnlargement: true })
            .jpeg({ quality: 85 })
            .toBuffer();
        return resized;
    } catch (err) {
        logger.warn(`⚠️ Error redimensionando imagen: ${err.message}`);
        throw err;
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

// Construir embed reutilizable para Discord (mismo formato que /discord/torrent-approved)
function buildDiscordEmbed(torrent) {
    const title = `${getCategoryEmoji(torrent.category)} NUEVO TORRENT EN ${getCategoryName(torrent.category)}`;
    const shortTitle = wrapPlain(torrent.name, 80);

    const fields = [];
    fields.push({ name: '📁 Título', value: shortTitle, inline: false });
    fields.push({ name: '👤 Uploader', value: String(torrent.user || 'N/A'), inline: true });
    fields.push({ name: '📂 Categoría', value: String(torrent.category || 'N/A'), inline: true });
    fields.push({ name: '💾 Tamaño', value: String(torrent.size || 'N/A'), inline: true });

    if (torrent.name) {
        const quality = extractQuality(torrent.name);
        const source = extractSource(torrent.name);
        const codec = extractCodec(torrent.name);
        const year = extractYear(torrent.name);
        if (quality) fields.push({ name: '🎞️ Calidad', value: String(quality), inline: true });
        if (source) fields.push({ name: '💿 Fuente', value: String(source), inline: true });
        if (codec) fields.push({ name: '🔧 Códec', value: String(codec), inline: true });
        if (year) fields.push({ name: '📅 Año', value: String(year), inline: true });
    }

    const links = [];
    links.push(`[Descargar](${config.tracker.base_url}/torrents/${torrent.torrent_id})`);
    if (config.features.include_imdb_link && torrent.imdb && torrent.imdb > 0) links.push(`[IMDB](https://imdb.com/title/tt${String(torrent.imdb).padStart(7,'0')})`);
    if (config.features.include_tmdb_info && torrent.tmdb_movie_id && torrent.tmdb_movie_id > 0) links.push(`[TMDB](https://www.themoviedb.org/movie/${torrent.tmdb_movie_id})`);

    fields.push({ name: '🔗 Enlaces', value: links.join(' • ') || 'N/A', inline: false });

    const embed = {
        title: title,
        description: undefined,
        color: 0x2ecc71,
        fields: fields,
        timestamp: new Date().toISOString()
    };

    return embed;
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
        
        // Obtener URL de imagen del póster si está disponible
        logger.info(`🔍 Intentando obtener póster para torrent ID: ${torrent.torrent_id}`);
        const posterUrl = await getPosterUrl(torrent);
        logger.info(`🔍 Resultado getPosterUrl: ${posterUrl}`);

        // Preparar parse_mode y preview
        const parseMode = (config.telegram && config.telegram.parse_mode) ? config.telegram.parse_mode : 'HTML';
        const disablePreview = (config.features && typeof config.features.disable_web_preview !== 'undefined') ? !!config.features.disable_web_preview : false;

        // Construir caption corto (para la foto) y mensaje detallado (se envía aparte)
        const categoryEmoji = getCategoryEmoji(torrent.category);
        const categoryName = getCategoryName(torrent.category);
    const shortTitle = wrapPlain(torrent.name, 60);

        const details = buildDetailsMessage(torrent);

        if (posterUrl) {
            logger.info(`📸 Enviando foto con caption (todo en un solo mensaje): ${posterUrl}`);
            try {
                // Construir caption completo (header + detalles) y truncar si es necesario
                const singleCaption = buildSingleCaption(torrent);
                const MAX_CAPTION = 1000; // seguro por debajo de límite de Telegram (~1024)
                const finalCaption = singleCaption.length > MAX_CAPTION ? singleCaption.slice(0, MAX_CAPTION - 3) + '...' : singleCaption;

                // Si está configurado poster_max_width, intentamos descargar y redimensionar la imagen
                if (config.features && config.features.poster_max_width) {
                    try {
                        const maxWidth = parseInt(config.features.poster_max_width, 10) || 320;
                        const imgBuffer = await downloadImageBuffer(posterUrl);
                        const resized = await resizeImageBuffer(imgBuffer, maxWidth);

                        await bot.sendPhoto(config.telegram.chat_id, resized, {
                            caption: finalCaption,
                            parse_mode: parseMode
                        });
                        logger.info(`✅ Foto (buffer) enviada exitosamente (redimensionada a ${maxWidth}px)`);
                    } catch (resizeError) {
                        logger.warn(`⚠️ Falló redimensionado/envío buffer: ${resizeError.message} — intentando enviar como URL`);
                        // Fallback a enviar por URL
                        await bot.sendPhoto(config.telegram.chat_id, posterUrl, {
                            caption: finalCaption,
                            parse_mode: parseMode
                        });
                    }
                } else {
                    // Enviar por URL si no se solicita redimensionado
                    await bot.sendPhoto(config.telegram.chat_id, posterUrl, {
                        caption: finalCaption,
                        parse_mode: parseMode
                    });
                }
                logger.info(`✅ Foto + caption enviada exitosamente`);
            } catch (photoError) {
                logger.error(`❌ Error enviando foto con caption: ${photoError.message}`);
                logger.info(`📝 Fallback: enviando solo detalle como texto`);
                await bot.sendMessage(config.telegram.chat_id, details, {
                    parse_mode: parseMode,
                    disable_web_page_preview: disablePreview
                });
            }
        } else {
            logger.info(`📝 No hay imagen, enviando solo mensaje de texto`);
            // Enviar solo mensaje de texto si no hay imagen
            await bot.sendMessage(config.telegram.chat_id, details, {
                parse_mode: parseMode,
                disable_web_page_preview: disablePreview
            });
        }
        
        logger.info(`✅ Notificación enviada exitosamente - ID: ${torrent.torrent_id}, Nombre: ${torrent.name}`);
        
        res.status(200).json({ 
            success: true, 
            message: 'Notificación enviada correctamente',
            torrent_id: torrent.torrent_id
        });
        
        // --- Forward to Discord if configured ---
        try {
            const discordWebhook = (config.discord && config.discord.webhook_url) ? config.discord.webhook_url : (torrent.webhook_url || null);
            if (discordWebhook) {
                logger.info(`🔁 Enviando notificación también a Discord: ${discordWebhook}`);
                const embed = buildDiscordEmbed(torrent);

                // attempt attachment if we have posterUrl and resizing configured
                if (posterUrl && config.features && config.features.poster_max_width) {
                    try {
                        const maxWidth = parseInt(config.features.poster_max_width, 10) || 320;
                        const imgBuffer = await downloadImageBuffer(posterUrl);
                        const resized = await resizeImageBuffer(imgBuffer, maxWidth);
                        const filename = `poster_${torrent.torrent_id}.jpg`;
                        embed.image = { url: `attachment://${filename}` };
                        const payload = { embeds: [embed] };
                        const sendResult = await sendDiscordWebhook(discordWebhook, payload, resized, filename);
                        logger.info('✅ Discord: notificación enviada con attachment', sendResult);
                    } catch (dErr) {
                        logger.warn('⚠️ Discord: fallo al adjuntar imagen, enviando embed con URL: ' + dErr.message);
                        embed.image = posterUrl ? { url: posterUrl } : undefined;
                        const payload = { embeds: [embed] };
                        const sendResult = await sendDiscordWebhook(discordWebhook, payload, null, null);
                        logger.info('✅ Discord: notificación enviada (fallback)', sendResult);
                    }
                } else {
                    // send embed without attachment
                    embed.image = posterUrl ? { url: posterUrl } : undefined;
                    const payload = { embeds: [embed] };
                    const sendResult = await sendDiscordWebhook(discordWebhook, payload, null, null);
                    logger.info('✅ Discord: notificación enviada', sendResult);
                }
            }
        } catch (err) {
            logger.error('❌ Error forwarding to Discord: ' + err.message, { error: err.stack });
        }
        
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

// Endpoint para enviar la misma notificación a Discord via Webhook
app.post('/discord/torrent-approved', async (req, res) => {
    try {
        const torrent = req.body;

        // Validar datos requeridos
        if (!torrent.torrent_id || !torrent.name || !torrent.user) {
            logger.warn('❌ Datos incompletos en notificación Discord:', torrent);
            return res.status(400).json({ 
                error: 'Datos incompletos. Se requieren: torrent_id, name, user' 
            });
        }

        // Obtener webhook: preferir config, luego el body
        const webhookUrl = (config.discord && config.discord.webhook_url) ? config.discord.webhook_url : (torrent.webhook_url || null);
        if (!webhookUrl) {
            logger.warn('❌ No hay webhook configurado para Discord');
            return res.status(400).json({ error: 'No webhook configurado. Añade config.discord.webhook_url o envía webhook_url en el body' });
        }

        // Filtrado
        if (!shouldNotify(torrent)) {
            logger.info(`⚠️ Torrent filtrado - Categoria: ${torrent.category}, Nombre: ${torrent.name}`);
            return res.status(200).json({ success: true, message: 'Torrent filtrado según configuración' });
        }

        // Obtener poster si aplica
        logger.info(`🔍 Discord: intentando obtener póster para torrent ID: ${torrent.torrent_id}`);
        const posterUrl = await getPosterUrl(torrent);
        logger.info(`🔍 Discord getPosterUrl: ${posterUrl}`);

        // Construir embed para Discord (plain text)
        function buildDiscordEmbed(torrent) {
            const title = `${getCategoryEmoji(torrent.category)} NUEVO TORRENT EN ${getCategoryName(torrent.category)}`;
            const shortTitle = wrapPlain(torrent.name, 80);

            const fields = [];
            fields.push({ name: '📁 Título', value: shortTitle, inline: false });
            fields.push({ name: '👤 Uploader', value: String(torrent.user || 'N/A'), inline: true });
            fields.push({ name: '📂 Categoría', value: String(torrent.category || 'N/A'), inline: true });
            fields.push({ name: '💾 Tamaño', value: String(torrent.size || 'N/A'), inline: true });

            if (torrent.name) {
                const quality = extractQuality(torrent.name);
                const source = extractSource(torrent.name);
                const codec = extractCodec(torrent.name);
                const year = extractYear(torrent.name);
                if (quality) fields.push({ name: '🎞️ Calidad', value: String(quality), inline: true });
                if (source) fields.push({ name: '💿 Fuente', value: String(source), inline: true });
                if (codec) fields.push({ name: '🔧 Códec', value: String(codec), inline: true });
                if (year) fields.push({ name: '📅 Año', value: String(year), inline: true });
            }

            // Links en el embed footer o en un field
            const links = [];
            links.push(`[Descargar](${config.tracker.base_url}/torrents/${torrent.torrent_id})`);
            if (config.features.include_imdb_link && torrent.imdb && torrent.imdb > 0) links.push(`[IMDB](https://imdb.com/title/tt${String(torrent.imdb).padStart(7,'0')})`);
            if (config.features.include_tmdb_info && torrent.tmdb_movie_id && torrent.tmdb_movie_id > 0) links.push(`[TMDB](https://www.themoviedb.org/movie/${torrent.tmdb_movie_id})`);

            fields.push({ name: '🔗 Enlaces', value: links.join(' • ') || 'N/A', inline: false });

            const embed = {
                title: title,
                description: undefined,
                color: 0x2ecc71,
                fields: fields,
                timestamp: new Date().toISOString()
            };

            // image handled separately (attachment or url)
            return embed;
        }

        const embed = buildDiscordEmbed(torrent);

        // Si tenemos poster y poster_max_width: descargar y enviar como attachment (multipart)
        if (posterUrl && config.features && config.features.poster_max_width) {
            try {
                const maxWidth = parseInt(config.features.poster_max_width, 10) || 320;
                const imgBuffer = await downloadImageBuffer(posterUrl);
                const resized = await resizeImageBuffer(imgBuffer, maxWidth);

                // preparar payload JSON referenciando attachment://filename
                const filename = `poster_${torrent.torrent_id}.jpg`;
                embed.image = { url: `attachment://${filename}` };
                const payload = { embeds: [embed] };

                const sendResult = await sendDiscordWebhook(webhookUrl, payload, resized, filename);
                logger.info('✅ Discord: notificación enviada con attachment', sendResult);
                return res.status(200).json({ success: true, message: 'Notificación Discord enviada (attachment)' });
            } catch (err) {
                logger.warn('⚠️ Discord: fallo al redimensionar/adjuntar, intentando enviar por URL: ' + err.message);
                // fallback a enviar embed con image.url = posterUrl
            }
        }

        // Enviar embed con posterUrl (o sin imagen si posterUrl null)
        if (posterUrl) embed.image = { url: posterUrl };
        const payload = { embeds: [embed] };
        const sendResult = await sendDiscordWebhook(webhookUrl, payload, null, null);
        logger.info('✅ Discord: notificación enviada', sendResult);
        return res.status(200).json({ success: true, message: 'Notificación Discord enviada' });

    } catch (error) {
        logger.error('❌ Error enviando notificación a Discord: ' + error.message, { error: error.stack });
        return res.status(500).json({ error: 'Error interno enviando a Discord', message: error.message });
    }
});

// Endpoint para probar Discord webhook
app.post('/discord/test', async (req, res) => {
    try {
        const webhookUrl = (config.discord && config.discord.webhook_url) ? config.discord.webhook_url : (req.body && req.body.webhook_url ? req.body.webhook_url : null);
        if (!webhookUrl) return res.status(400).json({ error: 'No webhook configured. Set config.discord.webhook_url or send webhook_url in body.' });

        const embed = {
            title: '🧪 MENSAJE DE PRUEBA - Discord',
            description: 'El servicio de notificaciones está funcionando correctamente.',
            color: 0x3498db,
            timestamp: new Date().toISOString()
        };

        const payload = { embeds: [embed] };
        const result = await sendDiscordWebhook(webhookUrl, payload, null, null);
        logger.info('✅ Discord test sent', result);
        res.status(200).json({ success: true, result });
    } catch (error) {
        logger.error('❌ Error sending Discord test: ' + error.message);
        res.status(500).json({ error: error.message });
    }
});

// Enviar al webhook de Discord. Si fileBuffer y filename están definidos, usamos multipart/form-data con payload_json y el archivo.
function sendDiscordWebhook(webhookUrl, payloadJson, fileBuffer, filename) {
    return new Promise((resolve, reject) => {
        try {
            const urlObj = new URL(webhookUrl);
            const options = {
                hostname: urlObj.hostname,
                path: urlObj.pathname + urlObj.search,
                method: 'POST',
                headers: {}
            };

            if (fileBuffer && filename) {
                const boundary = '----UNIT3DBoundary' + Date.now();
                options.headers['Content-Type'] = 'multipart/form-data; boundary=' + boundary;

                const payloadPart = `--${boundary}\r\nContent-Disposition: form-data; name="payload_json"\r\n\r\n${JSON.stringify(payloadJson)}\r\n`;
                const fileHeader = `--${boundary}\r\nContent-Disposition: form-data; name="file"; filename="${filename}"\r\nContent-Type: image/jpeg\r\n\r\n`;
                const endPart = `\r\n--${boundary}--\r\n`;

                const req = https.request(options, (res) => {
                    let data = '';
                    res.on('data', (chunk) => data += chunk);
                    res.on('end', () => resolve({ statusCode: res.statusCode, body: data }));
                });

                req.on('error', (err) => reject(err));

                req.write(payloadPart);
                req.write(fileHeader);
                req.write(fileBuffer);
                req.write(endPart);
                req.end();
            } else {
                const bodyStr = JSON.stringify(payloadJson);
                options.headers['Content-Type'] = 'application/json';
                options.headers['Content-Length'] = Buffer.byteLength(bodyStr);

                const req = https.request(options, (res) => {
                    let data = '';
                    res.on('data', (chunk) => data += chunk);
                    res.on('end', () => resolve({ statusCode: res.statusCode, body: data }));
                });
                req.on('error', (err) => reject(err));
                req.write(bodyStr);
                req.end();
            }
        } catch (err) {
            reject(err);
        }
    });
}

// Endpoint para probar la conexión con Telegram
app.post('/test-telegram', async (req, res) => {
    try {
        const testMessage = '🧪 MENSAJE DE PRUEBA\n\nEl bot de Telegram está funcionando correctamente.\n\n🕒 ' + new Date().toLocaleString();
        
        const parseMode = (config.telegram && config.telegram.parse_mode) ? config.telegram.parse_mode : 'HTML';
        await bot.sendMessage(config.telegram.chat_id, testMessage, {
            parse_mode: parseMode
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
