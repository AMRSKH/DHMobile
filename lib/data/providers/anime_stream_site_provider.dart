import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;
import '../../domain/models/show.dart';
import '../../domain/models/episode.dart';
import '../../domain/models/schedule_entry.dart';
import '../../domain/models/stream_source.dart';
import '../../domain/providers/stream_provider.dart';
import '../../core/debug_log.dart';
import 'animexin_listing_parser.dart';
import 'stream_resolver.dart';
import 'stream_source_filter.dart';

const String kMobileUserAgent =
    'Mozilla/5.0 (Linux; Android 11; Pixel 5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';

/// A donghua site built on the "AnimeStream" WordPress theme. AnimeXin,
/// DonghuaWorld, LuciferDonghua, DonghuaStream, and LMAnime all use it, so
/// one parser reads all of them (the same finding as DonghuaCLI's source
/// plugins, checked against each site on 2026-11-10, TASK-021):
///
/// - search: `/?s=<query>`, one `article.bs` card per series
/// - episodes: `.eplister ul li` with `.epl-num`, `.epl-title`, `.epl-date`
/// - servers: `select.mirror option` values (base64 iframe HTML) and the
///   `.player-embed iframe`
class AnimeStreamSiteProvider implements DonghuaStreamProvider {
  @override
  final String id;

  @override
  final String name;

  /// For example `https://animexin.dev`, without a trailing slash.
  final String baseUrl;

  final Dio _dio;

  AnimeStreamSiteProvider({
    required this.id,
    required this.name,
    required this.baseUrl,
    Dio? dio,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: baseUrl,
               connectTimeout: const Duration(seconds: 10),
               receiveTimeout: const Duration(seconds: 15),
               headers: {
                 'User-Agent': kMobileUserAgent,
                 'Referer': '$baseUrl/',
                 'Accept':
                     'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
               },
             ),
           );

  /// The host of [baseUrl], for example `animexin.dev`.
  String get host => Uri.parse(baseUrl).host;

  /// True when [url] is a page of this site (also with a `www.` prefix).
  bool owns(String url) {
    final urlHost = Uri.tryParse(url)?.host ?? '';
    return urlHost == host || urlHost == 'www.$host';
  }

  /// The series that match [query]. Throws when the site cannot be read;
  /// an empty query gives an empty list.
  @override
  Future<List<Show>> search(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return const [];

    final html = await fetchPage('/', queryParameters: {'s': cleanQuery});
    final results = parseSearchResults(html, providerId: id, baseUrl: baseUrl);
    DLog.event('search', '$id q="$cleanQuery" unique=${results.length}');
    return results;
  }

  @override
  Future<Map<int, List<ScheduleEntry>>> schedule() async {
    final schedule = parseSchedule(
      await fetchPage('/schedule/'),
      providerId: id,
    );
    final total = schedule.values.fold<int>(0, (sum, day) => sum + day.length);
    DLog.event(
      'schedule',
      '$id total=$total days=${[for (var d = 1; d <= 7; d++) schedule[d]!.length].join(',')}',
    );
    // One empty day is normal. No show at all means the page has changed.
    if (total == 0) {
      throw const FormatException('The schedule page has no shows');
    }
    return schedule;
  }

  @override
  Future<List<Show>> newSeries() => _seriesList('latest');

  @override
  Future<List<Show>> popular() => _seriesList('popular');

  /// Pages read at most by [completedPages], against a loop of "Next" links.
  static const int maxCompletedPages = 40;

  @override
  Stream<List<Show>> completed() async* {
    final all = <Show>[];
    await for (final page in completedPages()) {
      all.addAll(page);
      yield List.unmodifiable(all);
    }
  }

  /// The site's completed series, one event per listing page
  /// (`/anime/?page=N&status=completed&order=update`), until a page has no
  /// "Next" link or no new series. A failing first page is an error; a later
  /// one ends the list (TASK-036).
  Stream<List<Show>> completedPages() async* {
    final seen = <String>{};
    for (var page = 1; page <= maxCompletedPages; page++) {
      final String html;
      try {
        html = await fetchPage(
          '/anime/',
          queryParameters: {
            'page': page,
            'status': 'completed',
            'order': 'update',
          },
        );
      } catch (e) {
        if (page == 1) rethrow;
        DLog.event('completed', '$id page $page failed, stopping: $e');
        return;
      }
      final shows = [
        for (final show in parseSeriesList(html, providerId: id))
          if (seen.add(show.id)) show,
      ];
      DLog.event('completed', '$id page=$page new=${shows.length}');
      if (shows.isEmpty) return;
      yield shows;
      if (!hasNextPage(html)) return;
    }
  }

