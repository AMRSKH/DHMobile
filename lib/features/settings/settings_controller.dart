import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/l10n/app_strings.dart';
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
    this.playerEngine = PlayerEngine.vlc,
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

  Future<void> clearCache() async {
    final storage = ref.read(storageServiceProvider);
    await storage.clearAllCache();
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

/// The app's own text in the chosen display language. Widgets watch it, so a
/// language change redraws them at once.
final stringsProvider = Provider<AppStrings>((ref) {
  return AppStrings(ref.watch(settingsProvider.select((s) => s.language)));
});
