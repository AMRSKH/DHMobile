import 'dart:async';

import 'package:donghua_player/core/l10n/app_strings.dart';
import 'package:donghua_player/core/widgets/skeleton.dart';
import 'package:donghua_player/core/widgets/underline_tab_bar.dart';
import 'package:donghua_player/data/storage/storage_service.dart';
import 'package:donghua_player/domain/models/schedule_entry.dart';
import 'package:donghua_player/domain/models/show.dart';
import 'package:donghua_player/features/detail/detail_screen.dart';
import 'package:donghua_player/features/explore/explore_controller.dart';
import 'package:donghua_player/features/explore/explore_screen.dart';
import 'package:donghua_player/features/library/library_controller.dart';
import 'package:donghua_player/features/search/search_controller.dart';
import 'package:donghua_player/features/search/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_stream_provider.dart';

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

Future<void> _pumpExplore(
  WidgetTester tester,
  FakeStreamProvider fake, {
  StorageService? storage,
  double width = 600,
}) async {
  // Wide enough for the whole day row in the test font, whose letters are
  // much wider than those of a real font.
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        streamProvider.overrideWithValue(fake),
        storageServiceProvider.overrideWithValue(storage ?? StorageService()),
      ],
      child: const MaterialApp(home: ExploreScreen()),
    ),
  );
}

/// Skeletons animate for ever, so the tests pump a fixed time and never
/// pumpAndSettle while one can be on screen.
Future<void> _wait(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Whether the category tab with [label] is the selected one, read from the
/// semantics flag of the tab.
bool _tabSelected(WidgetTester tester, String label) {
  final tab = find.ancestor(
    of: find.descendant(
      of: find.byType(UnderlineTabBar),
      matching: find.text(label),
    ),
    matching: find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.button == true,
    ),
  );
  return tester.widget<Semantics>(tab).properties.selected ?? false;
}

