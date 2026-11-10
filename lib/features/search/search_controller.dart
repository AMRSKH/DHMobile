import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/show.dart';
import '../../domain/providers/stream_provider.dart';
import '../../data/providers/multi_source_provider.dart';
import '../../core/debug_log.dart';

/// Every source at once: search asks all of them, a show's episodes and
/// streams come from its own site, Explore from the main source.
final streamProvider = Provider<DonghuaStreamProvider>((ref) {
  return MultiSourceStreamProvider();
});

/// Search is a page pushed from Explore, so its state goes with the page: a
/// new visit starts with an empty field and the popular list, not the
/// results of the last visit (QA TASK-023).
final searchControllerProvider =
    NotifierProvider.autoDispose<SearchController, AsyncValue<List<Show>>>(
      SearchController.new,
    );

class SearchController extends Notifier<AsyncValue<List<Show>>> {
  // Counts requests. A search can wait up to the slowest source, so an
  // answer that arrives after a newer request was made is dropped
  // (QA TASK-021).
  int _request = 0;

  @override
  AsyncValue<List<Show>> build() {
    Future.microtask(() => _loadInitial());
    return const AsyncValue.loading();
  }

  Future<void> _loadInitial() async {
    final request = ++_request;
    final provider = ref.read(streamProvider);
    try {
      final results = await provider.search('');
      if (request != _request) return;
      DLog.event('search.initial', 'count=${results.length}');
      state = AsyncValue.data(results);
    } catch (e, st) {
      if (request != _request) return;
      DLog.error('search.initial', e, st);
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> search(String query) async {
    final request = ++_request;
    state = const AsyncValue.loading();
    try {
      final provider = ref.read(streamProvider);
      final results = await provider.search(query);
      if (request != _request) {
        DLog.event('search.result', 'q="$query" dropped, a newer one runs');
        return;
      }
      DLog.event('search.result', 'q="$query" count=${results.length}');
      state = AsyncValue.data(results);
    } catch (e, st) {
      if (request != _request) return;
      DLog.error('search.result', e, st);
      state = AsyncValue.error(e, st);
    }
  }
}
