import 'dart:async';

import 'package:donghua_player/core/widgets/skeleton.dart';
import 'package:donghua_player/data/storage/storage_service.dart';
import 'package:donghua_player/domain/models/show.dart';
import 'package:donghua_player/features/library/library_controller.dart';
import 'package:donghua_player/features/search/search_controller.dart';
import 'package:donghua_player/features/search/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_stream_provider.dart';

Future<void> _pumpSearch(
  WidgetTester tester,
  FakeStreamProvider fake, {
  StorageService? storage,
}) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        streamProvider.overrideWithValue(fake),
        storageServiceProvider.overrideWithValue(storage ?? StorageService()),
      ],
      child: const MaterialApp(home: SearchScreen()),
    ),
  );
}

/// The skeleton animates for ever, so no pumpAndSettle here.
Future<void> _wait(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('shows a skeleton while loading, then the results', (
    tester,
  ) async {
    final answer = Completer<List<Show>>();
    final fake = FakeStreamProvider(onSearch: (_) => answer.future);
    await _pumpSearch(tester, fake);
    await _wait(tester);

    expect(find.text('DHMobile'), findsOneWidget);
    expect(find.text('DonghuaPlayer'), findsNothing);
    expect(find.byType(SkeletonPosterGrid), findsOneWidget);
    expect(find.byType(SkeletonBox), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    // The first load asks for the list without a query.
    expect(fake.searchQueries, ['']);

    answer.complete([
      fakeShow('a', title: 'Found A', episode: 'Ongoing'),
      fakeShow('b', title: 'Found B'),
    ]);
    await _wait(tester);

    expect(find.byType(SkeletonPosterGrid), findsNothing);
    expect(find.byType(SkeletonBox), findsNothing);
    expect(find.text('Found A'), findsOneWidget);
    expect(find.text('Found B'), findsOneWidget);
  });

  testWidgets('a new search shows the skeleton again', (tester) async {
    final answers = <Completer<List<Show>>>[];
    final fake = FakeStreamProvider(
      onSearch: (_) {
        final completer = Completer<List<Show>>();
        answers.add(completer);
        return completer.future;
      },
    );
    await _pumpSearch(tester, fake);
    await _wait(tester);
    answers[0].complete([fakeShow('a', title: 'First List')]);
    await _wait(tester);
    expect(find.text('First List'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'soul');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await _wait(tester);

    expect(fake.searchQueries, ['', 'soul']);
    expect(find.byType(SkeletonPosterGrid), findsOneWidget);
    expect(find.text('First List'), findsNothing);

    answers[1].complete([fakeShow('b', title: 'Soul Result')]);
    await _wait(tester);
    expect(find.text('Soul Result'), findsOneWidget);
    expect(find.byType(SkeletonPosterGrid), findsNothing);
  });

  testWidgets('an older answer that arrives late does not replace a newer '
      'one', (tester) async {
    final answers = <Completer<List<Show>>>[];
    final fake = FakeStreamProvider(
      onSearch: (_) {
        final completer = Completer<List<Show>>();
        answers.add(completer);
        return completer.future;
      },
    );
    await _pumpSearch(tester, fake);
    await _wait(tester);
    answers[0].complete([fakeShow('a', title: 'First List')]);
    await _wait(tester);

    await tester.enterText(find.byType(TextField), 'slow');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await _wait(tester);
    await tester.enterText(find.byType(TextField), 'fast');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await _wait(tester);
    expect(fake.searchQueries, ['', 'slow', 'fast']);

    answers[2].complete([fakeShow('f', title: 'Fast Result')]);
    await _wait(tester);
    answers[1].complete([fakeShow('s', title: 'Slow Result')]);
    await _wait(tester);

    expect(find.text('Fast Result'), findsOneWidget);
    expect(find.text('Slow Result'), findsNothing);
  });

  testWidgets('a failure shows a fixed text with Retry, not the raw error', (
    tester,
  ) async {
    var fail = true;
    final fake = FakeStreamProvider(
      onSearch: (_) async {
        if (fail) throw StateError('GET https://example.test/secret failed');
        return [fakeShow('a', title: 'After Retry')];
      },
    );
    await _pumpSearch(tester, fake);
    await _wait(tester);

    expect(
      find.text('Could not load. Check your connection and try again.'),
      findsOneWidget,
    );
    expect(find.textContaining('example.test'), findsNothing);
    expect(find.text('Retry'), findsOneWidget);

    fail = false;
    await tester.tap(find.text('Retry'));
    await _wait(tester);
    expect(find.text('After Retry'), findsOneWidget);
  });

  testWidgets('no result has its own text', (tester) async {
    final fake = FakeStreamProvider(onSearch: (_) async => const []);
    await _pumpSearch(tester, fake);
    await _wait(tester);

    expect(find.text('No donghua found. Try another title.'), findsOneWidget);
    expect(find.byType(SkeletonBox), findsNothing);
  });

  testWidgets('uses Khmer labels when the display language is Khmer', (
    tester,
  ) async {
    final storage = StorageService();
    await storage.setLanguageCode('km');
    final fake = FakeStreamProvider(onSearch: (_) async => const []);
    await _pumpSearch(tester, fake, storage: storage);
    await _wait(tester);

    expect(
      find.text('ស្វែងរក Donghua (ឧ. BTTH, Soul Land)...'),
      findsOneWidget,
    );
    expect(
      find.text('រកមិនឃើញ Donghua ទេ។ សូមសាកចំណងជើងផ្សេង។'),
      findsOneWidget,
    );
    expect(find.byTooltip('ផ្ទុកឡើងវិញ'), findsOneWidget);
    // The app name is not translated.
    expect(find.text('DHMobile'), findsOneWidget);
  });

  testWidgets('each result shows the name of its source', (tester) async {
    final fake = FakeStreamProvider(
      onSearch: (_) async => [
        Show(
          id: 'https://donghuaworld.com/anime/ri/',
          title: 'From DonghuaWorld',
          poster: '',
          providerId: 'donghuaworld',
        ),
        fakeShow('x', title: 'Unknown source'),
      ],
    );
    await _pumpSearch(tester, fake);
    await _wait(tester);

    expect(find.text('From DonghuaWorld'), findsOneWidget);
    expect(find.text('DonghuaWorld'), findsOneWidget);
    // A provider id that is no known source gets no badge.
    expect(find.text('Unknown source'), findsOneWidget);
    expect(find.text('fake'), findsNothing);
  });
}
