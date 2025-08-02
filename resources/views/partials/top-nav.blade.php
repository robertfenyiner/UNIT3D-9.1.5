<nav class="top-nav" x-data="{ expanded: false }" x-bind:class="expanded && 'mobile'">
    <div class="top-nav__left">
        <!--<a class="top-nav__branding" href="{{ route('home.index') }}">-->
            <!--<img src="{{ url('/favicon.ico') }}" style="height: 35px" />-->
            <!--<span class="top-nav__site-logo">{{ \config('other.title') }}</span>-->
            <a href="{{ route('home.index') }}" style="height: 32px;"><img src="{{ url('/img/ltsmall.png') }}" style="height: 32px;">
        
        </a>
        @include('partials.quick-search-dropdown')
    </div>
    <ul class="top-nav__main-menus" x-bind:class="expanded && 'mobile'">
        <li class="top-nav--left__list-item top-nav__dropdown">
            <a class="top-nav__dropdown--nontouch" href="{{ route('torrents.index') }}">
                <div class="top-nav--left__container">
                    {{ __('torrent.torrents') }}
                </div>
            </a>
            <a class="top-nav__dropdown--touch" tabindex="0">
                <div class="top-nav--left__container">
                    {{ __('torrent.torrents') }}
                </div>
            </a>
            <ul>
                <li>
                    <a href="{{ route('torrents.index') }}">
                        <i class="{{ config('other.font-awesome') }} fa-download"></i>
                        {{ __('torrent.torrents') }}
                    </a>
                </li>
                <!--
                <li>
                    <a href="{{ route('torrents.pending') }}">
                        <i class="{{ config('other.font-awesome') }} fa-hourglass-half"></i>
                        {{ __('common.pending-torrents') }}
                    </a>
                </li>
                -->
                <li>
                    <a href="{{ route('torrents.create') }}">
                        <i class="{{ config('other.font-awesome') }} fa-upload"></i>
                        {{ __('common.upload') }}
                    </a>
                </li>
                <li>
                    <a href="{{ route('requests.index') }}">
                        <i class="{{ config('other.font-awesome') }} fa-hands-helping"></i>
                        {{ __('request.requests') }}
                    </a>
                </li>
                <li>
                    <a href="{{ route('rss.index') }}">
                        <i class="{{ config('other.font-awesome') }} fa-rss"></i>
                        {{ __('rss.rss') }}
                    </a>
                </li>
                <li>
                    <a href="{{ route('mediahub.index') }}">
                        <i class="{{ config('other.font-awesome') }} fa-database"></i>
                        MediaHub
                    </a>
                </li>
            </ul>
        </li>
        <li class="top-nav--left__list-item top-nav__dropdown">
            <a class="top-nav__dropdown--nontouch" href="{{ route('forums.index') }}">
                <div class="top-nav--left__container">
                    {{ __('common.community') }}
                </div>
            </a>
            <a class="top-nav__dropdown--touch" tabindex="0">
                <div class="top-nav--left__container">
                    {{ __('common.community') }}
                </div>
            </a>
            <ul>
                <li>
                    <a href="{{ route('forums.index') }}">
                        <i class="{{ config('other.font-awesome') }} fa-comments"></i>
                        {{ __('forum.forums') }}
                    </a>
                </li>
                <li>
                    <a href="{{ route('playlists.index') }}">
                        <i class="{{ config('other.font-awesome') }} fa-list-ol"></i>
                        {{ __('playlist.playlists') }}
                    </a>
                </li>
                <li>
                    <a href="{{ route('polls.index') }}">
                        <i class="{{ config('other.font-awesome') }} fa-chart-pie"></i>
                        {{ __('poll.polls') }}
                    </a>
                </li>
                <li>
                    <a href="{{ route('stats') }}">
                        <i class="{{ config('other.font-awesome') }} fa-chart-bar"></i>
                        {{ __('common.extra-stats') }}
                    </a>
                </li>
                <li>
                    <a href="{{ route('articles.index') }}">
                        <i class="{{ config('other.font-awesome') }} fa-newspaper"></i>
                        {{ __('common.news') }}
                    </a>
                </li>
                @if (! empty(config('unit3d.chat-link-url')))
                    <li>
                        <a href="{{ config('unit3d.chat-link-url') }}">
                            <i class="{{ config('unit3d.chat-link-icon') }}"></i>
                            {{ config('unit3d.chat-link-name') ?: __('common.chat') }}
                        </a>
                    </li>
                @endif
            </ul>
        </li>
        <li class="top-nav__dropdown">
            <a tabindex="0">
                <div class="top-nav--left__container">
                    {{ __('common.support') }}

                    @if ($hasUnreadTicket)
                        <x-animation.notification />
                    @endif
                </div>
            </a>
            <ul>
                <li>
                    <a href="{{ config('other.rules_url') }}">
                        <i class="{{ config('other.font-awesome') }} fa-info"></i>
                        {{ __('common.rules') }}
                    </a>
                </li>
                <li>
                    <a href="{{ config('other.faq_url') }}">
                        <i class="{{ config('other.font-awesome') }} fa-question"></i>
                        {{ __('common.faq') }}
                    </a>
                </li>
                <li>
                    <a href="{{ route('wikis.index') }}">
                        <i class="{{ config('other.font-awesome') }} fa-list-alt"></i>
                        Wiki
                    </a>
                </li>
                <li>
                    <a href="{{ route('tickets.index') }}">
                        <i class="{{ config('other.font-awesome') }} fa-life-ring"></i>
                        {{ __('ticket.helpdesk') }}
                        @if ($hasUnreadTicket)
                            <x-animation.notification />
                        @endif
                    </a>
                </li>
                <li>
                    <a href="{{ route('staff') }}">
                        <i class="{{ config('other.font-awesome') }} fa-user-secret"></i>
                        {{ __('common.staff') }}
                    </a>
                </li>
            </ul>
        </li>
        <li class="top-nav__dropdown">
            <a tabindex="0">
                <div class="top-nav--left__container">
                    {{ __('common.other') }}
                    @if ($events->contains(fn ($event) => ! $event->claimed_prizes_exists && $event->ends_at->endOfDay()->isFuture()))
                        <x-animation.notification />
                    @endif
                </div>
            </a>
            <ul>
                @foreach ($events as $event)
                    <li>
                        <a href="{{ route('events.show', ['event' => $event]) }}">
                            <i class="{{ config('other.font-awesome') }} fa-calendar-star"></i>
                            {{ $event->name }}
                            @if (! $event->claimed_prizes_exists && $event->ends_at->isFuture())
                                <x-animation.notification />
                            @endif
                        </a>
                    </li>
                @endforeach

                <li>
                    <a href="{{ route('subtitles.index') }}">
                        <i class="{{ config('other.font-awesome') }} fa-closed-captioning"></i>
                        {{ __('common.subtitles') }}
                    </a>
                </li>
                <li>
                    <a href="{{ route('top10.index') }}">
                        <i class="{{ config('other.font-awesome') }} fa-trophy-alt"></i>
                        {{ __('common.top-10') }}
                    </a>
                </li>
                <li>
                    <a href="{{ route('missing.index') }}">
                        <i class="{{ config('other.font-awesome') }} fa-ballot-check"></i>
                        {{ __('common.missing') }}
                    </a>
                </li>
                <li>
                    <a href="{{ route('internal') }}">
                        <i class="{{ config('other.font-awesome') }} fa-star-shooting"></i>
                        {{ __('common.internal') }}
                    </a>
                </li>
            </ul>
        </li>
        @if (config('donation.is_enabled'))
            <li class="top-nav__dropdown">
                <a tabindex="0" title="{{ $donationPercentage }}% filled">
                    <div class="top-nav--left__container">
                        <span
                            class="{{ $donationPercentage < 100 ? 'fa-fade' : '' }}"
                            style="color: lightcoral"
                        >
                            Apoya A Lat-Team
                        </span>
                        <div class="progress" style="background-color: slategray">
                            <div
                                class="progress-bar"
                                role="progressbar"
                                style="
                                    width: {{ $donationPercentage }}%;
                                    background-color: slategray;
                                    border-bottom: 2px solid lightcoral !important;
                                    max-width: 100%;
                                "
                                aria-valuenow="{{ $donationPercentage }}"
                                aria-valuemin="0"
                                aria-valuemax="{{ config('donation.monthly_goal') }}"
                            ></div>
                        </div>
                    </div>
                </a>
                <ul>
                    <li>
                        <a href="{{ route('donations.index') }}">
                            <i class="fas fa-display-chart-up-circle-dollar"></i>
                            Donaciones {{ config('other.title') }} ({{ $donationPercentage }}%)
                        </a>
                    </li>
                    <!--<li>
                        <a href="https://square.link/u/VjB1CNfm" target="_blank">
                            <i class="fas fa-handshake"></i>
                            Support UNIT3D
                        </a>-->
                    </li>
                </ul>
            </li>
        @endif
    </ul>
    <div class="top-nav__right" x-bind:class="expanded && 'mobile'">
        <a
            class="top-nav__username--highresolution"
            href="{{ route('users.show', ['user' => auth()->user()]) }}"
        >
            <span
                class="text-bold"
                style="
                    color: {{ auth()->user()->group->color }};
                    background-image: {{ auth()->user()->group->effect }};
                "
            >
                <i class="{{ auth()->user()->group->icon }}"></i>
                {{ $user->username }}
                @if ($hasActiveWarning)
                    <i
                        class="{{ config('other.font-awesome') }} fa-exclamation-circle text-orange"
                        title="{{ __('common.active-warning') }}"
                    ></i>
                @endif
            </span>
        </a>
        <ul class="top-nav__icon-bar" x-bind:class="expanded && 'mobile'">
            @if ($user->group->is_modo)
                <li>
                    <a
                        class="top-nav--right__icon-link"
                        href="{{ route('staff.dashboard.index') }}"
                        title="{{ __('staff.staff-dashboard') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-cogs"></i>
                        @if ($hasUnresolvedReport)
                            <x-animation.notification />
                        @endif
                    </a>
                </li>
            @endif

            @if ($user->group->is_torrent_modo)
                <li>
                    <a
                        class="top-nav--right__icon-link"
                        href="{{ route('staff.moderation.index') }}"
                        title="{{ __('staff.torrent-moderation') }}"
                    >
                        <i class="{{ config('other.font-awesome') }} fa-tasks"></i>

                        @if ($hasUnmoderatedTorrent)
                            <x-animation.notification />
                        @endif
                    </a>
                </li>
            @endif

            <li>
                <a
                    class="top-nav--right__icon-link"
                    href="{{ route('users.conversations.index', ['user' => auth()->user()]) }}"
                    title="{{ __('pm.inbox') }}"
                >
                    <i class="{{ config('other.font-awesome') }} fa-envelope"></i>
                    @if ($hasUnreadPm)
                        <x-animation.notification />
                    @endif
                </a>
            </li>
            <li>
                <a
                    class="top-nav--right__icon-link"
                    href="{{ route('users.notifications.index', ['user' => auth()->user()]) }}"
                    title="{{ __('user.notifications') }}"
                >
                    <i class="{{ config('other.font-awesome') }} fa-bell"></i>
                    @if ($hasUnreadNotification)
                        <x-animation.notification />
                    @endif
                </a>
            </li>
            <li class="top-nav__dropdown user-menu">
                {{-- Replaced with new user sidebar toggle --}}
                <div class="user-sidebar__toggle user-sidebar__toggle--top-nav" onclick="toggleUserSidebar()">
                    <img 
                        src="{{ $user->image ? route('authenticated_images.user_avatar', ['user' => $user]) : url('img/profile.png') }}" 
                        alt="{{ $user->username }}" 
                        class="user-sidebar__toggle-avatar"
                    />
                    <span class="user-sidebar__toggle-label">Menú de Usuario</span>
                </div>
            </li>
        </ul>
    </div>
    <button
        class="top-nav__toggle {{ \config('other.font-awesome') }}"
        x-bind:class="expanded ? 'fa-times mobile' : 'fa-bars'"
        x-on:click="expanded = !expanded"
    ></button>
