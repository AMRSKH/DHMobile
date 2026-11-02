import 'dart:convert';
import 'package:dio/dio.dart';
import '../../domain/models/stream_source.dart';

class StreamResolver {
  final Dio _dio;

  StreamResolver({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                headers: {
                  'User-Agent':
                      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                },
                connectTimeout: const Duration(seconds: 4),
                receiveTimeout: const Duration(seconds: 4),
              ),
            );

  Future<List<StreamSource>> resolve(String rawUrl, {String? serverHint, String? referer}) async {
    final url = rawUrl.trim();
    if (url.isEmpty) return [];

    // Skip cloud storage or captcha sites that do not provide direct streams
    if (url.contains('mega.nz') ||
        url.contains('mega.io') ||
        url.contains('drive.google') ||
        url.contains('dropbox.com') ||
        url.contains('vvide0.com') ||
        url.contains('dood')) {
      return [];
    }

    // 1. Direct playable stream
    if (url.endsWith('.m3u8') || url.endsWith('.mp4') || url.endsWith('.mkv')) {
      return [
        StreamSource(
          url: url,
          quality: 'Direct',
          server: serverHint ?? 'Direct Server',
          headers: referer != null ? {'Referer': referer} : {},
        ),
      ];
    }

    // 2. Dailymotion resolver
    if (url.contains('dailymotion.com')) {
      final dmSources = await _resolveDailymotion(url, serverHint: serverHint);
      if (dmSources.isNotEmpty) return dmSources;
    }

    // 3. OK.ru resolver
    if (url.contains('ok.ru')) {
      final okSources = await _resolveOkRu(url, serverHint: serverHint);
      if (okSources.isNotEmpty) return okSources;
    }

    // 4. Rumble resolver
    if (url.contains('rumble.com')) {
      final rumbleSources = await _resolveRumble(url, serverHint: serverHint);
      if (rumbleSources.isNotEmpty) return rumbleSources;
    }

    // 5. Generic embed with m3u8 in source
    try {
      final embedSources = await _resolveGenericEmbed(url, referer: referer, serverHint: serverHint);
      if (embedSources.isNotEmpty) return embedSources;
    } catch (_) {}

    return [];
  }

  Future<List<StreamSource>> _resolveDailymotion(String url, {String? serverHint}) async {
    try {
      String? videoId;
      final queryMatch = RegExp(r'[?&]video=([a-zA-Z0-9]+)').firstMatch(url);
      if (queryMatch != null) {
        videoId = queryMatch.group(1);
      } else {
        final pathMatch = RegExp(r'dailymotion\.com/(?:(?:embed/)?video/|videoembed/)?([a-zA-Z0-9]+)').firstMatch(url);
        if (pathMatch != null) {
          videoId = pathMatch.group(1);
        }
      }

      if (videoId == null || videoId.isEmpty) return [];

      final metaUrl = 'https://www.dailymotion.com/player/metadata/video/$videoId';
      final response = await _dio.get(metaUrl);
      final data = response.data is Map ? response.data : json.decode(response.data.toString());

      final List<StreamSource> sources = [];
      final autoQualities = data['qualities']?['auto'] as List?;
      if (autoQualities != null && autoQualities.isNotEmpty) {
        final m3u8Url = autoQualities.first['url'] as String?;
        if (m3u8Url != null && m3u8Url.isNotEmpty) {
          sources.add(
            StreamSource(
              url: m3u8Url,
              quality: 'Multi-Bitrate (HLS)',
              server: serverHint ?? 'Dailymotion Fast',
              headers: {
                'User-Agent':
                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              },
            ),
          );
        }
      }
      return sources;
    } catch (_) {
      return [];
    }
  }

