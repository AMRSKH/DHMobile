import 'package:donghua_player/core/l10n/app_strings.dart';
import 'package:donghua_player/data/storage/storage_service.dart';
import 'package:donghua_player/features/library/library_controller.dart';
import 'package:donghua_player/features/settings/settings_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ProviderContainer _containerFor(StorageService storage) {
  final container = ProviderContainer(
    overrides: [storageServiceProvider.overrideWithValue(storage)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  // A StorageService that was never initialised keeps its values in memory,
  // so these tests need no Hive box.
  test('the display language is English by default', () {
    final storage = StorageService();
    final container = _containerFor(storage);

    expect(storage.getLanguageCode(), 'en');
    expect(container.read(settingsProvider).language, AppLanguage.en);
    expect(container.read(stringsProvider).language, AppLanguage.en);
    expect(container.read(stringsProvider)(S.settings), 'Settings');
  });

  test('setLanguage changes the state, the strings, and the storage', () async {
    final storage = StorageService();
    final container = _containerFor(storage);

    await container.read(settingsProvider.notifier).setLanguage(AppLanguage.km);

    expect(container.read(settingsProvider).language, AppLanguage.km);
    expect(container.read(stringsProvider)(S.settings), 'ការកំណត់');
    expect(storage.getLanguageCode(), 'km');
  });

  test('the stored language is read again after a restart', () async {
    final storage = StorageService();
    await _containerFor(
      storage,
    ).read(settingsProvider.notifier).setLanguage(AppLanguage.km);

    // A new container stands for the next start of the app.
    final restarted = _containerFor(storage);
    expect(restarted.read(settingsProvider).language, AppLanguage.km);
    expect(restarted.read(stringsProvider)(S.explore), 'រុករក');
  });

  test('an unknown stored code falls back to English', () async {
    final storage = StorageService();
    await storage.setLanguageCode('xx');

    expect(
      _containerFor(storage).read(settingsProvider).language,
      AppLanguage.en,
    );
  });

  test('changing the language keeps the other settings', () async {
    final storage = StorageService();
    final container = _containerFor(storage);
    final notifier = container.read(settingsProvider.notifier);

    await notifier.setDefaultQuality('1080p');
    await notifier.setPreferredSubtitle('Indonesian');
    await notifier.setLanguage(AppLanguage.km);

    final settings = container.read(settingsProvider);
    expect(settings.defaultQuality, '1080p');
    expect(settings.preferredSubtitle, 'Indonesian');
    expect(settings.language, AppLanguage.km);
  });
}
