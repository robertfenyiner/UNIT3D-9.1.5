const express = require('express');
const fs = require('fs');
const path = require('path');
const { uploadLimiter } = require('../middleware/rateLimit');
const { upload, handleMulterError, validateUpload, cleanupTemp } = require('../middleware/upload');
const imageProcessor = require('../services/imageProcessor');
const config = require('../config/config.json');
const logger = require('../services/logger');

const router = express.Router();

// Aplicar rate limiting
router.use(uploadLimiter);

/**
 * POST /upload
 * Subir una o múltiples imágenes
 */
router.post('/', 
    cleanupTemp,
    upload,
    handleMulterError,
    validateUpload,
    async (req, res) => {
        try {
            const startTime = Date.now();
            const results = [];
            const errors = [];
            
            // Procesar cada archivo
            for (const file of req.files) {
                try {
                    // Leer archivo temporal
                    const fileBuffer = await fs.promises.readFile(file.path);
                    
                    // Validar imagen
                    const validation = await imageProcessor.validateImage(fileBuffer, file.originalname);
                    if (!validation.valid) {
                        errors.push({
                            file: file.originalname,
                            error: validation.error
                        });
                        continue;
                    }
                    
                    // Procesar imagen
                    const processed = await imageProcessor.processImage(fileBuffer, file.originalname);
                    
                    // Generar URLs públicas
                    const baseUrl = config.storage.publicUrl;
                    const imageUrl = `${baseUrl}/${processed.processed.fileName}`;
                    const thumbnailUrl = processed.thumbnail ? 
                        `${baseUrl}/thumbs/${processed.thumbnail.fileName}` : null;
                    
                    // Preparar resultado
                    const result = {
                        success: true,
                        file: {
                            original: file.originalname,
                            filename: processed.processed.fileName,
                            size: processed.processed.size,
                            width: processed.processed.width,
                            height: processed.processed.height,
                            format: processed.processed.format
                        },
                        urls: {
                            image: imageUrl,
                            thumbnail: thumbnailUrl,
                            // URLs para BBCode
                            bbcode: `[img]${imageUrl}[/img]`,
                            bbcodeThumb: thumbnailUrl ? `[url=${imageUrl}][img]${thumbnailUrl}[/img][/url]` : null
                        },
                        stats: {
                            originalSize: processed.original.size,
                            finalSize: processed.processed.size,
                            compression: processed.processed.compression,
                            processingTime: processed.processing.timeMs
                        }
                    };
                    
                    results.push(result);
                    
                } catch (error) {
                    logger.logError('Error processing file', error, {
                        filename: file.originalname,
                        mimetype: file.mimetype,
                        size: file.size
                    });
                    
                    errors.push({
                        file: file.originalname,
                        error: error.message
                    });
                } finally {
                    // Limpiar archivo temporal
                    if (fs.existsSync(file.path)) {
                        await fs.promises.unlink(file.path);
                    }
                }
            }
            
            const totalTime = Date.now() - startTime;
            
            // Preparar respuesta
            const response = {
                success: results.length > 0,
                message: `Procesados ${results.length} de ${req.files.length} archivos`,
                totalFiles: req.files.length,
                successfulUploads: results.length,
                errors: errors.length,
                data: results,
                processingTime: totalTime
            };
            
            if (errors.length > 0) {
                response.errors = errors;
            }
            
            // Log del resultado
            logger.logUpload('Upload completed', {
                totalFiles: req.files.length,
                successful: results.length,
                errors: errors.length,
                totalTime: totalTime + 'ms',
                ip: req.ip
            });
            
            // Retornar respuesta compatible con imgbb
            if (results.length === 1 && errors.length === 0) {
                // Para compatibilidad con imgbb, formato simplificado para una imagen
                const result = results[0];
                return res.json({
                    success: true,
                    data: {
                        id: path.parse(result.file.filename).name,
                        title: result.file.original,
                        url_viewer: result.urls.image,
                        url: result.urls.image,
                        display_url: result.urls.image,
                        width: result.file.width,
                        height: result.file.height,
                        size: result.file.size,
                        time: Math.floor(Date.now() / 1000),
                        expiration: 0, // Sin expiración
                        image: {
                            filename: result.file.filename,
                            name: result.file.original,
                            mime: `image/${result.file.format}`,
                            extension: result.file.format,
                            url: result.urls.image
                        },
                        thumb: result.urls.thumbnail ? {
                            filename: result.urls.thumbnail.split('/').pop(),
                            name: result.file.original + '_thumb',
                            mime: 'image/jpeg',
                            extension: 'jpg',
                            url: result.urls.thumbnail
                        } : null,
                        // Campos adicionales para compatibilidad
                        bbcode_full: result.urls.bbcode,
                        bbcode_embed: result.urls.bbcode,
                        bbcode_thumbnail: result.urls.bbcodeThumb || result.urls.bbcode
                    }
                });
            }
            
            // Para múltiples archivos
            res.json(response);
            
        } catch (error) {
            logger.logError('Upload endpoint error', error, {
                ip: req.ip,
                filesCount: req.files ? req.files.length : 0
            });
            
            res.status(500).json({
                success: false,
                error: 'Internal server error',
                message: 'Error interno procesando la subida'
            });
        }
    }
);

