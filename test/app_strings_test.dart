import 'package:donghua_player/core/l10n/app_strings.dart';
import 'package:flutter_test/flutter_test.dart';

Set<String> _placeholders(String text) {
  return RegExp(r'\{(\w+)\}').allMatches(text).map((m) => m.group(1)!).toSet();
}

void main() {
  group('AppLanguage', () {
    test('has the two labels the owner asked for', () {
      expect(AppLanguage.en.label, 'EN - English');
      expect(AppLanguage.km.label, 'KH - ភាសាខ្មែរ');
      expect(AppLanguage.en.code, 'en');
      expect(AppLanguage.km.code, 'km');
    });

    test('fromCode falls back to English', () {
      expect(AppLanguage.fromCode('km'), AppLanguage.km);
      expect(AppLanguage.fromCode('en'), AppLanguage.en);
      expect(AppLanguage.fromCode('fr'), AppLanguage.en);
      expect(AppLanguage.fromCode(''), AppLanguage.en);
      expect(AppLanguage.fromCode(null), AppLanguage.en);
    });
  });

  group('string tables', () {
    test('every key has a text in every language', () {
      for (final language in AppLanguage.values) {
        final table = AppStrings.tableOf(language);
        for (final key in S.values) {
          expect(
            table[key]?.trim(),
            isNotEmpty,
            reason: '${key.name} is missing in ${language.code}',
          );
        }
        expect(table.length, S.values.length);
      }
    });

    test('every language uses the placeholders of English', () {
      final en = AppStrings.tableOf(AppLanguage.en);
      for (final language in AppLanguage.values) {
        final table = AppStrings.tableOf(language);
        for (final key in S.values) {
          expect(
            _placeholders(table[key]!),
            _placeholders(en[key]!),
            reason: 'placeholders of ${key.name} differ in ${language.code}',
          );
        }
      }
    });

    test('Chinese texts are really Chinese', () {
      final han = RegExp('[一-鿿]');
      // Names and a pure number line stay as they are.
      const latinOnPurpose = {S.developmentBody, S.cacheUsage};
      for (final entry in AppStrings.tableOf(AppLanguage.zh).entries) {
        if (latinOnPurpose.contains(entry.key)) continue;
        expect(
          han.hasMatch(entry.value),
          isTrue,
          reason: '${entry.key.name} has no Chinese character',
        );
      }
    });

    test('Chinese is offered as ZH - 中文', () {
      expect(AppLanguage.zh.code, 'zh');
      expect(AppLanguage.zh.label, 'ZH - 中文');
      expect(AppLanguage.fromCode('zh'), AppLanguage.zh);
      expect(const AppStrings(AppLanguage.zh)(S.settings), '设置');
    });

    test('Khmer texts use Latin digits', () {
      final khmerDigits = RegExp('[០-៩]');
      for (final entry in AppStrings.tableOf(AppLanguage.km).entries) {
        expect(
          khmerDigits.hasMatch(entry.value),
          isFalse,
          reason: '${entry.key.name} has a Khmer digit',
        );
      }
    });

    test('Khmer texts are really Khmer', () {
      final khmer = RegExp('[ក-៿]');
      // Kept in Latin on purpose: the owner reads "Server" more easily.
      const latinOnPurpose = {S.playerServerWord};
      for (final entry in AppStrings.tableOf(AppLanguage.km).entries) {
        if (latinOnPurpose.contains(entry.key)) continue;
        expect(
          khmer.hasMatch(entry.value),
          isTrue,
          reason: '${entry.key.name} has no Khmer letter',
        );
      }
    });
  });

  group('AppStrings', () {
    const en = AppStrings(AppLanguage.en);
    const km = AppStrings(AppLanguage.km);

    test('call returns the text of the language', () {
      expect(en(S.explore), 'Explore');
      expect(km(S.explore), 'រុករក');
      expect(en(S.categoryNewSeries), 'New Series');
      expect(km(S.categoryNewSeries), 'រឿងថ្មី');
      expect(en(S.categoryPopular), 'Popular');
      expect(km(S.categoryPopular), 'ពេញនិយម');
      expect(km(S.displayLanguage), 'ភាសាបង្ហាញ');
    });

    test('fmt fills the placeholders', () {
      expect(en.fmt(S.versionLine, {'version': '1.0.3'}), 'Version 1.0.3');
      expect(km.fmt(S.versionLine, {'version': '1.0.3'}), 'កំណែ 1.0.3');
      expect(en.fmt(S.episodesCount, {'count': 12}), 'Episodes (12)');
      expect(km.fmt(S.episodeShort, {'number': 7}), 'ភាគ 7');
    });

    test('fmt leaves an unknown placeholder and does not expand values', () {
      expect(
        en.fmt(S.watchedProgress, {'position': '1:00'}),
        'Watched 1:00 / {duration}',
      );
      expect(
        en.fmt(S.playerConnecting, {
          'server': '{index}',
          'index': 2,
          'total': 5,
        }),
        'Connecting to {index} (2/5)',
      );
    });

    test('weekdayShort maps 1..7 to Monday..Sunday', () {
      expect(
        [for (var day = 1; day <= 7; day++) en.weekdayShort(day)],
        ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      );
      expect(
        [for (var day = 1; day <= 7; day++) km.weekdayShort(day)],
        ['ច័ន្ទ', 'អង្គារ', 'ពុធ', 'ព្រហ', 'សុក្រ', 'សៅរ៍', 'អាទិត្យ'],
      );
      expect(en.weekdayShort(0), 'Mon');
      expect(en.weekdayShort(9), 'Sun');
    });
  });
}
