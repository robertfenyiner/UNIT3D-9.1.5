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

namespace App\Http\Controllers\Staff;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\UserNameChange;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class UserNameChangeController extends Controller
{
    /**
     * Display All Username Change Requests.
     */
    public function index(): \Illuminate\Contracts\View\Factory|\Illuminate\View\View
    {
        return view('Staff.username-changes.index', [
            'usernameChanges' => UserNameChange::with('user')->orderBy('created_at', 'desc')->paginate(25),
        ]);
    }

    /**
     * Show Username Change Request.
     */
    public function show(int $id): \Illuminate\Contracts\View\Factory|\Illuminate\View\View
    {
        $usernameChange = UserNameChange::findOrFail($id);

        return view('Staff.username-changes.show', [
            'usernameChange' => $usernameChange,
        ]);
    }

    /**
     * Process Username Change Request.
     */
    public function update(Request $request, int $id): \Illuminate\Http\RedirectResponse
    {
        $usernameChange = UserNameChange::findOrFail($id);
        $user = User::findOrFail($usernameChange->user_id);

        $request->validate([
            'status' => 'required|in:Approved,Rejected',
            'new_username' => 'required_if:status,Approved|string|min:3|max:20|unique:users,username,'.$user->id,
            'rejection_reason' => 'required_if:status,Rejected|nullable|string|max:255',
        ]);

        return DB::transaction(function () use ($request, $usernameChange, $user) {
            // Registrar el staff que realizó el cambio
            $usernameChange->staff_id = auth()->id();

            if ($request->status === 'Approved') {
                // Guardar el nombre de usuario anterior
                $oldUsername = $user->username;

                // Actualizar el nombre de usuario
                $user->username = $request->new_username;
                $user->save();

                // Actualizar el registro de cambio
                $usernameChange->old_username = $oldUsername;
                $usernameChange->new_username = $user->username;
                $usernameChange->status = 'Approved';
                $usernameChange->save();

                // Notificar al usuario
                $user->notify(new \App\Notifications\UsernameChangeApproved($oldUsername, $user->username, $usernameChange->id));

                return to_route('staff.username-changes.index')
                    ->with('success', 'El cambio de nombre de usuario ha sido aprobado.');
            }

            // Si fue rechazado
            $usernameChange->status = 'Rejected';
            $usernameChange->rejection_reason = $request->rejection_reason;
            $usernameChange->save();

            // Notificar al usuario
            $user->notify(new \App\Notifications\UsernameChangeRejected($request->rejection_reason));

            return to_route('staff.username-changes.index')
                ->with('success', 'El cambio de nombre de usuario ha sido rechazado.');
        }, 5);
    }
}
