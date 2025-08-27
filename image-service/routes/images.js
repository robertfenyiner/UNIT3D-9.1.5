const express = require('express');
const fs = require('fs');
const path = require('path');
const mime = require('mime-types');
const { viewLimiter } = require('../middleware/rateLimit');
const config = require('../config/config.json');
const logger = require('../services/logger');

const router = express.Router();

// Aplicar rate limiting ligero para visualización
router.use(viewLimiter);

/**
 * GET /image/:filename
 * Servir imagen directamente
 */
router.get('/:filename', async (req, res) => {
    try {
        const filename = req.params.filename;
        const filePath = path.join(config.storage.path, filename);
        
        // Validar que el archivo existe
        if (!fs.existsSync(filePath)) {
            return res.status(404).json({
                success: false,
                error: 'Image not found',
                message: 'Imagen no encontrada'
            });
        }
        
        // Obtener información del archivo
        const stats = fs.statSync(filePath);
        const mimeType = mime.lookup(filePath) || 'application/octet-stream';
        
        // Headers de cache y seguridad
        res.set({
            'Content-Type': mimeType,
            'Content-Length': stats.size,
            'Cache-Control': 'public, max-age=31536000', // 1 año
            'ETag': `"${stats.mtime.getTime()}-${stats.size}"`,
            'Last-Modified': stats.mtime.toUTCString(),
            'X-Content-Type-Options': 'nosniff',
            'Content-Security-Policy': "default-src 'none'",
            'X-Frame-Options': 'DENY'
        });
        
        // Verificar If-None-Match (ETag)
        const clientETag = req.headers['if-none-match'];
        const serverETag = `"${stats.mtime.getTime()}-${stats.size}"`;
        
        if (clientETag && clientETag === serverETag) {
            return res.status(304).end();
        }
        
        // Verificar If-Modified-Since
        const ifModifiedSince = req.headers['if-modified-since'];
        if (ifModifiedSince) {
            const clientTime = new Date(ifModifiedSince);
            const serverTime = new Date(stats.mtime);
            
            if (serverTime <= clientTime) {
                return res.status(304).end();
            }
        }
        
        // Soporte para Range requests (para videos/imágenes grandes)
        const range = req.headers.range;
        if (range) {
            const parts = range.replace(/bytes=/, '').split('-');
            const start = parseInt(parts[0], 10);
            const end = parts[1] ? parseInt(parts[1], 10) : stats.size - 1;
            
            if (start >= stats.size || end >= stats.size) {
                return res.status(416).set({
                    'Content-Range': `bytes */${stats.size}`
                }).end();
            }
            
            const chunkSize = (end - start) + 1;
            res.status(206).set({
                'Content-Range': `bytes ${start}-${end}/${stats.size}`,
                'Accept-Ranges': 'bytes',
                'Content-Length': chunkSize
            });
            
            const stream = fs.createReadStream(filePath, { start, end });
            return stream.pipe(res);
        }
        
        // Enviar archivo completo
        const stream = fs.createReadStream(filePath);
        stream.pipe(res);
        
        // Log de acceso (solo para debugging, comentar en producción para performance)
        if (config.logging.level === 'debug') {
            logger.info(`Image served: ${filename}`, {
                filename,
                size: stats.size,
                mimeType,
                ip: req.ip,
                userAgent: req.get('User-Agent')
            });
        }
        
    } catch (error) {
        logger.error('Error serving image:', error, {
            filename: req.params.filename,
            ip: req.ip
        });
        
        res.status(500).json({
            success: false,
            error: 'Internal server error',
            message: 'Error interno sirviendo la imagen'
        });
    }
});

/**
 * GET /image/thumbs/:filename  
 * Servir thumbnails
 */
