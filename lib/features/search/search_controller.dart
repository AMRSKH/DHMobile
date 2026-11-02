import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/show.dart';
import '../../domain/providers/stream_provider.dart';
import '../../data/providers/animexin_stream_provider.dart';

final streamProvider = Provider<DonghuaStreamProvider>((ref) {
  return AnimeXinStreamProvider();
});

final searchControllerProvider =
    NotifierProvider<SearchController, AsyncValue<List<Show>>>(() {
  return SearchController();
});

class SearchController extends Notifier<AsyncValue<List<Show>>> {
  @override
  AsyncValue<List<Show>> build() {
    Future.microtask(() => _loadInitial());
    return const AsyncValue.loading();
  }

  Future<void> _loadInitial() async {
    final provider = ref.read(streamProvider);
    try {
      final results = await provider.search('');
      state = AsyncValue.data(results);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> search(String query) async {
    state = const AsyncValue.loading();
    try {
      final provider = ref.read(streamProvider);
      final results = await provider.search(query);
      state = AsyncValue.data(results);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
