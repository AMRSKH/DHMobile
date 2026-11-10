import 'dart:io';

import 'package:donghua_player/core/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Khmer text falls back to the embedded Inter Khmer Looped', () {
    expect(AppTheme.darkTheme.textTheme.bodyMedium?.fontFamilyFallback, [
      AppTheme.khmerFontFamily,
    ]);
  });

  test('AppBar titles fall back to it too', () {
    // AppBar uses titleTextStyle without the text theme (TASK-034 QA).
    expect(AppTheme.darkTheme.appBarTheme.titleTextStyle?.fontFamilyFallback, [
      AppTheme.khmerFontFamily,
    ]);
  });

  test('the font files and their license are embedded and declared', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('family: ${AppTheme.khmerFontFamily}'));
    for (final name in [
      'InterKhmerLooped-Regular.ttf',
      'InterKhmerLooped-SemiBold.ttf',
      'InterKhmerLooped-Bold.ttf',
      'OFL.txt',
    ]) {
      final path = 'assets/fonts/inter_khmer_looped/$name';
      expect(File(path).existsSync(), isTrue, reason: path);
      expect(pubspec, contains(path), reason: '$path not in pubspec.yaml');
    }
    // A TrueType font starts with 00 01 00 00.
    final head = File(
      'assets/fonts/inter_khmer_looped/InterKhmerLooped-Regular.ttf',
    ).readAsBytesSync().sublist(0, 4);
    expect(head, [0, 1, 0, 0]);
  });
}
