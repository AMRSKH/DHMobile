import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
/// horizontally without a scrollbar when it does not fit, and keeps the
/// active tab in view: at once on the first layout and when the labels or
/// the width change, animated when [selectedIndex] changes.
class UnderlineTabBar extends StatefulWidget {
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
  State<UnderlineTabBar> createState() => _UnderlineTabBarState();
}

class _UnderlineTabBarState extends State<UnderlineTabBar> {
  final ScrollController _controller = ScrollController();

  /// One key per tab, so the active tab can be found after layout. Each tab
  /// keeps its own key, so no subtree moves when the selection changes.
  List<GlobalKey> _tabKeys = const [];

  /// Width of the row at the last layout, to see a change such as a
  /// rotation.
  double? _lastWidth;

  @override
  void initState() {
    super.initState();
    _syncKeys();
    _revealSelectedAfterLayout(animate: false);
  }

  @override
  void didUpdateWidget(UnderlineTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncKeys();
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _revealSelectedAfterLayout(animate: true);
    } else if (!listEquals(oldWidget.labels, widget.labels)) {
      // Other labels, for example after a language change, move the tabs.
      _revealSelectedAfterLayout(animate: false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _syncKeys() {
    final count = widget.labels.length;
    if (_tabKeys.length == count) return;
    _tabKeys = [
      for (var i = 0; i < count; i++)
        i < _tabKeys.length ? _tabKeys[i] : GlobalKey(),
    ];
  }

  void _revealSelectedAfterLayout({required bool animate}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _revealSelected(animate: animate);
    });
  }

  /// Scrolls the least distance that shows the active tab with the row
  /// padding on both sides. Does nothing when it is already visible, when
  /// the row fits, or when [UnderlineTabBar.selectedIndex] is out of range.
  void _revealSelected({required bool animate}) {
    final index = widget.selectedIndex;
    if (index < 0 || index >= _tabKeys.length) return;
    if (!_controller.hasClients) return;
    final box = _tabKeys[index].currentContext?.findRenderObject();
    if (box == null || !box.attached) return;
    final viewport = RenderAbstractViewport.maybeOf(box);
    if (viewport == null) return;

    final position = _controller.position;
    // Offsets that put the tab at the start or at the end of the view.
    final atStart = viewport.getOffsetToReveal(box, 0).offset;
    final atEnd = viewport.getOffsetToReveal(box, 1).offset;
    var target = position.pixels;
    if (target > atStart - _horizontalPadding) {
      target = atStart - _horizontalPadding;
    } else if (target < atEnd + _horizontalPadding) {
      target = atEnd + _horizontalPadding;
    }
    target = target.clamp(position.minScrollExtent, position.maxScrollExtent);
    if ((target - position.pixels).abs() < 0.5) return;

    if (animate) {
      _controller.animateTo(target, duration: _duration, curve: Curves.easeOut);
    } else {
      _controller.jumpTo(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.labels;
    return LayoutBuilder(
      builder: (context, constraints) {
        // A new width, for example after a rotation, can leave the active
        // tab off screen. Only a change schedules a reveal, so this cannot
        // loop.
        final width = constraints.maxWidth;
        if (_lastWidth != null && _lastWidth != width) {
          _revealSelectedAfterLayout(animate: false);
        }
        _lastWidth = width;
        return _buildRow(context, labels);
      },
    );
  }

  Widget _buildRow(BuildContext context, List<String> labels) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: SingleChildScrollView(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++)
              Padding(
                padding: EdgeInsetsDirectional.only(
                  end: i == labels.length - 1 ? 0 : _gap,
                ),
                child: _UnderlineTab(
                  key: _tabKeys[i],
                  label: labels[i],
                  selected: i == widget.selectedIndex,
                  onTap: () => widget.onSelected(i),
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
    super.key,
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
