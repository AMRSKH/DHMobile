/// Facts about the app that the UI shows. `test/app_info_test.dart` checks
/// that they match `pubspec.yaml` and the Android manifest.
class AppInfo {
  const AppInfo._();

  /// Same as `android:label` in `AndroidManifest.xml`.
  static const String name = 'DHMobile';

  /// The part of `version:` in `pubspec.yaml` before the `+`.
  static const String version = '1.0.3';

  /// The part of `version:` in `pubspec.yaml` after the `+`.
  static const String buildNumber = '4';

  /// The player the app really uses. See `_useFallbackPlayer` in
  /// `player_screen.dart`.
  static const String playerEngine = 'video_player (ExoPlayer)';

  static const String contentSource = 'AnimeXin (animexin.dev)';
}
