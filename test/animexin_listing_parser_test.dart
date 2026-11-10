import 'dart:io';

import 'package:donghua_player/data/providers/animexin_listing_parser.dart';
import 'package:donghua_player/domain/models/schedule_entry.dart';
import 'package:flutter_test/flutter_test.dart';

// Saved copies of the source pages. They are read from disk, the tests never
// use the network.
String _fixture(String name) => File('test/fixtures/$name').readAsStringSync();

String _scheduleItem({
  String url = 'https://animexin.dev/show-a/',
  String? linkTitle = 'Show A',
  String tt = 'Show A',
  String epx = "<span class='epx'>released</span>",
  String sb = '12',
  String img = '<img src="https://animexin.dev/a.jpg">',
}) {
  final titleAttr = linkTitle == null ? '' : ' title="$linkTitle"';
  return '''
<div class="bs"><div class="bsx">
<a href="$url"$titleAttr>
<div class="limit"><div class="bt">$epx<span class="sb Sub">$sb</span></div>$img</div>
<div class="tt">$tt</div>
</a>
</div></div>''';
}

String _scheduleBlock(String day, List<String> items) {
  return '<div class="bixbox schedulepage sch_$day">'
      '<div class="listupd">${items.join()}</div></div>';
}

String _listingItem({
  String url = 'https://animexin.dev/show-a/',
  String? linkTitle = 'Show A',
  String h2 = 'Show A',
  String status = 'Ongoing',
  String img = '<img src="https://animexin.dev/a.jpg"/>',
}) {
  final titleAttr = linkTitle == null ? '' : ' title="$linkTitle"';
  return '''
<article class="bs"><div class="bsx">
<a href="$url"$titleAttr>
<div class="limit"><div class="bt"><span class="epx">$status</span><span class="sb Sub">Sub</span></div>$img</div>
<div class="tt"> $h2 <h2 itemprop="headline">$h2</h2></div>
</a>
</div></article>''';
}

String _listing(List<String> items) =>
    '<div class="listupd">${items.join()}</div>';

