import 'dart:async';

import 'package:donghua_player/core/widgets/skeleton.dart';
import 'package:donghua_player/data/storage/storage_service.dart';
import 'package:donghua_player/domain/models/episode.dart';
import 'package:donghua_player/features/detail/detail_screen.dart';
import 'package:donghua_player/features/library/library_controller.dart';
import 'package:donghua_player/features/search/search_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_stream_provider.dart';

final _show = fakeShow('detail', title: 'Detail Show', episode: 'EP 12');

Future<void> _pumpDetail(
  WidgetTester tester,
  FakeStreamProvider fake, {
  StorageService? storage,
}) async {
  tester.view.physicalSize = const Size(400, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      // The provider would try a failed load again by itself, which only
      // leaves timers behind in a test.
      retry: (_, _) => null,
      overrides: [
        streamProvider.overrideWithValue(fake),
        storageServiceProvider.overrideWithValue(storage ?? StorageService()),
      ],
      child: MaterialApp(home: DetailScreen(show: _show)),
    ),
  );
}

/// The skeleton animates for ever, so no pumpAndSettle here.
Future<void> _wait(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('shows the episode skeleton while loading, then the episodes', (
    tester,
  ) async {
    final answer = Completer<List<Episode>>();
    final fake = FakeStreamProvider(onEpisodes: (_) => answer.future);
    await _pumpDetail(tester, fake);
    await _wait(tester);

    expect(find.text('Detail Show'), findsOneWidget);
    expect(find.text('EP 12'), findsOneWidget);
    expect(find.text('Episodes'), findsOneWidget);
    expect(find.byType(SliverSkeletonEpisodes), findsOneWidget);
    // The grid layout is the default: twelve cells.
    expect(find.byType(SkeletonBox), findsNWidgets(12));
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // The skeleton follows the layout switch.
    await tester.tap(find.byTooltip('Switch to List'));
    await _wait(tester);
    expect(find.byType(SkeletonBox), findsNWidgets(6));
    await tester.tap(find.byTooltip('Switch to Grid'));
    await _wait(tester);
    expect(find.byType(SkeletonBox), findsNWidgets(12));

    answer.complete(fakeEpisodes(_show.id, 3));
    await _wait(tester);

    expect(find.byType(SliverSkeletonEpisodes), findsNothing);
    expect(find.byType(SkeletonBox), findsNothing);
    expect(find.text('Episodes (3)'), findsOneWidget);
    expect(find.text('EP 1'), findsOneWidget);
    expect(find.text('EP 3'), findsOneWidget);
    expect(find.text('Watch Now • Episode 1'), findsOneWidget);
    expect(fake.episodeRequests, [_show.id]);
  });

  testWidgets('a show without episodes says so', (tester) async {
    final fake = FakeStreamProvider(onEpisodes: (_) async => const []);
    await _pumpDetail(tester, fake);
    await _wait(tester);

    expect(find.text('No episodes available.'), findsOneWidget);
    expect(find.text('Episodes (0)'), findsOneWidget);
    expect(find.byType(SkeletonBox), findsNothing);
    expect(find.textContaining('Watch Now'), findsNothing);
  });

  testWidgets('a failed load shows a fixed text with Retry', (tester) async {
    var fail = true;
    final fake = FakeStreamProvider(
      onEpisodes: (showId) async {
        if (fail) throw StateError('GET https://example.test/secret failed');
        return fakeEpisodes(showId, 2);
      },
    );
    await _pumpDetail(tester, fake);
    await _wait(tester);

    expect(find.text('Could not load the episodes.'), findsOneWidget);
    expect(find.textContaining('example.test'), findsNothing);
    expect(find.text('Retry'), findsOneWidget);

    fail = false;
    await tester.tap(find.text('Retry'));
    await _wait(tester);

    expect(find.text('Episodes (2)'), findsOneWidget);
    expect(find.text('Could not load the episodes.'), findsNothing);
  });

  testWidgets('uses Khmer labels, and leaves the source text alone', (
    tester,
  ) async {
    final storage = StorageService();
    await storage.setLanguageCode('km');
    final fake = FakeStreamProvider();
    await _pumpDetail(tester, fake, storage: storage);
    await _wait(tester);

    expect(find.text('បញ្ជីភាគ (3)'), findsOneWidget);
    expect(find.text('ភាគ 1'), findsOneWidget);
    expect(find.text('ភាគ 3'), findsOneWidget);
    expect(find.text('មើលឥឡូវនេះ • Episode 1'), findsOneWidget);
    expect(find.byTooltip('បន្ថែមទៅចំណូលចិត្ត'), findsOneWidget);
    // From the source: the title and the stored episode badge.
    expect(find.text('Detail Show'), findsOneWidget);
    expect(find.text('EP 12'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
