import 'package:donghua_player/data/storage/storage_service.dart';
import 'package:donghua_player/domain/models/player_engine.dart';
import 'package:donghua_player/features/library/library_controller.dart';
import 'package:donghua_player/features/settings/settings_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ProviderContainer _containerFor(StorageService storage) {
  final container = ProviderContainer(
    overrides: [storageServiceProvider.overrideWithValue(storage)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('PlayerEngine', () {
    test('VLC falls back to ExoPlayer, ExoPlayer to the next source', () {
      expect(PlayerEngine.vlc.fallbackEngine(), PlayerEngine.exo);
      expect(PlayerEngine.exo.fallbackEngine(), isNull);
    });

    test('codes round trip, and unknown codes give the default', () {
      for (final engine in PlayerEngine.values) {
        expect(PlayerEngine.fromCode(engine.code), engine);
      }
      expect(PlayerEngine.defaultEngine, PlayerEngine.exo);
      expect(PlayerEngine.fromCode(null), PlayerEngine.exo);
      expect(PlayerEngine.fromCode('mpv'), PlayerEngine.exo);
    });

    test('chain lists the engines a source is tried on', () {
      expect(PlayerEngine.vlc.chain, 'VLC (libVLC) → ExoPlayer');
      expect(PlayerEngine.exo.chain, 'ExoPlayer');
    });
  });

  group('player engine setting', () {
    // A StorageService that was never initialised keeps its values in
    // memory, so these tests need no Hive box.
    test('is ExoPlayer by default', () {
      final storage = StorageService();

      expect(storage.getPlayerEngineCode(), isNull);
      expect(
        _containerFor(storage).read(settingsProvider).playerEngine,
        PlayerEngine.exo,
      );
    });

    test('is stored and read again after a restart', () async {
      final storage = StorageService();
      final container = _containerFor(storage);

      await container
          .read(settingsProvider.notifier)
          .setPlayerEngine(PlayerEngine.vlc);

      expect(container.read(settingsProvider).playerEngine, PlayerEngine.vlc);
      expect(storage.getPlayerEngineCode(), 'vlc');
      expect(
        _containerFor(storage).read(settingsProvider).playerEngine,
        PlayerEngine.vlc,
      );
    });

    test('keeps the other settings when it changes', () async {
      final storage = StorageService();
      await storage.setDefaultQuality('1080p');
      final container = _containerFor(storage);

      await container
          .read(settingsProvider.notifier)
          .setPlayerEngine(PlayerEngine.vlc);

      expect(container.read(settingsProvider).defaultQuality, '1080p');
    });
  });
}
