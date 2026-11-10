/// A site the app reads donghua from.
class ContentSource {
  /// Stored in `Show.providerId`.
  final String id;
  final String name;

  /// For example `https://animexin.dev`, without a trailing slash.
  final String baseUrl;

  const ContentSource({
    required this.id,
    required this.name,
    required this.baseUrl,
  });
}

/// Every source, in priority order. The first is the main source and serves
/// Explore. The list follows the sources of DonghuaCLI
/// (https://github.com/Thanukamax/donghua-cli, `sources/`), minus AnimeKhor,
/// which answers plain HTTP clients with a bot check (403 on 2026-11-10).
const List<ContentSource> kContentSources = [
  ContentSource(
    id: 'animexin',
    name: 'AnimeXin',
    baseUrl: 'https://animexin.dev',
  ),
  ContentSource(
    id: 'donghuaworld',
    name: 'DonghuaWorld',
    baseUrl: 'https://donghuaworld.com',
  ),
  ContentSource(
    id: 'luciferdonghua',
    name: 'LuciferDonghua',
    baseUrl: 'https://luciferdonghua.org',
  ),
  ContentSource(
    id: 'donghuastream',
    name: 'DonghuaStream',
    baseUrl: 'https://donghuastream.org',
  ),
  ContentSource(id: 'lmanime', name: 'LMAnime', baseUrl: 'https://lmanime.com'),
];

/// Display name of the source with [providerId], or `null` for an id that
/// is not in [kContentSources] (old saved shows can carry `default`).
String? sourceNameOf(String providerId) {
  for (final source in kContentSources) {
    if (source.id == providerId) return source.name;
  }
  return null;
}
