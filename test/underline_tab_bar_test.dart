import 'dart:io';

import 'package:donghua_player/core/widgets/underline_tab_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _labels = ['Schedule', 'New Series', 'Popular'];

/// Family name of the Roboto files loaded for the real-font tests.
const _realFont = 'TabBarRoboto';

/// The Roboto files of the Flutter SDK, or null when one is missing.
List<File>? _robotoFiles() {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null || root.isEmpty) return null;
  final dir = [
    root,
    'bin',
    'cache',
    'artifacts',
    'material_fonts',
  ].join(Platform.pathSeparator);
  final files = [
    for (final name in [
      'roboto-regular.ttf',
      'roboto-medium.ttf',
      'roboto-bold.ttf',
    ])
      File('$dir${Platform.pathSeparator}$name'),
  ];
  return files.every((file) => file.existsSync()) ? files : null;
}

/// Pumps the bar in the real font at [scale] and lets the animations finish.
Future<void> _pumpRealFont(
  WidgetTester tester, {
  required int selected,
  required double scale,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: Scaffold(
            body: DefaultTextStyle(
              style: const TextStyle(fontFamily: _realFont),
              child: Align(
                alignment: Alignment.topLeft,
                child: UnderlineTabBar(
                  labels: _labels,
                  selectedIndex: selected,
                  onSelected: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
}

/// Pumps the bar with [selected] active and lets the animations finish.
Future<void> _pumpBar(
  WidgetTester tester, {
  int selected = 0,
  List<String> labels = _labels,
  ValueChanged<int>? onSelected,
  double width = 600,
  bool settle = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: UnderlineTabBar(
              labels: labels,
              selectedIndex: selected,
              onSelected: onSelected ?? (_) {},
            ),
          ),
        ),
      ),
    ),
  );
  if (settle) await tester.pump(const Duration(milliseconds: 300));
}

/// The style the visible label is painted with.
TextStyle _labelStyle(WidgetTester tester, String label) {
  final richText = tester.widget<RichText>(
    find.descendant(of: find.text(label), matching: find.byType(RichText)),
  );
  return richText.text.style!;
}

/// The whole tab around [label]: the tap target with the semantics flags.
Finder _tab(String label) {
  return find.ancestor(
    of: find.text(label),
    matching: find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.button == true,
    ),
  );
}

