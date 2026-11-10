import 'dart:async';

import 'package:donghua_player/domain/models/schedule_entry.dart';
import 'package:donghua_player/domain/models/show.dart';
import 'package:donghua_player/features/explore/explore_controller.dart';
import 'package:donghua_player/features/search/search_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_stream_provider.dart';

ProviderContainer _containerFor(FakeStreamProvider fake) {
  final container = ProviderContainer(
    overrides: [streamProvider.overrideWithValue(fake)],
  );
  addTearDown(container.dispose);
  // Keeps the controller alive and listened to, like the screen does.
  container.listen(exploreControllerProvider, (_, _) {});
  return container;
}

/// Lets the microtask of `build()` and the answers of the fake run.
Future<void> _settle() => pumpEventQueue();

Map<int, List<ScheduleEntry>> _weekWith(String title) {
  return fakeWeek({
    DateTime.monday: [ScheduleEntry(show: fakeShow(title, title: title))],
  });
}

void main() {
  test('starts on the schedule of today and loads only the schedule', () async {
    final fake = FakeStreamProvider();
    final container = _containerFor(fake);

    final first = container.read(exploreControllerProvider);
    expect(first.category, ExploreCategory.schedule);
    expect(first.weekday, DateTime.now().weekday);
    expect(first.schedule.isLoading, isTrue);

    await _settle();

    final state = container.read(exploreControllerProvider);
    expect(state.schedule.hasValue, isTrue);
    expect(state.schedule.requireValue.keys, hasLength(7));
    expect(state.entriesOfDay.single.show.title, 'Day ${state.weekday} Show');
    expect(fake.scheduleCalls, 1);
    expect(fake.newSeriesCalls, 0);
    expect(fake.popularCalls, 0);
  });

  test('a category is loaded on its first use and kept after that', () async {
    final fake = FakeStreamProvider();
    final container = _containerFor(fake);
    final controller = container.read(exploreControllerProvider.notifier);
    await _settle();

    controller.selectCategory(ExploreCategory.newSeries);
    expect(
      container.read(exploreControllerProvider).category,
      ExploreCategory.newSeries,
    );
    expect(
      container.read(exploreControllerProvider).newSeries.isLoading,
      isTrue,
    );
    await _settle();
    expect(
      container
          .read(exploreControllerProvider)
          .newSeries
          .requireValue
          .first
          .title,
      'New One',
    );

    controller.selectCategory(ExploreCategory.popular);
    await _settle();
    expect(
      container
          .read(exploreControllerProvider)
          .popular
          .requireValue
          .first
          .title,
      'Popular One',
    );

    // Going back and forth asks the source nothing new.
    controller.selectCategory(ExploreCategory.schedule);
    controller.selectCategory(ExploreCategory.newSeries);
    controller.selectCategory(ExploreCategory.popular);
    await _settle();

    expect(fake.scheduleCalls, 1);
    expect(fake.newSeriesCalls, 1);
    expect(fake.popularCalls, 1);
  });

  test('a day change needs no network', () async {
    final fake = FakeStreamProvider();
    final container = _containerFor(fake);
    final controller = container.read(exploreControllerProvider.notifier);
    await _settle();

    for (var day = 1; day <= 7; day++) {
      controller.selectWeekday(day);
      final state = container.read(exploreControllerProvider);
      expect(state.weekday, day);
      expect(state.entriesOfDay.single.show.title, 'Day $day Show');
    }
    controller.selectWeekday(0);
    expect(container.read(exploreControllerProvider).weekday, 1);
    controller.selectWeekday(12);
    expect(container.read(exploreControllerProvider).weekday, 7);

    expect(fake.scheduleCalls, 1);
  });

  test('refresh fetches only the current category again', () async {
    final fake = FakeStreamProvider();
    final container = _containerFor(fake);
    final controller = container.read(exploreControllerProvider.notifier);
    await _settle();

    await controller.refresh();
    expect(fake.scheduleCalls, 2);
    expect(fake.newSeriesCalls, 0);
    expect(fake.popularCalls, 0);

    controller.selectCategory(ExploreCategory.popular);
    await _settle();
    await controller.refresh();
    expect(fake.scheduleCalls, 2);
    expect(fake.newSeriesCalls, 0);
    expect(fake.popularCalls, 2);
  });

  test('refresh keeps the category and the selected day', () async {
    final fake = FakeStreamProvider();
    final container = _containerFor(fake);
    final controller = container.read(exploreControllerProvider.notifier);
    await _settle();

    controller.selectWeekday(3);
    final pending = controller.refresh();
    expect(
      container.read(exploreControllerProvider).schedule.isLoading,
      isTrue,
    );
    await pending;

    final state = container.read(exploreControllerProvider);
    expect(state.category, ExploreCategory.schedule);
    expect(state.weekday, 3);
    expect(state.entriesOfDay.single.show.title, 'Day 3 Show');
  });

  test('a failure becomes an error state, and refresh can recover', () async {
    var fail = true;
    final fake = FakeStreamProvider(
      onSchedule: () async {
        if (fail) throw const FormatException('The schedule page has no shows');
        return fakeWeekOnePerDay();
      },
    );
    final container = _containerFor(fake);
    await _settle();

    final failed = container.read(exploreControllerProvider);
    expect(failed.schedule.hasError, isTrue);
    expect(failed.schedule.error, isA<FormatException>());
    expect(failed.entriesOfDay, isEmpty);

    fail = false;
    await container.read(exploreControllerProvider.notifier).refresh();

    final state = container.read(exploreControllerProvider);
    expect(state.schedule.hasError, isFalse);
    expect(state.schedule.requireValue.keys, hasLength(7));
  });

  test('a failed list does not touch the other categories', () async {
    final fake = FakeStreamProvider(
      onPopular: () async => throw StateError('offline'),
    );
    final container = _containerFor(fake);
    final controller = container.read(exploreControllerProvider.notifier);
    await _settle();

    controller.selectCategory(ExploreCategory.popular);
    await _settle();

    final state = container.read(exploreControllerProvider);
    expect(state.popular.hasError, isTrue);
    expect(state.schedule.hasValue, isTrue);
    expect(state.schedule.hasError, isFalse);
  });

  test('an older answer that arrives late is dropped', () async {
    final answers = <Completer<Map<int, List<ScheduleEntry>>>>[];
    final fake = FakeStreamProvider(
      onSchedule: () {
        final completer = Completer<Map<int, List<ScheduleEntry>>>();
        answers.add(completer);
        return completer.future;
      },
    );
    final container = _containerFor(fake);
    final controller = container.read(exploreControllerProvider.notifier);
    await _settle();
    expect(answers, hasLength(1));

    final refreshed = controller.refresh();
    expect(answers, hasLength(2));

    // The second request answers first, the first one after it.
    answers[1].complete(_weekWith('Fresh'));
    await refreshed;
    answers[0].complete(_weekWith('Stale'));
    await _settle();

    final monday = container
        .read(exploreControllerProvider)
        .schedule
        .requireValue[DateTime.monday]!;
    expect(monday.single.show.title, 'Fresh');
  });

  test('an older failure does not replace a newer answer', () async {
    final answers = <Completer<List<Show>>>[];
    final fake = FakeStreamProvider(
      onNewSeries: () {
        final completer = Completer<List<Show>>();
        answers.add(completer);
        return completer.future;
      },
    );
    final container = _containerFor(fake);
    final controller = container.read(exploreControllerProvider.notifier);
    await _settle();

    controller.selectCategory(ExploreCategory.newSeries);
    final refreshed = controller.refresh();
    expect(answers, hasLength(2));

    answers[1].complete([fakeShow('fresh', title: 'Fresh')]);
    await refreshed;
    answers[0].completeError(StateError('timeout'));
    await _settle();

    final state = container.read(exploreControllerProvider);
    expect(state.newSeries.hasError, isFalse);
    expect(state.newSeries.requireValue.single.title, 'Fresh');
  });

  test('an answer after dispose is ignored', () async {
    final answer = Completer<Map<int, List<ScheduleEntry>>>();
    final fake = FakeStreamProvider(onSchedule: () => answer.future);
    final container = ProviderContainer(
      overrides: [streamProvider.overrideWithValue(fake)],
    );
    container.listen(exploreControllerProvider, (_, _) {});
    await _settle();
    expect(fake.scheduleCalls, 1);

    container.dispose();
    answer.complete(fakeWeekOnePerDay());

    // A state change on the disposed controller would throw here.
    await _settle();
  });
}
