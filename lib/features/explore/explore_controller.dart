import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/schedule_entry.dart';
import '../../domain/models/show.dart';
import '../search/search_controller.dart';
import '../../core/debug_log.dart';

enum ExploreCategory { schedule, newSeries, popular }

class ExploreState {
  final ExploreCategory category;

  /// The day shown in the schedule, 1 (Monday) to 7 (Sunday).
  final int weekday;

  /// The whole week, keys 1 to 7. Loaded once, a day change needs no network.
  final AsyncValue<Map<int, List<ScheduleEntry>>> schedule;
  final AsyncValue<List<Show>> newSeries;
  final AsyncValue<List<Show>> popular;

  const ExploreState({
    required this.category,
    required this.weekday,
    this.schedule = const AsyncValue.loading(),
    this.newSeries = const AsyncValue.loading(),
    this.popular = const AsyncValue.loading(),
  });

  /// The shows of the selected weekday, while the schedule is loaded.
  List<ScheduleEntry> get entriesOfDay {
    return schedule.asData?.value[weekday] ?? const [];
  }

  ExploreState copyWith({
    ExploreCategory? category,
    int? weekday,
    AsyncValue<Map<int, List<ScheduleEntry>>>? schedule,
    AsyncValue<List<Show>>? newSeries,
    AsyncValue<List<Show>>? popular,
  }) {
    return ExploreState(
      category: category ?? this.category,
      weekday: weekday ?? this.weekday,
      schedule: schedule ?? this.schedule,
      newSeries: newSeries ?? this.newSeries,
      popular: popular ?? this.popular,
    );
  }
}

final exploreControllerProvider =
    NotifierProvider<ExploreController, ExploreState>(() {
      return ExploreController();
    });

class ExploreController extends Notifier<ExploreState> {
  // One counter per category. A load raises it, and an answer that comes
  // back with an older number is dropped: a newer load has replaced it.
  final Map<ExploreCategory, int> _requests = {};

  // Categories that were asked for at least once.
  final Set<ExploreCategory> _started = {};

  @override
  ExploreState build() {
    _requests.clear();
    _started.clear();
    Future.microtask(() {
      if (ref.mounted) _load(ExploreCategory.schedule);
    });
    return ExploreState(
      category: ExploreCategory.schedule,
      weekday: DateTime.now().weekday.clamp(1, 7),
    );
  }

  /// Shows [category]. Its list is loaded on the first use and kept for the
  /// session after that.
  void selectCategory(ExploreCategory category) {
    DLog.event('explore.category', category.name);
    state = state.copyWith(category: category);
    if (!_started.contains(category)) _load(category);
  }

  /// Shows another day of the schedule that is already loaded.
  void selectWeekday(int day) {
    state = state.copyWith(weekday: day.clamp(1, 7));
  }

  /// Fetches the current category again.
  Future<void> refresh() => _load(state.category);

  Future<void> _load(ExploreCategory category) async {
    _started.add(category);
    final request = (_requests[category] ?? 0) + 1;
    _requests[category] = request;
    bool isCurrent() => ref.mounted && _requests[category] == request;

    final provider = ref.read(streamProvider);
    switch (category) {
      case ExploreCategory.schedule:
        state = state.copyWith(schedule: const AsyncValue.loading());
        final result = await AsyncValue.guard(provider.schedule);
        if (!isCurrent()) return;
        state = state.copyWith(schedule: result);
        _log(category, result, (week) {
          return week.values.fold<int>(0, (sum, day) => sum + day.length);
        });
      case ExploreCategory.newSeries:
        state = state.copyWith(newSeries: const AsyncValue.loading());
        final result = await AsyncValue.guard(provider.newSeries);
        if (!isCurrent()) return;
        state = state.copyWith(newSeries: result);
        _log(category, result, (shows) => shows.length);
      case ExploreCategory.popular:
        state = state.copyWith(popular: const AsyncValue.loading());
        final result = await AsyncValue.guard(provider.popular);
        if (!isCurrent()) return;
        state = state.copyWith(popular: result);
        _log(category, result, (shows) => shows.length);
    }
  }

  /// The screen shows a fixed text for a failure. The real error is only
  /// written to the debug log.
  void _log<T>(
    ExploreCategory category,
    AsyncValue<T> result,
    int Function(T value) count,
  ) {
    final error = result.asError;
    if (error != null) {
      DLog.error('explore.${category.name}', error.error, error.stackTrace);
      return;
    }
    final data = result.asData;
    if (data != null) {
      DLog.event('explore.${category.name}', 'count=${count(data.value)}');
    }
  }
}
