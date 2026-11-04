import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:donghua_player/domain/models/episode.dart';
import 'package:donghua_player/domain/models/show.dart';
import 'package:donghua_player/features/library/library_controller.dart';

void main() {
  test('history notifier refreshes after saving progress', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const show = Show(
      id: 'show-1',
      title: 'Test Show',
      poster: '',
      providerId: 'test',
    );
    const episode = Episode(
      id: 'ep-1',
      number: 1.0,
      title: 'Episode 1',
      showId: 'show-1',
    );

    expect(container.read(historyProvider), isEmpty);

    await container
        .read(historyProvider.notifier)
        .saveProgress(
          show: show,
          episode: episode,
          positionMs: 1000,
          durationMs: 10000,
        );

    final history = container.read(historyProvider);
    expect(history, hasLength(1));
    expect(history.first.episode.id, 'ep-1');
    expect(history.first.positionMs, 1000);
  });
}
