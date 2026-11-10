import 'package:hive_flutter/hive_flutter.dart';
import '../../core/debug_log.dart';
import '../../domain/models/show.dart';
import '../../domain/models/episode.dart';
import '../../domain/models/history_item.dart';

class StorageService {
  static const String favoritesBoxName = 'favorites_box';
  static const String historyBoxName = 'history_box';
  static const String settingsBoxName = 'settings_box';

  static const String keyDefaultQuality = 'default_quality';
  static const String keyPreferredSubtitle = 'preferred_subtitle';
  static const String keyLanguage = 'display_language';
  static const String keyPlayerEngine = 'player_engine';

  Box? _favoritesBox;
  Box? _historyBox;
  Box? _settingsBox;

  // In-memory fallback for testing / previews
  final Map<String, Map<String, dynamic>> _memFavorites = {};
  final Map<String, Map<dynamic, dynamic>> _memHistory = {};
  final Map<String, String> _memSettings = {};

  Future<void> init() async {
    try {
      await Hive.initFlutter();
      _favoritesBox = await Hive.openBox(favoritesBoxName);
      _historyBox = await Hive.openBox(historyBoxName);
      _settingsBox = await Hive.openBox(settingsBoxName);
    } catch (e) {
      DLog.error('storage.hiveInit', e);
    }
  }

  // Favorites
  List<Show> getFavorites() {
    final list = <Show>[];
    if (_favoritesBox != null && _favoritesBox!.isOpen) {
      for (var key in _favoritesBox!.keys) {
        final data = _favoritesBox!.get(key);
        if (data is Map) {
          list.add(Show.fromMap(Map<String, dynamic>.from(data)));
        }
      }
    } else {
      for (var data in _memFavorites.values) {
        list.add(Show.fromMap(data));
      }
    }
    return list;
  }

  bool isFavorite(String showId) {
    if (_favoritesBox != null && _favoritesBox!.isOpen) {
      return _favoritesBox!.containsKey(showId);
    }
    return _memFavorites.containsKey(showId);
  }

  Future<void> toggleFavorite(Show show) async {
    if (isFavorite(show.id)) {
      if (_favoritesBox != null && _favoritesBox!.isOpen) {
        await _favoritesBox!.delete(show.id);
      }
      _memFavorites.remove(show.id);
    } else {
      if (_favoritesBox != null && _favoritesBox!.isOpen) {
        await _favoritesBox!.put(show.id, show.toMap());
      }
      _memFavorites[show.id] = show.toMap();
    }
  }

  Future<void> clearFavorites() async {
    if (_favoritesBox != null && _favoritesBox!.isOpen) {
      await _favoritesBox!.clear();
    }
    _memFavorites.clear();
  }

  // History
  List<WatchHistoryItem> getHistory() {
    final list = <WatchHistoryItem>[];
    if (_historyBox != null && _historyBox!.isOpen) {
      for (var key in _historyBox!.keys) {
        final data = _historyBox!.get(key);
        if (data is Map) {
          try {
            list.add(WatchHistoryItem.fromMap(data));
          } catch (e) {
            DLog.error('storage.historyParse', e);
          }
        }
      }
    } else {
      for (var data in _memHistory.values) {
        try {
          list.add(WatchHistoryItem.fromMap(data));
        } catch (_) {}
      }
    }
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  WatchHistoryItem? getLastWatched(String showId) {
    final all = getHistory().where((item) => item.show.id == showId).toList();
    if (all.isEmpty) return null;
    return all.first;
  }

  int? getEpisodeProgress(String episodeId) {
    if (_historyBox != null && _historyBox!.isOpen) {
      final data = _historyBox!.get(episodeId);
      if (data is Map) {
        return (data['positionMs'] as num?)?.toInt();
      }
    } else {
      final data = _memHistory[episodeId];
      if (data != null) {
        return (data['positionMs'] as num?)?.toInt();
      }
    }
    return null;
  }

  Future<void> saveHistory({
    required Show show,
    required Episode episode,
    required int positionMs,
    required int durationMs,
  }) async {
    final item = WatchHistoryItem(
      show: show,
      episode: episode,
      positionMs: positionMs,
      durationMs: durationMs,
      updatedAt: DateTime.now(),
    );
    if (_historyBox != null && _historyBox!.isOpen) {
      await _historyBox!.put(episode.id, item.toMap());
    }
    _memHistory[episode.id] = item.toMap();
  }

  Future<void> removeHistoryItem(String episodeId) async {
    if (_historyBox != null && _historyBox!.isOpen) {
      await _historyBox!.delete(episodeId);
    }
    _memHistory.remove(episodeId);
  }

  Future<void> clearHistory() async {
    if (_historyBox != null && _historyBox!.isOpen) {
      await _historyBox!.clear();
    }
    _memHistory.clear();
  }

  // Settings
  String getDefaultQuality() {
    if (_settingsBox != null && _settingsBox!.isOpen) {
      return _settingsBox!.get(keyDefaultQuality, defaultValue: '720p')
          as String;
    }
    return _memSettings[keyDefaultQuality] ?? '720p';
  }

  Future<void> setDefaultQuality(String quality) async {
    if (_settingsBox != null && _settingsBox!.isOpen) {
      await _settingsBox!.put(keyDefaultQuality, quality);
    }
    _memSettings[keyDefaultQuality] = quality;
  }

  String getPreferredSubtitle() {
    if (_settingsBox != null && _settingsBox!.isOpen) {
      return _settingsBox!.get(keyPreferredSubtitle, defaultValue: 'English')
          as String;
    }
    return _memSettings[keyPreferredSubtitle] ?? 'English';
  }

  Future<void> setPreferredSubtitle(String sub) async {
    if (_settingsBox != null && _settingsBox!.isOpen) {
      await _settingsBox!.put(keyPreferredSubtitle, sub);
    }
    _memSettings[keyPreferredSubtitle] = sub;
  }

  /// Code of the display language, 'en' when nothing was stored yet.
  String getLanguageCode() {
    if (_settingsBox != null && _settingsBox!.isOpen) {
      final value = _settingsBox!.get(keyLanguage, defaultValue: 'en');
      return value is String ? value : 'en';
    }
    return _memSettings[keyLanguage] ?? 'en';
  }

  Future<void> setLanguageCode(String code) async {
    if (_settingsBox != null && _settingsBox!.isOpen) {
      await _settingsBox!.put(keyLanguage, code);
    }
    _memSettings[keyLanguage] = code;
  }

  /// Code of the chosen player engine, `null` when nothing was stored yet.
  String? getPlayerEngineCode() {
    if (_settingsBox != null && _settingsBox!.isOpen) {
      final value = _settingsBox!.get(keyPlayerEngine);
      return value is String ? value : null;
    }
    return _memSettings[keyPlayerEngine];
  }

  Future<void> setPlayerEngineCode(String code) async {
    if (_settingsBox != null && _settingsBox!.isOpen) {
      await _settingsBox!.put(keyPlayerEngine, code);
    }
    _memSettings[keyPlayerEngine] = code;
  }
}
