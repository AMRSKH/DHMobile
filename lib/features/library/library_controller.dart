import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/storage/storage_service.dart';
import '../../domain/models/show.dart';
import '../../domain/models/episode.dart';
import '../../domain/models/history_item.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

// Favorites Notifier
class FavoritesNotifier extends Notifier<List<Show>> {
  @override
  List<Show> build() {
    final storage = ref.watch(storageServiceProvider);
    return storage.getFavorites();
  }

  Future<void> toggleFavorite(Show show) async {
    final storage = ref.read(storageServiceProvider);
    await storage.toggleFavorite(show);
    state = storage.getFavorites();
  }

  bool isFavorite(String showId) {
    return state.any((s) => s.id == showId);
  }

  Future<void> clearFavorites() async {
    final storage = ref.read(storageServiceProvider);
    await storage.clearFavorites();
    state = [];
  }
}

final favoritesProvider = NotifierProvider<FavoritesNotifier, List<Show>>(
  FavoritesNotifier.new,
);

// History Notifier
class HistoryNotifier extends Notifier<List<WatchHistoryItem>> {
  @override
  List<WatchHistoryItem> build() {
    final storage = ref.watch(storageServiceProvider);
    return storage.getHistory();
  }

  Future<void> saveProgress({
    required Show show,
    required Episode episode,
    required int positionMs,
    required int durationMs,
  }) async {
    final storage = ref.read(storageServiceProvider);
    await storage.saveHistory(
      show: show,
      episode: episode,
      positionMs: positionMs,
      durationMs: durationMs,
    );
    state = storage.getHistory();
  }

  Future<void> removeItem(String episodeId) async {
    final storage = ref.read(storageServiceProvider);
    await storage.removeHistoryItem(episodeId);
    state = storage.getHistory();
  }

  Future<void> clearHistory() async {
    final storage = ref.read(storageServiceProvider);
    await storage.clearHistory();
    state = [];
  }

  WatchHistoryItem? getLastWatched(String showId) {
    final list = state.where((item) => item.show.id == showId).toList();
    return list.isEmpty ? null : list.first;
  }
}

final historyProvider = NotifierProvider<HistoryNotifier, List<WatchHistoryItem>>(
  HistoryNotifier.new,
);
