import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import '../../domain/models/schedule_entry.dart';
import '../../domain/models/show.dart';

/// Weekday of the `sch_<name>` class token on a schedule block, 1 (Monday)
/// to 7 (Sunday).
const Map<String, int> _weekdayByClass = {
  'sch_monday': DateTime.monday,
  'sch_tuesday': DateTime.tuesday,
  'sch_wednesday': DateTime.wednesday,
  'sch_thursday': DateTime.thursday,
  'sch_friday': DateTime.friday,
  'sch_saturday': DateTime.saturday,
  'sch_sunday': DateTime.sunday,
};

final RegExp _episodeNumber = RegExp(r'^\d+(?:\.\d+)?$');

/// Parses the `/schedule/` page.
///
/// The result has every key from 1 (Monday) to 7 (Sunday). A day without
/// shows has an empty list. The page does not start at Monday, so the weekday
/// comes from the class of each block and not from its position.
Map<int, List<ScheduleEntry>> parseSchedule(
  String html, {
  required String providerId,
}) {
  final result = <int, List<ScheduleEntry>>{
    for (var day = DateTime.monday; day <= DateTime.sunday; day++) day: [],
  };
  final document = html_parser.parse(html);

  for (final block in document.querySelectorAll('div.schedulepage')) {
    final weekday = _weekdayOf(block);
    if (weekday == null) continue;
    final entries = result[weekday]!;
    final seenUrls = entries.map((e) => e.show.id).toSet();

    for (final item in block.querySelectorAll('.bsx')) {
      final link = item.querySelector('a');
      final url = _attr(link, 'href');
      final title = _firstNotEmpty([
        _attr(link, 'title'),
        _text(item.querySelector('.tt')),
      ]);
      if (url.isEmpty || title.isEmpty || !seenUrls.add(url)) continue;

      final release = item.querySelector('.epx');
      final releaseText = _text(release);
      final episode = _text(item.querySelector('.sb'));

      entries.add(
        ScheduleEntry(
          show: Show(
            id: url,
            title: title,
            poster: _poster(item),
            // Only a real number. The release time never goes in here:
            // Detail shows this field as a badge and favorites store it.
            episodeCount: _episodeNumber.hasMatch(episode)
                ? 'EP $episode'
                : null,
            providerId: providerId,
          ),
          released: releaseText.toLowerCase() == 'released',
          releaseAt: _releaseAt(_attr(release, 'data-rlsdt')),
          releaseText: releaseText.isEmpty ? null : releaseText,
        ),
      );
    }
  }
  return result;
}

/// Parses a series listing, `/anime/?order=popular` or
/// `/anime/?order=latest`, in the order of the page.
List<Show> parseSeriesList(String html, {required String providerId}) {
  final document = html_parser.parse(html);
  final shows = <Show>[];
  final seenUrls = <String>{};

  for (final article in document.querySelectorAll('.listupd article.bs')) {
    final link = article.querySelector('.bsx a');
    final url = _attr(link, 'href');
    // `.tt` holds the title twice, as a text node and as an `<h2>`, so the
    // link title comes first and the `<h2>` is the fallback.
    final title = _firstNotEmpty([
      _attr(link, 'title'),
      _text(article.querySelector('.tt h2')),
    ]);
    if (url.isEmpty || title.isEmpty || !seenUrls.add(url)) continue;

    final status = _text(article.querySelector('.epx'));
    shows.add(
      Show(
        id: url,
        title: title,
        poster: _poster(article),
        status: status.isEmpty ? null : status,
        providerId: providerId,
      ),
    );
  }
  return shows;
}

int? _weekdayOf(Element block) {
  for (final token in block.classes) {
    final weekday = _weekdayByClass[token.toLowerCase()];
    if (weekday != null) return weekday;
  }
  return null;
}

String _attr(Element? element, String name) {
  return element?.attributes[name]?.trim() ?? '';
}

String _text(Element? element) => element?.text.trim() ?? '';

String _firstNotEmpty(List<String> values) {
  return values.firstWhere((value) => value.isNotEmpty, orElse: () => '');
}

/// The poster URL: `data-src` of a lazy-loaded image first, then `src`. An
/// inline `data:` image is a placeholder of the page, not a poster.
String _poster(Element item) {
  final image = item.querySelector('img');
  for (final name in const ['data-src', 'src']) {
    final value = _attr(image, name);
    if (value.isNotEmpty && !value.toLowerCase().startsWith('data:')) {
      return value;
    }
  }
  return '';
}

/// `data-rlsdt` is the release time in seconds since the epoch.
DateTime? _releaseAt(String value) {
  final seconds = int.tryParse(value);
  if (seconds == null || seconds <= 0) return null;
  return DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
}
