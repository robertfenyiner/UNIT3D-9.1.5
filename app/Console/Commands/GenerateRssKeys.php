<?php

declare(strict_types=1);

namespace App\Console\Commands;

use App\Models\User;
use Illuminate\Console\Command;
use Illuminate\Support\Str;

class GenerateRssKeys extends Command
{
    protected $signature = 'rss:generate-keys {--force : Force regenerate existing keys}';
    protected $description = 'Generate RSS keys for users who don\'t have them';

    public function handle(): int
    {
        $force = $this->option('force');
        
        $query = User::query();
        
        if (!$force) {
            $query->where(function ($q) {
                $q->whereNull('rsskey')
                  ->orWhere('rsskey', '');
            });
        }
        
        $users = $query->get();
        
        if ($users->isEmpty()) {
            $this->info('No users need RSS key generation.');
            return self::SUCCESS;
        }
        
        $this->info("Processing {$users->count()} users...");
        
        $updated = 0;
        
        foreach ($users as $user) {
            $oldKey = $user->rsskey;
            $newKey = Str::random(32);
            
            $user->update(['rsskey' => $newKey]);
            
            $this->line("User {$user->id} ({$user->username}): " . 
                      ($oldKey ? "Updated" : "Generated") . " RSS key");
            
            $updated++;
        }
        
        $this->info("✅ Successfully processed {$updated} users.");
        
        return self::SUCCESS;
    }
}