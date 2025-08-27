const sharp = require('sharp');
const path = require('path');
const fs = require('fs');
const { v4: uuidv4 } = require('uuid');
const config = require('../config/config.json');
const logger = require('./logger');

class ImageProcessor {
    constructor() {
        this.maxWidth = config.images.maxWidth || 2000;
        this.maxHeight = config.images.maxHeight || 2000;
        this.quality = config.images.quality || 85;
        this.thumbnailWidth = config.images.thumbnailWidth || 350;
        this.thumbnailQuality = config.images.thumbnailQuality || 75;
    }

    /**
     * Procesa una imagen: redimensiona, optimiza y genera thumbnail
     */
    async processImage(inputBuffer, originalName, options = {}) {
        try {
            const startTime = Date.now();
            
            // Generar nombre único
            const extension = path.extname(originalName).toLowerCase();
            const baseName = uuidv4();
            const fileName = `${baseName}${extension}`;
            const thumbnailName = `${baseName}_thumb${extension}`;
            
            // Crear rutas de destino
            const outputPath = path.join(config.storage.path, fileName);
            const thumbnailPath = path.join(config.storage.path, 'thumbs', thumbnailName);
            
            // Asegurar que el directorio de thumbnails existe
            const thumbDir = path.join(config.storage.path, 'thumbs');
            if (!fs.existsSync(thumbDir)) {
                fs.mkdirSync(thumbDir, { recursive: true });
            }
            
            // Obtener metadata de la imagen original
            const metadata = await sharp(inputBuffer).metadata();
            
            logger.info(`🖼️ Procesando imagen: ${originalName}`, {
                originalSize: inputBuffer.length,
                dimensions: `${metadata.width}x${metadata.height}`,
                format: metadata.format
            });
            
            // Determinar si necesita redimensionamiento
            const needsResize = metadata.width > this.maxWidth || metadata.height > this.maxHeight;
            
            let processedImage = sharp(inputBuffer);
            
            // Redimensionar si es necesario (manteniendo aspect ratio)
            if (needsResize) {
                processedImage = processedImage.resize(this.maxWidth, this.maxHeight, {
                    fit: 'inside',
                    withoutEnlargement: true
                });
            }
            
            // Optimizar según el formato
            switch (metadata.format) {
                case 'jpeg':
                case 'jpg':
                    processedImage = processedImage.jpeg({ 
                        quality: this.quality,
                        progressive: true,
                        mozjpeg: true
                    });
                    break;
                    
                case 'png':
                    processedImage = processedImage.png({ 
                        compressionLevel: 8,
                        progressive: true
                    });
                    break;
                    
                case 'webp':
                    processedImage = processedImage.webp({ 
                        quality: this.quality,
                        effort: 4
                    });
                    break;
                    
                case 'gif':
                    // Para GIFs animados, mantenemos el formato original
                    processedImage = processedImage.gif();
                    break;
                    
                default:
                    // Convertir formatos no soportados a JPEG
                    processedImage = processedImage.jpeg({ 
                        quality: this.quality,
                        progressive: true
                    });
            }
            
            // Guardar imagen procesada
            const processedBuffer = await processedImage.toBuffer();
            await fs.promises.writeFile(outputPath, processedBuffer);
            
            // Generar thumbnail
            let thumbnailBuffer = null;
            if (config.features.enableThumbnails && metadata.format !== 'gif') {
                thumbnailBuffer = await sharp(inputBuffer)
                    .resize(this.thumbnailWidth, null, {
                        fit: 'inside',
                        withoutEnlargement: true
                    })
                    .jpeg({ quality: this.thumbnailQuality })
                    .toBuffer();
                    
                await fs.promises.writeFile(thumbnailPath, thumbnailBuffer);
            }
            
            // Obtener metadata de la imagen procesada
            const finalMetadata = await sharp(processedBuffer).metadata();
            
            const processingTime = Date.now() - startTime;
            
            const result = {
                success: true,
                original: {
                    name: originalName,
                    size: inputBuffer.length,
                    width: metadata.width,
                    height: metadata.height,
                    format: metadata.format
                },
                processed: {
                    fileName: fileName,
                    path: outputPath,
                    size: processedBuffer.length,
                    width: finalMetadata.width,
                    height: finalMetadata.height,
                    format: finalMetadata.format,
                    compression: Math.round((1 - processedBuffer.length / inputBuffer.length) * 100)
                },
                thumbnail: thumbnailBuffer ? {
                    fileName: thumbnailName,
                    path: thumbnailPath,
                    size: thumbnailBuffer.length
                } : null,
                processing: {
                    timeMs: processingTime,
                    resized: needsResize
                }
            };
            
            logger.logUpload('Image processed', {
                fileName: fileName,
                originalSize: inputBuffer.length,
                finalSize: processedBuffer.length,
                compression: result.processed.compression + '%',
                processingTime: processingTime + 'ms'
            });
            
            return result;
            
        } catch (error) {
            logger.logError('Image processing failed', error, {
                originalName,
                bufferSize: inputBuffer.length
            });
            throw error;
        }
    }

    /**
     * Valida si un buffer contiene una imagen válida
     */
    async validateImage(buffer, originalName) {
        try {
            const metadata = await sharp(buffer).metadata();
            
            // Verificar que es una imagen válida
            if (!metadata.format || !metadata.width || !metadata.height) {
                throw new Error('Archivo no es una imagen válida');
            }
            
            // Verificar tipo de archivo permitido
            const allowedFormats = ['jpeg', 'jpg', 'png', 'gif', 'webp'];
            if (!allowedFormats.includes(metadata.format.toLowerCase())) {
                throw new Error(`Formato ${metadata.format} no permitido. Formatos válidos: ${allowedFormats.join(', ')}`);
            }
            
            // Verificar dimensiones mínimas
            if (metadata.width < 10 || metadata.height < 10) {
                throw new Error('Imagen demasiado pequeña (mínimo 10x10px)');
            }
            
            // Verificar dimensiones máximas
            const maxDimension = 5000; // Límite de seguridad
            if (metadata.width > maxDimension || metadata.height > maxDimension) {
                throw new Error(`Imagen demasiado grande (máximo ${maxDimension}x${maxDimension}px)`);
            }
            
            return {
                valid: true,
                metadata: {
                    width: metadata.width,
                    height: metadata.height,
                    format: metadata.format,
                    size: buffer.length
                }
            };
            
        } catch (error) {
            logger.logError('Image validation failed', error, {
                originalName,
                bufferSize: buffer.length
            });
            
            return {
                valid: false,
                error: error.message
            };
        }
    }

    /**
     * Limpia archivos temporales antiguos
     */
    async cleanupTempFiles(maxAgeHours = 24) {
        try {
            const tempDir = config.storage.tempPath;
            if (!fs.existsSync(tempDir)) return;
            
            const files = await fs.promises.readdir(tempDir);
            const maxAge = maxAgeHours * 60 * 60 * 1000; // en millisegundos
            const now = Date.now();
            
            let deletedCount = 0;
            
            for (const file of files) {
                const filePath = path.join(tempDir, file);
                const stats = await fs.promises.stat(filePath);
                
                if (now - stats.mtimeMs > maxAge) {
                    await fs.promises.unlink(filePath);
                    deletedCount++;
                }
            }
            
            if (deletedCount > 0) {
                logger.info(`🧹 Cleanup: Eliminados ${deletedCount} archivos temporales`);
            }
            
        } catch (error) {
            logger.error('Cleanup failed:', error);
        }
    }
}

module.exports = new ImageProcessor();