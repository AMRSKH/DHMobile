import 'package:donghua_player/features/library/library_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('historyEpisodeLabel', () {
    test('drops a title that only repeats the episode number', () {
      expect(historyEpisodeLabel('2', 'Episode 2'), 'Episode 2');
      expect(historyEpisodeLabel('2', '  episode 2 '), 'Episode 2');
    });

    test('drops a title that spells the same number another way', () {
      expect(historyEpisodeLabel('2', 'Episode 02'), 'Episode 2');
      expect(historyEpisodeLabel('2', 'EPISODE 002'), 'Episode 2');
      expect(historyEpisodeLabel('2', 'Ep 2'), 'Episode 2');
      expect(historyEpisodeLabel('2', 'ep. 02'), 'Episode 2');
      expect(historyEpisodeLabel('2', 'EP2'), 'Episode 2');
      expect(historyEpisodeLabel('12', 'Episode 12.0'), 'Episode 12');
      expect(historyEpisodeLabel('1.5', 'Ep 1.50'), 'Episode 1.5');
    });

    test('keeps a title with more than the episode number', () {
      expect(
        historyEpisodeLabel('2', 'Episode 02 - The Awakening'),
        'Episode 2 • Episode 02 - The Awakening',
      );
      expect(
        historyEpisodeLabel('2', 'Ep 2 Finale'),
        'Episode 2 • Ep 2 Finale',
      );
      expect(historyEpisodeLabel('2', 'Ep 20'), 'Episode 2 • Ep 20');
      expect(historyEpisodeLabel('2', 'Ep. 3'), 'Episode 2 • Ep. 3');
    });

    test('drops an empty title', () {
      expect(historyEpisodeLabel('7', ''), 'Episode 7');
      expect(historyEpisodeLabel('7', '   '), 'Episode 7');
    });

    test('keeps a real title', () {
      expect(
        historyEpisodeLabel('2', 'The Awakening'),
        'Episode 2 • The Awakening',
      );
    });

    test('keeps a title that names another episode', () {
      expect(historyEpisodeLabel('2', 'Episode 12'), 'Episode 2 • Episode 12');
      expect(
        historyEpisodeLabel('1.5', 'Episode 1'),
        'Episode 1.5 • Episode 1',
      );
    });

    test('uses the episode word of the display language', () {
      // Titles of the source stay English, so "Episode 2" still only
      // repeats the number.
      expect(
        historyEpisodeLabel('2', 'Episode 2', episodeWord: 'ភាគ'),
        'ភាគ 2',
      );
      expect(historyEpisodeLabel('2', 'Ep 02', episodeWord: 'ភាគ'), 'ភាគ 2');
      expect(historyEpisodeLabel('7', '', episodeWord: 'ភាគ'), 'ភាគ 7');
      expect(
        historyEpisodeLabel('x', 'episode x', episodeWord: 'ភាគ'),
        'ភាគ x',
      );
      expect(historyEpisodeLabel('2', 'ភាគ 2', episodeWord: 'ភាគ'), 'ភាគ 2');
      expect(
        historyEpisodeLabel('2', 'The Awakening', episodeWord: 'ភាគ'),
        'ភាគ 2 • The Awakening',
      );
    });
  });
}