  /// The first page of the series listing in the given order. A failure is
  /// thrown, so the screen can show it with a retry.
  Future<List<Show>> _seriesList(String order) async {
    final shows = parseSeriesList(
      await fetchPage('/anime/', queryParameters: {'order': order}),
      providerId: id,
    );
    DLog.event('seriesList', '$id order=$order count=${shows.length}');
    if (shows.isEmpty) {
      throw FormatException('The "$order" listing has no series');
    }
    return shows;
  }

  Future<String> fetchPage(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.get<String>(
      path,
      queryParameters: queryParameters,
      options: Options(responseType: ResponseType.plain),
    );
    return response.data ?? '';
  }

  @override
  Future<List<Episode>> episodes(String showId) async {
    try {
      final response = await _dio.get(showId);
      final document = html_parser.parse(response.data);

      final items = document.querySelectorAll(
        '.eplister ul li, .episodelist ul li',
      );
      final List<Episode> episodeList = [];
      final Set<String> seenUrls = {};

      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        final a = item.querySelector('a');
        final numEl = item.querySelector('.epl-num');
        final titleEl = item.querySelector('.epl-title');
        final dateEl = item.querySelector('.epl-date');

        final epUrl = absoluteUrl(a?.attributes['href'] ?? '', baseUrl);
        final epNumStr = numEl?.text.trim() ?? '${items.length - i}';
        final epTitle = titleEl?.text.trim() ?? 'Episode $epNumStr';
        final epNum =
            double.tryParse(
              RegExp(r'^\d+').firstMatch(epNumStr)?.group(0) ?? '',
            ) ??
            (items.length - i).toDouble();

        if (epUrl.isNotEmpty && seenUrls.add(epUrl)) {
          episodeList.add(
            Episode(
              id: epUrl,
              number: epNum,
              title: epTitle,
              showId: showId,
              uploadDate: dateEl?.text.trim(),
            ),
          );
        }
      }

      if (episodeList.isNotEmpty) {
        episodeList.sort((a, b) => a.number.compareTo(b.number));
        DLog.event(
          'episodes',
          '$id show=$showId nodes=${items.length} '
              'unique=${episodeList.length} '
              'first=${episodeList.first.number.toInt()} '
              'last=${episodeList.last.number.toInt()} '
              'lastTitle="${episodeList.last.title}"',
        );
        return episodeList;
      }
      DLog.event('episodes', '$id show=$showId nodes=${items.length} empty');
    } catch (e, st) {
      DLog.error('episodes', e, st);
    }

