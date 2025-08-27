const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
const path = require('path');
const fs = require('fs');
// Cargar configuración según el entorno
const configFile = process.env.NODE_ENV === 'production' ? './config/config.json' : './config/config.dev.json';
const config = require(configFile);
const logger = require('./services/logger');

// Importar rutas
const uploadRoutes = require('./routes/upload');
const imageRoutes = require('./routes/images');
const manageRoutes = require('./routes/manage');
const healthRoutes = require('./routes/health');

const app = express();

// Crear directorios necesarios
const dirs = [
    config.storage.tempPath,
    path.dirname(config.logging.file)
];
dirs.forEach(dir => {
    if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
    }
});

// Middleware de seguridad
app.use(helmet({
    contentSecurityPolicy: false,
    crossOriginEmbedderPolicy: false
}));

// CORS configurado para UNIT3D
app.use(cors({
    origin: config.security.allowedOrigins,
    credentials: true,
    methods: ['GET', 'POST', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
}));

// Compresión
app.use(compression());

// Logging de requests
app.use(morgan('combined', {
    stream: {
        write: (message) => logger.info(message.trim())
    }
}));

// Parseo de JSON con límite
app.use(express.json({ limit: '1MB' }));
app.use(express.urlencoded({ extended: true, limit: '1MB' }));

// Servir archivos estáticos (interfaz web)
app.use('/static', express.static(path.join(__dirname, 'public')));

// Headers de seguridad adicionales
app.use((req, res, next) => {
    res.setHeader('X-Powered-By', 'UNIT3D Image Service');
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('X-Frame-Options', 'DENY');
    next();
});

// Rutas principales
app.use('/health', healthRoutes);
app.use('/upload', uploadRoutes);
app.use('/image', imageRoutes);
app.use('/manage', manageRoutes);

// Ruta principal - interfaz web
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'uploader.html'));
});

// Manejo de rutas no encontradas
app.use('*', (req, res) => {
    res.status(404).json({
        success: false,
        error: 'Endpoint not found',
        message: 'La ruta solicitada no existe'
    });
});

// Manejo global de errores
app.use((err, req, res, next) => {
    logger.error('Error no manejado:', {
        error: err.message,
        stack: err.stack,
        url: req.url,
        method: req.method,
        ip: req.ip
    });

    // Error de Multer (subida de archivos)
    if (err.code === 'LIMIT_FILE_SIZE') {
        return res.status(413).json({
            success: false,
            error: 'File too large',
            message: `Archivo demasiado grande. Máximo ${config.images.maxSize}`
        });
    }

    // Error de Multer (tipo no permitido)
    if (err.code === 'LIMIT_UNEXPECTED_FILE') {
        return res.status(400).json({
            success: false,
            error: 'Invalid file type',
            message: 'Tipo de archivo no permitido'
        });
    }

    // Error genérico
    res.status(500).json({
        success: false,
        error: 'Internal server error',
        message: 'Error interno del servidor'
    });
});

// Inicializar servidor
const PORT = config.server.port || 3002;
const HOST = config.server.host || 'localhost';

const server = app.listen(PORT, HOST, () => {
    logger.info(`🚀 ${config.server.name} iniciado en http://${HOST}:${PORT}`);
    logger.info(`📁 Storage path: ${config.storage.path}`);
    logger.info(`🔗 Public URL: ${config.storage.publicUrl}`);
    
    // Verificar que el directorio de storage existe
    if (!fs.existsSync(config.storage.path)) {
        logger.warn(`⚠️ Directorio de storage no existe: ${config.storage.path}`);
        logger.info('💡 Ejecuta: sudo bash scripts/setup-rclone.sh');
    } else {
        logger.info('✅ Storage directory disponible');
    }
});

// Manejo elegante de cierre
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
process.on('uncaughtException', (err) => {
    logger.error('💥 Excepción no capturada:', err);
    process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
    logger.error('💥 Promise rejection no manejada:', {
        reason: reason,
        promise: promise
    });
});

module.exports = app;