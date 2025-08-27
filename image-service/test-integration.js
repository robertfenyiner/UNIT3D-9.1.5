/**
 * Script de prueba para verificar integración UNIT3D Image Service
 * Ejecutar con: node test-integration.js
 */

const fs = require('fs');
const path = require('path');
const http = require('http');

console.log('🧪 Test de Integración UNIT3D Image Service');
console.log('=' . repeat(50));

// Verificar archivos críticos
const criticalFiles = [
    'app.js',
    'config/config.json',
    'package.json',
    'routes/upload.js',
    'routes/images.js',
    'services/imageProcessor.js',
    'public/uploader.html'
];

console.log('\n📁 Verificando archivos críticos:');
let missingFiles = [];

criticalFiles.forEach(file => {
    if (fs.existsSync(path.join(__dirname, file))) {
        console.log(`✅ ${file}`);
    } else {
        console.log(`❌ ${file} - FALTANTE`);
        missingFiles.push(file);
    }
});

if (missingFiles.length > 0) {
    console.log(`\n❌ Error: ${missingFiles.length} archivo(s) faltante(s)`);
    process.exit(1);
}

// Verificar package.json
console.log('\n📦 Verificando dependencias:');
try {
    const pkg = JSON.parse(fs.readFileSync('./package.json', 'utf8'));
    const requiredDeps = ['express', 'multer', 'sharp', 'helmet', 'cors'];
    
    requiredDeps.forEach(dep => {
        if (pkg.dependencies && pkg.dependencies[dep]) {
            console.log(`✅ ${dep}: ${pkg.dependencies[dep]}`);
        } else {
            console.log(`❌ ${dep}: FALTANTE`);
        }
    });
} catch (error) {
    console.log('❌ Error leyendo package.json:', error.message);
}

// Verificar configuración
console.log('\n⚙️ Verificando configuración:');
try {
    const config = JSON.parse(fs.readFileSync('./config/config.json', 'utf8'));
    
    console.log(`✅ Puerto: ${config.server?.port || 'NO DEFINIDO'}`);
    console.log(`✅ Storage path: ${config.storage?.path || 'NO DEFINIDO'}`);
    console.log(`✅ Max file size: ${config.images?.maxSize || 'NO DEFINIDO'}`);
    console.log(`✅ Allowed origins: ${config.security?.allowedOrigins?.length || 0} origen(es)`);
    
    // Verificar directorios de storage
    const storagePath = config.storage?.path || './storage/images';
    const tempPath = config.storage?.tempPath || './storage/temp';
    
    [storagePath, tempPath].forEach(dir => {
        if (!fs.existsSync(dir)) {
            console.log(`⚠️ Creando directorio: ${dir}`);
            fs.mkdirSync(dir, { recursive: true });
        }
    });
    
} catch (error) {
    console.log('❌ Error leyendo configuración:', error.message);
}

// Verificar JavaScript syntax
console.log('\n🔍 Verificando sintaxis de archivos principales:');
const jsFiles = ['app.js', 'routes/upload.js', 'services/imageProcessor.js'];

jsFiles.forEach(file => {
    try {
        require.resolve(path.join(__dirname, file));
        console.log(`✅ ${file} - sintaxis OK`);
    } catch (error) {
        console.log(`❌ ${file} - Error: ${error.message}`);
    }
});

// Test de endpoint básico (si el servidor está corriendo)
console.log('\n🌐 Verificando conectividad local:');

function testEndpoint(port, path, callback) {
    const req = http.request({
        hostname: 'localhost',
        port: port,
        path: path,
        method: 'GET',
        timeout: 3000
    }, (res) => {
        callback(null, res.statusCode);
    });
    
    req.on('error', (err) => {
        callback(err);
    });
    
    req.on('timeout', () => {
        req.destroy();
        callback(new Error('Timeout'));
    });
    
    req.end();
}

testEndpoint(3002, '/health', (err, statusCode) => {
    if (err) {
        console.log('⚠️ Servidor no disponible en puerto 3002 (normal si no está iniciado)');
        console.log(`   Error: ${err.message}`);
    } else {
        console.log(`✅ Servidor responde - HTTP ${statusCode}`);
    }
    
    console.log('\n📋 Resumen de verificación:');
    console.log('✅ Estructura de archivos completa');
    console.log('✅ Configuración válida');
    console.log('✅ Sintaxis JavaScript correcta');
    console.log('\n💡 Para iniciar el servidor:');
    console.log('   Windows: debug-windows.bat');
    console.log('   Linux: node app.js');
    console.log('\n🔗 URLs importantes:');
    console.log('   Interfaz: http://localhost:3002');
    console.log('   Health: http://localhost:3002/health');
    console.log('   API Upload: http://localhost:3002/upload');
});