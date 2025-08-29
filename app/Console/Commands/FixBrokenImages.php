<?php

declare(strict_types=1);

namespace App\Console\Commands;

use App\Models\User;
use Illuminate\Console\Command;

class FixBrokenImages extends Command
{
    /**
     * The name and signature of the console command.
     */
    protected $signature = 'fix:broken-images {--dry-run : Show what would be fixed without making changes}';

    /**
     * The console command description.
     */
    protected $description = 'Fix broken profile images from removed image-service';

    /**
     * Execute the console command.
     */
    public function handle(): void
    {
        $dryRun = $this->option('dry-run');
        
        $this->info('🔍 Searching for broken profile images...');
        $this->newLine();

        // Patrones de URLs rotas
        $brokenPatterns = [
            'localhost:3002',
            'http://localhost:3002/image/',
            'image-service',
            '/var/www/html/storage/images'
        ];

        $totalFound = 0;
        $totalFixed = 0;

        foreach ($brokenPatterns as $pattern) {
            $this->info("🔎 Searching for URLs containing: '$pattern'");
            
            $brokenUsers = User::whereNotNull('image')
                ->where('image', 'like', "%$pattern%")
                ->get(['id', 'username', 'image']);

            if ($brokenUsers->count() > 0) {
                $this->error("   ❌ Found {$brokenUsers->count()} users with broken URLs:");
                
                foreach ($brokenUsers as $user) {
                    $this->line("   - User: {$user->username} (ID: {$user->id})");
                    $this->line("     Broken URL: {$user->image}");
                    
                    if (!$dryRun) {
                        $user->update(['image' => null]);
                        $this->info("     ✅ Image cleared");
                        $totalFixed++;
                    } else {
                        $this->comment("     🔄 Would be cleared (dry-run mode)");
                    }
                    
                    $totalFound++;
                    $this->newLine();
                }
            } else {
                $this->info("   ✅ No URLs found with this pattern");
            }
            $this->newLine();
        }

        // Buscar URLs sospechosas adicionales
        $this->info('🔎 Checking for other suspicious image URLs...');
        
        $suspiciousUsers = User::whereNotNull('image')
            ->where('image', '!=', '')
            ->get(['id', 'username', 'image'])
            ->filter(function ($user) {
                $imageUrl = $user->image;
                
                // Servicios válidos conocidos
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
                
                // Verificar si es de un servicio válido
                foreach ($validServices as $service) {
                    if (str_contains($imageUrl, $service)) {
                        return false; // Es válida
                    }
                }
                
                // URLs sospechosas (locales o inválidas)
                return str_contains($imageUrl, 'localhost') ||
                       str_contains($imageUrl, '127.0.0.1') ||
                       str_contains($imageUrl, '192.168.') ||
                       str_contains($imageUrl, '10.0.') ||
                       (str_starts_with($imageUrl, 'http://') && !str_contains($imageUrl, '.com') && !str_contains($imageUrl, '.net') && !str_contains($imageUrl, '.org'));
            });

        if ($suspiciousUsers->count() > 0) {
            $this->warn("   ⚠️ Found {$suspiciousUsers->count()} suspicious URLs:");
            
            foreach ($suspiciousUsers as $user) {
                $this->line("   - User: {$user->username} (ID: {$user->id})");
                $this->line("     URL: {$user->image}");
                
                if (!$dryRun && $this->confirm("     Clean this URL?", false)) {
                    $user->update(['image' => null]);
                    $this->info("     ✅ URL cleaned");
                    $totalFixed++;
                } elseif ($dryRun) {
                    $this->comment("     🔄 Would ask to clean (dry-run mode)");
                }
                
                $totalFound++;
                $this->newLine();
            }
        } else {
            $this->info("   ✅ No suspicious URLs found");
        }

        // Resumen
        $this->newLine();
        $this->info('📊 SUMMARY:');
        $this->line('=============');
        
        if ($dryRun) {
            $this->comment("✅ Total images that would be fixed: $totalFound");
            $this->newLine();
            $this->info("💡 Run without --dry-run to actually fix the images:");
            $this->line("   php artisan fix:broken-images");
        } else {
            $this->info("✅ Total images found: $totalFound");
            $this->info("✅ Total images fixed: $totalFixed");
            
            if ($totalFixed > 0) {
                $this->newLine();
                $this->info("🎉 Broken images cleaned successfully!");
                $this->info("💡 Affected users can now upload new profile images.");
                $this->info("💡 New images will use imgbb.com as before.");
            }
        }
        
        $this->newLine();
        $this->info("✅ Command completed.");
    }
}