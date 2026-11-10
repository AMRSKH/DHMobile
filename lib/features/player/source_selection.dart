import '../../domain/models/stream_source.dart';

final RegExp _heightPattern = RegExp(r'(\d{3,4})p', caseSensitive: false);

/// The [subLangCode] a subtitle setting asks for, or `null` when it asks for
/// none ('None' or unknown).
String? _languageKeyword(String subtitle) {
  switch (subtitle.trim().toLowerCase()) {
    case 'english':
      return 'ENG';
    case 'indonesian':
      return 'IDN';
    default:
      return null;
  }
}

/// 2 = the wanted language, 1 = no single language (SUB or MULTI), 0 = an
/// other language. Uses the same words as the menu label (QA TASK-030), so
/// "ENG SUB" counts as English here too.
int _languageTier(StreamSource source, String code) {
  final lang = subLangCode(source.server);
  if (lang == code) return 2;
  if (lang == 'SUB' || lang == 'MULTI') return 1;
  return 0;
}

int? _parseHeight(String text) {
  final match = _heightPattern.firstMatch(text);
  return match == null ? null : int.tryParse(match.group(1)!);
}

/// Picks the source to start with: preferred subtitle language first, then
/// the preferred quality inside that language group.
///
/// Returns an index into [sources], or 0 when the list is empty.
int pickInitialSourceIndex(
  List<StreamSource> sources, {
  required String quality,
  required String subtitle,
}) {
  if (sources.isEmpty) return 0;

  var candidates = List<int>.generate(sources.length, (i) => i);
  final keyword = _languageKeyword(subtitle);
  if (keyword != null) {
    final tiers = [for (final s in sources) _languageTier(s, keyword)];
    final best = tiers.reduce((a, b) => a > b ? a : b);
    candidates = [
      for (var i = 0; i < sources.length; i++)
        if (tiers[i] == best) i,
    ];
  }

  final preferred = quality.trim().toLowerCase();
  if (preferred.isEmpty || preferred == 'auto') return candidates.first;

  // 2K/4K: start on an adaptive stream of the language group when there is
  // one. It begins at a low bitrate and climbs as high as the network allows,
  // so playback starts at once; failover then tries the fixed files (owner's
  // choice, TASK-031).
  final wanted = _parseHeight(preferred);
  if (wanted != null && wanted >= 1440) {
    for (final i in candidates) {
      if (isAdaptiveStream(sources[i])) return i;
    }
  }

  for (final i in candidates) {
    if (sources[i].quality.toLowerCase().contains(preferred)) return i;
  }

  final target = _parseHeight(preferred);
  if (target != null) {
    int? bestIndex;
    int? bestHeight;
    for (final i in candidates) {
      final height = _parseHeight(sources[i].quality);
      if (height == null) continue;
      final closer =
          bestHeight == null ||
          (height - target).abs() < (bestHeight - target).abs() ||
          ((height - target).abs() == (bestHeight - target).abs() &&
              height < bestHeight);
      if (closer) {
        bestIndex = i;
        bestHeight = height;
      }
    }
    if (bestIndex != null) return bestIndex;
  }

  return candidates.first;
}

/// Picks the source to try after a failure: the same choice as
/// [pickInitialSourceIndex], made over the sources whose index is not in
/// [failed]. So the nearest quality of the preferred language comes before
/// any source of another language.
///
/// Returns an index into [sources], or -1 when every source has failed.
int pickFailoverSourceIndex(
  List<StreamSource> sources, {
  required Set<int> failed,
  required String quality,
  required String subtitle,
}) {
  final remaining = [
    for (var i = 0; i < sources.length; i++)
      if (!failed.contains(i)) i,
  ];
  if (remaining.isEmpty) return -1;

  final picked = pickInitialSourceIndex(
    [for (final i in remaining) sources[i]],
    quality: quality,
    subtitle: subtitle,
  );
  return remaining[picked];
}

/// Resume point to keep when the same episode is loaded again from another
/// source. The current position wins when it is past the first 3 s and past
/// a resume point that was not applied yet.
int carriedResumeMs({required int positionMs, required int pendingMs}) {
  return positionMs > 3000 && positionMs > pendingMs ? positionMs : pendingMs;
}

