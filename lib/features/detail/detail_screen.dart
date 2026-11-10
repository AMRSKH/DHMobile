import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/debug_log.dart';
import '../../domain/models/show.dart';
import '../../domain/models/episode.dart';
import '../library/library_controller.dart';
import '../player/player_screen.dart';
import 'detail_controller.dart';

class DetailScreen extends ConsumerStatefulWidget {
  final Show show;
  final void Function(Episode episode, List<Episode> allEpisodes)?
  onEpisodeSelected;

  const DetailScreen({super.key, required this.show, this.onEpisodeSelected});

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> {
  bool _isSynopsisExpanded = false;
  bool _isGridView = true;

  String _formatTime(int ms) {
    final dur = Duration(milliseconds: ms);
    final m = dur.inMinutes;
    final s = dur.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final episodesAsync = ref.watch(showEpisodesProvider(widget.show.id));
    final favorites = ref.watch(favoritesProvider);
    final isFav = favorites.any((s) => s.id == widget.show.id);
    final history = ref.watch(historyProvider);
    final lastWatched = history
        .where((h) => h.show.id == widget.show.id)
        .firstOrNull;
    final historyByEpisode = {
      for (final item in history) item.episode.id: item,
    };

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            actions: [
              IconButton(
                icon: Icon(
                  isFav
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFav ? AppTheme.primaryRed : Colors.white,
                ),
                tooltip: isFav ? 'Remove Favorite' : 'Add to Favorites',
                onPressed: () {
                  ref
                      .read(favoritesProvider.notifier)
                      .toggleFavorite(widget.show);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      duration: const Duration(seconds: 1),
                      content: Text(
                        isFav ? 'Removed from favorites' : 'Added to favorites',
                      ),
                    ),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.show.poster.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: widget.show.poster,
                      httpHeaders: const {
                        'Referer': 'https://animexin.dev/',
                        'User-Agent':
                            'Mozilla/5.0 (Linux; Android 11; Pixel 5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
                      },
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) =>
                          Container(color: const Color(0xFF181A20)),
                    )
                  else
                    Container(color: const Color(0xFF181A20)),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF101216).withValues(alpha: 0.8),
                          const Color(0xFF101216),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.show.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (widget.show.episodeCount != null)
                        _TagBadge(
                          label: widget.show.episodeCount!,
                          color: AppTheme.primaryRed,
                        ),
                      ...widget.show.genres.map(
                        (g) =>
                            _TagBadge(label: g, color: const Color(0xFF262A34)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Watch Now or Continue Watching button
                  episodesAsync.maybeWhen(
                    data: (episodes) {
                      if (episodes.isEmpty) return const SizedBox.shrink();

                      if (lastWatched != null) {
                        final epIndex = episodes.indexWhere(
                          (e) => e.id == lastWatched.episode.id,
                        );
                        final targetEp = epIndex >= 0
                            ? episodes[epIndex]
                            : episodes.first;
                        final targetIndex = epIndex >= 0 ? epIndex : 0;
                        final epNumStr = targetEp.number % 1 == 0
                            ? targetEp.number.toInt().toString()
                            : targetEp.number.toString();

                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryRed,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(
                              Icons.play_circle_fill_rounded,
                              size: 28,
                            ),
                            label: Text(
                              'Continue Ep $epNumStr (${_formatTime(lastWatched.positionMs)})',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () {
                              _handleEpisodeTap(
                                targetEp,
                                episodes,
                                initialPositionMs: lastWatched.positionMs,
                                index: targetIndex,
                              );
                            },
                          ),
                        );
                      }

                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryRed,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.play_arrow_rounded, size: 28),
                          label: Text(
                            'Watch Now • ${episodes.first.title}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () {
                            _handleEpisodeTap(episodes.first, episodes);
                          },
                        ),
                      );
                    },
                    orElse: () => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),
                  if (widget.show.synopsis != null &&
                      widget.show.synopsis!.isNotEmpty) ...[
                    const Text(
                      'Synopsis',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isSynopsisExpanded = !_isSynopsisExpanded;
                        });
                      },
                      child: Text(
                        widget.show.synopsis!,
                        maxLines: _isSynopsisExpanded ? null : 3,
                        overflow: _isSynopsisExpanded
                            ? null
                            : TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFB0B3B8),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      episodesAsync.maybeWhen(
                        data: (episodes) => Text(
                          'Episodes (${episodes.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        orElse: () => const Text(
                          'Episodes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _isGridView ? Icons.view_list : Icons.grid_view,
                          color: Colors.white70,
                        ),
                        tooltip: _isGridView
                            ? 'Switch to List'
                            : 'Switch to Grid',
                        onPressed: () {
                          setState(() {
                            _isGridView = !_isGridView;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          episodesAsync.when(
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 40,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Failed to load episodes: $err',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          ref.invalidate(showEpisodesProvider(widget.show.id));
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            data: (episodes) {
              if (episodes.isNotEmpty) {
                DLog.event(
                  'detail.episodes',
                  'show="${widget.show.title}" count=${episodes.length} '
                      'first=${episodes.first.number.toInt()} '
                      'last=${episodes.last.number.toInt()}',
                );
              }
              if (episodes.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No episodes available.',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                );
              }

              if (_isGridView) {
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 1.6,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final ep = episodes[index];
                      final epLabel = ep.number > 0
                          ? 'EP ${ep.number.toInt()}'
                          : 'EP ${index + 1}';
                      final histItem = historyByEpisode[ep.id];

                      return InkWell(
                        onTap: () => _handleEpisodeTap(
                          ep,
                          episodes,
                          initialPositionMs: histItem?.positionMs,
                          index: index,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: histItem != null
                                ? const Color(0xFF232732)
                                : const Color(0xFF1C1F26),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: histItem != null
                                  ? AppTheme.primaryRed.withValues(alpha: 0.5)
                                  : const Color(0xFF2A2E39),
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Center(
                                  child: Text(
                                    epLabel,
                                    style: TextStyle(
                                      color: histItem != null
                                          ? Colors.white
                                          : Colors.white70,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                              if (histItem != null)
                                LinearProgressIndicator(
                                  value: histItem.progressPercentage,
                                  backgroundColor: Colors.white10,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        AppTheme.primaryRed,
                                      ),
                                  minHeight: 2,
                                ),
                            ],
                          ),
                        ),
                      );
                    }, childCount: episodes.length),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final ep = episodes[index];
                    final histItem = historyByEpisode[ep.id];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1F26),
                        borderRadius: BorderRadius.circular(10),
                        border: histItem != null
                            ? Border.all(
                                color: AppTheme.primaryRed.withValues(
                                  alpha: 0.3,
                                ),
                              )
                            : null,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          ListTile(
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF262A34),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${ep.number.toInt()}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            title: Text(
                              ep.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: histItem != null
                                ? Text(
                                    'Watched ${_formatTime(histItem.positionMs)} / ${_formatTime(histItem.durationMs)}',
                                    style: const TextStyle(
                                      color: AppTheme.primaryRed,
                                      fontSize: 12,
                                    ),
                                  )
                                : (ep.uploadDate != null
                                      ? Text(
                                          ep.uploadDate!,
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12,
                                          ),
                                        )
                                      : null),
                            trailing: Icon(
                              histItem != null
                                  ? Icons.play_circle_fill_rounded
                                  : Icons.play_circle_outline,
                              color: AppTheme.primaryRed,
                            ),
                            onTap: () => _handleEpisodeTap(
                              ep,
                              episodes,
                              initialPositionMs: histItem?.positionMs,
                              index: index,
                            ),
                          ),
                          if (histItem != null)
                            LinearProgressIndicator(
                              value: histItem.progressPercentage,
                              backgroundColor: Colors.white10,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryRed,
                              ),
                              minHeight: 2,
                            ),
                        ],
                      ),
                    );
                  }, childCount: episodes.length),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  void _handleEpisodeTap(
    Episode episode,
    List<Episode> allEpisodes, {
    int? initialPositionMs,
    int? index,
  }) {
    DLog.event(
      'detail.episodeTap',
      'show="${widget.show.title}" ep=${episode.number.toInt()} '
          'resumeMs=${initialPositionMs ?? 0} index=$index total=${allEpisodes.length}',
    );
    if (widget.onEpisodeSelected != null) {
      widget.onEpisodeSelected!(episode, allEpisodes);
    } else {
      final epIndex = index ?? allEpisodes.indexOf(episode);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PlayerScreen(
            show: widget.show,
            episodes: allEpisodes,
            initialEpisodeIndex: epIndex >= 0 ? epIndex : 0,
            initialPositionMs: initialPositionMs,
          ),
        ),
      );
    }
  }
}

class _TagBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _TagBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
