import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/show.dart';
import '../search/search_controller.dart';
import '../../core/debug_log.dart';

final exploreControllerProvider =
    NotifierProvider<ExploreController, AsyncValue<List<Show>>>(() {
      return ExploreController();
    });

class ExploreController extends Notifier<AsyncValue<List<Show>>> {
  int selectedWeekday = DateTime.now().weekday.clamp(1, 7);

  @override
  AsyncValue<List<Show>> build() {
    Future.microtask(() => _loadWeekday(selectedWeekday));
    return const AsyncValue.loading();
  }

  Future<void> selectWeekday(int day) async {
    selectedWeekday = day.clamp(1, 7);
    await _loadWeekday(selectedWeekday);
  }

  Future<void> _loadWeekday(int day) async {
    state = const AsyncValue.loading();
    try {
      final provider = ref.read(streamProvider);
      final results = await provider.search('', weekday: day);
      DLog.event('explore.trending', 'weekday=$day count=${results.length}');
      state = AsyncValue.data(results);
    } catch (e, st) {
      DLog.error('explore.trending', e, st);
      state = AsyncValue.error(e, st);
    }
  }
}
