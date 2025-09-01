@if ($this->isBookmarked)
    <button
        wire:click="destroy"
        class="form__button form__button--filled form__button--centered"
        title="Bookmarked by {{ $bookmarksCount }} users"
    >
        <i class="{{ config('other.font-awesome') }} fa-bookmark-slash"></i>
        {{ __('torrent.unbookmark') }} ({{ $bookmarksCount }})
    </button>
@else
    <button
        wire:click="store"
        class="form__button form__button--outlined form__button--centered"
        title="Bookmarked by {{ $bookmarksCount }} users"
    >
        <i class="{{ config('other.font-awesome') }} fa-bookmark"></i>
        {{ __('torrent.bookmark') }} ({{ $bookmarksCount }})
    </button>
@endif
