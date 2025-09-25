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

namespace App\Http\Controllers\User;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreTransactionRequest;
use App\Models\BonExchange;
use App\Models\BonTransactions;
use App\Models\PersonalFreeleech;
use App\Models\User;
use App\Notifications\PersonalFreeleechCreated;
use App\Services\Unit3dAnnounce;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * @see \Tests\Feature\Http\Controllers\BonusControllerTest
 */
class TransactionController extends Controller
{
    /**
     * BonusController Constructor.
     */
    public function __construct(protected \App\Interfaces\ByteUnitsInterface $byteUnits)
    {
    }

    /**
     * Show Bonus Store System.
     */
    public function create(Request $request, User $user): \Illuminate\Contracts\View\Factory|\Illuminate\View\View
    {
        abort_unless($request->user()->is($user), 403);

        return view('user.transaction.create', [
            'user'     => $user,
            'bon'      => $user->formatted_seedbonus,
            'activefl' => $user->personalFreeleeches()->exists(),
            'items'    => BonExchange::all(),
        ]);
    }

    /**
     * Exchange Points For A Item.
     */
    public function store(StoreTransactionRequest $request, User $user): \Illuminate\Http\RedirectResponse
    {
        abort_unless($request->user()->is($user), 403);

        return DB::transaction(function () use ($request, $user) {
            $user->refresh();
            $bonExchange = BonExchange::findOrFail($request->integer('exchange'));

            if ($bonExchange->cost > $user->seedbonus) {
                return back()->withErrors('Not enough BON.');
            }

            switch (true) {
                case $bonExchange->upload:
                    if (config('other.bon.max-buffer-to-buy-upload') !== null && $user->uploaded - $user->downloaded > config('other.bon.max-buffer-to-buy-upload')) {
                        return back()->withErrors('You already have enough buffer.');
                    }

                    $user->increment('uploaded', $bonExchange->value);

                    break;
                case $bonExchange->download:
                    if ($user->downloaded < $bonExchange->value) {
                        return back()->withErrors('Not enough download.');
                    }

                    $user->decrement('downloaded', $bonExchange->value);

                    break;
                case $bonExchange->personal_freeleech:
                    if (cache()->get('personal_freeleech:'.$user->id)) {
                        return back()->withErrors('Your previous personal freeleech is still active.');
                    }

                    PersonalFreeleech::create(['user_id' => $user->id]);

                    cache()->put('personal_freeleech:'.$user->id, true);

                    Unit3dAnnounce::addPersonalFreeleech($user->id);

                    $user->notify(new PersonalFreeleechCreated());

                    break;
                case $bonExchange->invite:
                    if (config('other.invites_restriced') && !\in_array($user->group->name, config('other.invite_groups'), true)) {
                        return back()->withErrors(trans('user.invites-disabled-group'));
                    }

                    if ($user->invites >= config('other.max_unused_user_invites', 1)) {
                        return back()->withErrors('You already have the maximum amount of unused invites allowed per user.');
                    }

                    $user->increment('invites', $bonExchange->value);

                    break;
                case $bonExchange->username_change:
                    // Crear una notificación al equipo de administración sobre el cambio solicitado
                    // Aquí no cambiamos el nombre de usuario directamente, sino que creamos una solicitud
                    // que un administrador debe aprobar

                    // Crear una nueva entrada en la base de datos para la solicitud de cambio de nombre
                    \App\Models\UserNameChange::create([
                        'user_id' => $user->id,
                        'status' => 'Pending', // Puede ser: Pending, Approved, Rejected
                    ]);

                    // Notificar a los administradores sobre la solicitud
                    $staffs = \App\Models\User::where('group_id', '=', 10)->get(); // Suponiendo que 10 es el ID del grupo de administradores
                    foreach ($staffs as $staff) {
                        $staff->notify(new \App\Notifications\UsernameChangeRequest($user));
                    }

                    break;
                case $bonExchange->remove_hnr:
                    // Obtener el HnR más antiguo del usuario
                    $hnr = \App\Models\Warning::where('user_id', '=', $user->id)
                        ->where('active', '=', 1)
                        ->whereNotNull('torrent')
                        ->orderBy('created_at', 'asc')
                        ->first();

                    if (!$hnr) {
                        return back()->withErrors('No tienes ningún Hit and Run activo para eliminar.');
                    }

                    // Marcar el HnR como inactivo
                    $hnr->active = 0;
                    $hnr->save();

                    break;
            }

            BonTransactions::create([
                'bon_exchange_id' => $bonExchange->id,
                'name'            => $bonExchange->description,
                'cost'            => $bonExchange->value,
                'sender_id'       => $user->id,
                'torrent_id'      => null,
            ]);

            $user->decrement('seedbonus', $bonExchange->cost);

            return back()->with('success', trans('bon.success'));
        }, 5);
    }
}
