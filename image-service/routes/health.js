const express = require('express');
const fs = require('fs');
const path = require('path');
const config = require('../config/config.json');
const logger = require('../services/logger');

const router = express.Router();

// Health check básico
router.get('/', (req, res) => {
    const startTime = process.hrtime();
    
    try {
        // Verificar que el directorio de storage existe y es accesible
        const storageExists = fs.existsSync(config.storage.path);
        const tempExists = fs.existsSync(config.storage.tempPath);
        
        // Verificar espacio en disco (si está montado)
        let storageInfo = null;
        if (storageExists) {
            try {
                const stats = fs.statSync(config.storage.path);
                storageInfo = {
                    accessible: true,
                    isDirectory: stats.isDirectory()
                };
            } catch (err) {
                storageInfo = {
                    accessible: false,
                    error: err.message
                };
            }
        }
        
        const [seconds, nanoseconds] = process.hrtime(startTime);
        const responseTime = seconds * 1000 + nanoseconds / 1000000;
        
        const healthData = {
            success: true,
            status: 'healthy',
            timestamp: new Date().toISOString(),
            service: config.server.name || 'UNIT3D Image Service',
            version: '1.0.0',
            uptime: process.uptime(),
            responseTime: `${responseTime.toFixed(2)}ms`,
            memory: {
                used: Math.round(process.memoryUsage().heapUsed / 1024 / 1024),
                total: Math.round(process.memoryUsage().heapTotal / 1024 / 1024),
                external: Math.round(process.memoryUsage().external / 1024 / 1024)
            },
            storage: {
                path: config.storage.path,
                exists: storageExists,
                info: storageInfo,
                tempPath: config.storage.tempPath,
                tempExists: tempExists
            },
            config: {
                port: config.server.port,
                maxFileSize: config.images.maxSize,
                allowedTypes: config.images.allowedTypes.length,
                rateLimit: config.security.rateLimit.max + '/' + Math.round(config.security.rateLimit.windowMs / 60000) + 'min'
            }
        };
        
        // Determinar estado general
        if (!storageExists || !tempExists || (storageInfo && !storageInfo.accessible)) {
            healthData.status = 'degraded';
            healthData.warnings = [];
            
            if (!storageExists) {
                healthData.warnings.push('Storage directory does not exist');
            }
            if (!tempExists) {
                healthData.warnings.push('Temp directory does not exist');
            }
            if (storageInfo && !storageInfo.accessible) {
                healthData.warnings.push('Storage directory not accessible');
            }
        }
        
        const statusCode = healthData.status === 'healthy' ? 200 : 503;
        res.status(statusCode).json(healthData);
        
    } catch (error) {
        logger.error('Health check failed:', error);
        
        res.status(503).json({
            success: false,
            status: 'unhealthy',
            timestamp: new Date().toISOString(),
            error: error.message
        });
    }
});

// Health check detallado (para monitoring)
router.get('/detailed', (req, res) => {
    try {
        const stats = {
            success: true,
            timestamp: new Date().toISOString(),
            system: {
                platform: process.platform,
                arch: process.arch,
                nodeVersion: process.version,
                uptime: process.uptime(),
                pid: process.pid
            },
            memory: process.memoryUsage(),
            cpu: process.cpuUsage(),
            config: {
                ...config,
                // Ocultar información sensible
                security: {
                    ...config.security,
                    auth: {
                        enabled: config.security.auth.enabled,
                        apiKey: config.security.auth.apiKey ? '[HIDDEN]' : null
                    }
                }
            }
        };
        
        res.json(stats);
        
    } catch (error) {
        logger.error('Detailed health check failed:', error);
        
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Endpoint para verificar conectividad con OneDrive
router.get('/storage', (req, res) => {
    try {
        const storageHealth = {
            success: true,
            storage: {
                path: config.storage.path,
                exists: fs.existsSync(config.storage.path),
                writable: false,
                testFile: null
            }
        };
        
        // Test de escritura
        if (storageHealth.storage.exists) {
            try {
                const testPath = path.join(config.storage.path, `.health-check-${Date.now()}.txt`);
                fs.writeFileSync(testPath, 'Health check test');
                fs.unlinkSync(testPath);
                
                storageHealth.storage.writable = true;
                storageHealth.storage.testFile = 'success';
            } catch (writeError) {
                storageHealth.storage.writable = false;
                storageHealth.storage.testFile = writeError.message;
                storageHealth.success = false;
            }
        } else {
            storageHealth.success = false;
        }
        
        const statusCode = storageHealth.success ? 200 : 503;
        res.status(statusCode).json(storageHealth);
        
    } catch (error) {
        logger.error('Storage health check failed:', error);
        
        res.status(503).json({
            success: false,
            error: error.message
        });
    }
});

module.exports = router;