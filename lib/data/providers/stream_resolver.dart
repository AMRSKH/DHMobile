import 'dart:convert';
import 'package:dio/dio.dart';
import '../../domain/models/stream_source.dart';

const String kDefaultUserAgent =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

class StreamResolver {
  final Dio _dio;

  StreamResolver({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              headers: {'User-Agent': kDefaultUserAgent},
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
            ),
          );

  Future<List<StreamSource>> resolve(
    String rawUrl, {
    String? serverHint,
    String? referer,
  }) async {
    String url = rawUrl.trim();
    if (url.isEmpty) return [];

    if (url.startsWith('//')) {
      url = 'https:$url';
    }

    // Skip cloud storage or dead hosters that do not provide direct media
    if (url.contains('mega.nz') ||
        url.contains('mega.io') ||
        url.contains('drive.google') ||
        url.contains('dropbox.com') ||
        url.contains('vvide0.com') ||
        url.contains('dood')) {
      return [];
    }

    // 1. Direct playable stream
    if (url.contains('.m3u8') || url.contains('.mp4') || url.contains('.mkv')) {
      return [
        StreamSource(
          url: url,
          quality: 'Direct',
          server: serverHint ?? 'Direct Server',
          headers: referer != null ? {'Referer': referer} : {},
        ),
      ];
    }

    // 2. OK.ru resolver (tested, verified, fastest high-speed MP4 streams)
    if (url.contains('ok.ru')) {
      final okSources = await _resolveOkRu(url, serverHint: serverHint);
      if (okSources.isNotEmpty) return okSources;
    }

    // 3. Dailymotion resolver
    if (url.contains('dailymotion.com')) {
      final dmSources = await _resolveDailymotion(url, serverHint: serverHint);
      if (dmSources.isNotEmpty) return dmSources;
    }

    // 4. Rumble resolver
    if (url.contains('rumble.com')) {
      final rumbleSources = await _resolveRumble(url, serverHint: serverHint);
      if (rumbleSources.isNotEmpty) return rumbleSources;
    }

    // 5. Generic embed resolver
    try {
      final embedSources = await _resolveGenericEmbed(
        url,
        referer: referer,
        serverHint: serverHint,
      );
      if (embedSources.isNotEmpty) return embedSources;
    } catch (_) {}

    return [];
  }

