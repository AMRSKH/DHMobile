import '../../domain/models/stream_source.dart';

final RegExp _heightPattern = RegExp(r'(\d{3,4})p', caseSensitive: false);

/// Keyword looked up in the server label for a subtitle setting, or `null`
/// when the setting does not ask for a language ('None' or unknown).
String? _languageKeyword(String subtitle) {
  switch (subtitle.trim().toLowerCase()) {
    case 'english':
      return 'english';
    case 'indonesian':
      return 'indo';
    default:
      return null;
  }
}

/// 2 = the wanted language, 1 = no language in the label, 0 = other language.
int _languageTier(StreamSource source, String keyword) {
  final server = (source.server ?? '').toLowerCase();
  if (server.contains(keyword)) return 2;
  if (!server.contains('english') && !server.contains('indo')) return 1;
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

/// Menu label for a source. The resolver often puts the quality in the server
/// name already ("OK.ru 720p"), so it is appended only when it is missing.
String sourceLabel(StreamSource source, int index) {
  final server = source.server ?? 'Server ${index + 1}';
  final quality = source.quality;
  if (server.toLowerCase().contains(quality.toLowerCase())) return server;
  return '$server ($quality)';
}
