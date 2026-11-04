import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;
import '../../domain/models/show.dart';
import '../../domain/models/episode.dart';
import '../../domain/models/stream_source.dart';
import '../../domain/providers/stream_provider.dart';
import 'stream_resolver.dart';
import 'stream_source_filter.dart';

class AnimeXinStreamProvider implements DonghuaStreamProvider {
  final Dio _dio;

  AnimeXinStreamProvider({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://animexin.dev',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
              headers: {
                'User-Agent':
                    'Mozilla/5.0 (Linux; Android 11; Pixel 5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
                'Referer': 'https://animexin.dev/',
                'Accept':
                    'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
              },
            ),
          );

  @override
  String get id => 'animexin';

  @override
  String get name => 'AnimeXin';

  @override
  Future<List<Show>> search(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return _getFeaturedShows();

    try {
      final response = await _dio.get('/', queryParameters: {'s': cleanQuery});

      final document = html_parser.parse(response.data);
      final articles = document.querySelectorAll(
        'article.bs, .listupd article, .bsx',
      );

      final List<Show> results = [];
      for (final article in articles) {
        final linkEl = article.querySelector('a');
        final titleEl = article.querySelector('.tt, h2, .entry-title');
        final imgEl = article.querySelector('img');
        final epEl = article.querySelector('.epx, .bt .ep');

        final url = linkEl?.attributes['href'] ?? '';
        final title =
            titleEl?.text.trim() ?? linkEl?.attributes['title']?.trim() ?? '';
        final poster =
            imgEl?.attributes['data-src'] ?? imgEl?.attributes['src'] ?? '';
        final epCount = epEl?.text.trim();

        if (url.isNotEmpty && title.isNotEmpty) {
          results.add(
            Show(
              id: url,
              title: title,
              poster: poster,
              episodeCount: epCount,
              providerId: id,
            ),
          );
        }
      }

      if (results.isNotEmpty) return results;
    } catch (_) {
      // Fallback to local catalog if network blocks or site changes
    }

    return _filterFallback(cleanQuery);
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

      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        final a = item.querySelector('a');
        final numEl = item.querySelector('.epl-num');
        final titleEl = item.querySelector('.epl-title');
        final dateEl = item.querySelector('.epl-date');

        final epUrl = a?.attributes['href'] ?? '';
        final epNumStr = numEl?.text.trim() ?? '${items.length - i}';
        final epTitle = titleEl?.text.trim() ?? 'Episode $epNumStr';
        final epNum =
            double.tryParse(epNumStr.replaceAll(RegExp(r'[^0-9.]'), '')) ??
            (items.length - i).toDouble();

        if (epUrl.isNotEmpty) {
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
        return episodeList;
      }
    } catch (_) {}

    // Do not invent episodes when scraping fails: fake IDs cannot be played
    // and would send the user into a dead player screen.
    return const [];
  }

  @override
  Future<List<StreamSource>> streams(String episodeId) async {
    final List<StreamSource> rawCandidates = [];
    final resolver = StreamResolver();

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
              headers: {
                'Referer': episodeId,
                'User-Agent':
                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
              },
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
              headers: {
                'Referer': episodeId,
                'User-Agent':
                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
              },
            ),
          );
        }
      }
    } catch (_) {}

    final List<StreamSource> resolvedSources = [];
    if (rawCandidates.isNotEmpty) {
      final results = await Future.wait(
        rawCandidates.map(
          (c) => resolver
              .resolve(c.url, serverHint: c.server, referer: episodeId)
              .catchError((_) => <StreamSource>[]),
        ),
      );
      for (final list in results) {
        resolvedSources.addAll(list);
      }
    }

    // Only expose sources that actually respond with playable media.
    if (resolvedSources.isEmpty) return const [];
    return StreamSourceFilter().filter(resolvedSources);
  }

  List<Show> _getFeaturedShows() {
    return const [
      Show(
        id: 'https://animexin.dev/btth-season-5/',
        title: 'Battle Through the Heavens (Season 5)',
        poster:
            'https://upload.wikimedia.org/wikipedia/en/thumb/4/4b/Battle_Through_the_Heavens_poster.jpg/220px-Battle_Through_the_Heavens_poster.jpg',
        episodeCount: 'EP 104',
        genres: ['Action', 'Fantasy', 'Cultivation'],
        synopsis:
            'In a land where no strength exists, a young martial artist awakens forgotten fire.',
        providerId: 'animexin',
      ),
      Show(
        id: 'https://animexin.dev/soul-land-2-the-peerless-tang-clan/',
        title: 'Soul Land 2: The Peerless Tang Clan',
        poster:
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR6J_g-zO8p7PzT0h149UqjP47NsmqM139G6g&s',
        episodeCount: 'EP 82',
        genres: ['Action', 'Martial Arts'],
        synopsis:
            'A million years after Tang San, a new legend begins on the Douluo Continent.',
        providerId: 'animexin',
      ),
      Show(
        id: 'https://animexin.dev/renegade-immortal/',
        title: 'Renegade Immortal (Xian Ni)',
        poster:
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTG-oP8L-1J-V-97i-n4o6aXzY5_l-x34G0eQ&s',
        episodeCount: 'EP 68',
        genres: ['Cultivation', 'Revenge'],
        synopsis:
            'Wang Lin journeys through a brutal cultivation world toward immortality.',
        providerId: 'animexin',
      ),
      Show(
        id: 'https://animexin.dev/perfect-world/',
        title: 'Perfect World (Wanmei Shijie)',
        poster:
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT6f77iG8rF9q5K2L9x1n-5uO-k0rT7eQ9a6A&s',
        episodeCount: 'EP 185',
        genres: ['Fantasy', 'Adventure'],
        synopsis:
            'Shi Hao grows to become a divine champion in a mythical universe.',
        providerId: 'animexin',
      ),
    ];
  }

  List<Show> _filterFallback(String query) {
    final lower = query.toLowerCase();
    return _getFeaturedShows().where((show) {
      return show.title.toLowerCase().contains(lower) ||
          show.genres.any((g) => g.toLowerCase().contains(lower));
    }).toList();
  }
}
