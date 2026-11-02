import 'show.dart';
import 'episode.dart';

class WatchHistoryItem {
  final Show show;
  final Episode episode;
  final int positionMs;
  final int durationMs;
  final DateTime updatedAt;

  const WatchHistoryItem({
    required this.show,
    required this.episode,
    required this.positionMs,
    required this.durationMs,
    required this.updatedAt,
  });

  double get progressPercentage {
    if (durationMs <= 0) return 0.0;
    final progress = positionMs / durationMs;
    return progress.clamp(0.0, 1.0);
  }

  bool get isCompleted => progressPercentage >= 0.92;

  Map<String, dynamic> toMap() {
    return {
      'show': show.toMap(),
      'episode': episode.toMap(),
      'positionMs': positionMs,
      'durationMs': durationMs,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory WatchHistoryItem.fromMap(Map<dynamic, dynamic> map) {
    return WatchHistoryItem(
      show: Show.fromMap(Map<String, dynamic>.from(map['show'] as Map? ?? {})),
      episode: Episode.fromMap(Map<String, dynamic>.from(map['episode'] as Map? ?? {})),
      positionMs: (map['positionMs'] as num?)?.toInt() ?? 0,
      durationMs: (map['durationMs'] as num?)?.toInt() ?? 0,
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

