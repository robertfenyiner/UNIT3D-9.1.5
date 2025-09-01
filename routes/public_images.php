<?php

declare(strict_types=1);

use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Public Image Routes
|--------------------------------------------------------------------------
|
| Routes here are intentionally registered without auth/banned/verified
| middleware so bots and integrations can fetch uploaded images directly.
|
*/

Route::get('/public-category-images/{category}', [App\Http\Controllers\AuthenticatedImageController::class, 'publicCategoryImage'])
    ->name('public_category_image');

Route::get('/public-torrent-covers/{id}', [App\Http\Controllers\AuthenticatedImageController::class, 'publicTorrentCover'])
    ->whereNumber('id')
    ->name('public_torrent_cover');

Route::get('/public-torrent-banners/{id}', [App\Http\Controllers\AuthenticatedImageController::class, 'publicTorrentBanner'])
    ->whereNumber('id')
    ->name('public_torrent_banner');
