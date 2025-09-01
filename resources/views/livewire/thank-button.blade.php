<button
    wire:click="store"
    class="form__button form__button--outlined form__button--centered"
>
    <i class="{{ config('other.font-awesome') }} fa-heart text-pink"></i>
    {{ __('torrent.thank') }} ({{ $torrent->thanks()->count() }})
</button>
