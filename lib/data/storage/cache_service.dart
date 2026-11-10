import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

import '../../core/debug_log.dart';

/// The app's cache folder: posters kept by `cached_network_image`
/// (`libCachedImageData`), and temporary files of the players and the HTTP
/// clients (TASK-033). Everything in it can be fetched again; history,
/// favorites, and settings live elsewhere (Hive, in the app's documents).
///
/// The folder is Android's `Context.getCacheDir()`, asked through the app's
/// own channel in `MainActivity.kt`, so no package is needed. Dart's
/// `Directory.systemTemp` is not it: on Android Flutter points that at the
/// code cache (found in QA of TASK-033). Without the channel the service
/// measures 0 and deletes nothing.
class CacheService {
  /// The bar in Settings measures against this, and a cache above it is
  /// cleared by itself at start (owner's choice, TASK-033).
  static const int limitBytes = 500 * 1024 * 1024;

  static const MethodChannel _channel = MethodChannel(
    'dev.amscenter.donghua_player/storage',
  );

  final Directory? _directory;

  /// The size above which [clearIfOverLimit] clears. Tests use a small one.
  final int limit;

  CacheService({Directory? directory, this.limit = limitBytes})
    : _directory = directory;

  Directory? _resolved;

  /// The cache folder: the one given to the constructor (tests), else the
  /// one Android reports, else `null`. Never a guessed folder: without
  /// Android's answer (widget tests on a PC) nothing may be measured or
  /// deleted, least of all the machine's own temp folder.
  Future<Directory?> directory() async {
    final given = _directory ?? _resolved;
    if (given != null) return given;
    try {
      final path = await _channel.invokeMethod<String>('cacheDir');
      if (path != null && path.isNotEmpty) return _resolved = Directory(path);
    } on PlatformException catch (e) {
      DLog.event('cache.dir', 'channel failed: $e');
    } on MissingPluginException catch (e) {
      DLog.event('cache.dir', 'no channel: $e');
    }
    return null;
  }

  /// Total size of the files in the cache folder. Files that vanish or
  /// cannot be read while counting are left out.
  Future<int> sizeBytes() async {
    final dir = await directory();
    if (dir == null) return 0;
    var total = 0;
    try {
      await for (final entity in dir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File) {
          try {
            total += await entity.length();
          } on FileSystemException {
            // Deleted between list and length: not counted.
          }
        }
      }
    } on FileSystemException catch (e) {
      DLog.event('cache.size', 'list failed: $e');
    }
    return total;
  }

  /// Deletes everything inside the cache folder (not the folder itself) and
  /// the decoded images in memory. On Android a file that is open is still
  /// removed (its download may fail once and be fetched again); an entry
  /// that cannot be removed is logged and kept.
  Future<void> clear() async {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    final dir = await directory();
    if (dir == null) return;
    try {
      await for (final entity in dir.list(followLinks: false)) {
        try {
          await entity.delete(recursive: true);
        } on FileSystemException catch (e) {
          DLog.event('cache.clear', 'kept ${entity.path}: $e');
        }
      }
    } on FileSystemException catch (e) {
      DLog.event('cache.clear', 'list failed: $e');
    }
  }

  /// Clears the cache when it is above [limit]. Returns whether it did.
  Future<bool> clearIfOverLimit() async {
    final size = await sizeBytes();
    DLog.event('cache.start', 'size=$size limit=$limit');
    if (size <= limit) return false;
    await clear();
    return true;
  }
}
