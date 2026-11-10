import 'package:donghua_player/domain/models/episode.dart';
import 'package:donghua_player/domain/models/schedule_entry.dart';
import 'package:donghua_player/domain/models/show.dart';
import 'package:donghua_player/domain/models/stream_source.dart';
import 'package:donghua_player/domain/providers/stream_provider.dart';

/// A show without a poster, so a widget test never asks for an image.
Show fakeShow(String slug, {String? title, String? status, String? episode}) {
  return Show(
    id: 'https://example.test/$slug/',
    title: title ?? 'Show $slug',
    poster: '',
    status: status,
    episodeCount: episode,
    providerId: 'fake',
  );
}

/// A week with every key from 1 to 7. Days that are not given are empty.
Map<int, List<ScheduleEntry>> fakeWeek([
  Map<int, List<ScheduleEntry>> days = const {},
]) {
  return {
    for (var day = 1; day <= 7; day++) day: days[day] ?? <ScheduleEntry>[],
  };
}

/// One show per weekday, titled "Day 1 Show" to "Day 7 Show".
Map<int, List<ScheduleEntry>> fakeWeekOnePerDay() {
  return {
    for (var day = 1; day <= 7; day++)
      day: [
        ScheduleEntry(
          show: fakeShow(
            'day-$day',
            title: 'Day $day Show',
            episode: 'EP $day',
          ),
          released: true,
          releaseText: 'released',
        ),
      ],
  };
}

List<Episode> fakeEpisodes(String showId, int count) {
  return [
    for (var n = 1; n <= count; n++)
      Episode(
        id: '$showId#ep-$n',
        number: n.toDouble(),
        title: 'Episode $n',
        showId: showId,
      ),
  ];
}

/// In-memory source for controller and widget tests. Every answer comes from
/// a callback, so a test can return data, throw, or hold the answer back
/// with a `Completer`. Nothing here touches the network.
class FakeStreamProvider implements DonghuaStreamProvider {
  Future<Map<int, List<ScheduleEntry>>> Function() onSchedule;
  Future<List<Show>> Function() onNewSeries;
  Future<List<Show>> Function() onPopular;
  Future<List<Show>> Function(String query) onSearch;
  Future<List<Episode>> Function(String showId) onEpisodes;

  int scheduleCalls = 0;
  int newSeriesCalls = 0;
  int popularCalls = 0;
  final List<String> searchQueries = [];
  final List<String> episodeRequests = [];

  FakeStreamProvider({
    Future<Map<int, List<ScheduleEntry>>> Function()? onSchedule,
    Future<List<Show>> Function()? onNewSeries,
    Future<List<Show>> Function()? onPopular,
    Future<List<Show>> Function(String query)? onSearch,
    Future<List<Episode>> Function(String showId)? onEpisodes,
  }) : onSchedule = onSchedule ?? (() async => fakeWeekOnePerDay()),
       onNewSeries =
           onNewSeries ??
           (() async => [
             fakeShow('new-1', title: 'New One', status: 'Upcoming'),
             fakeShow('new-2', title: 'New Two', status: 'Ongoing'),
           ]),
       onPopular =
           onPopular ??
           (() async => [
             fakeShow('pop-1', title: 'Popular One', status: 'Completed'),
             fakeShow('pop-2', title: 'Popular Two', status: 'Ongoing'),
           ]),
       onSearch = onSearch ?? ((query) async => const <Show>[]),
       onEpisodes = onEpisodes ?? ((showId) async => fakeEpisodes(showId, 3));

  @override
  String get id => 'fake';

  @override
  String get name => 'Fake';

  @override
  Future<Map<int, List<ScheduleEntry>>> schedule() {
    scheduleCalls++;
    return onSchedule();
  }

  @override
  Future<List<Show>> newSeries() {
    newSeriesCalls++;
    return onNewSeries();
  }

  @override
  Future<List<Show>> popular() {
    popularCalls++;
    return onPopular();
  }

  @override
  Future<List<Show>> search(String query) {
    searchQueries.add(query);
    return onSearch(query);
  }

  @override
  Future<List<Episode>> episodes(String showId) {
    episodeRequests.add(showId);
    return onEpisodes(showId);
  }

  @override
  Future<List<StreamSource>> streams(String episodeId) async => const [];
}