/**
 * POST /upload/url
 * Subir imagen desde URL
 */
router.post('/url', async (req, res) => {
    try {
        const { url, filename } = req.body;
        
        if (!url) {
            return res.status(400).json({
                success: false,
                error: 'Missing URL',
                message: 'URL de imagen requerida'
            });
        }
        
        // Validar URL
        try {
            new URL(url);
        } catch {
            return res.status(400).json({
                success: false,
                error: 'Invalid URL',
                message: 'URL inválida'
            });
        }
        
        // Descargar imagen
        const https = require('https');
        const http = require('http');
        
        const client = url.startsWith('https:') ? https : http;
        
        const downloadPromise = new Promise((resolve, reject) => {
            const request = client.get(url, (response) => {
                if (response.statusCode !== 200) {
                    reject(new Error(`HTTP ${response.statusCode}`));
                    return;
                }
                
                const chunks = [];
                response.on('data', chunk => chunks.push(chunk));
                response.on('end', () => resolve(Buffer.concat(chunks)));
            });
            
            request.on('error', reject);
            request.setTimeout(10000, () => {
                request.destroy();
                reject(new Error('Timeout downloading image'));
            });
        });
        
        const imageBuffer = await downloadPromise;
        const originalName = filename || path.basename(new URL(url).pathname) || 'image.jpg';
        
        // Validar y procesar imagen
        const validation = await imageProcessor.validateImage(imageBuffer, originalName);
        if (!validation.valid) {
            return res.status(400).json({
                success: false,
                error: 'Invalid image',
                message: validation.error
            });
        }
        
        const processed = await imageProcessor.processImage(imageBuffer, originalName);
        
        // Generar respuesta
        const baseUrl = config.storage.publicUrl;
        const imageUrl = `${baseUrl}/${processed.processed.fileName}`;
        const thumbnailUrl = processed.thumbnail ? 
            `${baseUrl}/thumbs/${processed.thumbnail.fileName}` : null;
        
        logger.logUpload('URL upload completed', {
            url: url,
            filename: processed.processed.fileName,
            size: processed.processed.size,
            ip: req.ip
        });
        
        res.json({
            success: true,
            data: {
                id: path.parse(processed.processed.fileName).name,
                title: originalName,
                url_viewer: imageUrl,
                url: imageUrl,
                display_url: imageUrl,
                width: processed.processed.width,
                height: processed.processed.height,
                size: processed.processed.size,
                time: Math.floor(Date.now() / 1000),
                expiration: 0,
                image: {
                    filename: processed.processed.fileName,
                    name: originalName,
                    mime: `image/${processed.processed.format}`,
                    extension: processed.processed.format,
                    url: imageUrl
                },
                thumb: thumbnailUrl ? {
                    filename: thumbnailUrl.split('/').pop(),
                    name: originalName + '_thumb',
                    mime: 'image/jpeg',
                    extension: 'jpg',
                    url: thumbnailUrl
                } : null,
                bbcode_full: `[img]${imageUrl}[/img]`,
                bbcode_embed: `[img]${imageUrl}[/img]`,
                bbcode_thumbnail: thumbnailUrl ? `[url=${imageUrl}][img]${thumbnailUrl}[/img][/url]` : `[img]${imageUrl}[/img]`
            }
        });
        
    } catch (error) {
        logger.logError('URL upload error', error, {
            url: req.body.url,
            ip: req.ip
        });
        
        res.status(500).json({
            success: false,
            error: 'Upload failed',
            message: error.message
        });
    }
});

module.exports = router;