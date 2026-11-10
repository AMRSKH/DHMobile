import 'package:donghua_player/domain/models/stream_source.dart';
import 'package:donghua_player/features/player/source_selection.dart';
import 'package:flutter_test/flutter_test.dart';

StreamSource _src(String? server, String quality) => StreamSource(
  url: 'https://example.com/video.mp4',
  server: server,
  quality: quality,
);

void main() {
  // Same shape as the resolver output: the server label carries the mirror
  // name and, for most hosts, the quality too.
  final mixed = [
    _src('Hardsub Indonesia Dailymotion 720p', '720p'),
    _src('Hardsub Indonesia Dailymotion 480p', '480p'),
    _src('Hardsub English OK.ru 1080p', '1080p'),
    _src('Hardsub English OK.ru 720p', '720p'),
    _src('Rumble 720p', '720p'),
  ];

  group('pickInitialSourceIndex', () {
    test('English and 720p picks the English source, not an earlier '
        'Indonesian one', () {
      expect(
        pickInitialSourceIndex(mixed, quality: '720p', subtitle: 'English'),
        3,
      );
    });

    test('Indonesian matches "Indonesia" in the server label', () {
      expect(
        pickInitialSourceIndex(mixed, quality: '720p', subtitle: 'Indonesian'),
        0,
      );
      expect(
        pickInitialSourceIndex(mixed, quality: '480p', subtitle: 'Indonesian'),
        1,
      );
    });

    test('None behaves like a quality-only choice', () {
      expect(
        pickInitialSourceIndex(mixed, quality: '720p', subtitle: 'None'),
        0,
      );
      expect(
        pickInitialSourceIndex(mixed, quality: '1080p', subtitle: 'None'),
        2,
      );
      expect(
        pickInitialSourceIndex(mixed, quality: '720p', subtitle: 'Klingon'),
        0,
      );
    });

    test('without a language match it uses a neutral source first', () {
      final sources = [
        _src('Hardsub Indonesia Dailymotion 720p', '720p'),
        _src('Rumble 720p', '720p'),
      ];
      expect(
        pickInitialSourceIndex(sources, quality: '720p', subtitle: 'English'),
        1,
      );
    });

    test('without a match or a neutral source it uses the other language', () {
      final sources = [
        _src('Hardsub Indonesia Dailymotion 480p', '480p'),
        _src('Hardsub Indonesia Dailymotion 720p', '720p'),
      ];
      expect(
        pickInitialSourceIndex(sources, quality: '720p', subtitle: 'English'),
        1,
      );
    });

    test('falls back to the nearest height', () {
      final sources = [
        _src('OK.ru 1080p', '1080p'),
        _src('OK.ru 480p', '480p'),
        _src('OK.ru 360p', '360p'),
      ];
      expect(
        pickInitialSourceIndex(sources, quality: '720p', subtitle: 'None'),
        1,
      );
    });

    test('a height tie picks the lower one', () {
      final sources = [
        _src('OK.ru 1080p', '1080p'),
        _src('OK.ru 360p', '360p'),
      ];
      expect(
        pickInitialSourceIndex(sources, quality: '720p', subtitle: 'None'),
        1,
      );
    });

    test('nearest height stays inside the language group', () {
      final sources = [
        _src('Hardsub Indonesia Dailymotion 720p', '720p'),
        _src('Hardsub English OK.ru 1080p', '1080p'),
        _src('Hardsub English OK.ru 480p', '480p'),
      ];
      expect(
        pickInitialSourceIndex(sources, quality: '720p', subtitle: 'English'),
        2,
      );
    });

    test('qualities without a height fall back to the first source', () {
      final sources = [
        _src('OK.ru HLS', 'Auto HLS'),
        _src('Dailymotion Fast', 'Multi-Bitrate (HLS)'),
      ];
      expect(
        pickInitialSourceIndex(sources, quality: '720p', subtitle: 'None'),
        0,
      );
    });

    test('Auto picks the first source of the language group', () {
      expect(
        pickInitialSourceIndex(mixed, quality: 'Auto', subtitle: 'English'),
        2,
      );
      expect(
        pickInitialSourceIndex(mixed, quality: 'auto', subtitle: 'None'),
        0,
      );
    });

    test('an empty list returns 0', () {
      expect(
        pickInitialSourceIndex(
          const <StreamSource>[],
          quality: '720p',
          subtitle: 'English',
        ),
        0,
      );
    });
  });

  group('pickFailoverSourceIndex', () {
    // The list of a real episode: 0..5 Indonesian, 6..11 English, each from
    // 144p to 1080p. English and 720p starts at index 10.
    const heights = ['144p', '240p', '360p', '480p', '720p', '1080p'];
    final okru = [
      for (final q in heights) _src('Hardsub Indonesia Ok.ru $q', q),
      for (final q in heights) _src('Hardsub English Ok.ru $q', q),
    ];

    int pick(Set<int> failed, {String subtitle = 'English'}) =>
        pickFailoverSourceIndex(
          okru,
          failed: failed,
          quality: '720p',
          subtitle: subtitle,
        );

    test('without a failure it is the initial choice', () {
      expect(okru, hasLength(12));
      expect(pick({}), 10);
      expect(
        pick({}),
        pickInitialSourceIndex(okru, quality: '720p', subtitle: 'English'),
      );
    });

    test('goes to the nearest quality of the same language first', () {
      // 480p is closer to 720p than 1080p is.
      expect(pick({10}), 9);
      // 360p and 1080p are equally far: the lower one wins.
      expect(pick({10, 9}), 8);
      expect(pick({10, 9, 8}), 11);
      expect(pick({10, 9, 8, 11}), 7);
      expect(pick({10, 9, 8, 11, 7}), 6);
    });

    test('never returns a failed index, also not the last one', () {
      expect(pick({11}), 10);
      expect(pick({10, 11}), 9);
    });

    test('falls to the other language when the group is exhausted', () {
      expect(pick({6, 7, 8, 9, 10, 11}), 4);
      expect(pick({6, 7, 8, 9, 10, 11, 4}), 3);
    });

    test('tries every source once, the preferred language first', () {
      final failed = <int>{};
      final order = <int>[];
      for (var next = pick(failed); next >= 0; next = pick(failed)) {
        // A pick that returns a failed index would loop forever.
        expect(failed.add(next), isTrue, reason: 'index $next picked twice');
        order.add(next);
      }
      expect(order, [10, 9, 8, 11, 7, 6, 4, 3, 2, 5, 1, 0]);
    });

    test('the Indonesian setting mirrors it', () {
      expect(pick({}, subtitle: 'Indonesian'), 4);
      expect(pick({4}, subtitle: 'Indonesian'), 3);
      expect(pick({0, 1, 2, 3, 4, 5}, subtitle: 'Indonesian'), 10);
    });

    test('without a language it stays on the quality', () {
      expect(pick({}, subtitle: 'None'), 4);
      expect(pick({4}, subtitle: 'None'), 10);
    });

    test('returns -1 when every source failed', () {
      expect(pick({for (var i = 0; i < okru.length; i++) i}), -1);
    });

    test('ignores failed indexes outside the list', () {
      expect(pick({-1, 12, 99}), 10);
    });

    test('an empty list returns -1', () {
      expect(
        pickFailoverSourceIndex(
          const <StreamSource>[],
          failed: const <int>{},
          quality: '720p',
          subtitle: 'English',
        ),
        -1,
      );
      expect(
        pickFailoverSourceIndex(
          const <StreamSource>[],
          failed: {0},
          quality: '720p',
          subtitle: 'English',
        ),
        -1,
      );
    });
  });

  group('carriedResumeMs', () {
    test('keeps a position past the first 3 s', () {
      expect(carriedResumeMs(positionMs: 5000, pendingMs: 0), 5000);
      expect(carriedResumeMs(positionMs: 3001, pendingMs: 0), 3001);
    });

    test('ignores a position inside the first 3 s', () {
      expect(carriedResumeMs(positionMs: 3000, pendingMs: 0), 0);
      expect(carriedResumeMs(positionMs: 0, pendingMs: 0), 0);
      expect(carriedResumeMs(positionMs: 2000, pendingMs: 1000), 1000);
    });

    test('a larger resume point that was not applied yet wins', () {
      expect(carriedResumeMs(positionMs: 5000, pendingMs: 90000), 90000);
      expect(carriedResumeMs(positionMs: 0, pendingMs: 90000), 90000);
      expect(carriedResumeMs(positionMs: 90000, pendingMs: 90000), 90000);
    });

    test('the position wins over a smaller resume point', () {
      expect(carriedResumeMs(positionMs: 90000, pendingMs: 5000), 90000);
    });
  });

  group('stickySourceIndex', () {
    test('finds the same server and quality, ignoring case', () {
      expect(
        stickySourceIndex(mixed, _src('hardsub english ok.ru 720P', '720P')),
        3,
      );
    });

    test('returns -1 when the source is missing', () {
      expect(
        stickySourceIndex(mixed, _src('Hardsub English 360p', '360p')),
        -1,
      );
      // Same server label with another quality is not the same source.
      expect(
        stickySourceIndex(mixed, _src('Hardsub English OK.ru 720p', '480p')),
        -1,
      );
    });

    test('returns -1 without a previous source', () {
      expect(stickySourceIndex(mixed, null), -1);
    });
  });

  group('sourceLabel', () {
    test('does not print the quality twice', () {
      expect(
        sourceLabel(_src('Hardsub English OK.ru 720p', '720p'), 0),
        'Hardsub English OK.ru 720p',
      );
      expect(
        sourceLabel(_src('Hardsub English OK.ru 144P', '144p'), 0),
        'Hardsub English OK.ru 144P',
      );
    });

    test('adds the quality when the server label lacks it', () {
      expect(
        sourceLabel(_src('Dailymotion Fast', 'Multi-Bitrate (HLS)'), 0),
        'Dailymotion Fast (Multi-Bitrate (HLS))',
      );
    });

    test('names a source without a server by its position', () {
      expect(sourceLabel(_src(null, '480p'), 2), 'Server 3 (480p)');
    });
  });

  group('isNearEnd', () {
    const minute = Duration(minutes: 1);

    test('the last 5 s count as the end', () {
      expect(isNearEnd(position: minute, duration: minute), isTrue);
      expect(
        isNearEnd(position: const Duration(seconds: 55), duration: minute),
        isTrue,
      );
    });

    test('an end in the middle is not the end', () {
      expect(
        isNearEnd(position: const Duration(seconds: 30), duration: minute),
        isFalse,
      );
    });

    test('an unknown length is never the end', () {
      expect(isNearEnd(position: minute, duration: Duration.zero), isFalse);
    });
  });

  group('canAutoReresolve', () {
    test('allows one fresh resolution, then the error shows', () {
      expect(kAutoReresolveLimit, 1);
      expect(canAutoReresolve(0), isTrue);
      expect(canAutoReresolve(1), isFalse);
      expect(canAutoReresolve(2), isFalse);
    });
  });

  group('hasRealProgress', () {
    const start = Duration(minutes: 4);

    test('10 s past the start counts as real playback', () {
      expect(
        hasRealProgress(from: start, now: start + const Duration(seconds: 10)),
        isTrue,
      );
    });

    test('a load that reports playing and dies at once does not', () {
      expect(hasRealProgress(from: start, now: start), isFalse);
      expect(
        hasRealProgress(from: start, now: start + const Duration(seconds: 9)),
        isFalse,
      );
    });

    test('a position before the start does not count', () {
      expect(hasRealProgress(from: start, now: Duration.zero), isFalse);
    });
  });
}
