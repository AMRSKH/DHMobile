class SubtitleTrack {
  final String language;
  final String url;

  const SubtitleTrack({
    required this.language,
    required this.url,
  });

  Map<String, dynamic> toMap() => {'language': language, 'url': url};

  factory SubtitleTrack.fromMap(Map<String, dynamic> map) => SubtitleTrack(
        language: map['language'] as String? ?? 'Default',
        url: map['url'] as String? ?? '',
      );
}

class StreamSource {
  final String url;
  final String quality;
  final Map<String, String> headers;
  final List<SubtitleTrack> subtitles;
  final String? server;

  const StreamSource({
    required this.url,
    this.quality = 'Default',
    this.headers = const {},
    this.subtitles = const [],
    this.server,
  });
}
