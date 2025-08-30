@php
    echo '<?xml version="1.0" encoding="UTF-8" ?>';
@endphp
<rss version="2.0"
     xmlns:atom="http://www.w3.org/2005/Atom"
     xmlns:content="http://purl.org/rss/1.0/modules/content/"
     xmlns:media="http://search.yahoo.com/mrss/"
     xmlns:dc="http://purl.org/dc/elements/1.1/">
    <channel>
        <title><![CDATA[{{ config('other.title') }}: {{ $rss->name }}]]></title>
        <link>{{ config('app.url') }}</link>
        <description>
            <![CDATA[{{ __('This feed contains your secure rsskey, please do not share with anyone.') }}]]>
        </description>
        <atom:link href="{{ route('rss.show.rsskey', ['id' => $rss->id, 'rsskey' => $user->rsskey]) }}"
                   type="application/rss+xml" rel="self"></atom:link>
        <copyright>{{ config('other.title') }} {{ now()->year }}</copyright>
        <language>en-us</language>
        <lastBuildDate>{{ now()->toRssString() }}</lastBuildDate>
        <ttl>5</ttl>
        @if($torrents)
            @foreach($torrents as $torrent)
                <item>
                    <title><![CDATA[{{ $torrent['name'] }}]]></title>
                    <category><![CDATA[{{ $torrent['category']['name'] ?? 'Unknown' }}]]></category>
                    <contentlength>{{ $torrent['size'] ?? 0 }}</contentlength>
                    <enclosure url="{{ route('torrent.download.rsskey', ['id' => $torrent['id'], 'rsskey' => $user->rsskey ]) }}" 
                               length="{{ $torrent['size'] ?? 0 }}" 
                               type="application/x-bittorrent" />
                    <link>{{ route('torrent.download.rsskey', ['id' => $torrent['id'], 'rsskey' => $user->rsskey ]) }}</link>
                    <guid isPermaLink="false">{{ config('app.url') }}-torrent-{{ $torrent['id'] }}</guid>
                    <description>
                        <![CDATA[<p>
                            <strong>Name</strong>: {{ $torrent['name'] }}<br>
                            <strong>Category</strong>: {{ $torrent['category']['name'] ?? 'Unknown' }}<br>
                            <strong>Type</strong>: {{ $torrent['type']['name'] ?? 'Unknown' }}<br>
                            <strong>Resolution</strong>: {{ $torrent['resolution']['name'] ?? 'No Res' }}<br>
                            <strong>Size</strong>: {{ App\Helpers\StringHelper::formatBytes($torrent['size'], 2) }}<br>
                            <strong>Uploaded</strong>: {{ \Illuminate\Support\Carbon::createFromTimestampUTC($torrent['created_at'])->diffForHumans() }}<br>
                            <strong>Seeders</strong>: {{ $torrent['seeders'] ?? 0 }} |
                            <strong>Leechers</strong>: {{ $torrent['leechers'] ?? 0 }} |
                            <strong>Completed</strong>: {{ $torrent['times_completed'] ?? 0 }}<br>
                            <strong>Uploader</strong>:
                            @if(!($torrent['anon'] ?? true) && isset($torrent['user']) && $torrent['user'])
                                {{ __('torrent.uploaded-by') }} {{ $torrent['user']['username'] }}
                            @else
                                {{ __('common.anonymous') }} {{ __('torrent.uploader') }}
                            @endif<br>
                            @if ((($torrent['category']['movie_meta'] ?? false) || ($torrent['category']['tv_meta'] ?? false)) && ($torrent['imdb'] ?? 0) != 0)
                                IMDB Link: <a href="https://anon.to?http://www.imdb.com/title/tt{{ \str_pad((string) $torrent['imdb'], \max(\strlen((string) $torrent['imdb']), 7), '0', STR_PAD_LEFT) }}"
                                             target="_blank">tt{{ $torrent['imdb'] }}</a><br>
                            @endif
                            @if (($torrent['category']['movie_meta'] ?? false) && ($torrent['tmdb_movie_id'] ?? 0) > 0)
                                TMDB Link: <a href="https://anon.to?https://www.themoviedb.org/movie/{{ $torrent['tmdb_movie_id'] }}"
                                              target="_blank">{{ $torrent['tmdb_movie_id'] }}</a><br>
                            @elseif (($torrent['category']['tv_meta'] ?? false) && ($torrent['tmdb_tv_id'] ?? 0) > 0)
                                TMDB Link: <a href="https://anon.to?https://www.themoviedb.org/tv/{{ $torrent['tmdb_tv_id'] }}"
                                              target="_blank">{{ $torrent['tmdb_tv_id'] }}</a><br>
                            @endif
                            @if (($torrent['category']['tv_meta'] ?? false) && ($torrent['tvdb'] ?? 0) != 0)
                                TVDB Link: <a href="https://anon.to?https://www.thetvdb.com/?tab=series&id={{ $torrent['tvdb'] }}"
                                             target="_blank">{{ $torrent['tvdb'] }}</a><br>
                            @endif
                            @if ((($torrent['category']['movie_meta'] ?? false) || ($torrent['category']['tv_meta'] ?? false)) && ($torrent['mal'] ?? 0) != 0)
                                MAL Link: <a href="https://anon.to?https://myanimelist.net/anime/{{ $torrent['mal'] }}"
                                             target="_blank">{{ $torrent['mal'] }}</a><br>
                            @endif
                            @if (($torrent['internal'] ?? 0) == 1)
                                <strong>Internal:</strong> This is a high quality internal release!<br>
                            @endif
                        </p>]]>
                    </description>
                    <dc:creator>
                        @if(!($torrent['anon'] ?? true) && isset($torrent['user']) && $torrent['user'])
                            {{ __('torrent.uploaded-by') }} {{ $torrent['user']['username'] }}
                        @else
                            {{ __('common.anonymous') }} {{ __('torrent.uploader') }}
                        @endif
                    </dc:creator>
                    <pubDate>{{ \Illuminate\Support\Carbon::createFromTimestampUTC($torrent['created_at'])->toRssString() }}</pubDate>
                </item>
            @endforeach
        @endif
    </channel>
</rss>
