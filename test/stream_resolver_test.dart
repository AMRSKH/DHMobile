import 'package:donghua_player/data/providers/stream_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isUnplayableHost', () {
    test('skips the hosts that never give a playable stream', () {
      for (final url in [
        'https://www.youtube.com/embed/6bHfLPK18FA',
        'https://youtu.be/6bHfLPK18FA',
        'https://mega.nz/embed/L9pAyIhT#key',
        'https://dood.yt/e/zipestbtru2n',
        'https://playmogo.com/e/keq4dmpbtwyn',
        'https://play.d.tube?v=4aokad5wLQtpvATxJSEMzr',
        'https://rumble.com/embed/v7fv4ny/?pub=4qfz5q',
        '//www.youtube.com/embed/x',
      ]) {
        expect(isUnplayableHost(url), isTrue, reason: url);
      }
    });

    test('keeps the hosts the resolver can read', () {
      for (final url in [
        'https://ok.ru/videoembed/4885840398900',
        'https://geo.dailymotion.com/player/xhojl.html?video=k40OD',
        'https://www.dailymotion.com/embed/video/k4b23EM2XP0uR2yR0qF',
        'https://play.streamplay.co.in/e/abc',
      ]) {
        expect(isUnplayableHost(url), isFalse, reason: url);
      }
    });

    test('only the host itself or its subdomains count', () {
      expect(isUnplayableHost('https://omega.io/v/1'), isFalse);
      expect(isUnplayableHost('https://hd.tube.example/v/1'), isFalse);
      expect(isUnplayableHost('https://notyoutube.com/v'), isFalse);
      expect(isUnplayableHost('https://m.youtube.com/watch?v=1'), isTrue);
      expect(isUnplayableHost('https://doodstream.com/e/1'), isTrue);
      expect(isUnplayableHost('https://dood.so/e/1'), isTrue);
      expect(isUnplayableHost('not a url'), isFalse);
    });

    test('an unplayable name in the path alone does not count', () {
      expect(
        isUnplayableHost('https://ok.ru/videoembed/1?from=youtube.com'),
        isFalse,
      );
    });

    test('an unplayable host is answered without a request', () async {
      final resolver = StreamResolver();
      final sw = Stopwatch()..start();
      expect(await resolver.resolve('https://youtu.be/abc'), isEmpty);
      expect(sw.elapsedMilliseconds, lessThan(100));
    });
  });
}
