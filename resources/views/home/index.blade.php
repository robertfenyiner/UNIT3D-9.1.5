@extends('layout.with-main')

@section('page', 'page__home')

@section('main')
    @include('blocks.news')
    @if (! auth()->user()->settings?->chat_hidden)
        <div id="vue">
            @include('blocks.chat')
        </div>
        @vite('resources/js/unit3d/chat.js')
    @endif

    @include('blocks.featured')
    @livewire('random-media')
    @include('blocks.poll')
    @livewire('top-torrents')
    @livewire('top-users')
    @include('blocks.latest-topics')
    {{--@include('blocks.latest-posts')--}}
    {{--@include('blocks.latest-comments')--}}
    @include('blocks.online')
@endsection
