class Episode {
  final String id;
  final double number;
  final String title;
  final String showId;
  final String? uploadDate;

  const Episode({
    required this.id,
    required this.number,
    required this.title,
    required this.showId,
    this.uploadDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'number': number,
      'title': title,
      'showId': showId,
      'uploadDate': uploadDate,
    };
  }

  factory Episode.fromMap(Map<String, dynamic> map) {
    return Episode(
      id: map['id'] as String? ?? '',
      number: (map['number'] as num?)?.toDouble() ?? 0.0,
      title: map['title'] as String? ?? '',
      showId: map['showId'] as String? ?? '',
      uploadDate: map['uploadDate'] as String?,
    );
  }
}
