/**
 * Prueba completa del sistema UNIT3D Image Service
 * Ejecutar con: node test-complete.js
 */

const http = require('http');
const fs = require('fs');
const path = require('path');
const FormData = require('form-data');

console.log('🧪 UNIT3D Image Service - Prueba Completa');
console.log('==========================================\n');

const SERVICE_URL = 'http://localhost:3003';
let server;

// Función para crear imagen de prueba
function createTestImage() {
    console.log('🎨 Creando imagen de prueba...');
    
    // Crear un buffer de imagen PNG simple (1x1 pixel rojo)
    const pngBuffer = Buffer.from([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1x1 pixel
        0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 
        0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, // IDAT chunk
        0x54, 0x08, 0xD7, 0x63, 0xF8, 0x00, 0x00, 0x00,
        0xFF, 0xFF, 0x03, 0x00, 0x00, 0x06, 0x00, 0x05,
        0x57, 0xBF, 0xAB, 0xD4, 0x00, 0x00, 0x00, 0x00, // IEND chunk
        0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82
    ]);
    
    return pngBuffer;
}

// Función para hacer request HTTP
function makeRequest(options, data = null) {
    return new Promise((resolve, reject) => {
        const req = http.request(options, (res) => {
            let body = '';
            res.on('data', (chunk) => {
                body += chunk;
            });
            res.on('end', () => {
                try {
                    const parsedBody = res.headers['content-type']?.includes('application/json') 
                        ? JSON.parse(body) 
                        : body;
                    resolve({ statusCode: res.statusCode, body: parsedBody, headers: res.headers });
                } catch (err) {
                    resolve({ statusCode: res.statusCode, body: body, headers: res.headers });
                }
            });
        });
        
        req.on('error', reject);
        
        if (data) {
            if (data instanceof FormData) {
                req.setHeader('Content-Type', data.getHeaders()['content-type']);
                req.setHeader('Content-Length', data.getLengthSync());
                data.pipe(req);
            } else {
                req.write(data);
                req.end();
            }
        } else {
            req.end();
        }
    });
}

// Iniciar servidor para pruebas
async function startServer() {
    return new Promise((resolve, reject) => {
        console.log('🚀 Iniciando servidor de prueba...');
        
        const app = require('./app.js');
        server = app.listen(3003, 'localhost', (err) => {
            if (err) {
                reject(err);
            } else {
                console.log('✅ Servidor iniciado en http://localhost:3003\n');
                setTimeout(resolve, 1000); // Esperar 1 segundo para que el servidor esté listo
            }
        });
    });
}

// Detener servidor
function stopServer() {
    if (server) {
        console.log('\n🛑 Deteniendo servidor...');
        server.close();
        console.log('✅ Servidor detenido');
    }
}

// Prueba de health check
async function testHealthCheck() {
    console.log('🏥 Probando health check...');
    
    try {
        const result = await makeRequest({
            hostname: 'localhost',
            port: 3003,
            path: '/health',
            method: 'GET'
        });
        
        if (result.statusCode === 200) {
            console.log('✅ Health check OK');
            return true;
        } else {
            console.log(`❌ Health check falló: HTTP ${result.statusCode}`);
            return false;
        }
    } catch (error) {
        console.log(`❌ Error en health check: ${error.message}`);
        return false;
    }
}

// Prueba de interfaz web
async function testWebInterface() {
    console.log('🌐 Probando interfaz web...');
    
    try {
        const result = await makeRequest({
            hostname: 'localhost',
            port: 3003,
            path: '/',
            method: 'GET'
        });
        
        if (result.statusCode === 200 && result.body.includes('UNIT3D Image Uploader')) {
            console.log('✅ Interfaz web cargada');
            return true;
        } else {
            console.log(`❌ Interfaz web falló: HTTP ${result.statusCode}`);
            return false;
        }
    } catch (error) {
        console.log(`❌ Error en interfaz web: ${error.message}`);
        return false;
    }
}

