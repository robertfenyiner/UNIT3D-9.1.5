const multer = require('multer');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const config = require('../config/config.json');
const logger = require('../services/logger');

// Configuración de storage temporal
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, config.storage.tempPath);
    },
    filename: (req, file, cb) => {
        // Generar nombre único para archivo temporal
        const uniqueName = uuidv4() + path.extname(file.originalname);
        cb(null, uniqueName);
    }
});

// Filtro de archivos
const fileFilter = (req, file, cb) => {
    // Verificar tipo MIME
    if (!config.images.allowedTypes.includes(file.mimetype)) {
        logger.logSecurity('Invalid file type uploaded', {
            mimetype: file.mimetype,
            originalName: file.originalname,
            ip: req.ip
        });
        
        return cb(new Error(`Tipo de archivo no permitido: ${file.mimetype}. Tipos válidos: ${config.images.allowedTypes.join(', ')}`), false);
    }
    
    // Verificar extensión
    const extension = path.extname(file.originalname).toLowerCase();
    if (!config.images.allowedExtensions.includes(extension)) {
        logger.logSecurity('Invalid file extension uploaded', {
            extension: extension,
            originalName: file.originalname,
            ip: req.ip
        });
        
        return cb(new Error(`Extensión no permitida: ${extension}. Extensiones válidas: ${config.images.allowedExtensions.join(', ')}`), false);
    }
    
    // Sanitizar nombre de archivo
    const sanitizedName = file.originalname
        .replace(/[^a-zA-Z0-9.-]/g, '_') // Reemplazar caracteres especiales
        .replace(/_{2,}/g, '_') // Reemplazar múltiples underscores
        .toLowerCase();
    
    file.originalname = sanitizedName;
    
    cb(null, true);
};

// Configuración de multer
const upload = multer({
    storage: storage,
    fileFilter: fileFilter,
    limits: {
        fileSize: config.images.maxSizeBytes || 10 * 1024 * 1024, // 10MB por defecto
        files: 10, // Máximo 10 archivos por request
        fieldSize: 1024 * 1024 // 1MB para otros campos
    },
    onError: (err, next) => {
        logger.logError('Multer error', err);
        next(err);
    }
});

// Middleware para manejar errores de multer
const handleMulterError = (err, req, res, next) => {
    if (err instanceof multer.MulterError) {
        logger.logError('Multer error', err, {
            code: err.code,
            field: err.field,
            ip: req.ip
        });
        
        switch (err.code) {
            case 'LIMIT_FILE_SIZE':
                return res.status(413).json({
                    success: false,
                    error: 'File too large',
                    message: `Archivo demasiado grande. Tamaño máximo: ${config.images.maxSize}`,
                    code: err.code
                });
                
            case 'LIMIT_FILE_COUNT':
                return res.status(400).json({
                    success: false,
                    error: 'Too many files',
                    message: 'Demasiados archivos. Máximo 10 archivos por request.',
                    code: err.code
                });
                
            case 'LIMIT_UNEXPECTED_FILE':
                return res.status(400).json({
                    success: false,
                    error: 'Unexpected field',
                    message: `Campo inesperado: ${err.field}`,
                    code: err.code
                });
                
            default:
                return res.status(400).json({
                    success: false,
                    error: 'Upload error',
                    message: err.message,
                    code: err.code
                });
        }
    }
    
    next(err);
};

// Middleware de validación adicional
const validateUpload = (req, res, next) => {
    // Verificar que se subió al menos un archivo
    if (!req.files || req.files.length === 0) {
        return res.status(400).json({
            success: false,
            error: 'No files uploaded',
            message: 'No se subieron archivos'
        });
    }
    
    // Log de la subida
    logger.logUpload('Files received', {
        count: req.files.length,
        files: req.files.map(f => ({
            originalName: f.originalname,
            mimetype: f.mimetype,
            size: f.size
        })),
        ip: req.ip,
        userAgent: req.get('User-Agent')
    });
    
    next();
};

// Middleware para limpiar archivos temporales en caso de error
const cleanupTemp = (req, res, next) => {
    const originalSend = res.send;
    const originalJson = res.json;
    
    // Override res.send y res.json para cleanup automático
    const cleanup = () => {
        if (req.files && req.files.length > 0) {
            const fs = require('fs');
            req.files.forEach(file => {
                if (fs.existsSync(file.path)) {
                    fs.unlink(file.path, (err) => {
                        if (err) {
                            logger.warn(`No se pudo eliminar archivo temporal: ${file.path}`, err);
                        }
                    });
                }
            });
        }
    };
    
    res.send = function(...args) {
        cleanup();
        return originalSend.apply(this, args);
    };
    
    res.json = function(...args) {
        cleanup();
        return originalJson.apply(this, args);
    };
    
    next();
};

module.exports = {
    upload: upload.array('images', 10), // Permitir hasta 10 imágenes
    single: upload.single('image'), // Para una sola imagen
    handleMulterError,
    validateUpload,
    cleanupTemp
};