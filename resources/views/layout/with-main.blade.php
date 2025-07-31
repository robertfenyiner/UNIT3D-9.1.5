@extends('layout.default')

@section('content')
    <div class="main-layout">
        {{-- Sidebar --}}
        <aside class="sidebar">
            @include('partials.sidebar')
        </aside>
        
        {{-- Main Content --}}
        <main class="main-content">
            <article>
                @yield('main')
            </article>
        </main>
    </div>
@endsection

@push('styles')
<style>
.main-layout {
    display: flex;
    min-height: calc(100vh - 120px);
    gap: 0;
}

.sidebar {
    width: 220px;
    background: linear-gradient(180deg, #1a1a1a 0%, #0f0f0f 100%);
    border-right: 1px solid #333;
    position: sticky;
    top: 80px;
    height: calc(100vh - 80px);
    overflow-y: auto;
    flex-shrink: 0;
    z-index: 100;
}

.main-content {
    flex: 1;
    min-width: 0;
    padding: 0;
}

/* Responsive */
@media (max-width: 1024px) {
    .sidebar {
        width: 200px;
    }
}

@media (max-width: 768px) {
    .main-layout {
        flex-direction: column;
    }
    
    .sidebar {
        width: 100%;
        height: auto;
        position: relative;
        top: 0;
        border-right: none;
        border-bottom: 1px solid #333;
    }
    
    .main-content {
        padding: 0;
    }
}

/* Scrollbar para sidebar */
.sidebar::-webkit-scrollbar {
    width: 4px;
}

.sidebar::-webkit-scrollbar-track {
    background: #1a1a1a;
}

.sidebar::-webkit-scrollbar-thumb {
    background: #444;
    border-radius: 2px;
}

.sidebar::-webkit-scrollbar-thumb:hover {
    background: #555;
}
</style>
@endpush