void main() {
  testWidgets('active label is white w600, inactive gray w400, same size', (
    tester,
  ) async {
    await _pumpBar(tester, selected: 1);

    final active = _labelStyle(tester, 'New Series');
    expect(active.color, const Color(0xFFFFFFFF));
    expect(active.fontWeight, FontWeight.w600);
    expect(active.fontSize, 15);

    for (final label in ['Schedule', 'Popular']) {
      final inactive = _labelStyle(tester, label);
      expect(inactive.color, const Color(0xFFAAAAAA));
      expect(inactive.fontWeight, FontWeight.w400);
      expect(inactive.fontSize, 15);
    }
  });

  testWidgets('no background, border or ink on the tabs', (tester) async {
    await _pumpBar(tester);
    final bar = find.byType(UnderlineTabBar);
    expect(
      find.descendant(of: bar, matching: find.byType(InkWell)),
      findsNothing,
    );
    expect(
      find.descendant(of: bar, matching: find.byType(Material)),
      findsNothing,
    );
    expect(find.byType(ChoiceChip), findsNothing);
  });

  testWidgets('the indicator is red, 3 px, rounded, under the active label '
      'only and as wide as the label', (tester) async {
    await _pumpBar(tester, selected: 2);

    final indicator = find.byKey(UnderlineTabBar.indicatorKey);
    expect(indicator, findsOneWidget);
    expect(
      find.descendant(of: _tab('Popular'), matching: indicator),
      findsOneWidget,
    );

    final box =
        tester.widget<Container>(indicator).decoration! as BoxDecoration;
    expect(box.color, const Color(0xFFFF0000));
    expect(box.borderRadius, BorderRadius.circular(1.5));

    final indicatorRect = tester.getRect(indicator);
    final labelRect = tester.getRect(find.text('Popular'));
    final tabRect = tester.getRect(_tab('Popular'));
    expect(indicatorRect.height, 3);
    // The label reserves the active width, so at the active weight the text
    // and the line have the same width and the same center.
    expect(indicatorRect.width, closeTo(labelRect.width, 0.01));
    expect(indicatorRect.center.dx, closeTo(labelRect.center.dx, 0.01));
    // Below the label, on the bottom edge of the tab.
    expect(indicatorRect.top, greaterThanOrEqualTo(labelRect.bottom));
    expect(indicatorRect.bottom, tabRect.bottom);
  });

  testWidgets('the indicator and the colors animate to the new tab', (
    tester,
  ) async {
    await _pumpBar(tester, selected: 1);
    await _pumpBar(tester, selected: 2, settle: false);
    // Half way: both lines are on screen and the color is between the two.
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(UnderlineTabBar.indicatorKey), findsNWidgets(2));
    final mid = _labelStyle(tester, 'Popular').color!;
    expect(mid, isNot(const Color(0xFFFFFFFF)));
    expect(mid, isNot(const Color(0xFFAAAAAA)));

    // Done after about 200 ms.
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byKey(UnderlineTabBar.indicatorKey), findsOneWidget);
    expect(
      find.descendant(
        of: _tab('Popular'),
        matching: find.byKey(UnderlineTabBar.indicatorKey),
      ),
      findsOneWidget,
    );
    expect(_labelStyle(tester, 'Popular').color, const Color(0xFFFFFFFF));
    expect(_labelStyle(tester, 'New Series').color, const Color(0xFFAAAAAA));
  });

  group('with a real font', () {
    // The test font draws every weight at the same width, so a layout shift
    // between w400 and w600 only shows with a real font. Roboto ships with
    // the Flutter SDK; `flutter test` sets FLUTTER_ROOT.
    final fontFiles = _robotoFiles();
    final skip = fontFiles == null
        ? 'Roboto not found under FLUTTER_ROOT/bin/cache/artifacts/'
              'material_fonts; set FLUTTER_ROOT to the Flutter SDK'
        : null;

    setUpAll(() async {
      if (fontFiles == null) return;
      final loader = FontLoader(_realFont);
      for (final file in fontFiles) {
        final bytes = file.readAsBytesSync();
        loader.addFont(Future.value(ByteData.sublistView(bytes)));
      }
      await loader.load();
    });

    for (final scale in [1.0, 1.6]) {
      testWidgets('a tab keeps its size and place when it becomes active, '
          'text scale $scale', (tester) async {
        await _pumpRealFont(tester, selected: 0, scale: scale);
        final before = {for (final l in _labels) l: tester.getRect(_tab(l))};
        final regularWidth = tester.getSize(find.text('New Series')).width;

        await _pumpRealFont(tester, selected: 1, scale: scale);
        final after = {for (final l in _labels) l: tester.getRect(_tab(l))};
        final boldWidth = tester.getSize(find.text('New Series')).width;

        // The font really is wider at w600, so the test can see a shift.
        expect(boldWidth, greaterThan(regularWidth));
        for (final label in _labels) {
          expect(after[label], before[label], reason: label);
        }
        // The reserved width is the label at w600.
        expect(after['New Series']!.width, closeTo(boldWidth, 0.01));
      }, skip: skip != null);
    }
    if (skip != null) {
      // ignore: avoid_print
      print('Skipped the real-font tests: $skip');
    }
  });

  testWidgets('tabs are 24 px apart and the row starts 16 px in', (
    tester,
  ) async {
    await _pumpBar(tester);
    final first = tester.getRect(_tab('Schedule'));
    final second = tester.getRect(_tab('New Series'));
    final third = tester.getRect(_tab('Popular'));
    final bar = tester.getRect(find.byType(UnderlineTabBar));
    expect(first.left - bar.left, 16);
    expect(second.left - first.right, 24);
    expect(third.left - second.right, 24);
  });

  testWidgets('the tap target is at least 48 px high', (tester) async {
    await _pumpBar(tester);
    for (final label in _labels) {
      expect(tester.getSize(_tab(label)).height, greaterThanOrEqualTo(48));
    }
  });

  testWidgets('tapping a tab calls onSelected with its index', (tester) async {
    final taps = <int>[];
    await _pumpBar(tester, onSelected: taps.add);

    await tester.tap(find.text('Popular'));
    await tester.tap(find.text('New Series'));
    await tester.tap(find.text('Schedule'));
    expect(taps, [2, 1, 0]);
  });

  testWidgets('each tab is a button with the selected flag', (tester) async {
    final handle = tester.ensureSemantics();
    await _pumpBar(tester, selected: 1);

    expect(
      tester.getSemantics(find.text('New Series')),
      containsSemantics(
        label: 'New Series',
        isButton: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
    for (final label in ['Schedule', 'Popular']) {
      expect(
        tester.getSemantics(find.text(label)),
        containsSemantics(
          label: label,
          isButton: true,
          isSelected: false,
          hasTapAction: true,
        ),
      );
    }
    handle.dispose();
  });

  testWidgets('no scrollbar, even under a behavior that adds one', (
    tester,
  ) async {
    final labels = [for (var i = 0; i < 8; i++) 'A long tab label $i'];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScrollConfiguration(
            behavior: const _AlwaysScrollbarBehavior(),
            child: Column(
              children: [
                SizedBox(
                  width: 120,
                  child: UnderlineTabBar(
                    labels: labels,
                    selectedIndex: 0,
                    onSelected: (_) {},
                  ),
                ),
                // Control: a plain horizontal scroll view in the same place
                // does get a scrollbar from the behavior.
                const SizedBox(
                  key: ValueKey('control'),
                  width: 120,
                  height: 40,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(width: 1000, height: 40),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.descendant(
        of: find.byType(UnderlineTabBar),
        matching: find.byType(Scrollbar),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('control')),
        matching: find.byType(Scrollbar),
      ),
      findsOneWidget,
    );
  });

  testWidgets('many long labels in a narrow row fit without overflow and '
      'scroll', (tester) async {
    // Ten labels of 180 px each in the 15 px test font, in a 300 px row.
    final labels = [for (var i = 0; i < 10; i++) 'Long label $i'];
    final taps = <int>[];
    await _pumpBar(tester, width: 300, labels: labels, onSelected: taps.add);
    expect(tester.takeException(), isNull);

    final last = find.text(labels.last);
    final startX = tester.getRect(last).left;
    expect(startX, greaterThan(300));

    // Scroll to the end: the last tab ends at the right padding.
    await tester.drag(find.byType(Scrollable), const Offset(-5000, 0));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.getRect(last).left, lessThan(startX));
    expect(tester.getRect(last).right, 300 - 16);

    await tester.tap(last);
    expect(taps, [labels.length - 1]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Khmer labels are not clipped', (tester) async {
    const khmer = ['កាលវិភាគ', 'រឿងថ្មី', 'ពេញនិយម'];
    await _pumpBar(tester, labels: khmer);
    expect(tester.takeException(), isNull);
    for (final label in khmer) {
      final text = tester.getRect(find.text(label));
      final tab = tester.getRect(_tab(label));
      expect(text.top, greaterThanOrEqualTo(tab.top));
      expect(text.bottom, lessThanOrEqualTo(tab.bottom));
    }
  });
}

/// Adds a scrollbar to every scroll view, in both directions and on every
/// platform, so the test can see that the tab bar turns it off.
class _AlwaysScrollbarBehavior extends MaterialScrollBehavior {
  const _AlwaysScrollbarBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return Scrollbar(controller: details.controller, child: child);
  }
}
