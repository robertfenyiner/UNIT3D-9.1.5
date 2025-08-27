const winston = require('winston');
const path = require('path');
const config = require('../config/config.json');

// Crear logger con Winston
const logger = winston.createLogger({
    level: config.logging.level || 'info',
    format: winston.format.combine(
        winston.format.timestamp({
            format: 'YYYY-MM-DD HH:mm:ss'
        }),
        winston.format.errors({ stack: true }),
        winston.format.json()
    ),
    defaultMeta: { 
        service: 'image-service' 
    },
    transports: [
        // Log a archivo
        new winston.transports.File({
            filename: config.logging.file || 'logs/image-service.log',
            maxsize: config.logging.maxSize ? 
                parseInt(config.logging.maxSize.replace('MB', '')) * 1024 * 1024 : 
                20 * 1024 * 1024,
            maxFiles: config.logging.maxFiles || 5,
            format: winston.format.combine(
                winston.format.timestamp(),
                winston.format.json()
            )
        }),
        
        // Log a consola (solo en desarrollo)
        new winston.transports.Console({
            format: winston.format.combine(
                winston.format.colorize(),
                winston.format.simple(),
                winston.format.printf(({ timestamp, level, message, service, ...meta }) => {
                    const metaStr = Object.keys(meta).length ? JSON.stringify(meta, null, 2) : '';
                    return `${timestamp} [${service}] ${level}: ${message} ${metaStr}`;
                })
            )
        })
    ]
});

// Función helper para log estructurado
logger.logUpload = (action, details) => {
    logger.info(`📤 ${action}`, {
        type: 'upload',
        action,
        ...details
    });
};

logger.logError = (action, error, details = {}) => {
    logger.error(`❌ ${action}`, {
        type: 'error',
        action,
        error: error.message,
        stack: error.stack,
        ...details
    });
};

logger.logSecurity = (event, details) => {
    logger.warn(`🔒 ${event}`, {
        type: 'security',
        event,
        ...details
    });
};

module.exports = logger;