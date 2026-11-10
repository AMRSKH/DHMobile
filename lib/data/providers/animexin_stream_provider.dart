import '../../domain/models/show.dart';
import '../../core/debug_log.dart';
import 'anime_stream_site_provider.dart';

final RegExp _episodeSuffix = RegExp(
  r'\s+(?:Episode|Ep\.?)\s*\d+.*$',
  caseSensitive: false,
);

/// Whitespace and the separators `: – — - |` at the end of a title.
final RegExp _trailingSeparators = RegExp(r'[\s:–—\-|]+$');

/// Removes the episode suffix that homepage posts carry in their title, for
/// example "Some Show Episode 11 Indonesia, English Sub" becomes "Some Show".
/// A separator left at the end ("Some Show:", "Some Show -") goes too.
/// A title that would end up empty is returned as it was, only trimmed.
String cleanShowTitle(String title) {
  final trimmed = title.trim();
  final cleaned = trimmed
      .replaceFirst(_episodeSuffix, '')
      .replaceFirst(_trailingSeparators, '');
  return cleaned.isEmpty ? trimmed : cleaned;
}

class AnimeXinStreamProvider extends AnimeStreamSiteProvider {
  AnimeXinStreamProvider({super.dio})
    : super(id: 'animexin', name: 'AnimeXin', baseUrl: 'https://animexin.dev');

  /// AnimeXin is the main source: without a query it shows the popular list,
  /// and when the site cannot be read it falls back to a small built-in
  /// catalog.
  @override
  Future<List<Show>> search(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return popular();

    try {
      final results = await super.search(cleanQuery);
      if (results.isNotEmpty) return results;
      DLog.event('search', 'q="$cleanQuery" no results, using fallback');
    } catch (e) {
      DLog.event('search', 'q="$cleanQuery" failed: $e');
      // Fallback to local catalog if network blocks or site changes
    }

    return _filterFallback(cleanQuery);
  }

  List<Show> _getFeaturedFallback() {
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
    return _getFeaturedFallback().where((show) {
      return show.title.toLowerCase().contains(lower) ||
          show.genres.any((g) => g.toLowerCase().contains(lower));
    }).toList();
  }
}
