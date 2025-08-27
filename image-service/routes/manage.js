const express = require('express');
const fs = require('fs');
const path = require('path');
const { strictLimiter } = require('../middleware/rateLimit');
const config = require('../config/config.json');
const logger = require('../services/logger');
const imageProcessor = require('../services/imageProcessor');

const router = express.Router();

// Aplicar rate limiting estricto para operaciones de gestión
router.use(strictLimiter);

/**
 * DELETE /manage/image/:filename
 * Eliminar una imagen y su thumbnail
 */
router.delete('/image/:filename', async (req, res) => {
    try {
        const filename = req.params.filename;
        
        // Validar formato de filename (seguridad)
        if (!/^[a-f0-9-]+\.[a-z]+$/i.test(filename)) {
            return res.status(400).json({
                success: false,
                error: 'Invalid filename',
                message: 'Nombre de archivo inválido'
            });
        }
        
        const filePath = path.join(config.storage.path, filename);
        const baseName = path.parse(filename).name;
        const extension = path.parse(filename).ext;
        const thumbPath = path.join(config.storage.path, 'thumbs', `${baseName}_thumb.jpg`);
        
        let deletedFiles = [];
        let errors = [];
        
        // Eliminar imagen principal
        if (fs.existsSync(filePath)) {
            try {
                await fs.promises.unlink(filePath);
                deletedFiles.push(filename);
                logger.info(`Image deleted: ${filename}`, {
                    ip: req.ip,
                    filename: filename
                });
            } catch (error) {
                errors.push({
                    file: filename,
                    error: error.message
                });
            }
        } else {
            errors.push({
                file: filename,
                error: 'File not found'
            });
        }
        
        // Eliminar thumbnail si existe
        if (fs.existsSync(thumbPath)) {
            try {
                await fs.promises.unlink(thumbPath);
                deletedFiles.push(`${baseName}_thumb.jpg`);
            } catch (error) {
                errors.push({
                    file: `${baseName}_thumb.jpg`,
                    error: error.message
                });
            }
        }
        
        if (deletedFiles.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'File not found',
                message: 'Archivo no encontrado',
                errors: errors
            });
        }
        
        res.json({
            success: true,
            message: `Eliminados ${deletedFiles.length} archivo(s)`,
            deletedFiles: deletedFiles,
            errors: errors.length > 0 ? errors : undefined
        });
        
    } catch (error) {
        logger.error('Error deleting image:', error, {
            filename: req.params.filename,
            ip: req.ip
        });
        
        res.status(500).json({
            success: false,
            error: 'Internal server error',
            message: 'Error interno eliminando la imagen'
        });
    }
});

/**
 * GET /manage/list
 * Listar todas las imágenes (con paginación)
 */
router.get('/list', async (req, res) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = Math.min(parseInt(req.query.limit) || 50, 100); // Máximo 100
        const sortBy = req.query.sort || 'mtime'; // name, size, mtime
        const order = req.query.order === 'asc' ? 'asc' : 'desc';
        
        const storageDir = config.storage.path;
        
        if (!fs.existsSync(storageDir)) {
            return res.status(503).json({
                success: false,
                error: 'Storage not available',
                message: 'Directorio de almacenamiento no disponible'
            });
        }
        
        // Obtener lista de archivos
        const files = await fs.promises.readdir(storageDir);
        const imageFiles = files.filter(file => {
            const ext = path.extname(file).toLowerCase();
            return config.images.allowedExtensions.includes(ext);
        });
        
        // Obtener información de cada archivo
        const fileInfoPromises = imageFiles.map(async (filename) => {
            try {
                const filePath = path.join(storageDir, filename);
                const stats = await fs.promises.stat(filePath);
                
                return {
                    filename: filename,
                    size: stats.size,
                    sizeFormatted: formatBytes(stats.size),
                    created: stats.birthtime.toISOString(),
                    modified: stats.mtime.toISOString(),
                    url: `${config.storage.publicUrl}/${filename}`,
                    // Para ordenamiento
                    _sortKey: {
                        name: filename.toLowerCase(),
                        size: stats.size,
                        mtime: stats.mtime.getTime()
                    }
                };
            } catch (error) {
                return null; // Archivo inaccesible
            }
        });
        
        let fileInfos = (await Promise.all(fileInfoPromises)).filter(info => info !== null);
        
        // Ordenar
        fileInfos.sort((a, b) => {
            const aVal = a._sortKey[sortBy];
            const bVal = b._sortKey[sortBy];
            
            if (order === 'asc') {
                return aVal < bVal ? -1 : (aVal > bVal ? 1 : 0);
            } else {
                return aVal > bVal ? -1 : (aVal < bVal ? 1 : 0);
            }
        });
        
        // Remover claves de ordenamiento
        fileInfos = fileInfos.map(info => {
            const { _sortKey, ...cleanInfo } = info;
            return cleanInfo;
        });
        
        // Paginación
        const total = fileInfos.length;
        const totalPages = Math.ceil(total / limit);
        const startIndex = (page - 1) * limit;
        const endIndex = startIndex + limit;
        const paginatedFiles = fileInfos.slice(startIndex, endIndex);
        
        res.json({
            success: true,
            data: paginatedFiles,
            pagination: {
                page: page,
                limit: limit,
                total: total,
                totalPages: totalPages,
                hasNext: page < totalPages,
                hasPrev: page > 1
            },
            sort: {
                sortBy: sortBy,
                order: order
            }
        });
        
    } catch (error) {
        logger.error('Error listing images:', error, {
            ip: req.ip
        });
        
        res.status(500).json({
            success: false,
            error: 'Internal server error',
            message: 'Error listando las imágenes'
        });
    }
});

