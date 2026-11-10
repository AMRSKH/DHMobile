import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:donghua_player/domain/models/show.dart';
import 'package:donghua_player/domain/models/episode.dart';
import 'package:donghua_player/domain/models/stream_source.dart';
import 'package:donghua_player/data/providers/animexin_stream_provider.dart';
import 'package:donghua_player/data/providers/stream_resolver.dart';

/// Answers every request from memory and records what was asked, so the
/// provider tests never touch the network.
class _FakeAdapter implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions options) handler;
  final List<Uri> requests = [];

  _FakeAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options.uri);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _html(String body, {int status = 200}) {
  return ResponseBody.fromString(
    body,
    status,
    headers: {
      Headers.contentTypeHeader: ['text/html; charset=utf-8'],
    },
  );
}

String _fixture(String name) => File('test/fixtures/$name').readAsStringSync();

AnimeXinStreamProvider _providerWith(_FakeAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://animexin.dev'))
    ..httpClientAdapter = adapter;
  return AnimeXinStreamProvider(dio: dio);
}

/// Serves the saved pages by path, like the source does.
_FakeAdapter _sourceAdapter() {
  return _FakeAdapter((options) {
    final uri = options.uri;
    if (uri.path == '/schedule/') {
      return _html(_fixture('animexin_schedule.html'));
    }
    if (uri.path == '/anime/' && uri.queryParameters['order'] == 'popular') {
      return _html(_fixture('animexin_popular.html'));
    }
    if (uri.path == '/anime/' && uri.queryParameters['order'] == 'latest') {
      return _html(_fixture('animexin_latest.html'));
    }
    return _html('not found', status: 404);
  });
}

const _emptyPage = '<html><body><div class="listupd"></div></body></html>';

void main() {
  group('AnimeXinStreamProvider listings', () {
    test('schedule() reads /schedule/ into seven days', () async {
      final adapter = _sourceAdapter();
      final schedule = await _providerWith(adapter).schedule();

      expect(adapter.requests, hasLength(1));
      expect(adapter.requests.single.path, '/schedule/');
      expect(schedule.keys.toList()..sort(), [1, 2, 3, 4, 5, 6, 7]);
      expect(schedule.values.expand((day) => day), hasLength(61));
      expect(schedule[DateTime.saturday], hasLength(14));
      expect(
        schedule.values
            .expand((d) => d)
            .every((e) => e.show.providerId == 'animexin'),
        isTrue,
      );
    });

    test('popular() reads /anime/?order=popular', () async {
      final adapter = _sourceAdapter();
      final shows = await _providerWith(adapter).popular();

      expect(adapter.requests.single.path, '/anime/');
      expect(adapter.requests.single.queryParameters, {'order': 'popular'});
      expect(shows, hasLength(30));
      expect(shows.first.title, 'Soul Land Season 2');
      expect(shows.first.providerId, 'animexin');
    });

    test('newSeries() reads /anime/?order=latest', () async {
      final adapter = _sourceAdapter();
      final shows = await _providerWith(adapter).newSeries();

      expect(adapter.requests.single.path, '/anime/');
      expect(adapter.requests.single.queryParameters, {'order': 'latest'});
      expect(shows, hasLength(30));
      expect(shows.first.status, 'Upcoming');
    });

    test('search with an empty query returns the popular list', () async {
      final adapter = _sourceAdapter();
      final provider = _providerWith(adapter);

      final shows = await provider.search('   ');
      final popular = await provider.popular();

      expect(shows.map((s) => s.id), popular.map((s) => s.id));
      expect(
        adapter.requests.every(
          (uri) => uri.queryParameters['order'] == 'popular',
        ),
        isTrue,
      );
    });

    test('a page without shows throws instead of using the built-in list', () {
      final provider = _providerWith(_FakeAdapter((_) => _html(_emptyPage)));

      expect(provider.schedule(), throwsFormatException);
      expect(provider.popular(), throwsFormatException);
      expect(provider.newSeries(), throwsFormatException);
      expect(provider.search(''), throwsFormatException);
    });

    test('a failed request is thrown to the caller', () {
      final provider = _providerWith(
        _FakeAdapter((_) => _html('Service Unavailable', status: 503)),
      );

      expect(provider.schedule(), throwsA(isA<DioException>()));
      expect(provider.popular(), throwsA(isA<DioException>()));
      expect(provider.newSeries(), throwsA(isA<DioException>()));
    });

    test('a schedule with one empty day is valid', () async {
      const page =
          '<div class="bixbox schedulepage sch_monday"></div>'
          '<div class="bixbox schedulepage sch_tuesday"><div class="bsx">'
          '<a href="https://animexin.dev/show-a/" title="Show A"></a>'
          '</div></div>';
      final schedule = await _providerWith(
        _FakeAdapter((_) => _html(page)),
      ).schedule();

      expect(schedule[DateTime.monday], isEmpty);
      expect(schedule[DateTime.tuesday], hasLength(1));
    });

    test('a text search still falls back to the built-in list', () async {
      final adapter = _FakeAdapter((_) => _html('down', status: 503));
      final results = await _providerWith(adapter).search('soul land');

      expect(adapter.requests.single.queryParameters, {'s': 'soul land'});
      expect(results, isNotEmpty);
      expect(
        results.every((s) => s.title.toLowerCase().contains('soul land')),
        isTrue,
      );
    });
  });

  group('Donghua Models & Provider Tests', () {
    test('Show serialization', () {
      const show = Show(
        id: 'test-id',
        title: 'Battle Through the Heavens',
        poster: 'https://example.com/poster.jpg',
        episodeCount: '104',
        providerId: 'animexin',
      );

      final map = show.toMap();
      expect(map['title'], equals('Battle Through the Heavens'));

      final fromMap = Show.fromMap(map);
      expect(fromMap.id, equals('test-id'));
      expect(fromMap.episodeCount, equals('104'));
    });

    test('Episode serialization', () {
      const ep = Episode(
        id: 'ep-1',
        number: 1.0,
        title: 'Episode 1',
        showId: 'test-id',
      );

      final map = ep.toMap();
      final fromMap = Episode.fromMap(map);
      expect(fromMap.number, equals(1.0));
      expect(fromMap.title, equals('Episode 1'));
    });

    test('StreamSource initialization', () {
      const source = StreamSource(
        url: 'https://example.com/video.mp4',
        quality: '1080p',
        server: 'Primary',
        headers: {'Referer': 'https://example.com'},
      );

      expect(source.url, contains('video.mp4'));
      expect(source.quality, equals('1080p'));
      expect(source.headers['Referer'], equals('https://example.com'));
    });

    test('StreamResolver direct m3u8 or mp4 handling', () async {
      final resolver = StreamResolver();
      final sources = await resolver.resolve(
        'https://example.com/stream.m3u8',
        serverHint: 'CDN 1',
      );
      expect(sources.isNotEmpty, isTrue);
      expect(sources.first.url, equals('https://example.com/stream.m3u8'));
      expect(sources.first.server, equals('CDN 1'));
    });
  });
}
