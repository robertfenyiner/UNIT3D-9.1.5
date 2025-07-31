@extends('layout.with-main')

@section('page', 'page__home')

@section('main')
    <div class="home-container">
        {{-- Welcome Banner --}}
        <div class="welcome-banner">
            <h1>Bienvenido a {{ config('other.title') }}</h1>
            <p>Tu tracker privado de torrents</p>
        </div>

        {{-- Stats Cards --}}
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-icon">
                    <i class="fas fa-download"></i>
                </div>
                <div class="stat-content">
                    <h3>{{ App\Models\Torrent::count() }}</h3>
                    <p>Torrents</p>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-icon">
                    <i class="fas fa-users"></i>
                </div>
                <div class="stat-content">
                    <h3>{{ App\Models\User::count() }}</h3>
                    <p>Usuarios</p>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-icon">
                    <i class="fas fa-seedling"></i>
                </div>
                <div class="stat-content">
                    <h3>{{ App\Models\Peer::where('seeder', '=', 1)->count() }}</h3>
                    <p>Seeders</p>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-icon">
                    <i class="fas fa-arrow-down"></i>
                </div>
                <div class="stat-content">
                    <h3>{{ App\Models\Peer::where('seeder', '=', 0)->count() }}</h3>
                    <p>Leechers</p>
                </div>
            </div>
        </div>

        {{-- Main Content Grid --}}
        <div class="content-grid">
            {{-- News Section --}}
            <div class="content-section">
                <div class="section-header">
                    <h2><i class="fas fa-newspaper"></i> Últimas Noticias</h2>
                </div>
                <div class="section-content">
                    @include('blocks.news')
                </div>
            </div>

            {{-- Chat Section --}}
            @if (! auth()->user()->settings?->chat_hidden)
            <div class="content-section">
                <div class="section-header">
                    <h2><i class="fas fa-comments"></i> Chat</h2>
                </div>
                <div class="section-content">
                    <div id="vue">
                        @include('blocks.chat')
                    </div>
                </div>
            </div>
            @endif

            {{-- Featured Torrents --}}
            <div class="content-section">
                <div class="section-header">
                    <h2><i class="fas fa-star"></i> Torrents Destacados</h2>
                </div>
                <div class="section-content">
                    @include('blocks.featured')
                </div>
            </div>

            {{-- Random Media --}}
            <div class="content-section">
                <div class="section-header">
                    <h2><i class="fas fa-random"></i> Media Aleatorio</h2>
                </div>
                <div class="section-content">
                    @livewire('random-media')
                </div>
            </div>
        </div>

        {{-- Additional Content --}}
        <div class="additional-content">
            @include('blocks.poll')
            @livewire('top-torrents')
            @livewire('top-users')
            @include('blocks.latest-topics')
            @include('blocks.online')
        </div>
    </div>

    @if (! auth()->user()->settings?->chat_hidden)
        @vite('resources/js/unit3d/chat.js')
    @endif
@endsection

@push('styles')
<style>
.home-container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 20px;
}

.welcome-banner {
    background: linear-gradient(135deg, #20b2aa 0%, #1a9a96 100%);
    padding: 40px;
    border-radius: 12px;
    text-align: center;
    margin-bottom: 30px;
    color: white;
}

.welcome-banner h1 {
    font-size: 2.5rem;
    margin: 0 0 10px 0;
    font-weight: 700;
}

.welcome-banner p {
    font-size: 1.1rem;
    margin: 0;
    opacity: 0.9;
}

.stats-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 20px;
    margin-bottom: 30px;
}

.stat-card {
    background: #2a2a2a;
    padding: 24px;
    border-radius: 10px;
    display: flex;
    align-items: center;
    border: 1px solid #404040;
    transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.stat-card:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 25px rgba(32, 178, 170, 0.2);
}

.stat-icon {
    background: linear-gradient(135deg, #20b2aa, #1a9a96);
    width: 50px;
    height: 50px;
    border-radius: 10px;
    display: flex;
    align-items: center;
    justify-content: center;
    margin-right: 16px;
    color: white;
    font-size: 20px;
}

.stat-content h3 {
    font-size: 1.8rem;
    margin: 0 0 4px 0;
    color: #fff;
    font-weight: 700;
}

.stat-content p {
    margin: 0;
    color: #888;
    font-size: 0.9rem;
}

.content-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
    gap: 24px;
    margin-bottom: 30px;
}

.content-section {
    background: #2a2a2a;
    border-radius: 10px;
    overflow: hidden;
    border: 1px solid #404040;
}

.section-header {
    padding: 20px 24px;
    background: #333;
    border-bottom: 1px solid #404040;
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.section-header h2 {
    margin: 0;
    font-size: 1.1rem;
    color: #fff;
    font-weight: 600;
}

.section-header h2 i {
    margin-right: 8px;
    color: #20b2aa;
}

.section-content {
    padding: 0;
    max-height: 400px;
    overflow-y: auto;
}

.additional-content {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
    gap: 24px;
}

/* Mobile responsive */
@media (max-width: 768px) {
    .home-container {
        padding: 16px;
    }
    
    .welcome-banner {
        padding: 30px 20px;
    }
    
    .welcome-banner h1 {
        font-size: 2rem;
    }
    
    .stats-grid {
        grid-template-columns: repeat(2, 1fr);
        gap: 16px;
    }
    
    .content-grid,
    .additional-content {
        grid-template-columns: 1fr;
        gap: 20px;
    }
    
    .stat-card {
        padding: 20px;
    }
}

@media (max-width: 480px) {
    .stats-grid {
        grid-template-columns: 1fr;
    }
    
    .welcome-banner h1 {
        font-size: 1.8rem;
    }
}
</style>
@endpush
