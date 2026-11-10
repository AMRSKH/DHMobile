import 'package:dio/dio.dart';

import '../../domain/models/stream_source.dart';

/// Extensions that always indicate a playable media file.
const Set<String> kPlayableExtensions = {'m3u8', 'mp4', 'mkv', 'webm', 'mpd'};

/// Content types that a media server returns for a playable stream.
const List<String> kPlayableContentTypes = [
  'video/',
  'audio/',
  'application/vnd.apple.mpegurl',
  'application/x-mpegurl',
  'application/dash+xml',
  'application/octet-stream',
];

/// Removes duplicate, dead, and non-media stream sources before the player
/// shows them. Only sources that respond with a playable media type are kept.
class StreamSourceFilter {
  final Dio _dio;
  final Duration timeout;

  StreamSourceFilter({Dio? dio, this.timeout = const Duration(seconds: 4)})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 4),
              receiveTimeout: const Duration(seconds: 4),
              validateStatus: (_) => true,
            ),
          );

  /// Hosts of OK.ru's video CDN. Their URLs come straight from OK.ru's own
  /// metadata a moment earlier, so they are kept without a probe: probing
  /// them cost time and, when a probe timed out, dropped working qualities
  /// (TASK-031). A dead one is still caught by failover and re-resolve.
  static const List<String> trustedHosts = [
    'vkuser.net',
    'okcdn.ru',
    'mycdn.me',
  ];

  static bool isTrusted(StreamSource source) {
    final host = Uri.tryParse(source.url)?.host.toLowerCase() ?? '';
    return trustedHosts.any(
      (trusted) => host == trusted || host.endsWith('.$trusted'),
    );
  }

  Future<List<StreamSource>> filter(List<StreamSource> sources) async {
    final unique = <StreamSource>[];
    final seen = <String>{};

    for (final source in sources) {
      final url = source.url.trim();
      if (url.isEmpty) continue;
      if (seen.add(url)) {
        unique.add(source);
      }
    }

    if (unique.isEmpty) return const [];

    final results = await Future.wait(
      unique.map(
        (source) async => isTrusted(source) || await _isPlayable(source),
      ),
    );

    return [
      for (var i = 0; i < unique.length; i++)
        if (results[i]) unique[i],
    ];
  }

  Future<bool> _isPlayable(StreamSource source) async {
    final head = await _send(source, method: 'HEAD', headers: source.headers);

    if (head == null) return false;

    if (_isSuccess(head.statusCode)) {
      if (_isHtml(head)) return false;
      if (_hasPlayableType(head, source.url)) return true;
      // Unknown type: confirm with a ranged GET below.
    } else if (head.statusCode != 405 && head.statusCode != 501) {
      // Some media servers reject HEAD but serve the stream over GET.
      return false;
    }

    final get = await _send(
      source,
      method: 'GET',
      headers: {...source.headers, 'Range': 'bytes=0-1'},
      stream: true,
    );

    if (get == null) return false;
    return _isSuccess(get.statusCode) && _hasPlayableType(get, source.url);
  }

  Future<_ProbeResult?> _send(
    StreamSource source, {
    required String method,
    required Map<String, String> headers,
    bool stream = false,
  }) async {
    try {
      final response = await _dio.request<dynamic>(
        source.url,
        options: Options(
          method: method,
          headers: headers,
          followRedirects: true,
          validateStatus: (_) => true,
          receiveTimeout: timeout,
          sendTimeout: timeout,
          responseType: stream ? ResponseType.stream : ResponseType.plain,
        ),
      );

      if (stream) {
        final body = response.data;
        if (body is ResponseBody) {
          try {
            await body.stream.listen((_) {}, cancelOnError: true).cancel();
          } catch (_) {}
        }
      }

      return _ProbeResult(
        statusCode: response.statusCode ?? 0,
        contentType: response.headers.value(Headers.contentTypeHeader),
      );
    } catch (_) {
      return null;
    }
  }

  bool _isSuccess(int? statusCode) {
    return statusCode != null && statusCode >= 200 && statusCode < 400;
  }

  bool _hasPlayableType(_ProbeResult result, String url) {
    final contentType = (result.contentType ?? '').toLowerCase();
    if (contentType.isEmpty) {
      // No header: trust a known media extension only.
      return _hasPlayableExtension(url);
    }
    if (contentType.contains('text/html')) return false;
    if (kPlayableContentTypes.any(contentType.contains)) return true;
    return _hasPlayableExtension(url);
  }

  bool _isHtml(_ProbeResult result) {
    return (result.contentType ?? '').toLowerCase().contains('text/html');
  }

  bool _hasPlayableExtension(String url) {
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? url.toLowerCase();
    return kPlayableExtensions.any((ext) => path.endsWith('.$ext'));
  }
}

class _ProbeResult {
  final int statusCode;
  final String? contentType;

  const _ProbeResult({required this.statusCode, this.contentType});
}
