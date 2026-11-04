import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:donghua_player/data/providers/stream_source_filter.dart';
import 'package:donghua_player/domain/models/stream_source.dart';

class _FakeAdapter implements HttpClientAdapter {
  final Map<String, List<_Reply>> replies;
  final Map<String, int> calls = {};

  _FakeAdapter(this.replies);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final url = options.uri.toString();
    final key = '$url|${options.method}';
    calls[key] = (calls[key] ?? 0) + 1;

    final queue = replies[key];
    if (queue == null || queue.isEmpty) {
      throw DioException(
        requestOptions: options,
        message: 'No fake reply for $key',
      );
    }

    final reply = queue.length > 1 ? queue.removeAt(0) : queue.first;
    return ResponseBody.fromString(
      '',
      reply.statusCode,
      headers: {
        Headers.contentTypeHeader: [reply.contentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _Reply {
  final int statusCode;
  final String contentType;

  const _Reply(this.statusCode, this.contentType);
}

StreamSourceFilter _filterWith(Map<String, List<_Reply>> replies) {
  final dio = Dio()..httpClientAdapter = _FakeAdapter(replies);
  return StreamSourceFilter(dio: dio);
}

void main() {
  test('keeps only reachable media sources and removes duplicates', () async {
    final filter = _filterWith({
      'https://cdn.test/a.m3u8|HEAD': [
        const _Reply(200, 'application/vnd.apple.mpegurl'),
      ],
      'https://cdn.test/b.mp4|HEAD': [const _Reply(404, 'text/html')],
      'https://cdn.test/page|HEAD': [const _Reply(200, 'text/html')],
    });

    final result = await filter.filter(const [
      StreamSource(url: 'https://cdn.test/a.m3u8'),
      StreamSource(url: 'https://cdn.test/a.m3u8'),
      StreamSource(url: 'https://cdn.test/b.mp4'),
      StreamSource(url: 'https://cdn.test/page'),
    ]);

    expect(result, hasLength(1));
    expect(result.single.url, 'https://cdn.test/a.m3u8');
  });

  test('retries with GET when the server rejects HEAD', () async {
    final filter = _filterWith({
      'https://cdn.test/c.mp4|HEAD': [const _Reply(405, 'text/plain')],
      'https://cdn.test/c.mp4|GET': [const _Reply(206, 'video/mp4')],
    });

    final result = await filter.filter(const [
      StreamSource(url: 'https://cdn.test/c.mp4'),
    ]);

    expect(result, hasLength(1));
  });

  test('accepts a media content type even without a file extension', () async {
    final filter = _filterWith({
      'https://cdn.test/play?token=1|HEAD': [const _Reply(200, 'video/mp4')],
    });

    final result = await filter.filter(const [
      StreamSource(url: 'https://cdn.test/play?token=1'),
    ]);

    expect(result, hasLength(1));
  });

  test('returns an empty list when every source fails', () async {
    final filter = _filterWith({
      'https://cdn.test/x.m3u8|HEAD': [const _Reply(500, 'text/plain')],
    });

    final result = await filter.filter(const [
      StreamSource(url: 'https://cdn.test/x.m3u8'),
    ]);

    expect(result, isEmpty);
  });
}
