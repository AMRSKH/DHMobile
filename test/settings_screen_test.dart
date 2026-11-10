import 'package:donghua_player/data/storage/cache_service.dart';
import 'package:donghua_player/data/storage/storage_service.dart';
import 'package:donghua_player/features/library/library_controller.dart';
import 'package:donghua_player/features/settings/settings_controller.dart';
import 'package:donghua_player/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<StorageService> _pumpSettings(
  WidgetTester tester, {
  CacheService? cache,
}) async {
  // Tall enough to build every row of the list at once.
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final storage = StorageService();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
        // Never the real temp folder of the test machine.
        cacheServiceProvider.overrideWithValue(cache ?? _FixedCache(0)),
      ],
      child: const MaterialApp(home: SettingsScreen()),
    ),
  );
  // Let the cache size arrive.
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pump();
  return storage;
}

/// A cache that reports [bytes] and records clear() calls.
class _FixedCache extends CacheService {
  int bytes;
  int clears = 0;

  _FixedCache(this.bytes);

  @override
  Future<int> sizeBytes() async => bytes;

  @override
  Future<void> clear() async {
    clears++;
    bytes = 0;
  }
}

void main() {
  testWidgets('Display Language offers KH and EN and switches the text', (
    tester,
  ) async {
    final storage = await _pumpSettings(tester);

    expect(find.text('GENERAL'), findsOneWidget);
    expect(find.text('Display Language'), findsOneWidget);
    expect(find.text('EN - English'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('Display Language'));
    await tester.pumpAndSettle();

    expect(find.text('Choose Display Language'), findsOneWidget);
    expect(find.text('KH - ភាសាខ្មែរ'), findsOneWidget);
    // Once as the current value in the list, once as an option.
    expect(find.text('EN - English'), findsNWidgets(2));

    await tester.tap(find.text('KH - ភាសាខ្មែរ'));
    await tester.pumpAndSettle();

    expect(storage.getLanguageCode(), 'km');
    expect(find.text('ភាសាបង្ហាញ'), findsOneWidget);
    expect(find.text('ការកំណត់'), findsOneWidget);
    expect(find.text('ទូទៅ'), findsOneWidget);
    expect(find.text('អំពីកម្មវិធី'), findsOneWidget);
    expect(find.text('KH - ភាសាខ្មែរ'), findsOneWidget);
    expect(find.text('Display Language'), findsNothing);
    expect(find.text('Settings'), findsNothing);

    // And back to English.
    await tester.tap(find.text('ភាសាបង្ហាញ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('EN - English'));
    await tester.pumpAndSettle();

    expect(storage.getLanguageCode(), 'en');
    expect(find.text('Display Language'), findsOneWidget);
  });

  testWidgets('dismissing the language dialog changes nothing', (tester) async {
    final storage = await _pumpSettings(tester);

    await tester.tap(find.text('Display Language'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(storage.getLanguageCode(), 'en');
    expect(find.text('Display Language'), findsOneWidget);
  });

  testWidgets('About follows the owner layout', (tester) async {
    await _pumpSettings(tester);

    expect(find.text('ABOUT'), findsOneWidget);
    expect(find.text('DHMobile'), findsOneWidget);
    expect(find.text('Version 1.0.8'), findsOneWidget);
    expect(find.textContaining('build'), findsNothing);
    expect(find.text('Credits'), findsOneWidget);
    expect(
      find.text('Player | ExoPlayer, VLC\nContents | DonghuaCLI'),
      findsOneWidget,
    );
    expect(find.text('Development'), findsOneWidget);
    expect(find.text('AMSCenter by AMSDev'), findsOneWidget);
    expect(find.text('Privacy'), findsOneWidget);
    expect(
      find.text(
        'No ads.\nNo tracking.\nHistory and favorites\n'
        'are stored only on this device.',
      ),
      findsOneWidget,
    );
    // The old rows are gone.
    expect(find.text('Content source'), findsNothing);
    expect(find.text('Player'), findsNothing);

    expect(find.text('video_player (ExoPlayer)'), findsNothing);
    expect(find.textContaining('(Release)'), findsNothing);
    expect(find.textContaining('100% offline'), findsNothing);
    expect(find.text('DonghuaPlayer'), findsNothing);
  });

  testWidgets('quality and subtitle keep their stored keys in Khmer', (
    tester,
  ) async {
    final storage = await _pumpSettings(tester);

    await tester.tap(find.text('Display Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('KH - ភាសាខ្មែរ'));
    await tester.pumpAndSettle();

    // The stored subtitle value 'English' is shown with its Khmer label.
    expect(storage.getPreferredSubtitle(), 'English');
    expect(find.text('អង់គ្លេស'), findsOneWidget);

    await tester.tap(find.text('ភាសាអក្សររត់'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ឥណ្ឌូនេស៊ី'));
    await tester.pumpAndSettle();
    expect(storage.getPreferredSubtitle(), 'Indonesian');

    await tester.tap(find.text('គុណភាពវីដេអូលំនាំដើម'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ស្វ័យប្រវត្តិ'));
    await tester.pumpAndSettle();
    expect(storage.getDefaultQuality(), 'Auto');
  });

  testWidgets('Video Player switches between VLC and ExoPlayer', (
    tester,
  ) async {
    final storage = await _pumpSettings(tester);

    expect(find.text('Video Player'), findsOneWidget);
    // ExoPlayer by default.
    expect(find.text('ExoPlayer'), findsOneWidget);
    expect(find.text('VLC (libVLC)'), findsNothing);

    await tester.tap(find.text('Video Player'));
    await tester.pumpAndSettle();
    expect(find.text('Choose Video Player'), findsOneWidget);
    await tester.tap(find.text('VLC (libVLC)'));
    await tester.pumpAndSettle();

    expect(storage.getPlayerEngineCode(), 'vlc');
    expect(find.text('VLC (libVLC)'), findsOneWidget);
  });

  testWidgets('Clear Cache shows the size against 500 MB and clears', (
    tester,
  ) async {
    final cache = _FixedCache(450 * 1024 * 1024);
    await _pumpSettings(tester, cache: cache);

    expect(find.text('450 MB of 500 MB'), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, closeTo(0.9, 0.001));
    // 90 % is near the limit: the bar is red.
    expect(bar.color, isNot(Colors.blueAccent));

    await tester.tap(find.text('Clear Cache'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    await tester.pump();

    expect(cache.clears, 1);
    expect(find.text('0 B of 500 MB'), findsOneWidget);
  });
}
