import 'package:donghua_player/data/providers/animexin_stream_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('cleanShowTitle', () {
    test('removes the episode suffix of a homepage post', () {
      expect(
        cleanShowTitle('Renegade Immortal Episode 11 Indonesia, English Sub'),
        'Renegade Immortal',
      );
      expect(
        cleanShowTitle('Soul Land 2 episode 82 English Sub'),
        'Soul Land 2',
      );
    });

    test('handles the short "Ep" forms', () {
      expect(cleanShowTitle('Perfect World Ep 185'), 'Perfect World');
      expect(cleanShowTitle('Perfect World Ep. 185 Sub Indo'), 'Perfect World');
      expect(cleanShowTitle('Perfect World EP185'), 'Perfect World');
    });

    test('keeps a season marker in front of the suffix', () {
      expect(
        cleanShowTitle('Battle Through the Heavens Season 5 Episode 104'),
        'Battle Through the Heavens Season 5',
      );
    });

    test('leaves a title without a suffix alone', () {
      expect(
        cleanShowTitle('  Battle Through the Heavens (Season 5)  '),
        'Battle Through the Heavens (Season 5)',
      );
      // No number after the word, so it is part of the name.
      expect(cleanShowTitle('The Lost Episode'), 'The Lost Episode');
    });

    test('removes a separator left in front of the suffix', () {
      expect(cleanShowTitle('Some Show: Episode 5'), 'Some Show');
      expect(cleanShowTitle('Some Show – Episode 5 English Sub'), 'Some Show');
      expect(cleanShowTitle('Some Show — Episode 5'), 'Some Show');
      expect(cleanShowTitle('Some Show - Ep 5'), 'Some Show');
      expect(cleanShowTitle('Some Show | Ep. 5 Sub Indo'), 'Some Show');
      expect(cleanShowTitle('Some Show  -  : Episode 5'), 'Some Show');
    });

    test('removes a trailing separator of a title without a suffix', () {
      expect(cleanShowTitle('Some Show:'), 'Some Show');
      expect(cleanShowTitle('Some Show –'), 'Some Show');
      expect(cleanShowTitle('Some Show - '), 'Some Show');
      expect(cleanShowTitle('Some Show |'), 'Some Show');
    });

    test('keeps a separator inside the title', () {
      expect(
        cleanShowTitle('Soul Land 2: The Peerless Tang Clan Episode 82'),
        'Soul Land 2: The Peerless Tang Clan',
      );
      expect(
        cleanShowTitle('Spare Me, Great Lord! - Season 2'),
        'Spare Me, Great Lord! - Season 2',
      );
    });

    test('never returns an empty title', () {
      expect(
        cleanShowTitle('Episode 11 English Sub'),
        'Episode 11 English Sub',
      );
      expect(cleanShowTitle('  Ep 3  '), 'Ep 3');
      // Only separators would be left: the trimmed original comes back.
      expect(cleanShowTitle(' - Episode 5 '), '- Episode 5');
      expect(cleanShowTitle(' | '), '|');
    });
  });
}
