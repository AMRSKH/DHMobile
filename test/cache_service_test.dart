import 'dart:io';

import 'package:donghua_player/core/format_bytes.dart';
import 'package:donghua_player/data/storage/cache_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('dh_cache_test_');
    File('${dir.path}/a.bin').writeAsBytesSync(List.filled(1000, 1));
    Directory('${dir.path}/libCachedImageData').createSync();
    File(
      '${dir.path}/libCachedImageData/p.jpg',
    ).writeAsBytesSync(List.filled(500, 2));
  });

  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test('sizeBytes counts every file, also in sub folders', () async {
    expect(await CacheService(directory: dir).sizeBytes(), 1500);
  });

  test('clear empties the folder but keeps it', () async {
    await CacheService(directory: dir).clear();

    expect(dir.existsSync(), isTrue);
    expect(dir.listSync(), isEmpty);
  });

  test('clearIfOverLimit clears only above the limit', () async {
    expect(
      await CacheService(directory: dir, limit: 2000).clearIfOverLimit(),
      isFalse,
    );
    expect(dir.listSync(), isNotEmpty);

    expect(
      await CacheService(directory: dir, limit: 1000).clearIfOverLimit(),
      isTrue,
    );
    expect(dir.listSync(), isEmpty);
  });

  test('a missing folder counts as empty', () async {
    dir.deleteSync(recursive: true);
    expect(await CacheService(directory: dir).sizeBytes(), 0);
  });

  test('without the Android channel nothing is measured or deleted', () async {
    // No directory given and no platform channel in a unit test: the
    // service must not fall back to any folder of this machine.
    final service = CacheService(limit: 0);
    expect(await service.directory(), isNull);
    expect(await service.sizeBytes(), 0);
    expect(await service.clearIfOverLimit(), isFalse);
  });

  test('the limit is 500 MB', () {
    expect(CacheService.limitBytes, 500 * 1024 * 1024);
  });

  test('formatBytes', () {
    expect(formatBytes(0), '0 B');
    expect(formatBytes(1023), '1023 B');
    expect(formatBytes(812 * 1024), '812 KB');
    expect(formatBytes((86.4 * 1024 * 1024).round()), '86.4 MB');
    expect(formatBytes(500 * 1024 * 1024), '500 MB');
    expect(formatBytes((1.2 * 1024 * 1024 * 1024).round()), '1.2 GB');
  });
}
