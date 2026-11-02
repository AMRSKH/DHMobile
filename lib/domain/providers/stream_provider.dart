import '../models/show.dart';
import '../models/episode.dart';
import '../models/stream_source.dart';

abstract class DonghuaStreamProvider {
  String get id;
  String get name;

  Future<List<Show>> search(String query);
  Future<List<Episode>> episodes(String showId);
  Future<List<StreamSource>> streams(String episodeId);
}
