import 'package:donghua_player/core/app_info.dart';
import 'package:donghua_player/core/theme/app_theme.dart';
import 'package:donghua_player/data/storage/storage_service.dart';
import 'package:donghua_player/features/home/main_screen.dart';
import 'package:donghua_player/features/library/library_controller.dart';
import 'package:donghua_player/features/search/search_controller.dart';
import 'package:donghua_player/features/splash/splash_screen.dart';
import 'package:donghua_player/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_stream_provider.dart';

Future<FakeStreamProvider> _pumpApp(WidgetTester tester) async {
  final fake = FakeStreamProvider();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        streamProvider.overrideWithValue(fake),
        storageServiceProvider.overrideWithValue(StorageService()),
      ],
      child: const DonghuaApp(),
    ),
  );
  return fake;
}

Text _logo(WidgetTester tester) => tester.widget<Text>(find.text(AppInfo.name));

double _logoScale(WidgetTester tester) {
  final transform = tester.widget<Transform>(find.byKey(SplashScreen.logoKey));
  // The horizontal scale. The z axis of the matrix always stays at 1.
  return transform.transform.entry(0, 0);
}

/// Plays the rest of the splash and the fade into the app. [played] is the
/// time the test has already pumped.
///
/// An animation reports "completed" on the first frame after its full
/// length, so each step pumps a little more than the nominal duration.
Future<void> _finishSplash(
  WidgetTester tester, {
  Duration played = Duration.zero,
}) async {
  const extra = Duration(milliseconds: 50);
  await tester.pump(SplashScreen.animationDuration - played + extra);
  await tester.pump();
  await tester.pump(SplashScreen.handoverDuration + extra);
  await tester.pump();
}

void main() {
  testWidgets('the app starts with the red logo on black and nothing else', (
    tester,
  ) async {
    await _pumpApp(tester);

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).title,
      'DHMobile',
    );
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(MainScreen), findsNothing);
    expect(find.text('DHMobile'), findsOneWidget);

    final scaffold = tester.widget<Scaffold>(
      find.descendant(
        of: find.byType(SplashScreen),
        matching: find.byType(Scaffold),
      ),
    );
    expect(scaffold.backgroundColor, Colors.black);

    // The credit lines moved to Settings, About.
    expect(find.textContaining('AMSCenter'), findsNothing);
    expect(find.textContaining('AMSDev'), findsNothing);
    expect(find.text('DonghuaMobile'), findsNothing);

    await _finishSplash(tester);
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(MainScreen), findsOneWidget);
  });

  testWidgets('the logo fades in, holds, then zooms and fades out', (
    tester,
  ) async {
    await _pumpApp(tester);

    // Start: invisible and a little small.
    expect(_logo(tester).style!.color!.a, 0.0);
    expect(_logoScale(tester), closeTo(0.80, 0.001));
    expect(_logo(tester).textScaler, TextScaler.noScaling);
    expect(_logo(tester).style!.fontWeight, FontWeight.w900);

    // 30%: fully visible at its normal size, in the app's red.
    await tester.pump(const Duration(milliseconds: 600));
    expect(_logo(tester).style!.color, AppTheme.primaryRed);
    expect(_logoScale(tester), closeTo(1.00, 0.001));

    // 50%: the slow push.
    await tester.pump(const Duration(milliseconds: 400));
    expect(_logo(tester).style!.color!.a, 1.0);
    expect(_logoScale(tester), closeTo(1.04, 0.001));

    // 70%: the zoom starts from 1.08.
    await tester.pump(const Duration(milliseconds: 400));
    expect(_logoScale(tester), closeTo(1.08, 0.001));
    expect(_logo(tester).style!.color!.a, 1.0);

    // 95%: zooming and fading.
    await tester.pump(const Duration(milliseconds: 500));
    expect(_logoScale(tester), greaterThan(3.0));
    expect(_logo(tester).style!.color!.a, inExclusiveRange(0.0, 1.0));
    expect(find.byType(MainScreen), findsNothing);

    await _finishSplash(tester, played: const Duration(milliseconds: 1900));
    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets('the splash hands over to Explore by itself, without waiting '
      'for a tap', (tester) async {
    final fake = await _pumpApp(tester);

    // The splash starts the schedule request while it plays.
    await tester.pump();
    expect(fake.scheduleCalls, 1);

    await tester.pump(const Duration(milliseconds: 1900));
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(MainScreen), findsNothing);

    // The first frame after the full 2000 ms starts the handover.
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump();
    // Both are on screen while the app fades in over the black splash.
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(MainScreen), findsOneWidget);

    await tester.pump(
      SplashScreen.handoverDuration + const Duration(milliseconds: 50),
    );
    await tester.pump();

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(MainScreen), findsOneWidget);
    // The title of the Explore page and the label in the navigation bar.
    expect(find.text('Explore'), findsNWidgets(2));
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Schedule'), findsOneWidget);
    expect(find.text('Day ${DateTime.now().weekday} Show'), findsOneWidget);
    // The schedule that the splash asked for is used. It is not loaded twice.
    expect(fake.scheduleCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the splash is not affected by the font scale of the system', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pumpApp(tester);
    await tester.pump(const Duration(milliseconds: 600));
    final scaled = tester.getSize(find.text(AppInfo.name));
    await _finishSplash(tester, played: const Duration(milliseconds: 600));

    tester.platformDispatcher.clearTextScaleFactorTestValue();
    await tester.pumpWidget(const SizedBox());
    await _pumpApp(tester);
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.getSize(find.text(AppInfo.name)), scaled);
    await _finishSplash(tester, played: const Duration(milliseconds: 600));
  });
}
