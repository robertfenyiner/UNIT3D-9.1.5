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
 * @author     HDVinnie <hdinnovations@protonmail.com>
 * @license    https://www.gnu.org/licenses/agpl-3.0.en.html/ GNU Affero General Public License v3.0
 */

namespace App\Notifications;

use App\Models\User;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Notification;

class UsernameChangeRequest extends Notification implements ShouldQueue
{
    use Queueable;

    /**
     * Create a new notification instance.
     */
    public function __construct(public User $user)
    {
    }

    /**
     * Get the notification's delivery channels.
     *
     * @return array<string>
     */
    public function via(): array
    {
        return ['database'];
    }

    /**
     * Get the array representation of the notification.
     *
     * @return array<string, mixed>
     */
    public function toArray(): array
    {
        // Buscar el ID de la solicitud de cambio de nombre
        $usernameChange = \App\Models\UserNameChange::where('user_id', $this->user->id)
            ->where('status', 'Pending')
            ->latest()
            ->first();

        $url = $usernameChange 
            ? route('staff.username-changes.show', ['id' => $usernameChange->id]) 
            : route('users.show', ['user' => $this->user]);

        return [
            'title'   => 'Nueva solicitud de cambio de nombre de usuario',
            'body'    => 'El usuario '.$this->user->username.' ha solicitado un cambio de nombre de usuario.',
            'url'     => $url,
        ];
    }
}