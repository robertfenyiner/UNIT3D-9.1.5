@extends('layout.with-main')

@section('page', 'page__home hawke-minimal-home')

@section('main')
    {{-- Hawke-style Stats Header --}}
    <section class="hawke-stats-header">
        <div class="container">
            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-icon">
                        <i class="{{ config('other.font-awesome') }} fa-users"></i>
                    </div>
                    <div class="stat-content">
                        <div class="stat-value">{{ isset($users) ? count($users) : 'N/A' }}</div>
                        <div class="stat-label">{{ __('common.online') }}</div>
                    </div>
                </div>
                
                <div class="stat-card">
                    <div class="stat-icon">
                        <i class="{{ config('other.font-awesome') }} fa-download"></i>
                    </div>
                    <div class="stat-content">
                        <div class="stat-value">{{ isset($featured) ? count($featured) : 'N/A' }}</div>
                        <div class="stat-label">Featured</div>
                    </div>
                </div>
                
                <div class="stat-card">
                    <div class="stat-icon">
                        <i class="{{ config('other.font-awesome') }} fa-newspaper"></i>
                    </div>
                    <div class="stat-content">
                        <div class="stat-value">{{ isset($articles) ? count($articles) : 'N/A' }}</div>
                        <div class="stat-label">{{ __('common.news') }}</div>
                    </div>
                </div>
                
                <div class="stat-card">
                    <div class="stat-icon">
                        <i class="{{ config('other.font-awesome') }} fa-comments"></i>
                    </div>
                    <div class="stat-content">
                        <div class="stat-value">{{ isset($topics) ? count($topics) : 'N/A' }}</div>
                        <div class="stat-label">Topics</div>
                    </div>
                </div>
                
                <div class="stat-card">
                    <div class="stat-icon">
                        <i class="{{ config('other.font-awesome') }} fa-clock"></i>
                    </div>
                    <div class="stat-content">
                        <div class="stat-value">{{ now()->format('H:i') }}</div>
                        <div class="stat-label">Server Time</div>
                    </div>
                </div>
            </div>
        </div>
    </section>

    {{-- News Section --}}
    @include('blocks.news')
    
    {{-- Chat Section --}}
    @if (! auth()->user()->settings?->chat_hidden)
        <div id="vue" class="hawke-chat-container">
            @include('blocks.chat')
        </div>
        @vite('resources/js/unit3d/chat.js')
    @endif

    {{-- Featured Torrents --}}
    @include('blocks.featured')
    
    {{-- Random Media Component --}}
    @livewire('random-media')
    
    {{-- Poll Component --}}
    @include('blocks.poll')
    
    {{-- Top Torrents Component --}}
    @livewire('top-torrents')
    
    {{-- Top Users Component --}}
    @livewire('top-users')
    
    {{-- Latest Topics --}}
    @include('blocks.latest-topics')
    
    {{-- Online Users --}}
    @include('blocks.online')
@endsection

@push('styles')
<style>
/* Hawke Minimal Home Page Styles */
.hawke-minimal-home {
    background: var(--gradient-primary);
    min-height: 100vh;
}

.hawke-stats-header {
    background: linear-gradient(135deg, rgba(0, 188, 212, 0.1) 0%, rgba(13, 27, 31, 0.8) 100%);
    border-bottom: 1px solid var(--border-primary);
    padding: var(--spacing-xl) 0;
    margin-bottom: var(--spacing-xl);
    backdrop-filter: blur(10px);
    -webkit-backdrop-filter: blur(10px);
}

.stats-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: var(--spacing-lg);
    max-width: 1200px;
    margin: 0 auto;
    padding: 0 var(--spacing-md);
}

.stat-card {
    background: rgba(38, 50, 56, 0.8);
    border: 1px solid var(--border-primary);
    border-radius: var(--radius-lg);
    padding: var(--spacing-lg);
    display: flex;
    align-items: center;
    gap: var(--spacing-md);
    transition: all var(--transition-base);
    backdrop-filter: blur(5px);
    -webkit-backdrop-filter: blur(5px);
    
    &:hover {
        transform: translateY(-2px);
        box-shadow: var(--shadow-lg);
        border-color: var(--color-primary);
        background: rgba(38, 50, 56, 0.9);
    }
}