/**
 * GET /manage/stats
 * Estadísticas del almacenamiento
 */
router.get('/stats', async (req, res) => {
    try {
        const storageDir = config.storage.path;
        const thumbsDir = path.join(storageDir, 'thumbs');
        
        if (!fs.existsSync(storageDir)) {
            return res.status(503).json({
                success: false,
                error: 'Storage not available',
                message: 'Directorio de almacenamiento no disponible'
            });
        }
        
        // Obtener estadísticas de archivos principales
        const files = await fs.promises.readdir(storageDir);
        const imageFiles = files.filter(file => {
            const ext = path.extname(file).toLowerCase();
            return config.images.allowedExtensions.includes(ext);
        });
        
        let totalSize = 0;
        let totalImages = 0;
        const formatStats = {};
        
        for (const filename of imageFiles) {
            try {
                const filePath = path.join(storageDir, filename);
                const stats = await fs.promises.stat(filePath);
                const ext = path.extname(filename).toLowerCase().substring(1);
                
                totalSize += stats.size;
                totalImages++;
                
                formatStats[ext] = (formatStats[ext] || 0) + 1;
            } catch (error) {
                // Archivo inaccesible, continuar
            }
        }
        
        // Estadísticas de thumbnails
        let totalThumbs = 0;
        let thumbsSize = 0;
        
        if (fs.existsSync(thumbsDir)) {
            const thumbFiles = await fs.promises.readdir(thumbsDir);
            
            for (const filename of thumbFiles) {
                try {
                    const filePath = path.join(thumbsDir, filename);
                    const stats = await fs.promises.stat(filePath);
                    thumbsSize += stats.size;
                    totalThumbs++;
                } catch (error) {
                    // Continuar
                }
            }
        }
        
        res.json({
            success: true,
            data: {
                images: {
                    total: totalImages,
                    totalSize: totalSize,
                    totalSizeFormatted: formatBytes(totalSize),
                    formats: formatStats
                },
                thumbnails: {
                    total: totalThumbs,
                    totalSize: thumbsSize,
                    totalSizeFormatted: formatBytes(thumbsSize)
                },
                storage: {
                    path: storageDir,
                    combined: {
                        totalSize: totalSize + thumbsSize,
                        totalSizeFormatted: formatBytes(totalSize + thumbsSize),
                        totalFiles: totalImages + totalThumbs
                    }
                },
                config: {
                    maxFileSize: config.images.maxSize,
                    allowedFormats: config.images.allowedTypes,
                    features: {
                        thumbnails: config.features.enableThumbnails,
                        compression: config.features.enableCompression
                    }
                },
                timestamp: new Date().toISOString()
            }
        });
        
    } catch (error) {
        logger.error('Error getting storage stats:', error, {
            ip: req.ip
        });
        
        res.status(500).json({
            success: false,
            error: 'Internal server error',
            message: 'Error obteniendo estadísticas'
        });
    }
});

/**
 * POST /manage/cleanup
 * Limpiar archivos temporales y thumbnails huérfanos
 */
router.post('/cleanup', async (req, res) => {
    try {
        const results = {
            tempFiles: {
                deleted: 0,
                errors: []
            },
            orphanedThumbs: {
                deleted: 0,
                errors: []
            }
        };
        
        // Limpiar archivos temporales
        try {
            await imageProcessor.cleanupTempFiles(24); // 24 horas
            logger.info('Temp files cleanup completed', { ip: req.ip });
        } catch (error) {
            results.tempFiles.errors.push(error.message);
        }
        
        // Limpiar thumbnails huérfanos
        const thumbsDir = path.join(config.storage.path, 'thumbs');
        if (fs.existsSync(thumbsDir)) {
            try {
                const thumbFiles = await fs.promises.readdir(thumbsDir);
                
                for (const thumbFile of thumbFiles) {
                    const originalName = thumbFile.replace('_thumb', '').replace(/\.jpg$/, '');
                    const originalPath = path.join(config.storage.path, originalName);
                    
                    // Si la imagen original no existe, eliminar thumbnail
                    if (!fs.existsSync(originalPath)) {
                        try {
                            await fs.promises.unlink(path.join(thumbsDir, thumbFile));
                            results.orphanedThumbs.deleted++;
                        } catch (error) {
                            results.orphanedThumbs.errors.push({
                                file: thumbFile,
                                error: error.message
                            });
                        }
                    }
                }
                
            } catch (error) {
                results.orphanedThumbs.errors.push(error.message);
            }
        }
        
        logger.info('Cleanup completed', {
            tempFiles: results.tempFiles.deleted,
            orphanedThumbs: results.orphanedThumbs.deleted,
            ip: req.ip
        });
        
        res.json({
            success: true,
            message: 'Cleanup completado',
            results: results
        });
        
    } catch (error) {
        logger.error('Error during cleanup:', error, {
            ip: req.ip
        });
        
        res.status(500).json({
            success: false,
            error: 'Internal server error',
            message: 'Error durante la limpieza'
        });
    }
});

// Función helper para formatear bytes (compartida con images.js)
function formatBytes(bytes, decimals = 2) {
    if (bytes === 0) return '0 Bytes';
    
    const k = 1024;
    const dm = decimals < 0 ? 0 : decimals;
    const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
    
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    
    return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
}

module.exports = router;