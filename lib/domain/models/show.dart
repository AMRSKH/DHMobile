class Show {
  final String id;
  final String title;
  final String poster;
  final String? episodeCount;
  final String? synopsis;
  final List<String> genres;
  final String? status;
  final String providerId;

  const Show({
    required this.id,
    required this.title,
    required this.poster,
    this.episodeCount,
    this.synopsis,
    this.genres = const [],
    this.status,
    required this.providerId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'poster': poster,
      'episodeCount': episodeCount,
      'synopsis': synopsis,
      'genres': genres,
      'status': status,
      'providerId': providerId,
    };
  }

  factory Show.fromMap(Map<String, dynamic> map) {
    return Show(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      poster: map['poster'] as String? ?? '',
      episodeCount: map['episodeCount'] as String?,
      synopsis: map['synopsis'] as String?,
      genres: List<String>.from(map['genres'] as List? ?? const []),
      status: map['status'] as String?,
      providerId: map['providerId'] as String? ?? 'default',
    );
  }
}