// Prueba de subida de imagen
async function testImageUpload() {
    console.log('📤 Probando subida de imagen...');
    
    try {
        const imageBuffer = createTestImage();
        const form = new FormData();
        form.append('images', imageBuffer, {
            filename: 'test.png',
            contentType: 'image/png'
        });
        
        const result = await makeRequest({
            hostname: 'localhost',
            port: 3003,
            path: '/upload',
            method: 'POST'
        }, form);
        
        if (result.statusCode === 200 && result.body.success) {
            console.log('✅ Subida de imagen exitosa');
            console.log(`📊 Resultado: ${JSON.stringify(result.body, null, 2)}`);
            return { success: true, data: result.body };
        } else {
            console.log(`❌ Subida de imagen falló: HTTP ${result.statusCode}`);
            console.log(`📊 Error: ${JSON.stringify(result.body, null, 2)}`);
            return { success: false, error: result.body };
        }
    } catch (error) {
        console.log(`❌ Error en subida de imagen: ${error.message}`);
        return { success: false, error: error.message };
    }
}

// Prueba de acceso a imagen
async function testImageAccess(imageUrl) {
    console.log('🖼️ Probando acceso a imagen subida...');
    
    try {
        // Extraer path de la URL
        const url = new URL(imageUrl);
        const result = await makeRequest({
            hostname: 'localhost',
            port: 3003,
            path: url.pathname,
            method: 'GET'
        });
        
        if (result.statusCode === 200) {
            console.log('✅ Imagen accesible');
            return true;
        } else {
            console.log(`❌ Imagen no accesible: HTTP ${result.statusCode}`);
            return false;
        }
    } catch (error) {
        console.log(`❌ Error accediendo a imagen: ${error.message}`);
        return false;
    }
}

// Función principal
async function runTests() {
    let passed = 0;
    let total = 0;
    
    try {
        // Iniciar servidor
        await startServer();
        
        // Ejecutar pruebas
        const tests = [
            testHealthCheck,
            testWebInterface
        ];
        
        for (const test of tests) {
            total++;
            if (await test()) {
                passed++;
            }
            console.log(''); // Línea en blanco
        }
        
        // Prueba de subida con verificación de acceso
        total++;
        const uploadResult = await testImageUpload();
        if (uploadResult.success) {
            passed++;
            
            // Verificar acceso a la imagen subida
            if (uploadResult.data && uploadResult.data.data && uploadResult.data.data[0]) {
                const imageUrl = uploadResult.data.data[0].urls.image;
                total++;
                if (await testImageAccess(imageUrl)) {
                    passed++;
                }
            }
        }
        
        // Resumen
        console.log('\n' + '='.repeat(40));
        console.log('📊 RESUMEN DE PRUEBAS');
        console.log('='.repeat(40));
        console.log(`✅ Pasadas: ${passed}/${total}`);
        console.log(`❌ Fallidas: ${total - passed}/${total}`);
        
        if (passed === total) {
            console.log('\n🎉 ¡Todas las pruebas pasaron! El servicio está funcionando correctamente.');
            console.log('\n📋 Próximos pasos:');
            console.log('1. Configurar OneDrive con rclone (para producción)');
            console.log('2. Actualizar config.json con tu dominio');
            console.log('3. Configurar el servicio systemd (Linux)');
            console.log('4. Probar integración completa con UNIT3D');
        } else {
            console.log('\n⚠️ Algunas pruebas fallaron. Revisa los logs para más detalles.');
        }
        
    } catch (error) {
        console.error('💥 Error crítico durante las pruebas:', error);
    } finally {
        stopServer();
        
        // Limpiar archivos de prueba
        setTimeout(() => {
            const testFiles = fs.readdirSync('./storage/images').filter(f => f.startsWith('test'));
            testFiles.forEach(file => {
                fs.unlinkSync(path.join('./storage/images', file));
                console.log(`🧹 Limpiado: ${file}`);
            });
        }, 1000);
    }
}

// Verificar dependencias
if (!fs.existsSync('./node_modules')) {
    console.log('❌ Dependencias no instaladas. Ejecuta: npm install');
    process.exit(1);
}

// Ejecutar pruebas
runTests().catch(console.error);