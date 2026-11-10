import '../models/show.dart';
import '../models/episode.dart';
import '../models/schedule_entry.dart';
import '../models/stream_source.dart';

abstract class DonghuaStreamProvider {
  String get id;
  String get name;

  Future<List<Show>> search(String query);

  /// The weekly schedule. Keys 1 (Monday) to 7 (Sunday), all present.
  /// Throws when the source cannot be read.
  Future<Map<int, List<ScheduleEntry>>> schedule();

  /// The series the source added last, newest first.
  /// Throws when the source cannot be read.
  Future<List<Show>> newSeries();

  /// The series in the source's popular order.
  /// Throws when the source cannot be read.
  Future<List<Show>> popular();

  /// Every completed series, as a list that grows while more pages arrive:
  /// each event is the whole list so far. The stream ends when every page is
  /// read, and fails only when not a single page could be read (TASK-036).
  Stream<List<Show>> completed();

  Future<List<Episode>> episodes(String showId);
  Future<List<StreamSource>> streams(String episodeId);
}
