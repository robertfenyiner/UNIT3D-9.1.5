        // Username Changes
        Route::prefix('username-changes')->group(function (): void {
            Route::name('username-changes.')->group(function (): void {
                Route::get('/', [App\Http\Controllers\Staff\UserNameChangeController::class, 'index'])->name('index');
                Route::get('/{id}', [App\Http\Controllers\Staff\UserNameChangeController::class, 'show'])->name('show');
                Route::post('/{id}', [App\Http\Controllers\Staff\UserNameChangeController::class, 'update'])->name('update');
            });
        });
