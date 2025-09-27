@extends('layout.with-main-and-sidebar')

@section('title')
    <title>{{ __('staff.staff-dashboard') }} - {{ config('other.title') }}</title>
@endsection

@section('meta')
    <meta name="description" content="{{ __('staff.staff-dashboard') }}" />
@endsection

@section('breadcrumbs')
    <li class="breadcrumb--active">
        {{ __('staff.staff-dashboard') }}
    </li>
@endsection

@section('page', 'page__staff-dashboard--index')

@section('main')

    <!-- Fantasma WebGL siguiendo el cursor -->
    <link rel="stylesheet" href="/css/ghost-webgl.css?v=1">
    <canvas id="ghost"></canvas>
    <script type="x-shader/x-fragment" id="vertShader">
        precision mediump float;
        varying vec2 vUv;
        attribute vec2 a_position;
        void main() {
            vUv = .5 * (a_position + 1.);
            gl_Position = vec4(a_position, 0.0, 1.0);
        }
    </script>
    <script type="x-shader/x-fragment" id="fragShader">
        precision mediump float;
        varying vec2 vUv;
        uniform float u_time;
        uniform float u_ratio;
        uniform float u_size;
        uniform vec2 u_pointer;
        uniform float u_smile;
        uniform vec2 u_target_pointer;
        uniform vec3 u_main_color;
        uniform vec3 u_border_color;
        uniform float u_flat_color;
        uniform sampler2D u_texture;
        #define TWO_PI 6.28318530718
        #define PI 3.14159265358979323846
        vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
        vec2 mod289(vec2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
        vec3 permute(vec3 x) { return mod289(((x*34.0)+1.0)*x); }
        float snoise(vec2 v) {
            const vec4 C = vec4(0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439);
            vec2 i = floor(v + dot(v, C.yy));
            vec2 x0 = v - i + dot(i, C.xx);
            vec2 i1;
            i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
            vec4 x12 = x0.xyxy + C.xxzz;
            x12.xy -= i1;
            i = mod289(i);
            vec3 p = permute(permute(i.y + vec3(0.0, i1.y, 1.0)) + i.x + vec3(0.0, i1.x, 1.0));
            vec3 m = max(0.5 - vec3(dot(x0, x0), dot(x12.xy, x12.xy), dot(x12.zw, x12.zw)), 0.0);
            m = m*m;
            m = m*m;
            vec3 x = 2.0 * fract(p * C.www) - 1.0;
            vec3 h = abs(x) - 0.5;
            vec3 ox = floor(x + 0.5);
            vec3 a0 = x - ox;
            m *= 1.79284291400159 - 0.85373472095314 * (a0*a0 + h*h);
            vec3 g;
            g.x = a0.x * x0.x + h.x * x0.y;
            g.yz = a0.yz * x12.xz + h.yz * x12.yw;
            return 130.0 * dot(m, g);
        }
        vec2 rotate(vec2 v, float angle) {
            float r_sin = sin(angle);
            float r_cos = cos(angle);
            return vec2(v.x * r_cos - v.y * r_sin, v.x * r_sin + v.y * r_cos);
        }
        float eyes(vec2 uv) {
            uv.y -= .5;
            uv.x *= 1.;
            uv.y *= .8;
            uv.x = abs(uv.x);
            uv.y += u_smile * .3 * pow(uv.x, 1.3);
            uv.x -= (.6 + .2 * u_smile);
            float d = clamp(length(uv), 0., 1.);
            return 1. - pow(d, .08);
        }
        float mouth(vec2 uv) {
            uv.y += 1.5;
            uv.x *= (.5 + .5 * abs(1. - u_smile));
            uv.y *= (3. - 2. * abs(1. - u_smile));
            uv.y -= u_smile * 4. * pow(uv.x, 2.);
            float d = clamp(length(uv), 0., 1.);
            return 1. - pow(d, .07);
        }
        float face(vec2 uv, float rotation) {
            uv = rotate(uv, rotation);
            uv /= (.27 * u_size);
            float eyes_shape = 10. * eyes(uv);
            float mouth_shape = 20. * mouth(uv);
            float col = 0.;
            col = mix(col, 1., eyes_shape);
            col = mix(col, 1., mouth_shape);
            return col;
        }
        void main() {
            vec2 point = u_pointer;
            point.x *= u_ratio;
            vec2 uv = vUv;
            uv.x *= u_ratio;
            uv -= point;
            float texture = texture2D(u_texture, vec2(vUv.x, 1. - vUv.y)).r;
            float shape = texture;
            float noise = snoise(uv * vec2(.7 / u_size, .6 / u_size) + vec2(0., .0015 * u_time));
            noise += 1.2;
            noise *= 2.1;
            noise += smoothstep(-.8, -.2, (uv.y) / u_size);
            float face = face(uv, 5. * (u_target_pointer.x - u_pointer.x));
            shape -= face;
            shape *= noise;
            vec3 border = (1. - u_border_color);
            border.g += .2 * sin(.005 * u_time);
            border *= .5;
            vec3 color = u_main_color;
            color -= (1. - u_flat_color) * border * smoothstep(.0, .01, shape);
            shape = u_flat_color * smoothstep(.8, 1., shape) + (1. - u_flat_color) * shape;
            color *= shape;
            gl_FragColor = vec4(color, shape);
        }
    </script>
    <script type="module" src="/js/ghost-webgl.js?v=1"></script>

    <div class="dashboard__menus">
        <section class="panelV2 panel--grid-item">
            <h2 class="panel__heading">
                <i class="{{ config('other.font-awesome') }} fa-link"></i>
                {{ __('staff.links') }}
            </h2>
            <div class="panel__body">
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.username-changes.index') }}"
                    >
                        <i class="fa fa-user-edit"></i>
                        Solicitudes de cambio de nombre de usuario
                    </a>
                </p>
                    <a class="form__button form__button--text" href="{{ route('home.index') }}">
                        <i class="{{ config('other.font-awesome') }} fa-columns"></i>
                        {{ __('staff.frontend') }}
                    </a>
                </p>
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.dashboard.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-columns"></i>
                        {{ __('staff.staff-dashboard') }}
                    </a>
                </p>
                @if (auth()->user()->group->is_owner)
                    <p class="form__group form__group--horizontal">
                        <a
                            class="form__button form__button--text"
                            href="{{ route('staff.backups.index') }}"
                        >
                            <i class="{{ config('other.font-awesome') }} fa-hdd"></i>
                            {{ __('backup.backup') }}
                            {{ __('backup.manager') }}
                        </a>
                    </p>
                    <p class="form__group form__group--horizontal">
                        <a
                            class="form__button form__button--text"
                            href="{{ route('staff.commands.index') }}"
                        >
                            <i class="fab fa-laravel"></i>
                            Commands
                        </a>
                    </p>

                    @if (config('donation.is_enabled'))
                        <p class="form__group form__group--horizontal">
                            <a
                                class="form__button form__button--text"
                                href="{{ route('staff.donations.index') }}"
                            >
                                <i class="{{ config('other.font-awesome') }} fa-money-bill"></i>
                                Donations
                            </a>
                        </p>
                        <p class="form__group form__group--horizontal">
                            <a
                                class="form__button form__button--text"
                                href="{{ route('staff.gateways.index') }}"
                            >
                                <i class="{{ config('other.font-awesome') }} fa-money-bill"></i>
                                Gateways
                            </a>
                        </p>
                        <p class="form__group form__group--horizontal">
                            <a
                                class="form__button form__button--text"
                                href="{{ route('staff.packages.index') }}"
                            >
                                <i class="{{ config('other.font-awesome') }} fa-money-bill"></i>
                                Packages
                            </a>
                        </p>
                    @endif
                @endif
            </div>
        </section>
        <section class="panelV2 panel--grid-item">
            <h2 class="panel__heading">
                <i class="{{ config('other.font-awesome') }} fa-wrench"></i>
                {{ __('staff.chat-tools') }}
            </h2>
            <div class="panel__body">
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.statuses.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-comment-dots"></i>
                        {{ __('staff.statuses') }}
                    </a>
                </p>
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.chatrooms.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-comment-dots"></i>
                        {{ __('staff.rooms') }}
                    </a>
                </p>
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.bots.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-robot"></i>
                        {{ __('staff.bots') }}
                    </a>
                </p>
                <div class="form__group form__group--horizontal">
                    <form
                        method="POST"
                        action="{{ route('staff.flush.chat') }}"
                        x-data="confirmation"
                    >
                        @csrf
                        <button
                            x-on:click.prevent="confirmAction"
                            data-b64-deletion-message="{{ base64_encode('Are you sure you want to delete all chatbox messages in all chatrooms (including private chatbox messages)?') }}"
                            class="form__button form__button--text"
                        >
                            <i class="{{ config('other.font-awesome') }} fa-broom"></i>
                            {{ __('staff.flush-chat') }}
                        </button>
                    </form>
                </div>
            </div>
        </section>
        <section class="panelV2 panel--grid-item">
            <h2 class="panel__heading">
                <i class="{{ config('other.font-awesome') }} fa-wrench"></i>
                {{ __('staff.general-tools') }}
            </h2>
            <div class="panel__body">
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.articles.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-newspaper"></i>
                        {{ __('staff.articles') }}
                    </a>
                </p>
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.events.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-calendar-star"></i>
                        {{ __('event.events') }}
                    </a>
                </p>
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.bon_exchanges.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-coins"></i>
                        {{ __('staff.bon-exchange') }}
                    </a>
                </p>
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.bon_earnings.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-coins"></i>
                        {{ __('staff.bon-earnings') }}
                    </a>
                </p>
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.blacklisted_clients.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-ban"></i>
                        {{ __('common.blacklist') }}
                    </a>
                </p>
                @if (auth()->user()->group->is_admin)
                    <p class="form__group form__group--horizontal">
                        <a
                            class="form__button form__button--text"
                            href="{{ route('staff.forum_categories.index') }}"
                        >
                            <i class="fab fa-wpforms"></i>
                            {{ __('staff.forums') }}
                        </a>
                    </p>
                @endif

                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.pages.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-file"></i>
                        {{ __('staff.pages') }}
                    </a>
                </p>
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.polls.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-chart-pie"></i>
                        {{ __('staff.polls') }}
                    </a>
                </p>
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.whitelisted_image_urls.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-globe"></i>
                        Whitelisted Image URLs
                    </a>
                </p>
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.wiki_categories.index') }}"
                    >
                        <i class="fab fa-wikipedia-w"></i>
                        Wikis
                    </a>
                </p>
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.blocked_ips.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-ban"></i>
                        {{ __('staff.blocked-ips') }}
                    </a>
                </p>
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.playlist_categories.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-list"></i>
                        Playlist Categories
                    </a>
                </p>
            </div>
        </section>
        <section class="panelV2 panel--grid-item">
            <h2 class="panel__heading">
                <i class="{{ config('other.font-awesome') }} fa-wrench"></i>
                {{ __('staff.torrent-tools') }}
            </h2>
            <div class="panel__body">
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.moderation.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-columns"></i>
                        {{ __('staff.torrent-moderation') }}
                    </a>
                </p>
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.categories.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-columns"></i>
                        {{ __('staff.torrent-categories') }}
                    </a>
                </p>
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.types.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-columns"></i>
                        {{ __('staff.torrent-types') }}
                    </a>
                </p>
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.resolutions.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-columns"></i>
                        {{ __('staff.torrent-resolutions') }}
                    </a>
                </p>
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.regions.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-columns"></i>
                        Torrent Regions
                    </a>
                </p>
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.distributors.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-columns"></i>
                        Torrent Distributors
                    </a>
                </p>
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.automatic_torrent_freeleeches.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-columns"></i>
                        Automatic Torrent Freeleeches
                    </a>
                </p>
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.peers.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-columns"></i>
                        Peers
                    </a>
                </p>
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.histories.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-columns"></i>
                        Histories
                    </a>
                </p>
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.torrent_downloads.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-columns"></i>
                        Downloads
                    </a>
                </p>
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.torrent_trumps.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-columns"></i>
                        Trumps
                    </a>
                </p>
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.unregistered_info_hashes.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-columns"></i>
                        Unregistered Info Hashes
                    </a>
                </p>
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.rss.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-rss"></i>
                        {{ __('staff.rss') }}
                    </a>
                </p>
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.media_languages.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-columns"></i>
                        {{ __('common.media-languages') }}
                    </a>
                </p>
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.cheated_torrents.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-question"></i>
                        Cheated Torrents
                    </a>
                </p>
                @if (config('announce.log_announces'))
                    <p class="form__group form__group--horizontal">
                        <a
                            class="form__button form__button--text"
                            href="{{ route('staff.announces.index') }}"
                        >
                            <i class="{{ config('other.font-awesome') }} fa-chart-bar"></i>
                            Announces
                        </a>
                    </p>
                @endif

                @if (! config('announce.external_tracker.is_enabled'))
                    <div class="form__group form__group--horizontal">
                        <form
                            method="POST"
                            action="{{ route('staff.flush.peers') }}"
                            x-data="confirmation"
                        >
                            @csrf
                            <button
                                x-on:click.prevent="confirmAction"
                                data-b64-deletion-message="{{ base64_encode('Are you sure you want to delete all ghost peers?') }}"
                                class="form__button form__button--text"
                            >
                                <i class="{{ config('other.font-awesome') }} fa-ghost"></i>
                                {{ __('staff.flush-ghost-peers') }}
                            </button>
                        </form>
                    </div>
                @endif
            </div>
        </section>
        <section class="panelV2 panel--grid-item">
            <h2 class="panel__heading">
                <i class="{{ config('other.font-awesome') }} fa-wrench"></i>
                {{ __('staff.user-tools') }}
            </h2>
            <div class="panel__body">
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.applications.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-list"></i>
                        {{ __('staff.applications') }} ({{ $pendingApplicationsCount }})
                        @if ($pendingApplicationsCount > 0)
                            <x-animation.notification />
                        @endif
                    </a>
                </p>
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.users.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-users"></i>
                        {{ __('staff.user-search') }}
                    </a>
                </p>
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.apikeys.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-key"></i>
                        {{ __('user.apikeys') }}
                    </a>
                </p>
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.passkeys.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-key"></i>
                        {{ __('staff.passkeys') }}
                    </a>
                </p>
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.rsskeys.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-key"></i>
                        {{ __('user.rsskeys') }}
                    </a>
                </p>
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.email_updates.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-key"></i>
                        {{ __('user.email-updates') }}
                    </a>
                </p>
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.password_reset_histories.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-key"></i>
                        {{ __('user.password-resets') }}
                    </a>
                </p>
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.watchlist.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-eye"></i>
                        Watchlist
                    </a>
                </p>
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.mass_private_message.create') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-envelope-square"></i>
                        {{ __('staff.mass-pm') }}
                    </a>
                </p>
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.mass_email.create') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-paper-plane"></i>
                        {{ __('staff.mass-email') }}
                    </a>
                </p>
                <div class="form__group form__group--horizontal">
                    <form
                        method="GET"
                        action="{{ route('staff.mass-actions.validate') }}"
                        x-data="confirmation"
                    >
                        @csrf
                        <button
                            x-on:click.prevent="confirmAction"
                            data-b64-deletion-message="{{ base64_encode('Are you sure you want to automatically validate all users even if their email address isn\'t confirmed?') }}"
                            class="form__button form__button--text"
                        >
                            <i class="{{ config('other.font-awesome') }} fa-history"></i>
                            {{ __('staff.mass-validate-users') }}
                        </button>
                    </form>
                </div>
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.cheaters.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-question"></i>
                        {{ __('staff.possible-leech-cheaters') }}
                    </a>
                </p>
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.leakers.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-faucet-drip"></i>
                        Leakers
                    </a>
                </p>
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.seedboxes.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-server"></i>
                        {{ __('staff.seedboxes') }}
                    </a>
                </p>
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.uploaders.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-upload"></i>
                        {{ __('torrent.uploader') }} {{ __('common.stats') }}
                    </a>
                </p>
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.internals.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-magic"></i>
                        Internals
                    </a>
                </p>
                @if (auth()->user()->group->is_admin)
                    <p class="form__group form__group--horizontal">
                        <a
                            class="form__button form__button--text"
                            href="{{ route('staff.groups.index') }}"
                        >
                            <i class="{{ config('other.font-awesome') }} fa-users"></i>
                            {{ __('staff.groups') }}
                        </a>
                    </p>
                @endif
            </div>
        </section>
        <section class="panelV2 panel--grid-item">
            <h2 class="panel__heading">
                <i class="{{ config('other.font-awesome') }} fa-file"></i>
                {{ __('staff.logs') }}
            </h2>
            <div class="panel__body">
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.audits.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-file"></i>
                        {{ __('staff.audit-log') }}
                    </a>
                </p>
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.bans.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-file"></i>
                        {{ __('staff.bans-log') }}
                    </a>
                </p>
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.authentications.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-file"></i>
                        {{ __('staff.failed-login-log') }}
                    </a>
                </p>
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.gifts.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-file"></i>
                        {{ __('staff.gifts-log') }}
                    </a>
                </p>
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.invites.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-file"></i>
                        {{ __('staff.invites-log') }}
                    </a>
                </p>
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.notes.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-file"></i>
                        {{ __('staff.user-notes') }}
                    </a>
                </p>
                @if (auth()->user()->group->is_owner)
                    <p class="form__group form__group--horizontal">
                        <a
                            class="form__button form__button--text"
                            href="{{ route('staff.laravel-log.index') }}"
                        >
                            <i class="fa fa-file"></i>
                            {{ __('staff.laravel-log') }}
                        </a>
                    </p>
                @endif

                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.reports.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-file"></i>
                        {{ __('staff.reports-log') }} ({{ $unsolvedReportsCount }})
                        @if ($unsolvedReportsCount > 0)
                            <x-animation.notification />
                        @endif
                    </a>
                </p>
                <p class="form__group form__group--horizontal">
                    <a
                        class="form__button form__button--text"
                        href="{{ route('staff.warnings.index') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-file"></i>
                        {{ __('staff.warnings-log') }}
                    </a>
                </p>
            </div>
        </section>
    </div>
@endsection

@section('sidebar')
    <section class="panelV2">
        <h2 class="panel__heading">SSL Certificate</h2>
        <dl class="key-value">
            <div class="key-value__group">
                <dt>URL</dt>
                <dd>{{ config('app.url') }}</dd>
            </div>
            @if (request()->secure())
                <div class="key-value__group">
                    <dt>Connection</dt>
                    <dd>Secure</dd>
                </div>
                <div class="key-value__group">
                    <dt>Issued By</dt>
                    <dd>
                        {{ ! is_string($certificate) ? $certificate->getIssuer() : 'No Certificate Info Found' }}
                    </dd>
                </div>
                <div class="key-value__group">
                    <dt>Expires</dt>
                    <dd>
                        {{ ! is_string($certificate) ? $certificate->expirationDate()->diffForHumans() : 'No Certificate Info Found' }}
                    </dd>
                </div>
            @else
                <div class="key-value__group">
                    <dt>Connection</dt>
                    <dd>
                        <strong>Not Secure</strong>
                    </dd>
                </div>
                <div class="key-value__group">
                    <dt>Issued By</dt>
                    <dd>N/A</dd>
                </div>
                <div class="key-value__group">
                    <dt>Expires</dt>
                    <dd>N/A</dd>
                </div>
            @endif
        </dl>
    </section>
    <section class="panelV2">
        <h2 class="panel__heading">Server Information</h2>
        <dl class="key-value">
            <div class="key-value__group">
                <dt>OS</dt>
                <dd>{{ $basic['os'] }}</dd>
            </div>
            <div class="key-value__group">
                <dt>PHP</dt>
                <dd>{{ $basic['php'] }}</dd>
            </div>
            <div class="key-value__group">
                <dt>Database</dt>
                <dd>{{ $basic['database'] }}</dd>
            </div>
            <div class="key-value__group">
                <dt>Laravel</dt>
                <dd>{{ $basic['laravel'] }}</dd>
            </div>
            <div class="key-value__group">
                <dt>{{ config('unit3d.codebase') }}</dt>
                <dd>{{ config('unit3d.version') }}</dd>
            </div>
        </dl>
    </section>
    <div class="dashboard__stats">
        <section class="panelV2 panel--grid-item">
            <h2 class="panel__heading">Torrents</h2>
            <dl class="key-value">
                <div class="key-value__group">
                    <dt>Total</dt>
                    <dd>{{ $torrents->total }}</dd>
                </div>
                <div class="key-value__group">
                    <dt>Pending</dt>
                    <dd>{{ $torrents->pending }}</dd>
                </div>
                <div class="key-value__group">
                    <dt>Approved</dt>
                    <dd>{{ $torrents->approved }}</dd>
                </div>
                <div class="key-value__group">
                    <dt>Postponed</dt>
                    <dd>{{ $torrents->postponed }}</dd>
                </div>
                <div class="key-value__group">
                    <dt>Rejected</dt>
                    <dd>{{ $torrents->rejected }}</dd>
                </div>
            </dl>
        </section>
        <section class="panelV2 panel--grid-item">
            <h2 class="panel__heading">Peers</h2>
            <dl class="key-value">
                <div class="key-value__group">
                    <dt>Total</dt>
                    <dd>{{ $peers->total }}</dd>
                </div>
                <div class="key-value__group">
                    <dt>Active</dt>
                    <dd>{{ $peers->active }}</dd>
                </div>
                <div class="key-value__group">
                    <dt>Inactive</dt>
                    <dd>{{ $peers->inactive }}</dd>
                </div>
                <div class="key-value__group">
                    <dt>Seeds</dt>
                    <dd>{{ $peers->seeders }}</dd>
                </div>
                <div class="key-value__group">
                    <dt>Leeches</dt>
                    <dd>{{ $peers->leechers }}</dd>
                </div>
            </dl>
        </section>
        <section class="panelV2 panel--grid-item">
            <h2 class="panel__heading">Users</h2>
            <dl class="key-value">
                <div class="key-value__group">
                    <dt>Total</dt>
                    <dd>{{ $users->total }}</dd>
                </div>
                <div class="key-value__group">
                    <dt>Validating</dt>
                    <dd>{{ $users->validating }}</dd>
                </div>
                <div class="key-value__group">
                    <dt>Banned</dt>
                    <dd>{{ $users->banned }}</dd>
                </div>
            </dl>
        </section>
        <section class="panelV2 panel--grid-item">
            <h2 class="panel__heading">RAM</h2>
            <dl class="key-value">
                <div class="key-value__group">
                    <dt>Total</dt>
                    <dd>{{ $ram['total'] }}</dd>
                </div>
                <div class="key-value__group">
                    <dt>Used</dt>
                    <dd>{{ $ram['used'] }}</dd>
                </div>
                <div class="key-value__group">
                    <dt>Free</dt>
                    <dd>{{ $ram['available'] }}</dd>
                </div>
            </dl>
        </section>
        <section class="panelV2 panel--grid-item">
            <h2 class="panel__heading">Disk</h2>
            <dl class="key-value">
                <div class="key-value__group">
                    <dt>Total</dt>
                    <dd>{{ $disk['total'] }}</dd>
                </div>
                <div class="key-value__group">
                    <dt>Used</dt>
                    <dd>{{ $disk['used'] }}</dd>
                </div>
                <div class="key-value__group">
                    <dt>Free</dt>
                    <dd>{{ $disk['free'] }}</dd>
                </div>
            </dl>
        </section>
        <section class="panelV2 panel--grid-item">
            <h2 class="panel__heading">Load Average</h2>
            <dl class="key-value">
                <div class="key-value__group">
                    <dt>1 minute</dt>
                    <dd>{{ $avg['1-minute'] ?? 'N/A' }}</dd>
                </div>
                <div class="key-value__group">
                    <dt>5 minutes</dt>
                    <dd>{{ $avg['5-minute'] ?? 'N/A' }}</dd>
                </div>
                <div class="key-value__group">
                    <dt>15 minutes</dt>
                    <dd>{{ $avg['15-minute'] ?? 'N/A' }}</dd>
                </div>
            </dl>
        </section>
    </div>
    <section class="panelV2">
        <h2 class="panel__heading">Directory Permissions</h2>
        <div class="data-table-wrapper">
            <table class="data-table">
                <thead>
                    <tr>
                        <th>Directory</th>
                        <th>Current</th>
                        <th><abbr title="Recommended">Rec.</abbr></th>
                    </tr>
                </thead>
                <tbody>
                    @foreach ($file_permissions as $permission)
                        <tr>
                            <td>{{ $permission['directory'] }}</td>
                            <td>
                                @if ($permission['permission'] === $permission['recommended'])
                                    <i
                                        class="{{ config('other.font-awesome') }} fa-check-circle"
                                    ></i>
                                    {{ $permission['permission'] }}
                                @else
                                    <i
                                        class="{{ config('other.font-awesome') }} fa-times-circle"
                                    ></i>
                                    {{ $permission['permission'] }}
                                @endif
                            </td>
                            <td>{{ $permission['recommended'] }}</td>
                        </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
    </section>
    @if (config('announce.external_tracker.is_enabled'))
        @if ($externalTrackerStats === true)
            <section class="panelV2">
                <h2 class="panel__heading">External Tracker Stats</h2>
                <div class="panel__body">External tracker not enabled.</div>
            </section>
        @elseif ($externalTrackerStats === false)
            <section class="panelV2">
                <h2 class="panel__heading">External Tracker Stats</h2>
                <div class="panel__body">Stats endpoint not found.</div>
            </section>
        @elseif ($externalTrackerStats === [])
            <section class="panelV2">
                <h2 class="panel__heading">External Tracker Stats</h2>
                <div class="panel__body">Tracker returned an error.</div>
            </section>
        @else
            <section class="panelV2">
                <h2 class="panel__heading">External Tracker Stats</h2>
                <dl class="key-value">
                    @php
                        $createdAt = \Illuminate\Support\Carbon::createFromTimestampUTC($externalTrackerStats['created_at']);
                        $lastRequestAt = \Illuminate\Support\Carbon::createFromTimestampUTC($externalTrackerStats['last_request_at']);
                        $lastAnnounceResponseAt = \Illuminate\Support\Carbon::createFromTimestampUTC($externalTrackerStats['last_announce_response_at']);
                    @endphp

                    <div class="key-value__group">
                        <dt>{{ __('torrent.started') }}</dt>
                        <dd>
                            <time
                                title="{{ $createdAt->format('Y-m-d h:i:s') }}"
                                datetime="{{ $createdAt->format('Y-m-d h:i:s') }}"
                            >
                                {{ $createdAt->diffForHumans() }}
                            </time>
                        </dd>
                    </div>
                    <div class="key-value__group">
                        <dt>Last Request At</dt>
                        <dd>
                            <time
                                title="{{ $lastRequestAt->format('Y-m-d h:i:s') }}"
                                datetime="{{ $lastRequestAt->format('Y-m-d h:i:s') }}"
                            >
                                {{ $lastRequestAt->diffForHumans() }}
                            </time>
                        </dd>
                    </div>
                    <div class="key-value__group">
                        <dt>Last Successful Response At</dt>
                        <dd>
                            <time
                                title="{{ $lastAnnounceResponseAt->format('Y-m-d h:i:s') }}"
                                datetime="{{ $lastAnnounceResponseAt->format('Y-m-d h:i:s') }}"
                            >
                                {{ $lastAnnounceResponseAt->diffForHumans() }}
                            </time>
                        </dd>
                    </div>
                </dl>
                <table class="data-table">
                    <thead>
                        <tr>
                            <th style="text-align: right">Interval (s)</th>
                            <th style="text-align: right">In (req/s)</th>
                            <th style="text-align: right">Out (req/s)</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach ([1, 10, 60, 900, 7200] as $interval)
                            <tr>
                                <td style="text-align: right">{{ $interval }}</td>
                                <td style="text-align: right">
                                    {{ \number_format($externalTrackerStats['requests_per_' . $interval . 's'], 0, null, "\u{202F}") }}
                                </td>
                                <td style="text-align: right">
                                    {{ \number_format($externalTrackerStats['announce_responses_per_' . $interval . 's'], 0, null, "\u{202F}") }}
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </section>
        @endif
    @endif
@endsection
