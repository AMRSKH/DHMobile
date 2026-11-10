/// Facts about the app that the UI shows. `test/app_info_test.dart` checks
/// that they match `pubspec.yaml` and the Android manifest.
///
/// The player engine is a setting (`PlayerEngine`), and the content sources
/// are listed in `kContentSources`.
class AppInfo {
  const AppInfo._();

  /// Same as `android:label` in `AndroidManifest.xml`.
  static const String name = 'DHMobile';

  /// The part of `version:` in `pubspec.yaml` before the `+`.
  static const String version = '1.0.9';

  /// The part of `version:` in `pubspec.yaml` after the `+`.
  static const String buildNumber = '10';
}
