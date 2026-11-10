import 'package:flutter/foundation.dart';

/// Lightweight, greppable debug logging for manual device testing.
///
/// Every line starts with `[DH]` so a single logcat filter shows the whole
/// user journey:
///
/// ```powershell
/// adb logcat -d | Select-String '\[DH\]'
/// ```
///
/// Logging is compiled out of release builds.
class DLog {
  const DLog._();

  static bool enabled = kDebugMode;

  static void event(String tag, [Object? data]) {
    if (!enabled) return;
    debugPrint(data == null ? '[DH] $tag' : '[DH] $tag | $data');
  }

  static void error(String tag, Object error, [StackTrace? stack]) {
    if (!enabled) return;
    debugPrint('[DH] ERROR $tag | $error');
    if (stack != null) debugPrint('[DH] ERROR $tag | $stack');
  }
}
