<?php

declare(strict_types=1);

/**
 * NOTICE OF LICENSE.
 *
 * UNIT3D Community Edition is open-sourced software licensed under the GNU Affero General Public License v3.0
 * The details is bundled with this project in the file LICENSE.txt.
 *
 * @project    UNIT3D Community Edition
 *
 * @author     Roardom <roardom@protonmail.com>
 * @license    https://www.gnu.org/licenses/agpl-3.0.en.html/ GNU Affero General Public License v3.0
 */

namespace App\Http\Controllers;

use App\Models\Article;
use App\Models\Category;
use App\Models\Playlist;
use App\Models\Torrent;
use App\Models\User;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class AuthenticatedImageController extends Controller
{
    private const array HEADERS = [
        'Cache-Control' => 'private, max-age=7200',
    ];

    public function articleImage(Article $article): \Symfony\Component\HttpFoundation\BinaryFileResponse
    {
        $path = $article->image === null
            ? public_path('img/missing-image.png')
            : Storage::disk('article-images')->path($article->image);

        abort_unless(file_exists($path), 404);

        return response()->file($path, self::HEADERS);
    }

    public function categoryImage(Category $category): \Symfony\Component\HttpFoundation\BinaryFileResponse
    {
        abort_if($category->image === null, 404);

        $path = Storage::disk('category-images')->path($category->image);

        abort_unless(file_exists($path), 404);

        return response()->file($path, self::HEADERS);
    }

    /**
     * Serve a public category image without requiring authentication.
     * This endpoint is intended for bots/integrations that need a stable URL
     * for manually uploaded category artwork.
     */
    public function publicCategoryImage(string $category)
    {
        // Try to find a Category model by name first (case-insensitive)
        $cat = Category::whereRaw('LOWER(name) = ?', [mb_strtolower($category)])->first();
        if ($cat && $cat->image) {
            $path = Storage::disk('category-images')->path($cat->image);
            if (file_exists($path)) {
                return response()->file($path, self::HEADERS);
            }
        }

        // Fallback: attempt to find a file matching the category slug or name in disk
        $possibleFiles = [
            $category . '.jpg',
            $category . '.png',
            Str::slug($category) . '.jpg',
            Str::slug($category) . '.png'
        ];

        foreach ($possibleFiles as $f) {
            try {
                $path = Storage::disk('category-images')->path($f);
                if (file_exists($path)) {
                    return response()->file($path, self::HEADERS);
                }
            } catch (\Exception $e) {
                // ignore
            }
        }

        abort(404);
    }

    public function playlistImage(Playlist $playlist): \Symfony\Component\HttpFoundation\BinaryFileResponse
    {
        abort_if($playlist->cover_image === null, 404);

        $path = Storage::disk('playlist-images')->path($playlist->cover_image);

        abort_unless(file_exists($path), 404);

        return response()->file($path, self::HEADERS);
    }

    public function torrentBanner(Torrent $torrent): \Symfony\Component\HttpFoundation\BinaryFileResponse
    {
        $path = Storage::disk('torrent-banners')->path("torrent-banner_{$torrent->id}.jpg");

        abort_unless(file_exists($path), 404);

        return response()->file($path, self::HEADERS);
    }

    public function torrentCover(Torrent $torrent): \Symfony\Component\HttpFoundation\BinaryFileResponse
    {
        $path = Storage::disk('torrent-covers')->path("torrent-cover_{$torrent->id}.jpg");

        abort_unless(file_exists($path), 404);

        return response()->file($path, self::HEADERS);
    }

    public function userAvatar(User $user): \Symfony\Component\HttpFoundation\BinaryFileResponse
    {
        abort_if($user->image === null, 404);

        $path = Storage::disk('user-avatars')->path($user->image);

        abort_unless(file_exists($path), 404);

        return response()->file($path, self::HEADERS);
    }

    public function userIcon(User $user): \Symfony\Component\HttpFoundation\BinaryFileResponse
    {
        abort_if($user->icon === null, 404);

        $path = Storage::disk('user-icons')->path($user->icon);

        abort_unless(file_exists($path), 404);

        return response()->file($path, self::HEADERS);
    }
}
