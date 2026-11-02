import 'package:flutter_test/flutter_test.dart';
import 'package:donghua_player/domain/models/show.dart';
import 'package:donghua_player/domain/models/episode.dart';
import 'package:donghua_player/domain/models/stream_source.dart';
import 'package:donghua_player/data/providers/animexin_stream_provider.dart';
import 'package:donghua_player/data/providers/stream_resolver.dart';

void main() {
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

    test('AnimeXinStreamProvider fallback catalog returns shows', () async {
      final provider = AnimeXinStreamProvider();
      final results = await provider.search('');
      expect(results.isNotEmpty, isTrue);
      expect(results.first.title, contains('Battle Through the Heavens'));
    });

    test('StreamResolver direct m3u8 or mp4 handling', () async {
      final resolver = StreamResolver();
      final sources = await resolver.resolve('https://example.com/stream.m3u8', serverHint: 'CDN 1');
      expect(sources.isNotEmpty, isTrue);
      expect(sources.first.url, equals('https://example.com/stream.m3u8'));
      expect(sources.first.server, equals('CDN 1'));
    });
  });
}
