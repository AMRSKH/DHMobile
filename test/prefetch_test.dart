import 'package:donghua_player/domain/models/stream_source.dart';
import 'package:donghua_player/features/player/prefetch.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const episode = Duration(minutes: 20);

  test('prefetches after 60 % of the episode', () {
    expect(
      shouldPrefetchNext(
        position: const Duration(minutes: 11),
        duration: episode,
      ),
      isFalse,
    );
    expect(
      shouldPrefetchNext(
        position: const Duration(minutes: 12),
        duration: episode,
      ),
      isTrue,
    );
  });

  test('prefetches in the last 3 minutes of a short episode', () {
    // 60 % of 5 minutes is 3:00, but 3 minutes are left already at 2:00.
    const short = Duration(minutes: 5);
    expect(
      shouldPrefetchNext(
        position: const Duration(minutes: 1, seconds: 59),
        duration: short,
      ),
      isFalse,
    );
    expect(
      shouldPrefetchNext(position: const Duration(minutes: 2), duration: short),
      isTrue,
    );
  });

  test('never before playback has a position and a length', () {
    expect(
      shouldPrefetchNext(position: Duration.zero, duration: episode),
      isFalse,
    );
    expect(
      shouldPrefetchNext(
        position: const Duration(minutes: 5),
        duration: Duration.zero,
      ),
      isFalse,
    );
  });

  group('usePrefetched', () {
    final at = DateTime(2026, 11, 10, 20);
    const one = [StreamSource(url: 'https://x.test/a.mp4')];

    test('uses a fresh list with servers', () {
      expect(
        usePrefetched(
          sources: one,
          fetchedAt: at,
          now: at.add(const Duration(minutes: 20)),
        ),
        isTrue,
      );
    });

    test('resolves again for an empty, missing, or old list', () {
      expect(usePrefetched(sources: const [], fetchedAt: at, now: at), isFalse);
      expect(usePrefetched(sources: null, fetchedAt: at, now: at), isFalse);
      expect(
        usePrefetched(
          sources: one,
          fetchedAt: at,
          now: at.add(const Duration(minutes: 21)),
        ),
        isFalse,
      );
    });
  });
}
