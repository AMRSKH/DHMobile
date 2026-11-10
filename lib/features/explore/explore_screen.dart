import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/debug_log.dart';
import '../../core/widgets/skeleton.dart';
import '../../domain/models/schedule_entry.dart';
import '../../domain/models/show.dart';
import '../detail/detail_screen.dart';
import '../settings/settings_controller.dart';
import 'explore_controller.dart';

/// The line under a schedule card: the episode and when it comes out, for
/// example "EP 47 · 10:50" or "EP 564 · Released".
///
/// The time is the local time of [ScheduleEntry.releaseAt]. Without it, the
/// text of the source is shown as it is.
String scheduleCaption(ScheduleEntry entry, AppStrings strings) {
  final String? release;
  if (entry.released) {
    release = strings(S.released);
  } else if (entry.releaseAt != null) {
    final local = entry.releaseAt!.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    release = '$hh:$mm';
  } else {
    release = entry.releaseText;
  }
  return [
    entry.show.episodeCount,
    release,
  ].whereType<String>().where((part) => part.isNotEmpty).join(' · ');
}

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(exploreControllerProvider);
    final controller = ref.read(exploreControllerProvider.notifier);
    final s = ref.watch(stringsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s(S.explore)),
        actions: [
          IconButton(
            tooltip: s(S.refresh),
            icon: const Icon(Icons.refresh),
            onPressed: controller.refresh,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CategoryRow(
            selected: state.category,
            strings: s,
            onSelected: controller.selectCategory,
          ),
          if (state.category == ExploreCategory.schedule)
            _DayRow(
              selected: state.weekday,
              strings: s,
              onSelected: controller.selectWeekday,
            ),
          Expanded(child: _body(state, controller, s)),
        ],
      ),
    );
  }

  Widget _body(ExploreState state, ExploreController controller, AppStrings s) {
    switch (state.category) {
      case ExploreCategory.schedule:
        return _AsyncGrid<Map<int, List<ScheduleEntry>>>(
          value: state.schedule,
          strings: s,
          onRetry: controller.refresh,
          builder: (week) {
            final entries = week[state.weekday] ?? const <ScheduleEntry>[];
            return _ShowGrid(
              // A new key per day, so the list starts at the top again.
              key: ValueKey('schedule-${state.weekday}'),
              emptyText: s(S.exploreEmptyDay),
              shows: [for (final entry in entries) entry.show],
              captions: [
                for (final entry in entries) scheduleCaption(entry, s),
              ],
            );
          },
        );
      case ExploreCategory.newSeries:
        return _seriesGrid(state.newSeries, controller, s, 'newSeries');
      case ExploreCategory.popular:
        return _seriesGrid(state.popular, controller, s, 'popular');
    }
  }

  Widget _seriesGrid(
    AsyncValue<List<Show>> value,
    ExploreController controller,
    AppStrings s,
    String key,
  ) {
    return _AsyncGrid<List<Show>>(
      value: value,
      strings: s,
      onRetry: controller.refresh,
      builder: (shows) => _ShowGrid(
        key: ValueKey(key),
        emptyText: s(S.exploreEmptyList),
        shows: shows,
        captions: [for (final show in shows) show.status ?? ''],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final ExploreCategory selected;
  final AppStrings strings;
  final ValueChanged<ExploreCategory> onSelected;

  const _CategoryRow({
    required this.selected,
    required this.strings,
    required this.onSelected,
  });

  static const Map<ExploreCategory, S> _labels = {
    ExploreCategory.schedule: S.categorySchedule,
    ExploreCategory.newSeries: S.categoryNewSeries,
    ExploreCategory.popular: S.categoryPopular,
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Row(
        children: [
          for (final category in ExploreCategory.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(strings(_labels[category]!)),
                selected: category == selected,
                showCheckmark: false,
                selectedColor: AppTheme.primaryRed,
                backgroundColor: AppTheme.cardDark,
                side: BorderSide.none,
                labelStyle: TextStyle(
                  color: category == selected ? Colors.white : Colors.white70,
                  fontWeight: category == selected
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
                onSelected: (_) => onSelected(category),
              ),
            ),
        ],
      ),
    );
  }
}

/// Day selector: Mon | Tue | Wed | ...
class _DayRow extends StatelessWidget {
  final int selected;
  final AppStrings strings;
  final ValueChanged<int> onSelected;

  const _DayRow({
    required this.selected,
    required this.strings,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    // 44 high: Khmer letters with marks above and below need more room than
    // Latin text of the same size.
    return SizedBox(
      height: 44,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: List.generate(7, (i) {
            final day = i + 1;
            final isSelected = selected == day;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => onSelected(day),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 8,
                    ),
                    child: Text(
                      strings.weekdayShort(day),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white38,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                if (i < 6)
                  const Text(
                    '|',
                    style: TextStyle(color: Colors.white24, fontSize: 14),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

/// Skeleton while loading, a fixed text with Retry on failure, the grid of
/// [builder] otherwise.
class _AsyncGrid<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final AppStrings strings;
  final VoidCallback onRetry;
  final Widget Function(T data) builder;

  const _AsyncGrid({
    required this.value,
    required this.strings,
    required this.onRetry,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnReload: false,
      skipLoadingOnRefresh: false,
      loading: () => const SkeletonPosterGrid(),
      // The error itself is in the debug log. It can hold addresses and
      // technical text that mean nothing to the user.
      error: (_, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: AppTheme.textMuted,
              ),
              const SizedBox(height: 12),
              Text(
                strings(S.loadFailed),
                style: const TextStyle(color: AppTheme.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  foregroundColor: Colors.white,
                ),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(strings(S.retry)),
              ),
            ],
          ),
        ),
      ),
      data: builder,
    );
  }
}

class _ShowGrid extends StatelessWidget {
  final List<Show> shows;

  /// One line per show, shown under its title. An empty line is left out.
  final List<String> captions;
  final String emptyText;

  const _ShowGrid({
    super.key,
    required this.shows,
    required this.captions,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    if (shows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            emptyText,
            style: const TextStyle(color: AppTheme.textMuted),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.62,
      ),
      itemCount: shows.length,
      itemBuilder: (context, index) {
        return _ExploreCard(show: shows[index], caption: captions[index]);
      },
    );
  }
}

class _ExploreCard extends StatelessWidget {
  final Show show;
  final String caption;

  const _ExploreCard({required this.show, required this.caption});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => DetailScreen(show: show)));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (show.poster.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: show.poster,
                      httpHeaders: const {
                        'Referer': 'https://animexin.dev/',
                        'User-Agent':
                            'Mozilla/5.0 (Linux; Android 11; Pixel 5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
                      },
                      fit: BoxFit.cover,
                      placeholder: (_, _) => const SkeletonBox(),
                      errorListener: (e) =>
                          DLog.event('explore.imageError', '${show.title} $e'),
                      errorWidget: (_, _, _) => Container(
                        color: AppTheme.surfaceDark,
                        child: const Icon(
                          Icons.movie,
                          color: AppTheme.textMuted,
                          size: 40,
                        ),
                      ),
                    )
                  else
                    Container(
                      color: AppTheme.surfaceDark,
                      child: const Icon(
                        Icons.movie,
                        color: AppTheme.textMuted,
                        size: 40,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            show.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (caption.isNotEmpty)
            Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
            ),
        ],
      ),
    );
  }
}
