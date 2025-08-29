<?php

declare(strict_types=1);

namespace App\Console\Commands;

use App\Models\User;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Storage;

class DiagnoseUserImages extends Command
{
    /**
     * The name and signature of the console command.
     */
    protected $signature = 'diagnose:user-images {--fix : Create missing directories and fix permissions}';

    /**
     * The console command description.
     */
    protected $description = 'Diagnose user avatar image issues';

    /**
     * Execute the console command.
     */
    public function handle(): void
    {
        $fix = $this->option('fix');
        
        $this->info('🔍 Diagnosing user avatar images...');
        $this->newLine();

        // 1. Verificar configuración de disco
        $this->info('📋 Storage Disk Configuration:');
        
        $diskConfig = config('filesystems.disks.user-avatars');
        if ($diskConfig) {
            $this->info("   ✅ Disk 'user-avatars' configured");
            $this->line("   📁 Root path: {$diskConfig['root']}");
            
            $actualPath = storage_path('app/images/users/avatars');
            $this->line("   📁 Full path: {$actualPath}");
            
            // Verificar si el directorio existe
            if (!is_dir($actualPath)) {
                $this->error("   ❌ Directory does not exist");
                
                if ($fix) {
                    $this->info("   🔧 Creating directory...");
                    if (mkdir($actualPath, 0755, true)) {
                        $this->info("   ✅ Directory created");
                    } else {
                        $this->error("   ❌ Failed to create directory");
                    }
                }
            } else {
                $this->info("   ✅ Directory exists");
                
                // Verificar permisos
                $perms = fileperms($actualPath);
                $this->line("   🔒 Permissions: " . substr(sprintf('%o', $perms), -4));
                
                if (!is_writable($actualPath)) {
                    $this->error("   ❌ Directory not writable");
                    
                    if ($fix) {
                        $this->info("   🔧 Fixing permissions...");
                        chmod($actualPath, 0755);
                        $this->info("   ✅ Permissions fixed");
                    }
                } else {
                    $this->info("   ✅ Directory is writable");
                }
                
                // Listar contenido
                $files = scandir($actualPath);
                $imageFiles = array_filter($files, function($file) {
                    return !in_array($file, ['.', '..']) && preg_match('/\.(jpg|jpeg|png|gif|webp)$/i', $file);
                });
                
                $this->line("   📄 Image files found: " . count($imageFiles));
                
                if (count($imageFiles) > 0 && count($imageFiles) <= 5) {
                    foreach ($imageFiles as $file) {
                        $this->line("      - {$file}");
                    }
                } elseif (count($imageFiles) > 5) {
                    $this->line("      - " . implode(', ', array_slice($imageFiles, 0, 3)) . " ... and " . (count($imageFiles) - 3) . " more");
                }
            }
        } else {
            $this->error("   ❌ Disk 'user-avatars' not configured");
        }
        
        $this->newLine();
        
        // 2. Verificar usuarios con imágenes
        $this->info('👥 Users with Avatar Images:');
        
        $usersWithImages = User::whereNotNull('image')
            ->where('image', '!=', '')
            ->get(['id', 'username', 'image']);
            
        $this->info("   📊 Total users with images: {$usersWithImages->count()}");
        
        if ($usersWithImages->count() > 0) {
            $this->newLine();
            $workingImages = 0;
            $brokenImages = 0;
            
            foreach ($usersWithImages as $user) {
                $this->line("   👤 User: {$user->username} (ID: {$user->id})");
                $this->line("      🖼️ Image filename: {$user->image}");
                
                try {
                    $disk = Storage::disk('user-avatars');
                    
                    if ($disk->exists($user->image)) {
                        $filePath = $disk->path($user->image);
                        $fileSize = filesize($filePath);
                        $this->info("      ✅ File exists ({$fileSize} bytes)");
                        $workingImages++;
                    } else {
                        $this->error("      ❌ File not found");
                        $brokenImages++;
                        
                        if ($fix) {
                            $this->info("      🔧 Clearing broken reference...");
                            $user->update(['image' => null]);
                            $this->info("      ✅ Reference cleared - user can upload new image");
                        }
                    }
                } catch (\Exception $e) {
                    $this->error("      ❌ Error accessing file: " . $e->getMessage());
                    $brokenImages++;
                }
                
                $this->newLine();
            }
            
            $this->info("📊 Summary:");
            $this->info("   ✅ Working images: {$workingImages}");
            $this->info("   ❌ Broken images: {$brokenImages}");
        }
        
        $this->newLine();
        
        // 3. Probar creación de archivo de prueba
        $this->info('🧪 Testing file creation:');
        
        try {
            $disk = Storage::disk('user-avatars');
            $testFileName = 'test_' . time() . '.txt';
            
            $disk->put($testFileName, 'Test file content');
            
            if ($disk->exists($testFileName)) {
                $this->info("   ✅ Test file created successfully");
                
                // Limpiar archivo de prueba
                $disk->delete($testFileName);
                $this->info("   ✅ Test file cleaned up");
            } else {
                $this->error("   ❌ Test file creation failed");
            }
        } catch (\Exception $e) {
            $this->error("   ❌ Error creating test file: " . $e->getMessage());
        }
        
        $this->newLine();
        
        // 4. Verificar ruta del controlador
        $this->info('🌐 Testing image controller route:');
        
        $testUser = User::whereNotNull('image')->first();
        
        if ($testUser) {
            $route = route('authenticated_images.user_avatar', ['user' => $testUser]);
            $this->line("   📋 Test URL: {$route}");
            $this->info("   💡 Try accessing this URL to test the image controller");
        } else {
            $this->info("   ℹ️ No users with images to test");
        }
        
        $this->newLine();
        
        if ($fix) {
            $this->info('✅ Diagnosis and fixes completed!');
        } else {
            $this->info('✅ Diagnosis completed!');
            $this->newLine();
            $this->comment('💡 To fix any issues found, run:');
            $this->line('   php artisan diagnose:user-images --fix');
        }
    }
}