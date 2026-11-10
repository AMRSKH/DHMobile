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

  Future<List<Episode>> episodes(String showId);
  Future<List<StreamSource>> streams(String episodeId);
}