.stat-icon {
    width: 48px;
    height: 48px;
    background: linear-gradient(135deg, var(--color-primary), var(--color-primary-dark));
    border-radius: var(--radius-md);
    display: flex;
    align-items: center;
    justify-content: center;
    color: var(--text-primary);
    font-size: 1.5rem;
    box-shadow: var(--shadow-md);
}

.stat-content {
    flex: 1;
}

.stat-value {
    font-size: var(--text-2xl);
    font-weight: 700;
    color: var(--text-primary);
    line-height: 1.2;
    margin-bottom: 2px;
}

.stat-label {
    font-size: var(--text-sm);
    color: var(--text-secondary);
    text-transform: uppercase;
    letter-spacing: 0.5px;
    font-weight: 500;
}

/* Enhanced Chat Container */
.hawke-chat-container {
    margin-bottom: var(--spacing-xl);
    
    .chatbox {
        max-height: 350px;
        box-shadow: var(--shadow-lg);
        border: 1px solid var(--color-primary);
        
        .chatbox__header {
            background: linear-gradient(135deg, var(--color-primary-dark), var(--color-primary));
            color: var(--text-primary);
            
            .chatbox__title {
                font-weight: 600;
                display: flex;
                align-items: center;
                gap: var(--spacing-sm);
                
                &:before {
                    content: "💬";
                    font-size: 1.2rem;
                }
            }
        }
        
        .chatbox__messages {
            background: var(--bg-primary);
            max-height: 250px;
            
            .message {
                padding: var(--spacing-sm) var(--spacing-md);
                border-radius: var(--radius-sm);
                margin-bottom: var(--spacing-xs);
                
                &:hover {
                    background: rgba(0, 188, 212, 0.08);
                }
            }
        }
    }
}

/* Enhanced Panels */
.panelV2 {
    background: rgba(38, 50, 56, 0.95);
    backdrop-filter: blur(10px);
    -webkit-backdrop-filter: blur(10px);
    border: 1px solid var(--border-primary);
    box-shadow: var(--shadow-lg);
    
    &:hover {
        border-color: rgba(0, 188, 212, 0.5);
    }
    
    .panel__header {
        background: linear-gradient(135deg, var(--bg-secondary), var(--bg-tertiary));
        border-bottom: 1px solid var(--border-primary);
        
        .panel__heading {
            color: var(--text-primary);
            font-weight: 600;
            
            i {
                color: var(--color-primary);
                margin-right: var(--spacing-sm);
            }
        }
    }
}

/* Featured Torrents Enhancement */
.blocks__featured {
    .featured-torrents {
        padding: var(--spacing-lg);
        
        .torrent-card {
            background: rgba(55, 71, 79, 0.8);
            border: 1px solid var(--border-primary);
            backdrop-filter: blur(5px);
            -webkit-backdrop-filter: blur(5px);
            transition: all var(--transition-base);
            
            &:hover {
                transform: translateY(-4px);
                box-shadow: var(--shadow-xl);
                border-color: var(--color-primary);
            }
        }
    }
}

/* Responsive Design */
@media (max-width: 768px) {
    .hawke-stats-header {
        padding: var(--spacing-lg) 0;
    }
    
    .stats-grid {
        grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
        gap: var(--spacing-md);
        padding: 0 var(--spacing-sm);
    }
    
    .stat-card {
        padding: var(--spacing-md);
        flex-direction: column;
        text-align: center;
        gap: var(--spacing-sm);
    }
    
    .stat-icon {
        width: 40px;
        height: 40px;
        font-size: 1.2rem;
    }
    
    .stat-value {
        font-size: var(--text-xl);
    }
}

@media (max-width: 480px) {
    .stats-grid {
        grid-template-columns: 1fr 1fr;
        gap: var(--spacing-sm);
    }
    
    .stat-card {
        padding: var(--spacing-sm);
    }
    
    .stat-value {
        font-size: var(--text-lg);
    }
    
    .stat-label {
        font-size: var(--text-xs);
    }
}
</style>
@endpush
