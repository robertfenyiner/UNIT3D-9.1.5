{{-- User Profile Section --}}
@auth
<div class="sidebar-profile">
    <div class="profile-avatar">
        <img src="{{ $user->image ? url('files/img/' . $user->image) : 'https://via.placeholder.com/48x48/333/fff?text=' . substr($user->username, 0, 1) }}" 
             alt="{{ $user->username }}" class="avatar">
    </div>
    <div class="profile-info">
        <h4 class="username">{{ $user->username }}</h4>
        <span class="user-class">{{ $user->group->name ?? 'Usuario' }}</span>
    </div>
    <div class="profile-stats">
        <div class="stat-item">
            <span class="stat-value">{{ App\Helpers\StringHelper::formatBytes($user->uploaded ?? 0) }}</span>
            <span class="stat-label">Subido</span>
        </div>
        <div class="stat-item">
            <span class="stat-value">{{ App\Helpers\StringHelper::formatBytes($user->downloaded ?? 0) }}</span>
            <span class="stat-label">Bajado</span>
        </div>
        <div class="stat-item">
            <span class="stat-value">{{ $user->formatted_ratio ?? '∞' }}</span>
            <span class="stat-label">Ratio</span>
        </div>
    </div>
</div>
@endauth

{{-- Navigation Menu --}}
<nav class="sidebar-nav">
    <div class="nav-section">
        <h5 class="nav-title">Principal</h5>
        <ul class="nav-list">
            <li class="nav-item {{ request()->routeIs('home.index') ? 'active' : '' }}">
                <a href="{{ route('home.index') }}" class="nav-link">
                    <i class="fas fa-home"></i>
                    <span>Inicio</span>
                </a>
            </li>
            <li class="nav-item {{ request()->routeIs('torrents.index') ? 'active' : '' }}">
                <a href="{{ route('torrents.index') }}" class="nav-link">
                    <i class="fas fa-download"></i>
                    <span>Torrents</span>
                </a>
            </li>
            <li class="nav-item {{ request()->routeIs('top10.index') ? 'active' : '' }}">
                <a href="{{ route('top10.index') }}" class="nav-link">
                    <i class="fas fa-trophy"></i>
                    <span>Top 10</span>
                </a>
            </li>
            <li class="nav-item {{ request()->routeIs('requests.index') ? 'active' : '' }}">
                <a href="{{ route('requests.index') }}" class="nav-link">
                    <i class="fas fa-plus-circle"></i>
                    <span>Peticiones</span>
                </a>
            </li>
        </ul>
    </div>

    <div class="nav-section">
        <h5 class="nav-title">Comunidad</h5>
        <ul class="nav-list">
            <li class="nav-item {{ request()->routeIs('mediahub.index') ? 'active' : '' }}">
                <a href="{{ route('mediahub.index') }}" class="nav-link">
                    <i class="fas fa-film"></i>
                    <span>MediaHub</span>
                </a>
            </li>
            <li class="nav-item {{ request()->routeIs('forums.*') ? 'active' : '' }}">
                <a href="{{ route('forums.index') }}" class="nav-link">
                    <i class="fas fa-comments"></i>
                    <span>Foro</span>
                </a>
            </li>
            <li class="nav-item {{ request()->routeIs('articles.index') ? 'active' : '' }}">
                <a href="{{ route('articles.index') }}" class="nav-link">
                    <i class="fas fa-newspaper"></i>
                    <span>Noticias</span>
                </a>
            </li>
        </ul>
    </div>

    @auth
    <div class="nav-section">
        <h5 class="nav-title">Mi cuenta</h5>
        <ul class="nav-list">
            <li class="nav-item {{ request()->routeIs('users.show', auth()->user()) ? 'active' : '' }}">
                <a href="{{ route('users.show', ['user' => auth()->user()]) }}" class="nav-link">
                    <i class="fas fa-user"></i>
                    <span>Mi perfil</span>
                </a>
            </li>
            <li class="nav-item {{ request()->routeIs('users.general_settings.*') ? 'active' : '' }}">
                <a href="{{ route('users.general_settings.edit', ['user' => auth()->user()]) }}" class="nav-link">
                    <i class="fas fa-cog"></i>
                    <span>Configuración</span>
                </a>
            </li>
            <li class="nav-item {{ request()->routeIs('users.history.*') ? 'active' : '' }}">
                <a href="{{ route('users.history.index', ['user' => auth()->user()]) }}" class="nav-link">
                    <i class="fas fa-history"></i>
                    <span>Mi historial</span>
                </a>
            </li>
            <li class="nav-item {{ request()->routeIs('users.bookmarks.*') ? 'active' : '' }}">
                <a href="{{ route('users.bookmarks.index', ['user' => auth()->user()]) }}" class="nav-link">
                    <i class="fas fa-bookmark"></i>
                    <span>Marcadores</span>
                </a>
            </li>
        </ul>
    </div>
    @endauth
</nav>

<style>
.sidebar-profile {
    padding: 20px 16px;
    border-bottom: 1px solid #333;
    text-align: center;
}

.profile-avatar {
    margin-bottom: 12px;
}

.avatar {
    width: 48px;
    height: 48px;
    border-radius: 50%;
    border: 2px solid #20b2aa;
    object-fit: cover;
}

.profile-info {
    margin-bottom: 16px;
}

.username {
    color: #fff;
    font-size: 14px;
    font-weight: 600;
    margin: 0 0 4px 0;
}

.user-class {
    color: #20b2aa;
    font-size: 11px;
    text-transform: uppercase;
    letter-spacing: 0.5px;
}

.profile-stats {
    display: flex;
    justify-content: space-between;
    gap: 8px;
}

.stat-item {
    flex: 1;
    text-align: center;
}

.stat-value {
    display: block;
    color: #fff;
    font-size: 11px;
    font-weight: 600;
    line-height: 1;
}

.stat-label {
    display: block;
    color: #888;
    font-size: 10px;
    margin-top: 2px;
}

.sidebar-nav {
    padding: 0;
}

.nav-section {
    border-bottom: 1px solid #333;
    padding: 16px 0;
}

.nav-section:last-child {
    border-bottom: none;
}

.nav-title {
    color: #888;
    font-size: 11px;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    margin: 0 0 12px 16px;
}

.nav-list {
    list-style: none;
    margin: 0;
    padding: 0;
}

.nav-item {
    margin: 0;
}

.nav-link {
    display: flex;
    align-items: center;
    padding: 10px 16px;
    color: #ccc;
    text-decoration: none;
    font-size: 13px;
    transition: all 0.2s ease;
    border-left: 3px solid transparent;
}

.nav-link:hover {
    background: rgba(32, 178, 170, 0.1);
    color: #20b2aa;
    text-decoration: none;
}

.nav-item.active .nav-link {
    background: rgba(32, 178, 170, 0.15);
    color: #20b2aa;
    border-left-color: #20b2aa;
}

.nav-link i {
    width: 16px;
    margin-right: 12px;
    font-size: 14px;
    text-align: center;
}

.nav-link span {
    flex: 1;
}

/* Mobile adjustments */
@media (max-width: 768px) {
    .sidebar-profile {
        padding: 16px;
    }
    
    .profile-stats {
        justify-content: center;
        gap: 16px;
    }
    
    .nav-section {
        padding: 12px 0;
    }
    
    .nav-link {
        padding: 12px 16px;
        font-size: 14px;
    }
    
    .nav-link i {
        margin-right: 16px;
        font-size: 16px;
    }
}
</style>
