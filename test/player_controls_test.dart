import 'package:donghua_player/domain/models/stream_source.dart';
import 'package:donghua_player/features/player/widgets/player_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('play/pause stays tappable while buffering, and the speed menu '
      'reports open, select, and close', (tester) async {
    var playPauseTaps = 0;
    var menuOpened = 0;
    var menuClosed = 0;
    double? selectedSpeed;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayerControls(
            title: 'Test Show',
            episodeTitle: 'Episode 1',
            isPlaying: true,
            isBuffering: true,
            position: const Duration(seconds: 30),
            duration: const Duration(minutes: 20),
            speed: 1.0,
            sources: const [
              StreamSource(
                url: 'https://example.com/video.mp4',
                server: 'Hardsub English OK.ru 720p',
                quality: '720p',
              ),
            ],
            currentSourceIndex: 0,
            hasNextEpisode: false,
            onPlayPause: () => playPauseTaps++,
            onSeek: (_) {},
            onSeekBack10: () {},
            onSeekForward10: () {},
            onSpeedChanged: (value) => selectedSpeed = value,
            onSourceChanged: (_) {},
            onNextEpisode: () {},
            onBack: () {},
            onMenuOpened: () => menuOpened++,
            onMenuClosed: () => menuClosed++,
          ),
        ),
      ),
    );

    // The spinner never settles, so this test pumps fixed durations instead
    // of pumpAndSettle.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byTooltip('Pause'), findsOneWidget);

    await tester.tap(find.byTooltip('Pause'));
    await tester.pump();
    expect(playPauseTaps, 1);

    await tester.tap(find.text('1.0x'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(menuOpened, 1);
    expect(menuClosed, 0);

    await tester.tap(find.text('1.5x'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(selectedSpeed, 1.5);
    expect(menuClosed, 1);
    expect(menuOpened, 1);
  });

  testWidgets('dismissing the source menu reports the close, and a long '
      'label does not overflow', (tester) async {
    var menuOpened = 0;
    var menuClosed = 0;
    int? selectedSource;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayerControls(
            title: 'Test Show',
            episodeTitle: 'Episode 1',
            isPlaying: true,
            isBuffering: false,
            position: Duration.zero,
            duration: const Duration(minutes: 20),
            speed: 1.0,
            sources: const [
              StreamSource(
                url: 'https://example.com/a.mp4',
                server:
                    'Hardsub Indonesia, English Subtitle Mirror Server '
                    'With A Very Long Descriptive Name OK.ru 144p',
                quality: '144p',
              ),
              StreamSource(
                url: 'https://example.com/b.mp4',
                server: 'Dailymotion Fast',
                quality: 'Multi-Bitrate (HLS)',
              ),
            ],
            currentSourceIndex: 0,
            hasNextEpisode: false,
            onPlayPause: () {},
            onSeek: (_) {},
            onSeekBack10: () {},
            onSeekForward10: () {},
            onSpeedChanged: (_) {},
            onSourceChanged: (index) => selectedSource = index,
            onNextEpisode: () {},
            onBack: () {},
            onMenuOpened: () => menuOpened++,
            onMenuClosed: () => menuClosed++,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Select Server / Quality'));
    await tester.pumpAndSettle();
    expect(menuOpened, 1);
    // A RenderFlex overflow would be reported as a test exception here.
    expect(tester.takeException(), isNull);
    expect(find.textContaining('144p (144p)'), findsNothing);
    expect(find.text('Dailymotion Fast (Multi-Bitrate (HLS))'), findsOneWidget);

    // Tap outside the menu to dismiss it without a selection.
    await tester.tapAt(const Offset(10, 590));
    await tester.pumpAndSettle();
    expect(menuClosed, 1);
    expect(selectedSource, isNull);

    await tester.tap(find.byTooltip('Select Server / Quality'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dailymotion Fast (Multi-Bitrate (HLS))'));
    await tester.pumpAndSettle();
    expect(selectedSource, 1);
    expect(menuClosed, 2);
  });
}
