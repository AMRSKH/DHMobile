import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../library/library_controller.dart';

class AppSettings {
  final String defaultQuality;
  final String preferredSubtitle;

  const AppSettings({
    required this.defaultQuality,
    required this.preferredSubtitle,
  });

  AppSettings copyWith({
    String? defaultQuality,
    String? preferredSubtitle,
  }) {
    return AppSettings(
      defaultQuality: defaultQuality ?? this.defaultQuality,
      preferredSubtitle: preferredSubtitle ?? this.preferredSubtitle,
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

  Future<void> clearCache() async {
    final storage = ref.read(storageServiceProvider);
    await storage.clearAllCache();
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);