void main() {
  group('scheduleCaption', () {
    const en = AppStrings(AppLanguage.en);
    const km = AppStrings(AppLanguage.km);

    test('a released episode shows the episode and "Released"', () {
      final entry = ScheduleEntry(
        show: fakeShow('a', episode: 'EP 564'),
        released: true,
        releaseText: 'released',
      );
      expect(scheduleCaption(entry, en), 'EP 564 · Released');
      expect(scheduleCaption(entry, km), 'EP 564 · ចេញហើយ');
    });

    test('an upcoming episode shows the local time of releaseAt', () {
      final releaseAt = DateTime.utc(2026, 11, 12, 6, 15);
      final local = releaseAt.toLocal();
      final expected =
          '${local.hour.toString().padLeft(2, '0')}:'
          '${local.minute.toString().padLeft(2, '0')}';
      final entry = ScheduleEntry(
        show: fakeShow('a', episode: 'EP 47'),
        releaseAt: releaseAt,
        releaseText: 'at 06:15',
      );
      expect(scheduleCaption(entry, en), 'EP 47 · $expected');
      // The raw text of the source is UTC and is not shown next to it.
      expect(scheduleCaption(entry, en).contains('at '), isFalse);
    });

    test('without a release date the text of the source is shown', () {
      final entry = ScheduleEntry(show: fakeShow('a'), releaseText: 'at 12:02');
      expect(scheduleCaption(entry, en), 'at 12:02');
    });

    test('missing parts are left out', () {
      expect(
        scheduleCaption(
          ScheduleEntry(show: fakeShow('a', episode: 'EP 3')),
          en,
        ),
        'EP 3',
      );
      expect(scheduleCaption(ScheduleEntry(show: fakeShow('a')), en), '');
    });
  });

  testWidgets('shows a skeleton while the schedule loads, then the shows', (
    tester,
  ) async {
    final answer = Completer<Map<int, List<ScheduleEntry>>>();
    final fake = FakeStreamProvider(onSchedule: () => answer.future);
    await _pumpExplore(tester, fake);
    await _wait(tester);

    expect(find.byType(SkeletonPosterGrid), findsOneWidget);
    expect(find.byType(SkeletonBox), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    answer.complete(fakeWeekOnePerDay());
    await _wait(tester);

    expect(find.byType(SkeletonPosterGrid), findsNothing);
    expect(find.byType(SkeletonBox), findsNothing);
    expect(find.text('Day ${DateTime.now().weekday} Show'), findsOneWidget);
  });

  testWidgets('starts on Schedule and today, and a day tap needs no reload', (
    tester,
  ) async {
    final fake = FakeStreamProvider();
    await _pumpExplore(tester, fake);
    await _wait(tester);

    expect(find.text('Explore'), findsOneWidget);
    expect(_tabSelected(tester, 'Schedule'), isTrue);
    expect(_tabSelected(tester, 'New Series'), isFalse);
    expect(_tabSelected(tester, 'Popular'), isFalse);
    for (final label in _weekdays) {
      expect(find.text(label), findsOneWidget);
    }

    final today = DateTime.now().weekday;
    expect(find.text('Day $today Show'), findsOneWidget);
    expect(find.text('EP $today · Released'), findsOneWidget);

    expect(_tabSelected(tester, _weekdays[today - 1]), isTrue);

    for (var day = 1; day <= 7; day++) {
      await tester.tap(find.text(_weekdays[day - 1]));
      await _wait(tester);
      for (var other = 1; other <= 7; other++) {
        expect(
          _tabSelected(tester, _weekdays[other - 1]),
          other == day,
          reason: 'after a tap on ${_weekdays[day - 1]}',
        );
      }
      expect(find.text('Day $day Show'), findsOneWidget);
      expect(
        find.textContaining('Day '),
        findsOneWidget,
        reason: 'only the shows of the selected day are listed',
      );
    }

    expect(fake.scheduleCalls, 1);
    expect(fake.newSeriesCalls, 0);
    expect(fake.popularCalls, 0);
  });

  testWidgets('the day row is an underline tab bar without separators', (
    tester,
  ) async {
    final fake = FakeStreamProvider();
    await _pumpExplore(tester, fake);
    await _wait(tester);

    // The category row and the day row.
    expect(find.byType(UnderlineTabBar), findsNWidgets(2));
    final dayRow = find.ancestor(
      of: find.text('Mon'),
      matching: find.byType(UnderlineTabBar),
    );
    expect(dayRow, findsOneWidget);
    for (final label in _weekdays) {
      expect(
        find.descendant(of: dayRow, matching: find.text(label)),
        findsOneWidget,
      );
    }
    expect(find.text('|'), findsNothing);
    expect(find.textContaining('|'), findsNothing);
    expect(
      find.descendant(of: dayRow, matching: find.byType(InkWell)),
      findsNothing,
    );
    // Only the selected day has the red line in the day row.
    expect(
      find.descendant(
        of: dayRow,
        matching: find.byKey(UnderlineTabBar.indicatorKey),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the selected day is in view in a narrow Khmer day row, at '
      'start and after a change', (tester) async {
    final storage = StorageService();
    await storage.setLanguageCode('km');
    final container = ProviderContainer(
      overrides: [
        streamProvider.overrideWithValue(FakeStreamProvider()),
        storageServiceProvider.overrideWithValue(storage),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(exploreControllerProvider.notifier);
    // Sunday, the far end of the row, whatever day the test runs on.
    controller.selectWeekday(7);

    // Narrower than the seven Khmer labels in the test font.
    tester.view.physicalSize = const Size(320, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ExploreScreen()),
      ),
    );
    await _wait(tester);
    expect(tester.takeException(), isNull);

    const khmerDays = [
      'ច័ន្ទ',
      'អង្គារ',
      'ពុធ',
      'ព្រហ',
      'សុក្រ',
      'សៅរ៍',
      'អាទិត្យ',
    ];
    final dayRow = find.ancestor(
      of: find.text(khmerDays.first),
      matching: find.byType(UnderlineTabBar),
    );
    final row = tester.getRect(dayRow);
    final scrollable = tester.state<ScrollableState>(
      find.descendant(of: dayRow, matching: find.byType(Scrollable)),
    );
    expect(scrollable.position.maxScrollExtent, greaterThan(0));

    bool inView(String label) {
      final tab = tester.getRect(find.text(label));
      return tab.left >= row.left && tab.right <= row.right;
    }

    // At start: Sunday is selected and in view, Monday is off screen.
    expect(_tabSelected(tester, khmerDays[6]), isTrue);
    expect(inView(khmerDays[6]), isTrue);
    expect(inView(khmerDays[0]), isFalse);

    // A change without a scroll by hand: the row brings Monday in.
    controller.selectWeekday(1);
    await tester.pump();
    await _wait(tester);
    expect(_tabSelected(tester, khmerDays[0]), isTrue);
    expect(inView(khmerDays[0]), isTrue);
    expect(inView(khmerDays[6]), isFalse);
    expect(find.text('Day 1 Show'), findsOneWidget);

    // And back to Sunday.
    controller.selectWeekday(7);
    await tester.pump();
    await _wait(tester);
    expect(_tabSelected(tester, khmerDays[6]), isTrue);
    expect(inView(khmerDays[6]), isTrue);
    expect(find.text('Day 7 Show'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lists every show of the day', (tester) async {
    final today = DateTime.now().weekday;
    final fake = FakeStreamProvider(
      onSchedule: () async => fakeWeek({
        today: [
          for (var n = 1; n <= 14; n++)
            ScheduleEntry(show: fakeShow('s$n', title: 'Title $n')),
        ],
      }),
    );
    await _pumpExplore(tester, fake);
    await _wait(tester);

    final grid = tester.widget<GridView>(find.byType(GridView));
    expect(grid.childrenDelegate.estimatedChildCount, 14);

    expect(find.text('Title 1'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Title 14'),
      300,
      scrollable: find.descendant(
        of: find.byType(GridView),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Title 14'), findsOneWidget);
  });

  testWidgets('New Series and Popular load on the first tap and hide the '
      'day row', (tester) async {
    final fake = FakeStreamProvider();
    await _pumpExplore(tester, fake);
    await _wait(tester);

    await tester.tap(find.text('New Series'));
    await _wait(tester);

    expect(_tabSelected(tester, 'New Series'), isTrue);
    expect(_tabSelected(tester, 'Schedule'), isFalse);
    expect(find.text('Mon'), findsNothing);
    expect(find.text('New One'), findsOneWidget);
    expect(find.text('New Two'), findsOneWidget);
    // The status of the source is the caption.
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('Ongoing'), findsOneWidget);
    expect(fake.newSeriesCalls, 1);
    expect(fake.popularCalls, 0);

    await tester.tap(find.text('Popular'));
    await _wait(tester);

    expect(_tabSelected(tester, 'Popular'), isTrue);
    expect(find.text('Popular One'), findsOneWidget);
    // The status line of the card; "Completed" is also a tab label now.
    expect(
      find.descendant(
        of: find.byType(GridView),
        matching: find.text('Completed'),
      ),
      findsOneWidget,
    );
    expect(find.text('New One'), findsNothing);
    expect(fake.popularCalls, 1);

    await tester.tap(find.text('Schedule'));
    await _wait(tester);

    expect(find.text('Mon'), findsOneWidget);
    expect(find.text('Day ${DateTime.now().weekday} Show'), findsOneWidget);
    expect(fake.scheduleCalls, 1);
    expect(fake.newSeriesCalls, 1);
  });

  testWidgets('a category shows its own skeleton while it loads', (
    tester,
  ) async {
    final answer = Completer<void>();
    final fake = FakeStreamProvider(
      onPopular: () async {
        await answer.future;
        return [fakeShow('pop', title: 'Late Popular')];
      },
    );
    await _pumpExplore(tester, fake);
    await _wait(tester);

    await tester.tap(find.text('Popular'));
    await _wait(tester);
    expect(find.byType(SkeletonPosterGrid), findsOneWidget);

    answer.complete();
    await _wait(tester);
    expect(find.byType(SkeletonPosterGrid), findsNothing);
    expect(find.text('Late Popular'), findsOneWidget);
  });

  testWidgets('a failure shows a fixed text with Retry, not the raw error', (
    tester,
  ) async {
    var fail = true;
    final fake = FakeStreamProvider(
      onSchedule: () async {
        if (fail) throw StateError('GET https://example.test/secret failed');
        return fakeWeekOnePerDay();
      },
    );
    await _pumpExplore(tester, fake);
    await _wait(tester);

    expect(
      find.text('Could not load. Check your connection and try again.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
    expect(find.textContaining('example.test'), findsNothing);
    expect(find.textContaining('StateError'), findsNothing);
    // The category row stays usable.
    expect(find.text('New Series'), findsOneWidget);

    fail = false;
    await tester.tap(find.text('Retry'));
    await _wait(tester);

    expect(find.text('Retry'), findsNothing);
    expect(find.text('Day ${DateTime.now().weekday} Show'), findsOneWidget);
    expect(fake.scheduleCalls, 2);
  });

  testWidgets('an empty day has its own text', (tester) async {
    final today = DateTime.now().weekday;
    final other = today == 1 ? 2 : 1;
    final fake = FakeStreamProvider(
      onSchedule: () async => fakeWeek({
        other: [ScheduleEntry(show: fakeShow('x', title: 'Other Day'))],
      }),
    );
    await _pumpExplore(tester, fake);
    await _wait(tester);

    expect(find.text('No shows are scheduled for this day.'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);

    await tester.tap(find.text(_weekdays[other - 1]));
    await _wait(tester);
    expect(find.text('Other Day'), findsOneWidget);
    expect(find.text('No shows are scheduled for this day.'), findsNothing);
  });

  testWidgets('Refresh fetches the current category again', (tester) async {
    final fake = FakeStreamProvider();
    await _pumpExplore(tester, fake);
    await _wait(tester);

    await tester.tap(find.byTooltip('Refresh'));
    await _wait(tester);
    expect(fake.scheduleCalls, 2);

    await tester.tap(find.text('Popular'));
    await _wait(tester);
    await tester.tap(find.byTooltip('Refresh'));
    await _wait(tester);
    expect(fake.popularCalls, 2);
    expect(fake.scheduleCalls, 2);
    expect(fake.newSeriesCalls, 0);
  });

  testWidgets('a show opened from Explore loads its episode list', (
    tester,
  ) async {
    final fake = FakeStreamProvider();
    await _pumpExplore(tester, fake);
    await _wait(tester);

    final today = DateTime.now().weekday;
    await tester.tap(find.text('Day $today Show'));
    await _wait(tester);
    await _wait(tester);

    expect(find.byType(DetailScreen), findsOneWidget);
    expect(fake.episodeRequests, ['https://example.test/day-$today/']);
    expect(find.text('Episodes (3)'), findsOneWidget);
  });

  testWidgets('uses Khmer labels when the display language is Khmer', (
    tester,
  ) async {
    final storage = StorageService();
    await storage.setLanguageCode('km');
    final fake = FakeStreamProvider();
    await _pumpExplore(tester, fake, storage: storage);
    await _wait(tester);

    expect(find.text('រុករក'), findsOneWidget);
    expect(find.text('កាលវិភាគ'), findsOneWidget);
    expect(find.text('រឿងថ្មី'), findsOneWidget);
    expect(find.text('ពេញនិយម'), findsOneWidget);
    for (final label in [
      'ច័ន្ទ',
      'អង្គារ',
      'ពុធ',
      'ព្រហ',
      'សុក្រ',
      'សៅរ៍',
      'អាទិត្យ',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.byTooltip('ផ្ទុកឡើងវិញ'), findsOneWidget);
    // Titles from the source stay as they are.
    final today = DateTime.now().weekday;
    expect(find.text('Day $today Show'), findsOneWidget);
    expect(find.text('EP $today · ចេញហើយ'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // A Khmer tab selects its category like an English one.
    await tester.tap(find.text('ពេញនិយម'));
    await _wait(tester);
    expect(_tabSelected(tester, 'ពេញនិយម'), isTrue);
    expect(_tabSelected(tester, 'កាលវិភាគ'), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the search button opens Search with the keyboard up', (
    tester,
  ) async {
    final fake = FakeStreamProvider(
      onSchedule: () async => fakeWeek(),
      onSearch: (_) async => [fakeShow('a', title: 'Popular A')],
    );
    await _pumpExplore(tester, fake);
    await _wait(tester);

    expect(find.byTooltip('Search'), findsOneWidget);
    expect(find.byType(SearchScreen), findsNothing);

    await tester.tap(find.byTooltip('Search'));
    await _wait(tester);
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(SearchScreen), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.autofocus, isTrue);
    expect(find.text('Popular A'), findsOneWidget);
    // A pushed page: Back returns to Explore.
    expect(find.byType(BackButton), findsOneWidget);
  });

  testWidgets('Search opens fresh each time, without the last results', (
    tester,
  ) async {
    final fake = FakeStreamProvider(
      onSchedule: () async => fakeWeek(),
      onSearch: (q) async => [
        fakeShow(
          q.isEmpty ? 'p' : 'r',
          title: q.isEmpty ? 'Popular A' : 'Result $q',
        ),
      ],
    );
    await _pumpExplore(tester, fake);
    await _wait(tester);

    await tester.tap(find.byTooltip('Search'));
    await _wait(tester);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byType(TextField), 'soul');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await _wait(tester);
    expect(find.text('Result soul'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await _wait(tester);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byTooltip('Search'));
    await _wait(tester);
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Result soul'), findsNothing);
    expect(find.text('Popular A'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '',
    );
  });

  testWidgets('Completed lists the series as their pages arrive', (
    tester,
  ) async {
    // Closed inside the test; a tearDown close() would wait for a done event
    // that the test's fake time never delivers.
    final pages = StreamController<List<Show>>();
    final fake = FakeStreamProvider(
      onSchedule: () async => fakeWeek(),
      onCompleted: () => pages.stream,
    );
    await _pumpExplore(tester, fake);
    await _wait(tester);

    await tester.tap(find.text('Completed').first);
    await _wait(tester);
    expect(fake.completedCalls, 1);
    expect(find.byType(SkeletonPosterGrid), findsOneWidget);

    pages.add([fakeShow('c1', title: 'First Page Show')]);
    await _wait(tester);
    expect(find.text('First Page Show'), findsOneWidget);
    // More pages are coming: the thin bar shows.
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    pages.add([
      fakeShow('c1', title: 'First Page Show'),
      fakeShow('c2', title: 'Second Page Show'),
    ]);
    // close() completes only after the done event is delivered, which in
    // a widget test needs a pump, so it is not awaited here.
    unawaited(pages.close());
    await _wait(tester);
    expect(find.text('Second Page Show'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);

    // Switching back and forth does not read the pages again.
    await tester.tap(find.text('Popular'));
    await _wait(tester);
    await tester.tap(find.text('Completed').first);
    await _wait(tester);
    expect(fake.completedCalls, 1);
  });

  testWidgets('Completed shows the error with Retry when every site fails', (
    tester,
  ) async {
    var calls = 0;
    final fake = FakeStreamProvider(
      onSchedule: () async => fakeWeek(),
      onCompleted: () {
        calls++;
        // Like MultiSourceStreamProvider: an error, then done.
        return calls == 1
            ? Stream<List<Show>>.error(const FormatException('all down'))
            : Stream.value([fakeShow('ok', title: 'Back Again')]);
      },
    );
    await _pumpExplore(tester, fake);
    await _wait(tester);

    await tester.tap(find.text('Completed').first);
    await _wait(tester);

    expect(find.text('Nothing to show yet.'), findsNothing);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await _wait(tester);
    expect(find.text('Back Again'), findsOneWidget);
  });

  testWidgets('a failing later page keeps the list on screen', (tester) async {
    final pages = StreamController<List<Show>>();
    final fake = FakeStreamProvider(
      onSchedule: () async => fakeWeek(),
      onCompleted: () => pages.stream,
    );
    await _pumpExplore(tester, fake);
    await _wait(tester);
    await tester.tap(find.text('Completed').first);
    await _wait(tester);

    pages.add([fakeShow('c1', title: 'Kept Show')]);
    await _wait(tester);
    pages.addError(const FormatException('page 2 down'));
    unawaited(pages.close());
    await _wait(tester);

    expect(find.text('Kept Show'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });
}
