import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:donghua_player/data/providers/anime_stream_site_provider.dart';
import 'package:donghua_player/data/providers/multi_source_provider.dart';
import 'package:donghua_player/domain/models/content_source.dart';
import 'package:donghua_player/domain/models/episode.dart';
import 'package:donghua_player/domain/models/schedule_entry.dart';
import 'package:donghua_player/domain/models/show.dart';
import 'package:donghua_player/domain/models/stream_source.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers every request from memory, so no test touches the network.
class _FakeAdapter implements HttpClientAdapter {
  final String Function(RequestOptions options) handler;

  _FakeAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      handler(options),
      200,
      headers: {
        Headers.contentTypeHeader: ['text/html; charset=utf-8'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// A site whose search answer is given by the test.
class _FakeSite extends AnimeStreamSiteProvider {
  final Future<List<Show>> Function(String query) onSearch;
  final Future<Map<int, List<ScheduleEntry>>> Function()? onSchedule;
  final Future<List<Show>> Function()? onPopular;
  final List<String> episodeCalls = [];
  final List<String> streamCalls = [];

  _FakeSite(
    String id, {
    required this.onSearch,
    this.onSchedule,
    this.onPopular,
  }) : super(id: id, name: id.toUpperCase(), baseUrl: 'https://$id.test');

  @override
  Future<Map<int, List<ScheduleEntry>>> schedule() =>
      onSchedule?.call() ?? Future.error(const FormatException('no page'));

  @override
  Future<List<Show>> popular() =>
      onPopular?.call() ?? Future.error(const FormatException('no page'));

  @override
  Future<List<Show>> newSeries() => popular();

  @override
  Future<List<Show>> search(String query) => onSearch(query);

  @override
  Future<List<Episode>> episodes(String showId) async {
    episodeCalls.add(showId);
    return const [];
  }

  @override
  Future<List<StreamSource>> streams(String episodeId) async {
    streamCalls.add(episodeId);
    return const [];
  }
}

Show _show(String site, String slug, String title) => Show(
  id: 'https://$site.test/anime/$slug/',
  title: title,
  poster: '',
  providerId: site,
);

/// The markup of an AnimeStream search page, as DonghuaWorld, DonghuaStream,
/// and LMAnime served it on 2026-11-10 (trimmed).
const _searchPage = '''
<html><body><div class="listupd">
<article class="bs" itemscope="itemscope">
  <div class="bsx">
    <a href="https://donghuaworld.com/anime/renegade-immortal-xian-ni/"
       itemprop="url" title="Renegade Immortal (Xian Ni)">
      <div class="limit">
        <div class="bt"><span class="epx">Ongoing</span></div>
        <img src="https://donghuaworld.com/wp-content/uploads/ri.webp"
             class="ts-post-image" title="Renegade Immortal">
      </div>
      <div class="tt">Renegade Immortal <h2 itemprop="headline">Renegade Immortal (Xian Ni)</h2></div>
    </a>
  </div>
</article>
<article class="bs" itemscope="itemscope">
  <div class="bsx">
    <a href="https://donghuaworld.com/anime/renegade-immortal-xian-ni/"
       itemprop="url" title="Renegade Immortal (Xian Ni)"></a>
  </div>
</article>
</div>
<a href="https://donghuaworld.com/genres/action/" title="View all Series in Action">Action</a>
</body></html>
''';

const _seriesPage = '''
<html><body><div class="eplister"><ul>
<li data-index="0"><a href="https://donghuaworld.com/ri-episode-2/">
  <div class="epl-num">2</div><div class="epl-title">Episode 2</div>
  <div class="epl-date">November 9, 2026</div></a></li>
<li data-index="1"><a href="https://donghuaworld.com/ri-episode-1/">
  <div class="epl-num">1</div><div class="epl-title">Episode 1</div>
  <div class="epl-date">November 2, 2026</div></a></li>
</ul></div></body></html>
''';

AnimeStreamSiteProvider _siteWith(String Function(RequestOptions) handler) {
  final dio = Dio(BaseOptions(baseUrl: 'https://donghuaworld.com'))
    ..httpClientAdapter = _FakeAdapter(handler);
  return AnimeStreamSiteProvider(
    id: 'donghuaworld',
    name: 'DonghuaWorld',
    baseUrl: 'https://donghuaworld.com',
    dio: dio,
  );
}

void main() {
  group('content sources', () {
    test('follow DonghuaCLI, with AnimeXin first as the main source', () {
      expect(kContentSources.map((s) => s.id), [
        'animexin',
        'donghuaworld',
        'luciferdonghua',
        'donghuastream',
        'lmanime',
      ]);
      expect(defaultSources().map((s) => s.id), [
        for (final s in kContentSources) s.id,
      ]);
      expect(kContentSources.map((s) => s.id).toSet(), hasLength(5));
    });

    test('names are found by provider id', () {
      expect(sourceNameOf('animexin'), 'AnimeXin');
      expect(sourceNameOf('lmanime'), 'LMAnime');
      expect(sourceNameOf('default'), isNull);
    });
  });

  group('AnimeStreamSiteProvider', () {
    test(
      'reads search cards once each, with poster and episode badge',
      () async {
        final site = _siteWith((options) {
          expect(options.uri.path, '/');
          expect(options.uri.queryParameters['s'], 'renegade');
          return _searchPage;
        });

        final shows = await site.search(' renegade ');

        expect(shows, hasLength(1));
        expect(
          shows.single.id,
          'https://donghuaworld.com/anime/renegade-immortal-xian-ni/',
        );
        expect(shows.single.title, 'Renegade Immortal (Xian Ni)');
        expect(
          shows.single.poster,
          'https://donghuaworld.com/wp-content/uploads/ri.webp',
        );
        expect(shows.single.episodeCount, 'Ongoing');
        expect(shows.single.providerId, 'donghuaworld');
      },
    );

    test('an empty query asks nothing', () async {
      final site = _siteWith((_) => fail('no request expected'));
      expect(await site.search('  '), isEmpty);
    });

    test('reads the episode list in number order', () async {
      final site = _siteWith((_) => _seriesPage);

      final episodes = await site.episodes(
        'https://donghuaworld.com/anime/renegade-immortal-xian-ni/',
      );

      expect(episodes.map((e) => e.number), [1, 2]);
      expect(episodes.first.id, 'https://donghuaworld.com/ri-episode-1/');
      expect(episodes.first.uploadDate, 'November 2, 2026');
    });

    test('owns its own host, with or without www', () {
      final site = _siteWith((_) => '');
      expect(site.owns('https://donghuaworld.com/x/'), isTrue);
      expect(site.owns('https://www.donghuaworld.com/x/'), isTrue);
      expect(site.owns('https://animexin.dev/x/'), isFalse);
      expect(site.owns('not a url'), isFalse);
    });
  });

  group('MultiSourceStreamProvider', () {
    test('asks every source and merges the answers', () async {
      final provider = MultiSourceStreamProvider(
        sources: [
          _FakeSite(
            'ax',
            onSearch: (_) async => [
              _show('ax', 'ri', 'Renegade Immortal'),
              _show('ax', 'ri-movie', 'Renegade Immortal Movie'),
            ],
          ),
          _FakeSite(
            'dw',
            onSearch: (_) async => [
              _show('dw', 'ri', 'Renegade Immortal [ Temporary ]'),
            ],
          ),
        ],
      );

      final shows = await provider.search('renegade');

      expect(shows.map((s) => s.id), [
        'https://ax.test/anime/ri/',
        'https://dw.test/anime/ri/',
        'https://ax.test/anime/ri-movie/',
      ]);
    });

    test('a failing or slow source is skipped, the others answer', () async {
      final never = Completer<List<Show>>();
      final provider = MultiSourceStreamProvider(
        searchTimeout: const Duration(milliseconds: 50),
        sources: [
          _FakeSite('ax', onSearch: (_) async => throw Exception('down')),
          _FakeSite('dw', onSearch: (_) => never.future),
          _FakeSite(
            'lm',
            onSearch: (_) async => [_show('lm', 'ri', 'Renegade Immortal')],
          ),
        ],
      );

      final shows = await provider.search('renegade');

      expect(shows.map((s) => s.providerId), ['lm']);
    });

    test('an empty query goes to the main source only', () async {
      final asked = <String>[];
      Future<List<Show>> record(String id, String q) async {
        asked.add('$id:$q');
        return const [];
      }

      final provider = MultiSourceStreamProvider(
        sources: [
          _FakeSite('ax', onSearch: (q) => record('ax', q)),
          _FakeSite('dw', onSearch: (q) => record('dw', q)),
        ],
      );

      await provider.search('   ');

      expect(asked, ['ax:']);
    });

    test('episodes go to the site of the show, unknown hosts to the main '
        'source', () async {
      final ax = _FakeSite('ax', onSearch: (_) async => const []);
      final dw = _FakeSite('dw', onSearch: (_) async => const []);
      final provider = MultiSourceStreamProvider(sources: [ax, dw]);

      await provider.episodes('https://dw.test/anime/ri/');
      await provider.episodes('https://www.dw.test/anime/ri/');
      await provider.episodes('https://elsewhere.test/anime/ri/');

      expect(dw.episodeCalls, [
        'https://dw.test/anime/ri/',
        'https://www.dw.test/anime/ri/',
      ]);
      expect(ax.episodeCalls, ['https://elsewhere.test/anime/ri/']);
      expect(provider.sourceFor('https://ax.test/a/'), same(ax));
    });

    test('streams go to the site of the episode', () async {
      final ax = _FakeSite('ax', onSearch: (_) async => const []);
      final dw = _FakeSite('dw', onSearch: (_) async => const []);
      final provider = MultiSourceStreamProvider(sources: [ax, dw]);

      await provider.streams('https://dw.test/ri-episode-1/');
      await provider.streams('https://ax.test/ri-episode-1/');

      expect(dw.streamCalls, ['https://dw.test/ri-episode-1/']);
      expect(ax.streamCalls, ['https://ax.test/ri-episode-1/']);
    });

    test('needs at least one source', () {
      expect(
        () => MultiSourceStreamProvider(sources: const []),
        throwsArgumentError,
      );
    });
  });

  group('mergeSearchResults', () {
    test('puts the best match of every source first', () {
      final merged = mergeSearchResults([
        [_show('a', '1', 'Alpha'), _show('a', '2', 'Beta')],
        [_show('b', '1', 'Gamma'), _show('b', '2', 'Delta')],
      ]);

      expect(merged.map((s) => s.title), ['Alpha', 'Gamma', 'Beta', 'Delta']);
    });

    test('keeps one series from several sources together', () {
      final merged = mergeSearchResults([
        [_show('a', '1', 'Alpha'), _show('a', '2', 'Soul Land')],
        [_show('b', '1', 'soul land!'), _show('b', '2', 'Alpha')],
      ]);

      expect(merged.map((s) => s.id), [
        'https://a.test/anime/1/',
        'https://b.test/anime/2/',
        'https://b.test/anime/1/',
        'https://a.test/anime/2/',
      ]);
    });

    test('drops a URL that two lists both carry', () {
      final same = _show('a', '1', 'Alpha');
      expect(
        mergeSearchResults([
          [same],
          [same],
        ]),
        hasLength(1),
      );
    });
  });

  group('normalizeShowTitle', () {
    test('ignores case, punctuation, and bracket notes', () {
      expect(
        normalizeShowTitle('Renegade Immortal [ Temporary ]'),
        normalizeShowTitle('renegade immortal'),
      );
      expect(
        normalizeShowTitle('Soul Land 2: The Peerless Tang Clan'),
        'soul land 2 the peerless tang clan',
      );
    });

    test('titles without Latin letters keep their own key', () {
      expect(normalizeShowTitle(' 仙逆 '), '仙逆');
      expect(normalizeShowTitle('仙逆'), isNot(normalizeShowTitle('斗破苍穹')));
    });

    test('keeps seasons apart', () {
      expect(
        normalizeShowTitle('Battle Through the Heavens Season 5'),
        isNot(normalizeShowTitle('Battle Through the Heavens Season 4')),
      );
    });
  });

  group('absoluteUrl', () {
    const base = 'https://lmanime.com';

    test('keeps absolute links', () {
      expect(absoluteUrl('https://x.test/a/', base), 'https://x.test/a/');
    });

    test('resolves relative links against the site', () {
      expect(absoluteUrl('/anime/ri/', base), 'https://lmanime.com/anime/ri/');
      expect(
        absoluteUrl('ri-episode-1/', base),
        'https://lmanime.com/ri-episode-1/',
      );
    });

    test('leaves an empty link empty', () {
      expect(absoluteUrl('  ', base), '');
    });
  });

  group('Explore from every source', () {
    ScheduleEntry entry(String site, String slug, {int? hour}) => ScheduleEntry(
      show: _show(site, slug, slug),
      releaseAt: hour == null ? null : DateTime.utc(2026, 11, 10, hour),
    );

    Map<int, List<ScheduleEntry>> week(Map<int, List<ScheduleEntry>> days) => {
      for (var d = 1; d <= 7; d++) d: days[d] ?? <ScheduleEntry>[],
    };

    test('mergeSchedules keeps every show, sorted by release time', () {
      final merged = mergeSchedules([
        week({
          2: [entry('ax', 'b', hour: 12), entry('ax', 'no-time')],
        }),
        week({
          2: [entry('dw', 'a', hour: 9), entry('dw', 'c', hour: 12)],
          5: [entry('dw', 'friday')],
        }),
      ]);

      expect(merged.keys, [1, 2, 3, 4, 5, 6, 7]);
      expect(merged[2]!.map((e) => e.show.title), ['a', 'b', 'c', 'no-time']);
      expect(merged[5]!.map((e) => e.show.title), ['friday']);
      expect(merged[1], isEmpty);
    });

    test('mergeSchedules lists the same URL once', () {
      final same = entry('ax', 'x', hour: 10);
      final merged = mergeSchedules([
        week({
          3: [same],
        }),
        week({
          3: [same],
        }),
      ]);
      expect(merged[3], hasLength(1));
    });

    test('schedule skips a source without a schedule page', () async {
      final provider = MultiSourceStreamProvider(
        sources: [
          _FakeSite(
            'ax',
            onSearch: (_) async => const [],
            onSchedule: () async => week({
              1: [entry('ax', 'one', hour: 8)],
            }),
          ),
          // No onSchedule: its schedule() fails, like DonghuaStream's page.
          _FakeSite('ds', onSearch: (_) async => const []),
          _FakeSite(
            'lm',
            onSearch: (_) async => const [],
            onSchedule: () async => week({
              1: [entry('lm', 'two', hour: 7)],
            }),
          ),
        ],
      );

      final merged = await provider.schedule();

      expect(merged[1]!.map((e) => e.show.providerId), ['lm', 'ax']);
    });

    test('a list fails only when every source fails', () async {
      final provider = MultiSourceStreamProvider(
        sources: [
          _FakeSite('ax', onSearch: (_) async => const []),
          _FakeSite('dw', onSearch: (_) async => const []),
        ],
      );

      await expectLater(provider.schedule(), throwsFormatException);
      await expectLater(provider.popular(), throwsFormatException);
    });

    test('popular and new series merge every source', () async {
      final provider = MultiSourceStreamProvider(
        sources: [
          _FakeSite(
            'ax',
            onSearch: (_) async => const [],
            onPopular: () async => [
              _show('ax', '1', 'Alpha'),
              _show('ax', '2', 'Beta'),
            ],
          ),
          _FakeSite(
            'dw',
            onSearch: (_) async => const [],
            onPopular: () async => [_show('dw', '1', 'Gamma')],
          ),
          _FakeSite('ds', onSearch: (_) async => const []),
        ],
      );

      expect((await provider.popular()).map((s) => s.title), [
        'Alpha',
        'Gamma',
        'Beta',
      ]);
      expect((await provider.newSeries()).map((s) => s.title), [
        'Alpha',
        'Gamma',
        'Beta',
      ]);
    });

    test('a slow source is left out of the lists', () async {
      final never = Completer<List<Show>>();
      final provider = MultiSourceStreamProvider(
        listingTimeout: const Duration(milliseconds: 50),
        sources: [
          _FakeSite(
            'ax',
            onSearch: (_) async => const [],
            onPopular: () => never.future,
          ),
          _FakeSite(
            'dw',
            onSearch: (_) async => const [],
            onPopular: () async => [_show('dw', '1', 'Gamma')],
          ),
        ],
      );

      expect((await provider.popular()).map((s) => s.title), ['Gamma']);
    });
  });
}
