import 'dart:async';

import '../../core/debug_log.dart';
import '../../domain/models/content_source.dart';
import '../../domain/models/episode.dart';
import '../../domain/models/schedule_entry.dart';
import '../../domain/models/show.dart';
import '../../domain/models/stream_source.dart';
import '../../domain/providers/stream_provider.dart';
import 'anime_stream_site_provider.dart';
import 'animexin_stream_provider.dart';

/// One provider per entry of [kContentSources], in the same order. AnimeXin
/// gets its own class for the built-in fallback catalog.
List<AnimeStreamSiteProvider> defaultSources() => [
  for (final source in kContentSources)
    source.id == 'animexin'
        ? AnimeXinStreamProvider()
        : AnimeStreamSiteProvider(
            id: source.id,
            name: source.name,
            baseUrl: source.baseUrl,
          ),
];

/// Searches every source at once and sends a show's episodes and streams to
/// the site the show came from. Explore (schedule, new, popular) comes from
/// the main source only: the other sites do not share its listing pages.
class MultiSourceStreamProvider implements DonghuaStreamProvider {
  /// In priority order. The first is the main source.
  final List<AnimeStreamSiteProvider> sources;

  /// A source that has not answered by then is left out of the results.
  final Duration searchTimeout;

  MultiSourceStreamProvider({
    List<AnimeStreamSiteProvider>? sources,
    this.searchTimeout = const Duration(seconds: 12),
  }) : sources = sources ?? defaultSources() {
    if (this.sources.isEmpty) {
      throw ArgumentError.value(sources, 'sources', 'must not be empty');
    }
  }

  AnimeStreamSiteProvider get primary => sources.first;

  @override
  String get id => 'multi';

  @override
  String get name => sources.map((s) => s.name).join(', ');

  @override
  Future<List<Show>> search(String query) async {
    final cleanQuery = query.trim();
    // Without a query the main source shows its popular list.
    if (cleanQuery.isEmpty) return primary.search('');

    final perSource = await Future.wait(
      sources.map((source) => _searchOne(source, cleanQuery)),
    );
    final merged = mergeSearchResults(perSource);
    DLog.event(
      'search.multi',
      'q="$cleanQuery" '
          '${[for (var i = 0; i < sources.length; i++) '${sources[i].id}=${perSource[i].length}'].join(' ')} '
          'merged=${merged.length}',
    );
    return merged;
  }

  /// One source's results. A source that fails or is too slow is a skip, so
  /// the others still answer.
  Future<List<Show>> _searchOne(
    AnimeStreamSiteProvider source,
    String query,
  ) async {
    try {
      return await source.search(query).timeout(searchTimeout);
    } catch (e) {
      DLog.event('search.multi', '${source.id} skipped: $e');
      return const <Show>[];
    }
  }

  @override
  Future<Map<int, List<ScheduleEntry>>> schedule() => primary.schedule();

  @override
  Future<List<Show>> newSeries() => primary.newSeries();

  @override
  Future<List<Show>> popular() => primary.popular();

  @override
  Future<List<Episode>> episodes(String showId) =>
      sourceFor(showId).episodes(showId);

  @override
  Future<List<StreamSource>> streams(String episodeId) =>
      sourceFor(episodeId).streams(episodeId);

  /// The source whose site [url] is on. Show and episode ids are page URLs.
  /// An unknown host goes to the main source, as every id did before there
  /// were several sources.
  AnimeStreamSiteProvider sourceFor(String url) {
    for (final source in sources) {
      if (source.owns(url)) return source;
    }
    return primary;
  }
}

/// Joins the result lists of several sources (in priority order) into one.
///
/// The best match of every source comes before the second best of any, so a
/// lower source still shows near the top. A series that several sources
/// carry stays in one group, at the place of its first hit, in the order the
/// hits came.
/// The same URL twice is kept once.
List<Show> mergeSearchResults(List<List<Show>> perSource) {
  final groups = <String, List<Show>>{};
  final seenUrls = <String>{};
  final longest = perSource.fold<int>(0, (m, l) => l.length > m ? l.length : m);

  for (var rank = 0; rank < longest; rank++) {
    for (final results in perSource) {
      if (rank >= results.length) continue;
      final show = results[rank];
      if (!seenUrls.add(show.id)) continue;
      groups.putIfAbsent(normalizeShowTitle(show.title), () => []).add(show);
    }
  }
  return [for (final group in groups.values) ...group];
}

final RegExp _bracketNoise = RegExp(
  r'[\[\(]\s*(?:temporary|new|eng(?:lish)? sub(?:bed)?|sub)\s*[\]\)]',
  caseSensitive: false,
);
final RegExp _nonWord = RegExp(r'[^a-z0-9]+');

/// A title key that treats "Renegade Immortal [ Temporary ]" and
/// "renegade immortal" as the same series. Season numbers and the rest of
/// the words stay, so different seasons stay apart.
///
/// A title without Latin letters or digits (for example "仙逆") keeps its
/// own trimmed text, so such titles do not all share one empty key.
String normalizeShowTitle(String title) {
  final key = title
      .toLowerCase()
      .replaceAll(_bracketNoise, ' ')
      .replaceAll(_nonWord, ' ')
      .trim();
  return key.isEmpty ? title.trim() : key;
}
