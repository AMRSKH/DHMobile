import 'dart:io';

import 'package:donghua_player/core/app_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('version and build number match pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsLinesSync();
    final versionLine = pubspec.firstWhere(
      (line) => line.startsWith('version:'),
    );
    final version = versionLine.substring('version:'.length).trim();

    expect(version, '${AppInfo.version}+${AppInfo.buildNumber}');
  });

  test('name matches android:label in the manifest', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final label = RegExp(r'android:label="([^"]*)"').firstMatch(manifest);

    expect(label, isNotNull);
    expect(label!.group(1), AppInfo.name);
  });

  test('the About facts are not empty', () {
    expect(AppInfo.contentSource, isNotEmpty);
  });
}