</nav>

<!-- User Statistics Section -->
<div class="user-stats-sidebar" style="position: fixed; top: 60px; right: 20px; background: rgba(0,0,0,0.9); border-radius: 8px; padding: 15px; width: 250px; z-index: 1000; box-shadow: 0 4px 6px rgba(0,0,0,0.3);">
    <div style="text-align: center; margin-bottom: 15px; color: #fff; font-weight: bold; border-bottom: 1px solid #444; padding-bottom: 10px;">
        Estadísticas del Usuario
    </div>
    <div class="stats-grid" style="display: grid; grid-template-columns: 1fr 1fr; gap: 10px;">
        <div class="stat-item" style="background: rgba(255,255,255,0.1); padding: 8px; border-radius: 4px; text-align: center;">
            <div style="color: #4CAF50; font-size: 12px; margin-bottom: 2px;">
                <i class="{{ config('other.font-awesome') }} fa-arrow-up"></i> Subido
            </div>
            <div style="color: #fff; font-size: 11px; font-weight: bold;">
                <a href="{{ route('users.torrents.index', ['user' => auth()->user()]) }}" style="color: #fff; text-decoration: none;">
                    {{ $user->formatted_uploaded }}
                </a>
            </div>
        </div>
        <div class="stat-item" style="background: rgba(255,255,255,0.1); padding: 8px; border-radius: 4px; text-align: center;">
            <div style="color: #f44336; font-size: 12px; margin-bottom: 2px;">
                <i class="{{ config('other.font-awesome') }} fa-arrow-down"></i> Descargado
            </div>
            <div style="color: #fff; font-size: 11px; font-weight: bold;">
                <a href="{{ route('users.history.index', ['user' => auth()->user(), 'downloaded' => 'include']) }}" style="color: #fff; text-decoration: none;">
                    {{ $user->formatted_downloaded }}
                </a>
            </div>
        </div>
        <div class="stat-item" style="background: rgba(255,255,255,0.1); padding: 8px; border-radius: 4px; text-align: center;">
            <div style="color: #2196F3; font-size: 12px; margin-bottom: 2px;">
                <i class="{{ config('other.font-awesome') }} fa-upload"></i> Seeding
            </div>
            <div style="color: #fff; font-size: 11px; font-weight: bold;">
                <a href="{{ route('users.peers.index', ['user' => auth()->user()]) }}" style="color: #fff; text-decoration: none;">
                    {{ $peerCount - $leechCount }}
                </a>
            </div>
        </div>
        <div class="stat-item" style="background: rgba(255,255,255,0.1); padding: 8px; border-radius: 4px; text-align: center;">
            <div style="color: #FF9800; font-size: 12px; margin-bottom: 2px;">
                <i class="{{ config('other.font-awesome') }} fa-download"></i> Leeching
            </div>
            <div style="color: #fff; font-size: 11px; font-weight: bold;">
                <a href="{{ route('users.peers.index', ['user' => auth()->user(), 'seeding' => 'exclude']) }}" style="color: #fff; text-decoration: none;">
                    {{ $leechCount }}
                </a>
            </div>
        </div>
        <div class="stat-item" style="background: rgba(255,255,255,0.1); padding: 8px; border-radius: 4px; text-align: center;">
            <div style="color: #9C27B0; font-size: 12px; margin-bottom: 2px;">
                <i class="{{ config('other.font-awesome') }} fa-exchange"></i> Buffer
            </div>
            <div style="color: #fff; font-size: 11px; font-weight: bold;">
                <a href="{{ route('users.history.index', ['user' => auth()->user()]) }}" style="color: #fff; text-decoration: none;">
                    {{ $user->formatted_buffer }}
                </a>
            </div>
        </div>
        <div class="stat-item" style="background: rgba(255,255,255,0.1); padding: 8px; border-radius: 4px; text-align: center;">
            <div style="color: #FFD700; font-size: 12px; margin-bottom: 2px;">
                <i class="{{ config('other.font-awesome') }} fa-coins"></i> Puntos
            </div>
            <div style="color: #fff; font-size: 11px; font-weight: bold;">
                <a href="{{ route('users.earnings.index', ['user' => auth()->user()]) }}" style="color: #fff; text-decoration: none;">
                    {{ $user->formatted_seedbonus }}
                </a>
            </div>
        </div>
        <div class="stat-item" style="background: rgba(255,255,255,0.1); padding: 8px; border-radius: 4px; text-align: center;">
            <div style="color: #00BCD4; font-size: 12px; margin-bottom: 2px;">
                <i class="{{ config('other.font-awesome') }} fa-sync-alt"></i> Ratio
            </div>
            <div style="color: #fff; font-size: 11px; font-weight: bold;">
                <a href="{{ route('users.history.index', ['user' => auth()->user()]) }}" style="color: #fff; text-decoration: none;">
                    {{ $user->formatted_ratio }}
                </a>
            </div>
        </div>
        <div class="stat-item" style="background: rgba(255,255,255,0.1); padding: 8px; border-radius: 4px; text-align: center;">
            <div style="color: #FFC107; font-size: 12px; margin-bottom: 2px;">
                <i class="{{ config('other.font-awesome') }} fa-star"></i> Tokens
            </div>
            <div style="color: #fff; font-size: 11px; font-weight: bold;">
                <a href="{{ route('users.show', ['user' => auth()->user()]) }}" style="color: #fff; text-decoration: none;">
                    {{ $user->fl_tokens }}
                </a>
            </div>
        </div>
    </div>
</div>
