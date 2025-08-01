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

return [
    /*
    |--------------------------------------------------------------------------
    | Enabled
    |--------------------------------------------------------------------------
    |
    | Hit and Run On / Off
    |
    */

    'enabled' => true,

    /*
    |--------------------------------------------------------------------------
    | Seedtime
    |--------------------------------------------------------------------------
    |
    | Min Seedtime Required In Seconds
    |
    */

    'seedtime' => 259200,

    /*
    |--------------------------------------------------------------------------
    | Max Warnings
    |--------------------------------------------------------------------------
    |
    | Max Warnings Before Download Privileges Disabled
    |
    */

    'max_warnings' => 3,

    /*
    |--------------------------------------------------------------------------
    | Grace Period
    |--------------------------------------------------------------------------
    |
    | Max Grace Time For User To Be Disconnected If "Seedtime" Value
    | Is Not Yet Met. "In Days"
    |
    */

    'grace' => 5,

    /*
    |--------------------------------------------------------------------------
    | Buffer
    |--------------------------------------------------------------------------
    |
    | Percentage Buffer of Torrent thats checked against 'actual_downloaded'
    |
    */

    'buffer' => 1,

    /*
    |--------------------------------------------------------------------------
    | Warning Expire
    |--------------------------------------------------------------------------
    |
    | Max Days A Warning Lasts Before Expiring "In Days"
    |
    */

    'expire' => 30,

    /*
    |--------------------------------------------------------------------------
    | Prewarn Period
    |--------------------------------------------------------------------------
    |
    | Max Time For User To Be Disconnected If "Seedtime" Value
    | Is Not Yet Met. A Prewarning PM Will Be Sent. "In Days"
    |
    */

    'prewarn' => 3,
];
