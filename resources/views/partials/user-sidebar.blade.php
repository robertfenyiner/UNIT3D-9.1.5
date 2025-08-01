{{-- User Sidebar Menu --}}
@auth
<aside class="user-sidebar" id="userSidebar">
    <div class="user-sidebar__header">
        <div class="user-sidebar__user-info">
            <img 
                src="{{ auth()->user()->image ? route('authenticated_images.user_avatar', ['user' => auth()->user()]) : url('img/profile.png') }}" 
                alt="{{ auth()->user()->username }}" 
                class="user-sidebar__avatar"
            />
            <div class="user-sidebar__user-details">
                <h3 class="user-sidebar__username">{{ auth()->user()->username }}</h3>
                <span class="user-sidebar__group" style="color: {{ auth()->user()->group->color }}">
                    {{ auth()->user()->group->name }}
                </span>
            </div>
        </div>
        <button class="user-sidebar__close" onclick="toggleUserSidebar()">
            <i class="fas fa-times"></i>
        </button>
    </div>
    
    <nav class="user-sidebar__nav">
        <ul class="user-sidebar__menu">
            <li class="user-sidebar__menu-item">
                <a href="{{ route('users.show', ['user' => auth()->user()]) }}" 
                   class="user-sidebar__menu-link {{ Route::is('users.show') ? 'active' : '' }}">
                    <i class="fas fa-user"></i>
                    <span>{{ __('user.my-profile') }}</span>
                </a>
            </li>
            
            <li class="user-sidebar__menu-item">
                <a href="{{ route('users.general_settings.edit', ['user' => auth()->user()]) }}" 
                   class="user-sidebar__menu-link {{ Route::is('users.general_settings.edit') ? 'active' : '' }}">
                    <i class="fas fa-cogs"></i>
                    <span>{{ __('user.my-settings') }}</span>
                </a>
            </li>
            
            <li class="user-sidebar__menu-item">
                <a href="{{ route('users.privacy_settings.edit', ['user' => auth()->user()]) }}" 
                   class="user-sidebar__menu-link {{ Route::is('users.privacy_settings.edit') ? 'active' : '' }}">
                    <i class="fas fa-eye"></i>
                    <span>{{ __('user.my-privacy') }}</span>
                </a>
            </li>
            
            <li class="user-sidebar__menu-item">
                <a href="{{ route('users.achievements.index', ['user' => auth()->user()]) }}" 
                   class="user-sidebar__menu-link {{ Route::is('users.achievements.index') ? 'active' : '' }}">
                    <i class="fas fa-trophy"></i>
                    <span>{{ __('user.my-achievements') }}</span>
                </a>
            </li>
            
            <li class="user-sidebar__menu-item">
                <a href="{{ route('users.torrents.index', ['user' => auth()->user()]) }}" 
                   class="user-sidebar__menu-link {{ Route::is('users.torrents.index') ? 'active' : '' }}">
                    <i class="fas fa-upload"></i>
                    <span>{{ __('user.my-uploads') }}</span>
                    @php
                        $uploadCount = auth()->user()->torrents()->count();
                    @endphp
                    @if($uploadCount > 0)
                        <span class="user-sidebar__badge">{{ $uploadCount }}</span>
                    @endif
                </a>
            </li>
            
            <li class="user-sidebar__menu-item">
                <a href="{{ route('users.history.index', ['user' => auth()->user(), 'downloaded' => 'include']) }}" 
                   class="user-sidebar__menu-link {{ Route::is('users.history.index') ? 'active' : '' }}">
                    <i class="fas fa-download"></i>
                    <span>{{ __('user.my-downloads') }}</span>
                </a>
            </li>
            
            <li class="user-sidebar__menu-item">
                <a href="{{ route('requests.index', ['requestor' => auth()->user()->username]) }}" 
                   class="user-sidebar__menu-link">
                    <i class="fas fa-question-circle"></i>
                    <span>{{ __('user.my-requested') }}</span>
                </a>
            </li>
            
            <li class="user-sidebar__menu-item">
                <a href="{{ route('users.bookmarks.index', ['user' => auth()->user()]) }}" 
                   class="user-sidebar__menu-link">
                    <i class="fas fa-bookmark"></i>
                    <span>{{ __('user.my-bookmarks') }}</span>
                </a>
            </li>
            
            <li class="user-sidebar__menu-item">
                <a href="{{ route('playlists.index', ['username' => auth()->user()->username]) }}" 
                   class="user-sidebar__menu-link">
                    <i class="fas fa-list"></i>
                    <span>{{ __('user.my-playlists') }}</span>
                </a>
            </li>
            
            <li class="user-sidebar__menu-item">
                <a href="{{ route('users.wishes.index', ['user' => auth()->user()]) }}" 
                   class="user-sidebar__menu-link">
                    <i class="fas fa-heart"></i>
                    <span>{{ __('user.my-wishlist') }}</span>
                </a>
            </li>
            
            @if(auth()->user()->group->is_modo)
            <li class="user-sidebar__separator"></li>
            <li class="user-sidebar__menu-item">
                <a href="{{ route('staff.dashboard.index') }}" 
                   class="user-sidebar__menu-link">
                    <i class="fas fa-shield-alt"></i>
                    <span>{{ __('staff.staff-dashboard') }}</span>
                </a>
            </li>
            @endif
            
            {{-- Logout Option --}}
            <li class="user-sidebar__menu-item user-sidebar__menu-item--logout">
                <form action="{{ route('logout') }}" method="POST" class="user-sidebar__logout-form">
                    @csrf
                    <button type="submit" class="user-sidebar__menu-link user-sidebar__menu-link--logout">
                        <i class="fas fa-sign-out-alt"></i>
                        <span>{{ __('common.logout') }}</span>
                    </button>
                </form>
            </li>
        </ul>
    </nav>
    
    <div class="user-sidebar__footer">
        <div class="user-sidebar__stats">
            <div class="user-sidebar__stat">
                <span class="user-sidebar__stat-label">Upload</span>
                <span class="user-sidebar__stat-value">{{ auth()->user()->formatted_uploaded }}</span>
            </div>
            <div class="user-sidebar__stat">
                <span class="user-sidebar__stat-label">Download</span>
                <span class="user-sidebar__stat-value">{{ auth()->user()->formatted_downloaded }}</span>
            </div>
            <div class="user-sidebar__stat">
                <span class="user-sidebar__stat-label">Ratio</span>
                <span class="user-sidebar__stat-value">{{ auth()->user()->formatted_ratio }}</span>
            </div>
            <div class="user-sidebar__stat">
                <span class="user-sidebar__stat-label">Seedtime</span>
                <span class="user-sidebar__stat-value">{{ auth()->user()->formatted_seedtime }}</span>
            </div>
            <div class="user-sidebar__stat">
                <span class="user-sidebar__stat-label">Seeding</span>
                <span class="user-sidebar__stat-value">{{ auth()->user()->num_seeding }}</span>
            </div>
            <div class="user-sidebar__stat">
                <span class="user-sidebar__stat-label">Leeching</span>
                <span class="user-sidebar__stat-value">{{ auth()->user()->num_leeching }}</span>
            </div>
            <div class="user-sidebar__stat">
                <span class="user-sidebar__stat-label">Buffer</span>
                <span class="user-sidebar__stat-value">{{ auth()->user()->formatted_buffer }}</span>
            </div>
            <div class="user-sidebar__stat">
                <span class="user-sidebar__stat-label">BON Points</span>
                <span class="user-sidebar__stat-value">{{ auth()->user()->formatted_seedbonus }}</span>
            </div>
            <div class="user-sidebar__stat">
                <span class="user-sidebar__stat-label">Bonus Ratio</span>
                <span class="user-sidebar__stat-value">{{ auth()->user()->formatted_bonus_ratio ?? '0.00' }}</span>
            </div>
            <div class="user-sidebar__stat">
                <span class="user-sidebar__stat-label">FL Tokens</span>
                <span class="user-sidebar__stat-value">{{ auth()->user()->fl_tokens ?? '0' }}</span>
            </div>
        </div>
    </div>
</aside>

{{-- Sidebar Overlay for mobile --}}
<div class="user-sidebar__overlay" id="userSidebarOverlay" onclick="toggleUserSidebar()"></div>
@endauth
