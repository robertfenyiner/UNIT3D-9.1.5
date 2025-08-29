<?php

/**
 * Script para arreglar imágenes rotas de perfiles de usuario
 * Busca y limpia URLs que apunten al servicio image-service eliminado
 */

require_once __DIR__.'/vendor/autoload.php';

use Illuminate\Database\Capsule\Manager as Capsule;
use Illuminate\Support\Facades\DB;

// Configurar conexión a base de datos
$capsule = new Capsule;

// Cargar configuración de Laravel
$config = include __DIR__.'/config/database.php';
$defaultConnection = $config['default'];
$dbConfig = $config['connections'][$defaultConnection];

$capsule->addConnection([
    'driver' => $dbConfig['driver'],
    'host' => $dbConfig['host'],
    'port' => $dbConfig['port'],
    'database' => $dbConfig['database'],
    'username' => $dbConfig['username'],
    'password' => $dbConfig['password'],
    'charset' => $dbConfig['charset'] ?? 'utf8mb4',
    'collation' => $dbConfig['collation'] ?? 'utf8mb4_unicode_ci',
]);

$capsule->setAsGlobal();
$capsule->bootEloquent();

echo "🔍 Buscando imágenes rotas en perfiles de usuario...\n\n";

try {
    // Patrones de URLs rotas que debemos buscar
    $brokenPatterns = [
        'localhost:3002',
        'http://localhost:3002/image/',
        'image-service',
        '/var/www/html/storage/images'
    ];

    $totalFixed = 0;

    foreach ($brokenPatterns as $pattern) {
        echo "🔎 Buscando URLs que contengan: '$pattern'\n";
        
        // Buscar usuarios con imágenes que contengan el patrón
        $brokenUsers = Capsule::table('users')
            ->whereNotNull('image')
            ->where('image', 'like', "%$pattern%")
            ->select('id', 'username', 'image')
            ->get();

        if ($brokenUsers->count() > 0) {
            echo "   ❌ Encontrados {$brokenUsers->count()} usuarios con URLs rotas:\n";
            
            foreach ($brokenUsers as $user) {
                echo "   - Usuario: {$user->username} (ID: {$user->id})\n";
                echo "     URL rota: {$user->image}\n";
                
                // Limpiar la URL rota (establecer como NULL)
                Capsule::table('users')
                    ->where('id', $user->id)
                    ->update(['image' => null]);
                
                echo "     ✅ Imagen limpiada\n\n";
                $totalFixed++;
            }
        } else {
            echo "   ✅ No se encontraron URLs con este patrón\n\n";
        }
    }

    // Buscar otras URLs sospechosas (que no sean de servicios conocidos)
    echo "🔎 Verificando otras URLs de imágenes...\n";
    
    $allImageUsers = Capsule::table('users')
        ->whereNotNull('image')
        ->where('image', '!=', '')
        ->select('id', 'username', 'image')
        ->get();

    $suspiciousUrls = [];
    
    foreach ($allImageUsers as $user) {
        $imageUrl = $user->image;
        
        // Verificar si es una URL válida de servicio conocido
        $validServices = [
            'imgur.com',
            'imgbb.com', 
            'postimg.cc',
            'ibb.co',
            'i.postimg.cc',
            'gravatar.com',
            'github.com',
            'githubusercontent.com'
        ];
        
        $isValid = false;
        foreach ($validServices as $service) {
            if (strpos($imageUrl, $service) !== false) {
                $isValid = true;
                break;
            }
        }
        
        // Si no es de un servicio conocido y parece ser local, marcarlo como sospechoso
        if (!$isValid && (
            strpos($imageUrl, 'localhost') !== false ||
            strpos($imageUrl, '127.0.0.1') !== false ||
            strpos($imageUrl, 'http://') === 0 && strpos($imageUrl, '.') === false
        )) {
            $suspiciousUrls[] = $user;
        }
    }

    if (count($suspiciousUrls) > 0) {
        echo "   ⚠️ Encontradas " . count($suspiciousUrls) . " URLs sospechosas:\n";
        
        foreach ($suspiciousUrls as $user) {
            echo "   - Usuario: {$user->username} (ID: {$user->id})\n";
            echo "     URL: {$user->image}\n";
            
            // Preguntar si limpiar estas también
            if (php_sapi_name() === 'cli') {
                echo "     ¿Limpiar esta URL? (y/N): ";
                $handle = fopen("php://stdin", "r");
                $response = trim(fgets($handle));
                fclose($handle);
                
                if (strtolower($response) === 'y' || strtolower($response) === 'yes') {
                    Capsule::table('users')
                        ->where('id', $user->id)
                        ->update(['image' => null]);
                    echo "     ✅ URL limpiada\n";
                    $totalFixed++;
                }
            }
            echo "\n";
        }
    } else {
        echo "   ✅ No se encontraron URLs sospechosas\n\n";
    }

    // Resumen
    echo "📊 RESUMEN:\n";
    echo "=============\n";
    echo "✅ Total de imágenes arregladas: $totalFixed\n";
    
    if ($totalFixed > 0) {
        echo "🎉 ¡Imágenes rotas limpiadas exitosamente!\n\n";
        echo "💡 Los usuarios afectados ahora pueden subir nuevas imágenes de perfil.\n";
        echo "💡 Las nuevas imágenes usarán imgbb.com como antes.\n";
    } else {
        echo "ℹ️ No se encontraron imágenes rotas que limpiar.\n";
    }

} catch (Exception $e) {
    echo "❌ Error: " . $e->getMessage() . "\n";
    echo "Stack trace:\n" . $e->getTraceAsString() . "\n";
}

echo "\n✅ Script completado.\n";