    // Do not invent episodes when scraping fails: fake IDs cannot be played
    // and would send the user into a dead player screen.
    return const [];
  }

  @override
  Future<List<StreamSource>> streams(String episodeId) async {
    final List<StreamSource> rawCandidates = [];
    final resolver = StreamResolver();
    final pageHeaders = {
      'Referer': episodeId,
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    };

    try {
      final response = await _dio.get(episodeId);
      final document = html_parser.parse(response.data);

      final options = document.querySelectorAll(
        'select.mirror option, .mirror select option',
      );
      for (final opt in options) {
        final rawVal = opt.attributes['value'] ?? '';
        final serverName = opt.text.trim();
        if (rawVal.isEmpty) continue;

        String decoded = rawVal;
        try {
          if (!rawVal.startsWith('http') && !rawVal.startsWith('<')) {
            decoded = utf8.decode(base64.decode(rawVal));
          }
        } catch (_) {}

        final iframeMatch = RegExp(
          r'''src=["']([^"']+)["']''',
        ).firstMatch(decoded);
        String? streamUrl =
            iframeMatch?.group(1) ??
            (decoded.startsWith('http') || decoded.startsWith('//')
                ? decoded
                : null);
        if (streamUrl != null && streamUrl.startsWith('//')) {
          streamUrl = 'https:$streamUrl';
        }

        if (streamUrl != null && streamUrl.isNotEmpty) {
          rawCandidates.add(
            StreamSource(
              url: streamUrl,
              quality: 'Multi-Quality',
              server: serverName.isNotEmpty ? serverName : 'Mirror',
              headers: pageHeaders,
            ),
          );
        }
      }

      final iframes = document.querySelectorAll(
        '.player-embed iframe, iframe.player-iframe',
      );
      for (final iframe in iframes) {
        String? src = iframe.attributes['src'] ?? iframe.attributes['data-src'];
        if (src != null && src.isNotEmpty) {
          if (src.startsWith('//')) src = 'https:$src';
          rawCandidates.add(
            StreamSource(
              url: src,
              quality: 'Auto',
              server: 'Primary Embed',
              headers: pageHeaders,
            ),
          );
        }
      }
    } catch (e) {
      // One unreadable episode page is a skip: the caller shows "no streams".
      DLog.event('streams.page', '$id $episodeId failed: $e');
    }

    // The page often names one embed twice ("Primary Embed" and its menu
    // entry). Resolve each URL once; the first, named entry wins (TASK-031).
    final seenUrls = <String>{};
    final candidates = [
      for (final c in rawCandidates)
        if (seenUrls.add(c.url)) c,
    ];

    final List<StreamSource> resolvedSources = [];
    if (candidates.isNotEmpty) {
      final results = await Future.wait(
        candidates.map((c) async {
          try {
            final resolved = await resolver.resolve(
              c.url,
              serverHint: c.server,
              referer: episodeId,
            );
            DLog.event('resolve', '${c.server} ${c.url} -> ${resolved.length}');
            return resolved;
          } catch (e) {
            DLog.event('resolve', '${c.server} ${c.url} ERROR $e');
            return <StreamSource>[];
          }
        }),
      );
      for (final list in results) {
        resolvedSources.addAll(list);
      }
    }

    // Only expose sources that actually respond with playable media.
    DLog.event(
      'streams.raw',
      '$id candidates=${rawCandidates.length} '
          'resolved=${resolvedSources.length} episode=$episodeId',
    );
    if (resolvedSources.isEmpty) return const [];
    final filtered = [
      for (final s in await StreamSourceFilter().filter(resolvedSources))
        s.copyWith(sourceName: name),
    ];
    DLog.event(
      'streams.ready',
      'kept=${filtered.length} '
          'servers=${filtered.map((s) => '${s.server}/${s.quality}').join(',')}',
    );
    return filtered;
  }
}

/// The series cards of an AnimeStream search page.
///
/// A relative link is made absolute against [baseUrl], because show ids are
/// routed to their source by host.
List<Show> parseSearchResults(
  String html, {
  required String providerId,
  String? baseUrl,
}) {
  final document = html_parser.parse(html);
  // `.bsx` is nested inside `article.bs`, so matching both would add every
  // result twice. Dedupe by URL as a second guard.
  final articles = document.querySelectorAll('article.bs, .listupd article');

  final List<Show> results = [];
  final seenUrls = <String>{};
  for (final article in articles) {
    final linkEl = article.querySelector('a');
    final titleEl = article.querySelector('.tt h2, .tt, h2, .entry-title');
    final imgEl = article.querySelector('img');
    final epEl = article.querySelector('.epx, .bt .ep');

    final href = linkEl?.attributes['href'] ?? '';
    final url = baseUrl == null ? href : absoluteUrl(href, baseUrl);
    final linkTitle = linkEl?.attributes['title']?.trim() ?? '';
    // `.tt` contains both a text node and an `<h2>` with the same title,
    // so prefer the link title to avoid duplicated text.
    final title = linkTitle.isNotEmpty
        ? linkTitle
        : (titleEl?.text.trim() ?? '');
    final poster =
        imgEl?.attributes['data-src'] ?? imgEl?.attributes['src'] ?? '';
    final epCount = epEl?.text.trim();

    if (url.isNotEmpty && title.isNotEmpty && seenUrls.add(url)) {
      results.add(
        Show(
          id: url,
          title: title,
          poster: poster,
          episodeCount: epCount,
          providerId: providerId,
        ),
      );
    }
  }
  return results;
}

/// [href] as an absolute URL, resolved against [baseUrl] when it is
/// relative. An empty or unparsable [href] is returned as it is.
String absoluteUrl(String href, String baseUrl) {
  final trimmed = href.trim();
  if (trimmed.isEmpty) return trimmed;
  final uri = Uri.tryParse(trimmed);
  if (uri == null || uri.hasScheme) return trimmed;
  return Uri.parse('$baseUrl/').resolveUri(uri).toString();
}