  Future<List<StreamSource>> _resolveOkRu(String url, {String? serverHint}) async {
    try {
      String cleanUrl = url;
      if (cleanUrl.startsWith('//')) cleanUrl = 'https:$cleanUrl';

      final idMatch = RegExp(r'ok\.ru/(?:video|videoembed)/(\d+)').firstMatch(cleanUrl);
      if (idMatch == null) return [];
      final videoId = idMatch.group(1)!;

      final embedUrl = 'https://ok.ru/videoembed/$videoId';
      final response = await _dio.get(embedUrl);
      final html = response.data.toString();
      final decoded = html.replaceAll('&quot;', '"').replaceAll(r'\u0026', '&').replaceAll(r'\/', '/');

      final List<StreamSource> sources = [];
      final hlsMatch = RegExp(r'"hlsManifestUrl"\s*:\s*"([^"]+)"').firstMatch(decoded);
      if (hlsMatch != null) {
        sources.add(
          StreamSource(
            url: hlsMatch.group(1)!,
            quality: 'Auto HLS',
            server: serverHint ?? 'OK.ru Fast',
            headers: {'User-Agent': 'Mozilla/5.0'},
          ),
        );
      }

      final hdMatch = RegExp(r'"name"\s*:\s*"hd"\s*,\s*"url"\s*:\s*"([^"]+)"').firstMatch(decoded);
      if (hdMatch != null) {
        sources.add(
          StreamSource(
            url: hdMatch.group(1)!,
            quality: '720p',
            server: '${serverHint ?? "OK.ru"} HD',
            headers: {'User-Agent': 'Mozilla/5.0'},
          ),
        );
      }

      final sdMatch = RegExp(r'"name"\s*:\s*"sd"\s*,\s*"url"\s*:\s*"([^"]+)"').firstMatch(decoded);
      if (sdMatch != null) {
        sources.add(
          StreamSource(
            url: sdMatch.group(1)!,
            quality: '480p',
            server: '${serverHint ?? "OK.ru"} SD',
            headers: {'User-Agent': 'Mozilla/5.0'},
          ),
        );
      }

      return sources;
    } catch (_) {
      return [];
    }
  }

  Future<List<StreamSource>> _resolveRumble(String url, {String? serverHint}) async {
    try {
      final idMatch = RegExp(r'rumble\.com/embed/([a-zA-Z0-9]+)').firstMatch(url);
      if (idMatch == null) return [];
      final videoId = idMatch.group(1)!;

      final apiUrl = 'https://rumble.com/embedJS/u3/?request=video&ver=2&v=$videoId';
      final response = await _dio.get(apiUrl);
      final data = response.data is Map ? response.data : json.decode(response.data.toString());

      final List<StreamSource> sources = [];
      final hlsUrl = data['u']?['hls']?['url'] as String? ?? data['ua']?['hls']?['auto']?['url'] as String?;
      if (hlsUrl != null && hlsUrl.isNotEmpty) {
        sources.add(
          StreamSource(
            url: hlsUrl,
            quality: 'HLS',
            server: serverHint ?? 'Rumble HLS',
          ),
        );
      }

      final q720 = data['ua']?['tar']?['720']?['url'] as String?;
      if (q720 != null) {
        sources.add(
          StreamSource(
            url: q720,
            quality: '720p',
            server: '${serverHint ?? "Rumble"} 720p',
          ),
        );
      }

      return sources;
    } catch (_) {
      return [];
    }
  }

  Future<List<StreamSource>> _resolveGenericEmbed(String url, {String? referer, String? serverHint}) async {
    final response = await _dio.get(
      url,
      options: Options(
        headers: referer != null ? {'Referer': referer} : {},
      ),
    );
    final html = response.data.toString();

    final m3u8Match = RegExp(r'''["'](https?://[^"']+\.m3u8[^"']*)["']''').firstMatch(html);
    if (m3u8Match != null) {
      return [
        StreamSource(
          url: m3u8Match.group(1)!,
          quality: 'Auto',
          server: serverHint ?? 'Embedded HLS',
          headers: {'Referer': url},
        ),
      ];
    }
    return [];
  }
}
