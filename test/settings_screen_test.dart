import 'package:donghua_player/data/storage/storage_service.dart';
import 'package:donghua_player/features/library/library_controller.dart';
import 'package:donghua_player/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<StorageService> _pumpSettings(WidgetTester tester) async {
  // Tall enough to build every row of the list at once.
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final storage = StorageService();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [storageServiceProvider.overrideWithValue(storage)],
      child: const MaterialApp(home: SettingsScreen()),
    ),
  );
  return storage;
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

  testWidgets('About shows the app name, version, player, and source', (
    tester,
  ) async {
    await _pumpSettings(tester);

    expect(find.text('ABOUT'), findsOneWidget);
    expect(find.text('DHMobile'), findsOneWidget);
    expect(find.text('Version 1.0.7 (build 8)'), findsOneWidget);
    expect(find.text('Player'), findsOneWidget);
    expect(find.text('VLC (libVLC) → ExoPlayer'), findsOneWidget);
    expect(find.text('Content source'), findsOneWidget);
    expect(
      find.text(
        'AnimeXin, DonghuaWorld, LuciferDonghua, DonghuaStream, LMAnime',
      ),
      findsOneWidget,
    );
    expect(find.text('Credits'), findsOneWidget);
    expect(
      find.text(
        'No ads. No tracking. History and favorites are stored only on this '
        'device.',
      ),
      findsOneWidget,
    );

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
    // The tile shows the engine, About shows the chain behind it.
    expect(find.text('VLC (libVLC)'), findsOneWidget);
    expect(find.text('VLC (libVLC) → ExoPlayer'), findsOneWidget);

    await tester.tap(find.text('Video Player'));
    await tester.pumpAndSettle();
    expect(find.text('Choose Video Player'), findsOneWidget);
    await tester.tap(find.text('ExoPlayer'));
    await tester.pumpAndSettle();

    expect(storage.getPlayerEngineCode(), 'exo');
    // Tile and About now both read "ExoPlayer".
    expect(find.text('ExoPlayer'), findsNWidgets(2));
    expect(find.text('VLC (libVLC) → ExoPlayer'), findsNothing);
  });
}