router.get('/thumbs/:filename', async (req, res) => {
    try {
        const filename = req.params.filename;
        const filePath = path.join(config.storage.path, 'thumbs', filename);
        
        // Validar que el archivo existe
        if (!fs.existsSync(filePath)) {
            // Si no existe el thumbnail, intentar servir la imagen original
            const originalPath = path.join(config.storage.path, filename.replace('_thumb', ''));
            if (fs.existsSync(originalPath)) {
                return res.redirect(`/image/${filename.replace('_thumb', '')}`);
            }
            
            return res.status(404).json({
                success: false,
                error: 'Thumbnail not found',
                message: 'Thumbnail no encontrado'
            });
        }
        
        // Obtener información del archivo
        const stats = fs.statSync(filePath);
        const mimeType = mime.lookup(filePath) || 'image/jpeg';
        
        // Headers optimizados para thumbnails
        res.set({
            'Content-Type': mimeType,
            'Content-Length': stats.size,
            'Cache-Control': 'public, max-age=31536000', // Cache agresivo para thumbnails
            'ETag': `"thumb-${stats.mtime.getTime()}-${stats.size}"`,
            'Last-Modified': stats.mtime.toUTCString(),
            'X-Content-Type-Options': 'nosniff'
        });
        
        // Verificar cache
        const clientETag = req.headers['if-none-match'];
        const serverETag = `"thumb-${stats.mtime.getTime()}-${stats.size}"`;
        
        if (clientETag && clientETag === serverETag) {
            return res.status(304).end();
        }
        
        // Enviar thumbnail
        const stream = fs.createReadStream(filePath);
        stream.pipe(res);
        
    } catch (error) {
        logger.error('Error serving thumbnail:', error, {
            filename: req.params.filename,
            ip: req.ip
        });
        
        res.status(500).json({
            success: false,
            error: 'Internal server error',
            message: 'Error interno sirviendo el thumbnail'
        });
    }
});

/**
 * GET /image/info/:filename
 * Obtener información de una imagen
 */
router.get('/info/:filename', async (req, res) => {
    try {
        const filename = req.params.filename;
        const filePath = path.join(config.storage.path, filename);
        
        if (!fs.existsSync(filePath)) {
            return res.status(404).json({
                success: false,
                error: 'Image not found',
                message: 'Imagen no encontrada'
            });
        }
        
        const stats = fs.statSync(filePath);
        const mimeType = mime.lookup(filePath) || 'application/octet-stream';
        
        // Obtener metadatos de la imagen usando Sharp
        const sharp = require('sharp');
        let metadata = null;
        
        try {
            metadata = await sharp(filePath).metadata();
        } catch (sharpError) {
            logger.warn('Could not get image metadata:', sharpError);
        }
        
        const info = {
            success: true,
            data: {
                filename: filename,
                size: stats.size,
                sizeFormatted: formatBytes(stats.size),
                mimeType: mimeType,
                created: stats.birthtime.toISOString(),
                modified: stats.mtime.toISOString(),
                url: `${config.storage.publicUrl}/${filename}`,
                metadata: metadata ? {
                    width: metadata.width,
                    height: metadata.height,
                    format: metadata.format,
                    space: metadata.space,
                    channels: metadata.channels,
                    depth: metadata.depth,
                    density: metadata.density,
                    hasProfile: metadata.hasProfile,
                    hasAlpha: metadata.hasAlpha
                } : null
            }
        };
        
        // Verificar si existe thumbnail
        const thumbPath = path.join(config.storage.path, 'thumbs', filename.replace(/\.[^.]+$/, '_thumb.jpg'));
        if (fs.existsSync(thumbPath)) {
            info.data.thumbnail = `${config.storage.publicUrl}/thumbs/${path.basename(thumbPath)}`;
        }
        
        res.json(info);
        
    } catch (error) {
        logger.error('Error getting image info:', error, {
            filename: req.params.filename,
            ip: req.ip
        });
        
        res.status(500).json({
            success: false,
            error: 'Internal server error',
            message: 'Error obteniendo información de la imagen'
        });
    }
});

/**
 * HEAD /image/:filename
 * Solo headers para verificar existencia sin transferir datos
 */
router.head('/:filename', (req, res) => {
    try {
        const filename = req.params.filename;
        const filePath = path.join(config.storage.path, filename);
        
        if (!fs.existsSync(filePath)) {
            return res.status(404).end();
        }
        
        const stats = fs.statSync(filePath);
        const mimeType = mime.lookup(filePath) || 'application/octet-stream';
        
        res.set({
            'Content-Type': mimeType,
            'Content-Length': stats.size,
            'Cache-Control': 'public, max-age=31536000',
            'ETag': `"${stats.mtime.getTime()}-${stats.size}"`,
            'Last-Modified': stats.mtime.toUTCString()
        });
        
        res.status(200).end();
        
    } catch (error) {
        res.status(500).end();
    }
});

// Función helper para formatear bytes
function formatBytes(bytes, decimals = 2) {
    if (bytes === 0) return '0 Bytes';
    
    const k = 1024;
    const dm = decimals < 0 ? 0 : decimals;
    const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
    
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    
    return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
}

module.exports = router;