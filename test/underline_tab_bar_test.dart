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
  TextDirection textDirection = TextDirection.ltr,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: textDirection,
        child: Scaffold(
          body: Align(
            alignment: AlignmentDirectional.topStart,
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
    ),
  );
  if (settle) {
    // A scroll to the active tab starts on the frame after the change, so
    // pump that frame before letting the animations run.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }
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

  testWidgets('right to left: tabs are 24 px apart and the row starts 16 px '
      'in from the right', (tester) async {
    await _pumpBar(tester, textDirection: TextDirection.rtl);
    final first = tester.getRect(_tab('Schedule'));
    final second = tester.getRect(_tab('New Series'));
    final third = tester.getRect(_tab('Popular'));
    final bar = tester.getRect(find.byType(UnderlineTabBar));
    // The first tab is on the right, the others follow to the left.
    expect(bar.right - first.right, 16);
    expect(first.left - second.right, 24);
    expect(second.left - third.right, 24);
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

  group('keeps the active tab in view', () {
    // Ten labels of 180 px each in the 15 px test font, in a 300 px row.
    final labels = [for (var i = 0; i < 10; i++) 'Long label $i'];

    /// Whether the whole tab of [label], with the row padding, is inside the
    /// 300 px row.
    void expectFullyVisible(WidgetTester tester, String label) {
      final bar = tester.getRect(find.byType(UnderlineTabBar));
      final rect = tester.getRect(_tab(label));
      expect(
        rect.left,
        greaterThanOrEqualTo(bar.left + 16 - 0.01),
        reason: label,
      );
      expect(
        rect.right,
        lessThanOrEqualTo(bar.right - 16 + 0.01),
        reason: label,
      );
    }

    testWidgets('the last tab active at start is in view after the first '
        'frame', (tester) async {
      await _pumpBar(
        tester,
        width: 300,
        labels: labels,
        selected: labels.length - 1,
        settle: false,
      );
      // The jump happens after the first layout, without an animation.
      await tester.pump();
      expectFullyVisible(tester, labels.last);
      // At the end of the row: the last tab ends at the right padding.
      expect(tester.getRect(_tab(labels.last)).right, closeTo(300 - 16, 0.01));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a tab in the middle active at start is in view', (
      tester,
    ) async {
      await _pumpBar(tester, width: 300, labels: labels, selected: 5);
      expectFullyVisible(tester, labels[5]);
    });

    testWidgets('a change to a tab off screen scrolls it into view, '
        'animated', (tester) async {
      await _pumpBar(tester, width: 300, labels: labels, selected: 0);
      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
      expect(scrollable.position.pixels, 0);
      expect(tester.getRect(_tab(labels[7])).left, greaterThan(300));

      await _pumpBar(
        tester,
        width: 300,
        labels: labels,
        selected: 7,
        settle: false,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // Half way through the animation the row has moved, but not all the
      // way yet.
      final mid = scrollable.position.pixels;
      expect(mid, greaterThan(0));

      await tester.pump(const Duration(milliseconds: 200));
      expect(scrollable.position.pixels, greaterThan(mid));
      expectFullyVisible(tester, labels[7]);
      // The least scroll: the tab comes in at the right edge.
      expect(tester.getRect(_tab(labels[7])).right, closeTo(300 - 16, 0.01));

      // Back to the first tab: it comes in at the left edge.
      await _pumpBar(tester, width: 300, labels: labels, selected: 0);
      expect(scrollable.position.pixels, 0);
      expectFullyVisible(tester, labels.first);
    });

    testWidgets('a change to a tab already in view does not scroll', (
      tester,
    ) async {
      // Labels of 180 px: in 600 px the first two tabs are in view.
      await _pumpBar(tester, width: 600, labels: labels, selected: 0);
      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
      await _pumpBar(tester, width: 600, labels: labels, selected: 1);
      expect(scrollable.position.pixels, 0);
      expect(scrollable.position.maxScrollExtent, greaterThan(0));
    });

    testWidgets('an index out of range does nothing', (tester) async {
      await _pumpBar(tester, width: 300, labels: labels, selected: 3);
      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
      final before = scrollable.position.pixels;

      for (final index in [-1, labels.length, 99]) {
        await _pumpBar(tester, width: 300, labels: labels, selected: index);
        expect(tester.takeException(), isNull);
        expect(scrollable.position.pixels, before);
        expect(find.byKey(UnderlineTabBar.indicatorKey), findsNothing);
      }

      await _pumpBar(tester, width: 300, labels: labels, selected: -1);
      await _pumpBar(tester, width: 300, labels: labels, selected: 99);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an index out of range at start does nothing', (tester) async {
      await _pumpBar(tester, width: 300, labels: labels, selected: 99);
      expect(tester.takeException(), isNull);
      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
      expect(scrollable.position.pixels, 0);
    });

    testWidgets('a row that fits never scrolls', (tester) async {
      for (final index in [0, 2, 1, 2]) {
        await _pumpBar(tester, selected: index);
        expect(tester.takeException(), isNull);
        final scrollable = tester.state<ScrollableState>(
          find.byType(Scrollable),
        );
        expect(scrollable.position.pixels, 0);
        expect(scrollable.position.maxScrollExtent, 0);
      }
    });

    testWidgets('longer labels at the same index keep the tab in view', (
      tester,
    ) async {
      await _pumpBar(tester, width: 300, labels: labels, selected: 9);
      expectFullyVisible(tester, labels[9]);

      // For example a language change: every label grows, the index stays.
      final longer = [for (var i = 0; i < 10; i++) 'Longer label $i'];
      await _pumpBar(tester, width: 300, labels: longer, selected: 9);
      expect(tester.takeException(), isNull);
      expectFullyVisible(tester, longer[9]);
    });

    testWidgets('shorter labels at the same index keep the tab in view', (
      tester,
    ) async {
      await _pumpBar(tester, width: 300, labels: labels, selected: 4);
      expectFullyVisible(tester, labels[4]);

      final shorter = [for (var i = 0; i < 10; i++) 'Tab $i'];
      await _pumpBar(tester, width: 300, labels: shorter, selected: 4);
      expectFullyVisible(tester, shorter[4]);
    });

    testWidgets('a narrower row keeps the tab in view', (tester) async {
      // In 800 px (the width of the test screen) tab 2 is in view at
      // offset 0.
      await _pumpBar(tester, width: 800, labels: labels, selected: 2);
      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
      expect(scrollable.position.pixels, 0);
      expect(tester.getRect(_tab(labels[2])).right, lessThanOrEqualTo(784));

      // For example a rotation to portrait.
      await _pumpBar(tester, width: 300, labels: labels, selected: 2);
      expect(tester.takeException(), isNull);
      expectFullyVisible(tester, labels[2]);
    });

    testWidgets('the same width does not scroll a row moved by hand', (
      tester,
    ) async {
      await _pumpBar(tester, width: 300, labels: labels, selected: 0);
      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
      await tester.drag(find.byType(Scrollable), const Offset(-500, 0));
      await tester.pump(const Duration(milliseconds: 300));
      final moved = scrollable.position.pixels;
      expect(moved, greaterThan(0));

      // A rebuild with the same width, labels and index leaves it there.
      await _pumpBar(tester, width: 300, labels: labels, selected: 0);
      expect(scrollable.position.pixels, moved);
    });

    testWidgets('right to left: the last tab active at start is in view', (
      tester,
    ) async {
      await _pumpBar(
        tester,
        width: 300,
        labels: labels,
        selected: labels.length - 1,
        textDirection: TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
      expectFullyVisible(tester, labels.last);
      // The row runs right to left: the last tab ends at the left padding.
      final bar = tester.getRect(find.byType(UnderlineTabBar));
      expect(
        tester.getRect(_tab(labels.last)).left,
        closeTo(bar.left + 16, 0.01),
      );

      await _pumpBar(
        tester,
        width: 300,
        labels: labels,
        selected: 0,
        textDirection: TextDirection.rtl,
      );
      expectFullyVisible(tester, labels.first);
      expect(
        tester.getRect(_tab(labels.first)).right,
        closeTo(bar.right - 16, 0.01),
      );
    });

    testWidgets('fewer labels than before do not throw', (tester) async {
      await _pumpBar(tester, width: 300, labels: labels, selected: 9);
      await _pumpBar(tester, width: 300, labels: labels.sublist(0, 3));
      expect(tester.takeException(), isNull);
      expect(find.text(labels[2]), findsOneWidget);
      expect(find.text(labels[3]), findsNothing);
    });
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
