import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The lighter end of the skeleton pulse. The darker end is
/// [AppTheme.cardDark].
const Color _skeletonHighlight = Color(0xFF2A2E39);

/// A grey block that pulses while the real content loads.
///
/// The animation never stops, so a widget test with a skeleton on screen has
/// to use `pump(duration)` and not `pumpAndSettle`.
class SkeletonBox extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = BorderRadius.zero,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  late final Animation<Color?> _color = ColorTween(
    begin: AppTheme.cardDark,
    end: _skeletonHighlight,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _color,
      builder: (context, _) => DecoratedBox(
        decoration: BoxDecoration(
          color: _color.value,
          borderRadius: widget.borderRadius,
        ),
        child: SizedBox(width: widget.width, height: widget.height),
      ),
    );
  }
}

/// Placeholder for a two-column grid of posters with a title line each.
/// It does not scroll.
class SkeletonPosterGrid extends StatelessWidget {
  final int itemCount;
  final EdgeInsetsGeometry padding;
  final double childAspectRatio;
  final double mainAxisSpacing;
  final double crossAxisSpacing;

  const SkeletonPosterGrid({
    super.key,
    this.itemCount = 6,
    this.padding = const EdgeInsets.all(12),
    this.childAspectRatio = 0.62,
    this.mainAxisSpacing = 12,
    this.crossAxisSpacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => const _SkeletonPosterCard(),
    );
  }
}

class _SkeletonPosterCard extends StatelessWidget {
  const _SkeletonPosterCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SkeletonBox(
            width: double.infinity,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        const SizedBox(height: 8),
        SkeletonBox(
          width: double.infinity,
          height: 12,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 6),
        FractionallySizedBox(
          widthFactor: 0.5,
          child: SkeletonBox(
            height: 10,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}

/// Placeholder for the episode list of the Detail screen, as a sliver.
/// [grid] follows the layout the user has chosen: the four-column grid of
/// episode numbers, or the list of episode rows.
class SliverSkeletonEpisodes extends StatelessWidget {
  final bool grid;

  const SliverSkeletonEpisodes({super.key, required this.grid});

  @override
  Widget build(BuildContext context) {
    if (grid) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 1.6,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) =>
                SkeletonBox(borderRadius: BorderRadius.circular(8)),
            childCount: 12,
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SkeletonBox(
              height: 72,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          childCount: 6,
        ),
      ),
    );
  }
}