/// How often the player resolves an episode's sources again by itself when
/// every source has failed, before it shows the error. Stream URLs expire,
/// and OK.ru binds them to the public IP (`srcIp`), which changes on some
/// networks (carrier-grade NAT), so a fresh list can work where the old one
/// failed (device test, TASK-024/025).
const int kAutoReresolveLimit = 1;

/// True when the player may resolve the sources again by itself, after
/// [used] automatic resolutions since the last load that played.
bool canAutoReresolve(int used) => used < kAutoReresolveLimit;

/// True when a load has played for real since it started at [from]: a load
/// can report "playing" and die at once, which must not earn a new automatic
/// re-resolve (QA TASK-025).
bool hasRealProgress({required Duration from, required Duration now}) {
  return now - from >= const Duration(seconds: 10);
}

/// True when an "ended" report at [position] is the real end of the episode:
/// the length is known and at most 5 s are left. libVLC also reports the end
/// when a stream dies in the middle.
bool isNearEnd({required Duration position, required Duration duration}) {
  if (duration <= Duration.zero) return false;
  return position >= duration - const Duration(seconds: 5);
}

/// Index of the source with the same server and quality as [previous], or -1.
int stickySourceIndex(List<StreamSource> sources, StreamSource? previous) {
  if (previous == null) return -1;
  final server = (previous.server ?? '').toLowerCase();
  final quality = previous.quality.toLowerCase();
  return sources.indexWhere(
    (s) =>
        (s.server ?? '').toLowerCase() == server &&
        s.quality.toLowerCase() == quality,
  );
}

/// True for an HLS master playlist that adapts its quality (Dailymotion
/// "Multi-Bitrate (HLS)", OK.ru "Auto HLS"), not a single fixed variant.
bool isAdaptiveStream(StreamSource source) {
  return source.url.toLowerCase().contains('.m3u8') &&
      qualityName(source.quality) == 'Auto';
}

/// Menu label for a source in the owner's format "SubLang-Source quality",
/// for example "ENG-DonghuaStream 2K" (TASK-030).
String sourceLabel(StreamSource source, int index) {
  final site = source.sourceName ?? 'Server ${index + 1}';
  return '${subLangCode(source.server)}-$site ${qualityName(source.quality)}';
}

/// [sourceLabel] for every source of [sources]. Equal labels get " (2)",
/// " (3)" in list order, so two servers of one site and quality stay apart.
List<String> sourceLabels(List<StreamSource> sources) {
  final seen = <String, int>{};
  return [
    for (var i = 0; i < sources.length; i++)
      () {
        final label = sourceLabel(sources[i], i);
        final n = seen[label] = (seen[label] ?? 0) + 1;
        return n == 1 ? label : '$label ($n)';
      }(),
  ];
}

/// Subtitle language of a server, from words in its name: ENG, IDN, MULTI,
/// POR, SPA, THA, VIE, or SUB when the name says none (owner's choice,
/// TASK-030).
String subLangCode(String? server) {
  final name = (server ?? '').toLowerCase();
  bool has(String pattern) => RegExp(pattern).hasMatch(name);
  if (has(r'multi|all\s*sub')) return 'MULTI';
  if (has(r'english|\beng\b')) return 'ENG';
  if (has(r'indonesia|\bindo\b|\bind\b|\bidn\b')) return 'IDN';
  if (has(r'portugu')) return 'POR';
  if (has(r'spanish|espa[nñ]ol|\besp\b')) return 'SPA';
  if (has(r'\bthai\b')) return 'THA';
  if (has(r'vietnam')) return 'VIE';
  return 'SUB';
}

/// The quality as the menu shows it: 4K for 2160p, 2K for 1440p, Auto for
/// an adaptive or multi-bitrate stream, the height (for example 720p), or
/// the source's own word when it names no height ("Direct").
String qualityName(String quality) {
  final height = _parseHeight(quality);
  if (height == null) {
    final q = quality.toLowerCase();
    if (q.contains('4k')) return '4K';
    if (q.contains('2k')) return '2K';
    if (RegExp(r'auto|hls|multi|bitrate|default').hasMatch(q) ||
        q.trim().isEmpty) {
      return 'Auto';
    }
    return quality.trim();
  }
  if (height >= 2160) return '4K';
  if (height >= 1440) return '2K';
  return '${height}p';
}