void main() {
  group('parseSchedule on the saved page', () {
    late Map<int, List<ScheduleEntry>> schedule;

    setUpAll(() {
      schedule = parseSchedule(
        _fixture('animexin_schedule.html'),
        providerId: 'animexin',
      );
    });

    test('has every weekday with all of its shows', () {
      expect(schedule.keys.toList()..sort(), [1, 2, 3, 4, 5, 6, 7]);
      expect(
        {for (final day in schedule.keys) day: schedule[day]!.length},
        {
          DateTime.monday: 8,
          DateTime.tuesday: 6,
          DateTime.wednesday: 11,
          DateTime.thursday: 7,
          DateTime.friday: 6,
          DateTime.saturday: 14,
          DateTime.sunday: 9,
        },
      );
      expect(schedule.values.expand((day) => day), hasLength(61));
    });

    test('reads the weekday from the block class, not from its position', () {
      // Friday is the first block of the page.
      final first = schedule[DateTime.friday]!.first;
      expect(
        first.show.id,
        'https://animexin.dev/perfect-world-wanmei-shijie/',
      );
      expect(first.show.title, 'Perfect World [Wanmei Shijie]');
      expect(
        first.show.poster,
        'https://animexin.dev/wp-content/uploads/2021/04/perfect-world-04-26.jpg',
      );
    });

    test('an item without a release date keeps only the raw text', () {
      final entry = schedule[DateTime.friday]!.first;
      expect(entry.released, isFalse);
      expect(entry.releaseAt, isNull);
      expect(entry.releaseText, 'at 12:02');
      // The episode number of the page is "??".
      expect(entry.show.episodeCount, isNull);
    });

    test('a released item has the episode number and no time', () {
      final entry = schedule[DateTime.friday]![1];
      expect(entry.show.title, 'Against the Sky Supreme');
      expect(entry.released, isTrue);
      expect(entry.releaseAt, isNull);
      expect(entry.releaseText, 'released');
      expect(entry.show.episodeCount, 'EP 564');
    });

    test('an upcoming item has its release time in UTC', () {
      final entry = schedule[DateTime.thursday]!.singleWhere(
        (e) => e.show.id == 'https://animexin.dev/primeval-overlord/',
      );
      expect(entry.released, isFalse);
      expect(entry.releaseText, 'at 06:15');
      expect(entry.releaseAt, DateTime.utc(2026, 11, 12, 6, 15));
      expect(entry.releaseAt!.isUtc, isTrue);
      expect(entry.show.episodeCount, 'EP 33');
      expect(entry.show.title, 'Ancient God Sovereign');
    });

    test('the "at HH:mm" text of the page is the UTC time of releaseAt', () {
      var checked = 0;
      for (final entry in schedule.values.expand((day) => day)) {
        final at = entry.releaseAt;
        if (at == null) continue;
        final hh = at.hour.toString().padLeft(2, '0');
        final mm = at.minute.toString().padLeft(2, '0');
        expect(entry.releaseText, 'at $hh:$mm');
        checked++;
      }
      expect(checked, 55);
    });

    test('never puts release data into the stored show', () {
      for (final entry in schedule.values.expand((day) => day)) {
        final show = entry.show;
        expect(show.providerId, 'animexin');
        expect(show.status, isNull);
        expect(show.id, startsWith('https://animexin.dev/'));
        expect(show.title, isNotEmpty);
        expect(show.poster, startsWith('https://'));
        expect(show.episodeCount, anyOf(isNull, matches(r'^EP \d+$')));
      }
      expect(
        schedule.values
            .expand((day) => day)
            .where((e) => e.show.episodeCount == null),
        hasLength(3),
      );
      expect(
        schedule.values.expand((day) => day).where((e) => e.released),
        hasLength(5),
      );
    });

    test('has no show twice in one day', () {
      for (final day in schedule.values) {
        final ids = day.map((e) => e.show.id).toList();
        expect(ids.toSet(), hasLength(ids.length));
      }
    });
  });

  group('parseSchedule', () {
    test('returns seven empty days for a page without a schedule', () {
      for (final html in ['', '<html><body><p>Maintenance</p></body></html>']) {
        final schedule = parseSchedule(html, providerId: 'animexin');
        expect(schedule.keys.toList()..sort(), [1, 2, 3, 4, 5, 6, 7]);
        expect(schedule.values.every((day) => day.isEmpty), isTrue);
      }
    });

    test('a day that is missing on the page stays empty', () {
      final schedule = parseSchedule(
        _scheduleBlock('sunday', [_scheduleItem()]) +
            _scheduleBlock('monday', [
              _scheduleItem(url: 'https://animexin.dev/show-b/'),
            ]),
        providerId: 'animexin',
      );
      expect(schedule[DateTime.sunday], hasLength(1));
      expect(schedule[DateTime.monday], hasLength(1));
      expect(schedule[DateTime.tuesday], isEmpty);
    });

    test('ignores a block with an unknown weekday class', () {
      final schedule = parseSchedule(
        _scheduleBlock('someday', [_scheduleItem()]),
        providerId: 'animexin',
      );
      expect(schedule.values.every((day) => day.isEmpty), isTrue);
    });

    test('skips an item without a URL or without a title', () {
      final schedule = parseSchedule(
        _scheduleBlock('monday', [
          _scheduleItem(url: ''),
          _scheduleItem(
            url: 'https://animexin.dev/no-title/',
            linkTitle: null,
            tt: '  ',
          ),
          _scheduleItem(url: 'https://animexin.dev/ok/', linkTitle: 'Ok'),
        ]),
        providerId: 'animexin',
      );
      expect(schedule[DateTime.monday]!.map((e) => e.show.title), ['Ok']);
    });

    test('falls back to .tt when the link has no title', () {
      final schedule = parseSchedule(
        _scheduleBlock('monday', [
          _scheduleItem(linkTitle: null, tt: 'From The Card'),
        ]),
        providerId: 'animexin',
      );
      expect(schedule[DateTime.monday]!.single.show.title, 'From The Card');
    });

    test('keeps a show once per day, and once in each of two days', () {
      final schedule = parseSchedule(
        _scheduleBlock('monday', [_scheduleItem(), _scheduleItem()]) +
            _scheduleBlock('tuesday', [_scheduleItem()]),
        providerId: 'animexin',
      );
      expect(schedule[DateTime.monday], hasLength(1));
      expect(schedule[DateTime.tuesday], hasLength(1));
    });

    test('prefers data-src and treats a data: image as no poster', () {
      final schedule = parseSchedule(
        _scheduleBlock('monday', [
          _scheduleItem(
            url: 'https://animexin.dev/lazy/',
            img:
                '<img src="data:image/gif;base64,R0lGOD" '
                'data-src="https://animexin.dev/lazy.jpg">',
          ),
          _scheduleItem(
            url: 'https://animexin.dev/inline/',
            img: '<img src="data:image/gif;base64,R0lGOD">',
          ),
          _scheduleItem(url: 'https://animexin.dev/none/', img: ''),
        ]),
        providerId: 'animexin',
      );
      expect(schedule[DateTime.monday]!.map((e) => e.show.poster), [
        'https://animexin.dev/lazy.jpg',
        '',
        '',
      ]);
    });

    test('reads the release fields', () {
      final schedule = parseSchedule(
        _scheduleBlock('monday', [
          _scheduleItem(
            url: 'https://animexin.dev/timed/',
            epx:
                "<span class='epx cndwn' data-cndwn='60' "
                "data-rlsdt='1794464100'>at 06:15</span>",
            sb: '33',
          ),
          _scheduleItem(
            url: 'https://animexin.dev/untimed/',
            epx:
                "<span class='epx cndwn' data-cndwn='-1' "
                "data-rlsdt=''>at 12:02</span>",
            sb: '??',
          ),
          _scheduleItem(
            url: 'https://animexin.dev/out/',
            epx: "<span class='epx'> Released </span>",
            sb: '7',
          ),
          _scheduleItem(
            url: 'https://animexin.dev/bad/',
            epx: "<span class='epx' data-rlsdt='soon'></span>",
            sb: 'Sub',
          ),
        ]),
        providerId: 'animexin',
      );
      final timed = schedule[DateTime.monday]![0];
      expect(timed.released, isFalse);
      expect(timed.releaseAt, DateTime.utc(2026, 11, 12, 6, 15));
      expect(timed.releaseText, 'at 06:15');
      expect(timed.show.episodeCount, 'EP 33');

      final untimed = schedule[DateTime.monday]![1];
      expect(untimed.released, isFalse);
      expect(untimed.releaseAt, isNull);
      expect(untimed.releaseText, 'at 12:02');
      expect(untimed.show.episodeCount, isNull);

      final out = schedule[DateTime.monday]![2];
      expect(out.released, isTrue);
      expect(out.releaseText, 'Released');
      expect(out.show.episodeCount, 'EP 7');

      final bad = schedule[DateTime.monday]![3];
      expect(bad.released, isFalse);
      expect(bad.releaseAt, isNull);
      expect(bad.releaseText, isNull);
      expect(bad.show.episodeCount, isNull);
    });
  });

  group('parseSeriesList on the saved pages', () {
    test('reads the 30 popular series in page order', () {
      final shows = parseSeriesList(
        _fixture('animexin_popular.html'),
        providerId: 'animexin',
      );
      expect(shows, hasLength(30));
      expect(shows.first.id, 'https://animexin.dev/soul-land-s2/');
      expect(shows.first.title, 'Soul Land Season 2');
      expect(shows.first.status, 'Completed');
      expect(
        shows.first.poster,
        'https://animexin.dev/wp-content/uploads/2019/12/sl-new-last.png',
      );
      expect(shows[1].title, 'Perfect World [Wanmei Shijie]');
      expect(shows[1].status, 'Ongoing');
      expect(shows.where((s) => s.status == 'Completed'), hasLength(12));
      expect(shows.where((s) => s.status == 'Ongoing'), hasLength(18));
    });

    test('reads the 30 newest series, upcoming ones included', () {
      final shows = parseSeriesList(
        _fixture('animexin_latest.html'),
        providerId: 'animexin',
      );
      expect(shows, hasLength(30));
      expect(
        shows.first.id,
        'https://animexin.dev/battle-through-the-heavens-battle-of-the-two-emperors/',
      );
      expect(
        shows.first.title,
        'Battle Through the Heavens: Battle of the Two Emperors',
      );
      expect(shows.first.status, 'Upcoming');
      expect(shows.where((s) => s.status == 'Upcoming'), hasLength(5));
      expect(shows.where((s) => s.status == 'Ongoing'), hasLength(13));
      expect(shows.where((s) => s.status == 'Completed'), hasLength(12));
    });

    test('fills the show fields the same way on both pages', () {
      for (final name in ['animexin_popular.html', 'animexin_latest.html']) {
        final shows = parseSeriesList(_fixture(name), providerId: 'animexin');
        expect(shows.map((s) => s.id).toSet(), hasLength(shows.length));
        for (final show in shows) {
          expect(show.providerId, 'animexin');
          expect(show.id, startsWith('https://animexin.dev/'));
          expect(show.title, isNotEmpty);
          // The title is in `.tt` twice. It must not be doubled.
          expect(show.title.contains('\n'), isFalse);
          expect(show.poster, startsWith('https://'));
          expect(show.episodeCount, isNull);
          expect(show.status, isNotNull);
        }
      }
    });
  });

  group('parseSeriesList', () {
    test('returns nothing for a page without a listing', () {
      expect(parseSeriesList('', providerId: 'animexin'), isEmpty);
      expect(
        parseSeriesList('<html><body>Blocked</body></html>', providerId: 'x'),
        isEmpty,
      );
    });

    test('skips items without URL or title and drops duplicates', () {
      final shows = parseSeriesList(
        _listing([
          _listingItem(url: ''),
          _listingItem(
            url: 'https://animexin.dev/no-title/',
            linkTitle: null,
            h2: '',
          ),
          _listingItem(),
          _listingItem(),
          _listingItem(url: 'https://animexin.dev/show-b/', linkTitle: 'B'),
        ]),
        providerId: 'animexin',
      );
      expect(shows.map((s) => s.title), ['Show A', 'B']);
    });

    test('falls back to the h2 when the link has no title', () {
      final shows = parseSeriesList(
        _listing([_listingItem(linkTitle: null, h2: 'Headline Title')]),
        providerId: 'animexin',
      );
      expect(shows.single.title, 'Headline Title');
    });

    test('an empty status becomes null, a data: image no poster', () {
      final shows = parseSeriesList(
        _listing([
          _listingItem(
            status: '',
            img: '<img src="data:image/svg+xml;base64,AAAA"/>',
          ),
        ]),
        providerId: 'animexin',
      );
      expect(shows.single.status, isNull);
      expect(shows.single.poster, '');
    });

    test('ignores articles outside the listing', () {
      final shows = parseSeriesList(
        '<div class="sidebar">${_listingItem()}</div>',
        providerId: 'animexin',
      );
      expect(shows, isEmpty);
    });
  });
}