  Future<List<StreamSource>> _resolveOkRu(
    String url, {
    String? serverHint,
  }) async {
    try {
      final idMatch = RegExp(
        r'ok\.ru/(?:video|videoembed)/(\d+)',
      ).firstMatch(url);
      if (idMatch == null) return [];
      final videoId = idMatch.group(1)!;

      final embedUrl = 'https://ok.ru/videoembed/$videoId';
      final response = await _dio.get(
        embedUrl,
        options: Options(
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Referer': 'https://ok.ru/',
          },
        ),
      );
      final html = response.data.toString();

      final List<StreamSource> sources = [];

      // Parse data-options JSON (the official mobile/desktop video manifest)
      final optionsMatch = RegExp(
        r'''data-options=["']([^"']+)["']''',
      ).firstMatch(html);
      if (optionsMatch != null) {
        String raw = optionsMatch.group(1)!;
        raw = raw
            .replaceAll('&quot;', '"')
            .replaceAll('&amp;', '&')
            .replaceAll('&lt;', '<')
            .replaceAll('&gt;', '>');
        try {
          final js = json.decode(raw);
          final flashvars = js['flashvars'] as Map?;
          final metaVal = flashvars?['metadata'];
          Map? meta;
          if (metaVal is String) {
            meta = json.decode(metaVal);
          } else if (metaVal is Map) {
            meta = metaVal;
          }

          final videos = meta?['videos'] as List?;
          if (videos != null && videos.isNotEmpty) {
            for (final v in videos) {
              final name = v['name'] as String?;
              final vUrl = v['url'] as String?;
              if (vUrl != null && vUrl.isNotEmpty) {
                String qualityLabel = 'Auto';
                if (name == 'ultra') {
                  qualityLabel = '2160p';
                } else if (name == 'quad') {
                  qualityLabel = '1440p';
                } else if (name == 'full') {
                  qualityLabel = '1080p';
                } else if (name == 'hd') {
                  qualityLabel = '720p';
                } else if (name == 'sd') {
                  qualityLabel = '480p';
                } else if (name == 'low') {
                  qualityLabel = '360p';
                } else if (name == 'lowest') {
                  qualityLabel = '240p';
                } else if (name == 'mobile') {
                  qualityLabel = '144p';
                }

                sources.add(
                  StreamSource(
                    url: vUrl,
                    quality: qualityLabel,
                    server: '${serverHint ?? "OK.ru"} $qualityLabel',
                    headers: {
                      'User-Agent': kDefaultUserAgent,
                      'Referer': 'https://ok.ru/',
                    },
                  ),
                );
              }
            }
          }

          final hlsUrl = meta?['hlsMasterPlaylistUrl'] as String?;
          if (hlsUrl != null && hlsUrl.isNotEmpty) {
            sources.add(
              StreamSource(
                url: hlsUrl,
                quality: 'Auto HLS',
                server: '${serverHint ?? "OK.ru"} HLS',
                headers: {
                  'User-Agent': kDefaultUserAgent,
                  'Referer': 'https://ok.ru/',
                },
              ),
            );
          }
        } catch (_) {}
      }

      // Regex fallback if JSON was slightly different
      if (sources.isEmpty) {
        final decoded = html
            .replaceAll('&quot;', '"')
            .replaceAll(r'\u0026', '&')
            .replaceAll(r'\/', '/');
        final hdMatch = RegExp(
          r'"name"\s*:\s*"hd"\s*,\s*"url"\s*:\s*"([^"]+)"',
        ).firstMatch(decoded);
        if (hdMatch != null) {
          sources.add(
            StreamSource(
              url: hdMatch.group(1)!,
              quality: '720p',
              server: '${serverHint ?? "OK.ru"} 720p',
              headers: {
                'User-Agent': kDefaultUserAgent,
                'Referer': 'https://ok.ru/',
              },
            ),
          );
        }

        final sdMatch = RegExp(
          r'"name"\s*:\s*"sd"\s*,\s*"url"\s*:\s*"([^"]+)"',
        ).firstMatch(decoded);
        if (sdMatch != null) {
          sources.add(
            StreamSource(
              url: sdMatch.group(1)!,
              quality: '480p',
              server: '${serverHint ?? "OK.ru"} 480p',
              headers: {
                'User-Agent': kDefaultUserAgent,
                'Referer': 'https://ok.ru/',
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

  Future<List<StreamSource>> _resolveDailymotion(
    String url, {
    String? serverHint,
  }) async {
    try {
      String? videoId;
      final queryMatch = RegExp(r'[?&]video=([a-zA-Z0-9]+)').firstMatch(url);
      if (queryMatch != null) {
        videoId = queryMatch.group(1);
      } else {
        final pathMatch = RegExp(
          r'dailymotion\.com/(?:(?:embed/)?video/|videoembed/)?([a-zA-Z0-9]+)',
        ).firstMatch(url);
        if (pathMatch != null) {
          videoId = pathMatch.group(1);
        }
      }

      if (videoId == null || videoId.isEmpty) return [];

      final metaUrl =
          'https://www.dailymotion.com/player/metadata/video/$videoId';
      final response = await _dio.get(
        metaUrl,
        options: Options(
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Referer': 'https://geo.dailymotion.com/',
          },
        ),
      );
      final data = response.data is Map
          ? response.data
          : json.decode(response.data.toString());
      if (data['error'] != null) {
        return [];
      }

      final setCookies = response.headers['set-cookie'];
      final cookieHeader =
          setCookies?.map((c) => c.split(';').first).join('; ') ?? '';

      final streamHeaders = {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Referer': 'https://geo.dailymotion.com/',
        if (cookieHeader.isNotEmpty) 'Cookie': cookieHeader,
      };

      final List<StreamSource> sources = [];
      final autoQualities = data['qualities']?['auto'] as List?;
      if (autoQualities != null && autoQualities.isNotEmpty) {
        final m3u8Url = autoQualities.first['url'] as String?;
        if (m3u8Url != null && m3u8Url.isNotEmpty) {
          try {
            final manifestResp = await _dio.get(
              m3u8Url,
              options: Options(headers: streamHeaders),
            );
            final manifestText = manifestResp.data.toString();
            final lines = manifestText.split('\n');
            String? pendingQuality;

            for (var line in lines) {
              final trimmed = line.trim();
              if (trimmed.startsWith('#EXT-X-STREAM-INF:')) {
                final resMatch = RegExp(
                  r'RESOLUTION=(\d+x\d+)',
                ).firstMatch(trimmed);
                if (resMatch != null) {
                  final res = resMatch.group(1)!;
                  final height = res.split('x').last;
                  pendingQuality = '${height}p';
                } else {
                  pendingQuality = 'Auto';
                }
              } else if (trimmed.isNotEmpty && !trimmed.startsWith('#')) {
                final streamUri = Uri.parse(
                  m3u8Url,
                ).resolve(trimmed).toString();
                sources.add(
                  StreamSource(
                    url: streamUri,
                    quality: pendingQuality ?? 'Auto',
                    server:
                        '${serverHint ?? 'Dailymotion'} ${pendingQuality ?? 'Direct'}',
                    headers: streamHeaders,
                  ),
                );
                pendingQuality = null;
              }
            }
          } catch (_) {}

          // Also keep master manifest as fallback
          sources.add(
            StreamSource(
              url: m3u8Url,
              quality: 'Multi-Bitrate (HLS)',
              server: serverHint ?? 'Dailymotion Fast',
              headers: streamHeaders,
            ),
          );
        }
      }
      return sources;
    } catch (_) {
      return [];
    }
  }

  Future<List<StreamSource>> _resolveRumble(
    String url, {
    String? serverHint,
  }) async {
    try {
      final idMatch = RegExp(
        r'rumble\.com/embed/([a-zA-Z0-9]+)',
      ).firstMatch(url);
      if (idMatch == null) return [];
      final videoId = idMatch.group(1)!;

      final apiUrl =
          'https://rumble.com/embedJS/u3/?request=video&ver=2&v=$videoId';
      final response = await _dio.get(apiUrl);
      final data = response.data is Map
          ? response.data
          : json.decode(response.data.toString());

      final List<StreamSource> sources = [];
      final hlsUrl =
          data['u']?['hls']?['url'] as String? ??
          data['ua']?['hls']?['auto']?['url'] as String?;
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

  Future<List<StreamSource>> _resolveGenericEmbed(
    String url, {
    String? referer,
    String? serverHint,
  }) async {
    final response = await _dio.get(
      url,
      options: Options(headers: referer != null ? {'Referer': referer} : {}),
    );
    final html = response.data.toString();

    final m3u8Match = RegExp(
      r'''["'](https?://[^"']+\.m3u8[^"']*)["']''',
    ).firstMatch(html);
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

    final mp4Match = RegExp(
      r'''["'](https?://[^"']+\.mp4[^"']*)["']''',
    ).firstMatch(html);
    if (mp4Match != null) {
      return [
        StreamSource(
          url: mp4Match.group(1)!,
          quality: 'Direct MP4',
          server: serverHint ?? 'Embedded Video',
          headers: {'Referer': url},
        ),
      ];
    }

    return [];
  }
}
