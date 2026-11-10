import '../../domain/models/stream_source.dart';

/// When the player starts resolving the next episode's servers in the
/// background (TASK-031): once 60 % of the current episode has played, or
/// when less than 3 minutes are left. Resolving takes several seconds, so
/// "Next" then starts at once. Not earlier, because stream URLs expire.
bool shouldPrefetchNext({
  required Duration position,
  required Duration duration,
}) {
  if (duration <= Duration.zero || position <= Duration.zero) return false;
  final left = duration - position;
  return position.inMilliseconds >= duration.inMilliseconds * 0.6 ||
      left <= const Duration(minutes: 3);
}

/// Whether "Next" may start from the prefetched [sources]: they arrived, are
/// not empty, and are at most [maxAge] old (stream URLs expire, and OK.ru's
/// are bound to the public IP).
bool usePrefetched({
  required List<StreamSource>? sources,
  required DateTime? fetchedAt,
  required DateTime now,
  Duration maxAge = const Duration(minutes: 20),
}) {
  if (sources == null || sources.isEmpty || fetchedAt == null) return false;
  return now.difference(fetchedAt) <= maxAge;
}
