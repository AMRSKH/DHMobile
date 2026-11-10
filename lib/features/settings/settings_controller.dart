import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/l10n/app_strings.dart';
import '../../data/storage/cache_service.dart';
import '../../domain/models/player_engine.dart';
import '../library/library_controller.dart';

class AppSettings {
  final String defaultQuality;
  final String preferredSubtitle;
  final AppLanguage language;
  final PlayerEngine playerEngine;

  const AppSettings({
    required this.defaultQuality,
    required this.preferredSubtitle,
    this.language = AppLanguage.en,
    this.playerEngine = PlayerEngine.defaultEngine,
  });

  AppSettings copyWith({
    String? defaultQuality,
    String? preferredSubtitle,
    AppLanguage? language,
    PlayerEngine? playerEngine,
  }) {
    return AppSettings(
      defaultQuality: defaultQuality ?? this.defaultQuality,
      preferredSubtitle: preferredSubtitle ?? this.preferredSubtitle,
      language: language ?? this.language,
      playerEngine: playerEngine ?? this.playerEngine,
    );
  }
}

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final storage = ref.watch(storageServiceProvider);
    return AppSettings(
      defaultQuality: storage.getDefaultQuality(),
      preferredSubtitle: storage.getPreferredSubtitle(),
      language: AppLanguage.fromCode(storage.getLanguageCode()),
      playerEngine: PlayerEngine.fromCode(storage.getPlayerEngineCode()),
    );
  }

  Future<void> setDefaultQuality(String quality) async {
    final storage = ref.read(storageServiceProvider);
    await storage.setDefaultQuality(quality);
    state = state.copyWith(defaultQuality: quality);
  }

  Future<void> setPreferredSubtitle(String sub) async {
    final storage = ref.read(storageServiceProvider);
    await storage.setPreferredSubtitle(sub);
    state = state.copyWith(preferredSubtitle: sub);
  }

  Future<void> setLanguage(AppLanguage language) async {
    final storage = ref.read(storageServiceProvider);
    await storage.setLanguageCode(language.code);
    state = state.copyWith(language: language);
  }

  Future<void> setPlayerEngine(PlayerEngine engine) async {
    final storage = ref.read(storageServiceProvider);
    await storage.setPlayerEngineCode(engine.code);
    state = state.copyWith(playerEngine: engine);
  }

  /// Empties the cache folder and measures it again (TASK-033).
  Future<void> clearCache() async {
    await ref.read(cacheServiceProvider).clear();
    ref.invalidate(cacheSizeProvider);
  }
}

/// The app's cache folder. Tests replace it with a temporary folder.
final cacheServiceProvider = Provider<CacheService>((ref) => CacheService());

/// The cache size the Settings bar measures against (500 MB).
const int cacheLimitBytes = CacheService.limitBytes;

/// Bytes in the cache folder, measured when Settings shows it.
final cacheSizeProvider = FutureProvider.autoDispose<int>(
  (ref) => ref.watch(cacheServiceProvider).sizeBytes(),
);

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

/// The app's own text in the chosen display language. Widgets watch it, so a
/// language change redraws them at once.
final stringsProvider = Provider<AppStrings>((ref) {
  return AppStrings(ref.watch(settingsProvider.select((s) => s.language)));
});
