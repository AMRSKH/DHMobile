import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/debug_log.dart';
import '../../domain/models/show.dart';
import '../detail/detail_screen.dart';
import 'explore_controller.dart';

const _weekdayLabels = <String>[
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exploreControllerProvider);
    final controller = ref.read(exploreControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                controller.selectWeekday(controller.selectedWeekday),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day selector: Mon | Tue | Wed | ...
          SizedBox(
            height: 40,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: List.generate(7, (i) {
                  final day = i + 1;
                  final selected = controller.selectedWeekday == day;
                  final isLast = i == 6;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => controller.selectWeekday(day),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            _weekdayLabels[i],
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.white38,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      if (!isLast)
                        const Text(
                          '|',
                          style: TextStyle(color: Colors.white24, fontSize: 14),
                        ),
                    ],
                  );
                }),
              ),
            ),
          ),

          Expanded(
            child: state.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryRed),
              ),
              error: (err, _) => Center(
                child: Text(
                  'Failed to load: $err',
                  style: const TextStyle(color: AppTheme.textMuted),
                  textAlign: TextAlign.center,
                ),
              ),
              data: (shows) {
                if (shows.isEmpty) {
                  return const Center(
                    child: Text(
                      'No trending titles yet',
                      style: TextStyle(color: AppTheme.textMuted),
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
                    return _ExploreCard(show: shows[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ExploreCard extends StatelessWidget {
  final Show show;
  const _ExploreCard({required this.show});

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
                      placeholder: (_, _) =>
                          Container(color: AppTheme.surfaceDark),
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
          if (show.episodeCount != null)
            Text(
              show.episodeCount!,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
            ),
        ],
      ),
    );
  }
}
