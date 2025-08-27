const rateLimit = require('express-rate-limit');
const config = require('../config/config.json');
const logger = require('../services/logger');

// Rate limiting para uploads
const uploadLimiter = rateLimit({
    windowMs: config.security.rateLimit.windowMs || 15 * 60 * 1000, // 15 minutos
    max: config.security.rateLimit.max || 50, // máximo 50 requests por ventana
    message: {
        success: false,
        error: 'Rate limit exceeded',
        message: config.security.rateLimit.message || 'Demasiadas requests. Intenta de nuevo más tarde.'
    },
    standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
    legacyHeaders: false, // Disable the `X-RateLimit-*` headers
    handler: (req, res) => {
        logger.logSecurity('Rate limit exceeded', {
            ip: req.ip,
            userAgent: req.get('User-Agent'),
            url: req.url
        });
        
        res.status(429).json({
            success: false,
            error: 'Rate limit exceeded',
            message: config.security.rateLimit.message || 'Demasiadas requests. Intenta de nuevo más tarde.'
        });
    },
    // Función para generar la key (por defecto usa IP)
    keyGenerator: (req) => {
        return req.ip;
    },
    // Skip successful requests (opcional)
    skip: (req, res) => {
        // No aplicar rate limit a health checks
        return req.path === '/health';
    }
});

// Rate limiting más estricto para endpoints sensibles
const strictLimiter = rateLimit({
    windowMs: 60 * 60 * 1000, // 1 hora
    max: 10, // máximo 10 requests por hora
    message: {
        success: false,
        error: 'Strict rate limit exceeded',
        message: 'Demasiadas requests a este endpoint. Intenta de nuevo en una hora.'
    },
    handler: (req, res) => {
        logger.logSecurity('Strict rate limit exceeded', {
            ip: req.ip,
            userAgent: req.get('User-Agent'),
            url: req.url
        });
        
        res.status(429).json({
            success: false,
            error: 'Strict rate limit exceeded',
            message: 'Demasiadas requests a este endpoint. Intenta de nuevo en una hora.'
        });
    }
});

// Rate limiting ligero para GET requests
const viewLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutos
    max: 1000, // 1000 requests por ventana para ver imágenes
    message: {
        success: false,
        error: 'View rate limit exceeded',
        message: 'Demasiadas requests de visualización.'
    },
    skip: (req, res) => {
        // No aplicar a health checks y OPTIONS
        return req.method === 'OPTIONS' || req.path === '/health';
    }
});

module.exports = {
    uploadLimiter,
    strictLimiter,
    viewLimiter
};