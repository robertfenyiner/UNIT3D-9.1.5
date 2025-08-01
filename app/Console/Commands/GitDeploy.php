<?php

declare(strict_types=1);

namespace App\Console\Commands;

use App\Console\ConsoleTools;
use Illuminate\Console\Command;

class GitDeploy extends Command
{
    use ConsoleTools;

    /**
     * The console command signature.
     */
    protected $signature = 'git:deploy {--force : Force deployment without confirmation}';

    /**
     * The console command description.
     */
    protected $description = 'Deploy latest changes from Git repository (optimized for development workflow)';

    /**
     * Execute the console command.
     */
    public function handle(): int
    {
        $this->info('🚀 Starting Git deployment...');

        // Check if we have uncommitted changes
        $status = shell_exec('git status --porcelain');
        if (!empty(trim($status))) {
            $this->warning('⚠️  You have uncommitted changes:');
            $this->line($status);
            
            if (!$this->option('force') && !$this->confirm('Continue with deployment?', false)) {
                $this->error('Deployment cancelled.');
                return 1;
            }
        }

        // Backup critical files
        $this->info('📦 Backing up critical files...');
        $this->execCommand('cp .env /tmp/env_backup_deploy');
        if (file_exists('laravel-echo-server.json')) {
            $this->execCommand('cp laravel-echo-server.json /tmp/echo_backup_deploy');
        }

        // Put application in maintenance mode
        $this->info('🔒 Putting application in maintenance mode...');
        $this->call('down');

        try {
            // Pull latest changes
            $this->info('⬇️  Pulling latest changes...');
            $this->execCommand('git fetch origin');
            $this->execCommand('git pull origin master');

            // Restore critical files
            $this->info('🔄 Restoring critical files...');
            $this->execCommand('cp /tmp/env_backup_deploy .env');
            if (file_exists('/tmp/echo_backup_deploy')) {
                $this->execCommand('cp /tmp/echo_backup_deploy laravel-echo-server.json');
            }

            // Run migrations
            if ($this->confirm('Run database migrations?', true)) {
                $this->info('🗄️  Running migrations...');
                $this->call('migrate', ['--force' => true]);
            }

            // Clear caches
            $this->info('🧹 Clearing caches...');
            $this->call('config:clear');
            $this->call('cache:clear');
            $this->call('view:clear');
            $this->call('route:clear');

            // Install/update dependencies if needed
            if ($this->confirm('Update Composer dependencies?', false)) {
                $this->info('📦 Updating Composer dependencies...');
                $this->execCommand('composer install --no-dev --optimize-autoloader');
            }

            if ($this->confirm('Build frontend assets?', false)) {
                $this->info('🎨 Building frontend assets...');
                $this->execCommand('npm ci');
                $this->execCommand('npm run build');
            }

        } catch (\Exception $e) {
            $this->error('❌ Deployment failed: ' . $e->getMessage());
            
            // Restore backups
            $this->info('🔄 Restoring backups...');
            $this->execCommand('cp /tmp/env_backup_deploy .env');
            if (file_exists('/tmp/echo_backup_deploy')) {
                $this->execCommand('cp /tmp/echo_backup_deploy laravel-echo-server.json');
            }
            
            $this->call('up');
            return 1;
        } finally {
            // Clean up temporary files
            $this->execCommand('rm -f /tmp/env_backup_deploy /tmp/echo_backup_deploy');
        }

        // Bring application back up
        $this->info('🔓 Bringing application back online...');
        $this->call('up');

        $this->info('✅ Deployment completed successfully!');
        return 0;
    }

    /**
     * Execute a command and handle errors.
     */
    private function execCommand(string $command): void
    {
        $output = shell_exec($command . ' 2>&1');
        if ($output === null) {
            throw new \Exception("Failed to execute: {$command}");
        }
        
        // Check exit code
        $exitCode = 0;
        exec($command, $result, $exitCode);
        if ($exitCode !== 0) {
            throw new \Exception("Command failed with exit code {$exitCode}: {$command}\nOutput: {$output}");
        }
    }
}
