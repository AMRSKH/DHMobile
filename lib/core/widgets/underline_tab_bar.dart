import 'package:flutter/material.dart';

/// Text color of the active tab.
const Color underlineTabActiveColor = Color(0xFFFFFFFF);

/// Text color of an inactive tab.
const Color underlineTabInactiveColor = Color(0xFFAAAAAA);

/// Color of the line under the active tab.
const Color underlineTabIndicatorColor = Color(0xFFFF0000);

const FontWeight _activeWeight = FontWeight.w600;
const FontWeight _inactiveWeight = FontWeight.w400;
const double _fontSize = 15;
const double _indicatorHeight = 3;
const double _indicatorRadius = 1.5;
const double _gap = 24;
const double _horizontalPadding = 16;
const double _minTapHeight = 48;
const double _labelVerticalPadding = 10;
const Duration _duration = Duration(milliseconds: 200);

/// A row of plain text tabs with a red line under the active one.
///
/// Every tab reserves the width of its label in the active weight, so a tab
/// keeps its size when it becomes active or inactive. The row scrolls
/// horizontally without a scrollbar when it does not fit.
class UnderlineTabBar extends StatelessWidget {
  /// Key of the visible line under the active tab.
  static const Key indicatorKey = ValueKey('underline-tab-indicator');

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const UnderlineTabBar({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++)
              Padding(
                padding: EdgeInsets.only(
                  right: i == labels.length - 1 ? 0 : _gap,
                ),
                child: _UnderlineTab(
                  label: labels[i],
                  selected: i == selectedIndex,
                  onTap: () => onSelected(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _UnderlineTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _UnderlineTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(
      context,
    ).style.merge(const TextStyle(fontSize: _fontSize));
    final activeStyle = base.copyWith(
      color: underlineTabActiveColor,
      fontWeight: _activeWeight,
    );
    final inactiveStyle = base.copyWith(
      color: underlineTabInactiveColor,
      fontWeight: _inactiveWeight,
    );

    return Semantics(
      container: true,
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _minTapHeight),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: _labelVerticalPadding,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Invisible copy in the active weight, at the same text
                    // scale: it sets the width, so the tab does not grow
                    // when it becomes active. It is a RichText, not a Text,
                    // so finders by text see one label per tab. Opacity 0
                    // already drops it from semantics; ExcludeSemantics only
                    // states that intent.
                    ExcludeSemantics(
                      child: Opacity(
                        opacity: 0,
                        child: RichText(
                          text: TextSpan(text: label, style: activeStyle),
                          maxLines: 1,
                          softWrap: false,
                          textScaler: MediaQuery.textScalerOf(context),
                        ),
                      ),
                    ),
                    AnimatedDefaultTextStyle(
                      duration: _duration,
                      curve: Curves.easeOut,
                      style: selected ? activeStyle : inactiveStyle,
                      maxLines: 1,
                      softWrap: false,
                      child: Text(label),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _Indicator(visible: selected),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The line under the label. It fades in and grows from the center.
class _Indicator extends StatelessWidget {
  final bool visible;

  const _Indicator({required this.visible});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: visible ? 1 : 0),
      duration: _duration,
      curve: Curves.easeOut,
      builder: (context, t, _) {
        if (t == 0) return const SizedBox(height: _indicatorHeight);
        return Opacity(
          opacity: t,
          child: Transform.scale(
            scaleX: t,
            child: Container(
              key: UnderlineTabBar.indicatorKey,
              height: _indicatorHeight,
              decoration: BoxDecoration(
                color: underlineTabIndicatorColor,
                borderRadius: BorderRadius.circular(_indicatorRadius),
              ),
            ),
          ),
        );
      },
    );
  }
}
