use \Illuminate\Support\Facades\URL;
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

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Notification;

class UsernameChangeRejected extends Notification implements ShouldQueue
{
    use Queueable;

    /**
     * The rejection reason.
     */
    private string|null $rejectionReason;

    /**
     * Create a new notification instance.
     */
    public function __construct(string $rejectionReason = null)
    {
        $this->rejectionReason = $rejectionReason;
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
        $message = 'Tu solicitud de cambio de nombre de usuario ha sido rechazada.';

        if ($this->rejectionReason) {
            $message .= ' Razón: '.$this->rejectionReason;
        } else {
            $message .= ' Si deseas más información, contacta a un administrador.';
        }

        return [
            'title'   => 'Cambio de nombre de usuario rechazado',
            'body'    => $message,
            'url'     => URL::route('staff.username-changes.index'),
        ];
    }
}
