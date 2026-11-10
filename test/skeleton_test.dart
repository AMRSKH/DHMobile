import 'package:donghua_player/core/theme/app_theme.dart';
import 'package:donghua_player/core/widgets/skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Color? _colorOf(WidgetTester tester, Finder box) {
  final decorated = tester.widget<DecoratedBox>(
    find.descendant(of: box, matching: find.byType(DecoratedBox)),
  );
  return (decorated.decoration as BoxDecoration).color;
}

void _usePhoneSizedView(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  // A skeleton animates for as long as it is on screen, so these tests pump
  // fixed durations and never pumpAndSettle.
  testWidgets('SkeletonBox pulses between the two skeleton colors', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(child: SkeletonBox(width: 100, height: 40)),
      ),
    );
    final box = find.byType(SkeletonBox);

    expect(tester.getSize(box), const Size(100, 40));
    expect(_colorOf(tester, box), AppTheme.cardDark);

    await tester.pump(const Duration(milliseconds: 500));
    final middle = _colorOf(tester, box);
    expect(middle, isNot(AppTheme.cardDark));
    expect(middle, isNot(const Color(0xFF2A2E39)));

    await tester.pump(const Duration(milliseconds: 500));
    expect(_colorOf(tester, box), const Color(0xFF2A2E39));

    // It runs back and keeps going.
    await tester.pump(const Duration(milliseconds: 1000));
    expect(_colorOf(tester, box), AppTheme.cardDark);
    expect(tester.hasRunningAnimations, isTrue);
  });

  testWidgets('SkeletonBox stops its animation when it leaves the tree', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: SkeletonBox(width: 10, height: 10)),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(SkeletonBox), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('SkeletonPosterGrid shows two columns of cards and does not '
      'scroll', (tester) async {
    _usePhoneSizedView(tester);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SkeletonPosterGrid())),
    );

    // Six cards, each with a poster and two text lines.
    expect(find.byType(SkeletonBox), findsNWidgets(18));
    final grid = tester.widget<GridView>(find.byType(GridView));
    expect(grid.physics, isA<NeverScrollableScrollPhysics>());
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 2);

    // The first two posters sit side by side.
    final posters = find.byWidgetPredicate(
      (w) => w is SkeletonBox && w.height == null,
    );
    expect(posters, findsNWidgets(6));
    expect(
      tester.getTopLeft(posters.at(0)).dy,
      tester.getTopLeft(posters.at(1)).dy,
    );
    expect(
      tester.getTopLeft(posters.at(1)).dx,
      greaterThan(tester.getTopRight(posters.at(0)).dx),
    );

    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
  });

  testWidgets('SliverSkeletonEpisodes follows the grid or the list layout', (
    tester,
  ) async {
    _usePhoneSizedView(tester);

    Widget host({required bool grid}) {
      return MaterialApp(
        home: Scaffold(
          body: CustomScrollView(slivers: [SliverSkeletonEpisodes(grid: grid)]),
        ),
      );
    }

    await tester.pumpWidget(host(grid: true));
    expect(find.byType(SkeletonBox), findsNWidgets(12));
    expect(find.byType(SliverGrid), findsOneWidget);
    // Four in a row.
    final boxes = find.byType(SkeletonBox);
    expect(
      tester.getTopLeft(boxes.at(0)).dy,
      tester.getTopLeft(boxes.at(3)).dy,
    );
    expect(
      tester.getTopLeft(boxes.at(4)).dy,
      greaterThan(tester.getTopLeft(boxes.at(0)).dy),
    );

    await tester.pumpWidget(host(grid: false));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(SkeletonBox), findsNWidgets(6));
    expect(find.byType(SliverList), findsOneWidget);
    expect(tester.getSize(find.byType(SkeletonBox).first).height, 72);
    expect(tester.takeException(), isNull);
  });
}
