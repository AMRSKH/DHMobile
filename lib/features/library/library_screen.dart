import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/skeleton.dart';
import '../../domain/models/show.dart';
import '../../domain/models/history_item.dart';
import '../detail/detail_screen.dart';
import '../player/player_screen.dart';
import '../settings/settings_controller.dart';
import '../../core/debug_log.dart';
import 'library_controller.dart';

/// A title that is nothing but "Episode N", "Ep N", or "Ep. N".
final RegExp _episodeOnlyTitle = RegExp(
  r'^(?:episode|ep\.?)\s*(\d+(?:\.\d+)?)$',
  caseSensitive: false,
);

/// Label for a history card. The episode title is left out when it is empty
/// or only repeats "Episode N", also in another spelling of the same number
/// ("Episode 02", "Ep 2").
///
/// [episodeWord] is the word for "Episode" in the display language. Titles
/// come from the source in English, so the check for a title that only
/// repeats the number always looks for the English forms.
String historyEpisodeLabel(
  String episodeNumber,
  String title, {
  String episodeWord = 'Episode',
}) {
  final base = '$episodeWord $episodeNumber';
  final trimmed = title.trim();
  final lower = trimmed.toLowerCase();
  if (trimmed.isEmpty ||
      lower == base.toLowerCase() ||
      lower == 'episode $episodeNumber'.toLowerCase()) {
    return base;
  }
  final match = _episodeOnlyTitle.firstMatch(trimmed);
  if (match != null) {
    final titleNumber = double.tryParse(match.group(1)!);
    final number = double.tryParse(episodeNumber.trim());
    if (titleNumber != null && titleNumber == number) return base;
  }
  return '$base • $trimmed';
}

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(s(S.libraryTitle)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryRed,
          labelColor: Colors.white,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: [
            Tab(icon: const Icon(Icons.history_rounded), text: s(S.history)),
            Tab(icon: const Icon(Icons.favorite_rounded), text: s(S.favorites)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_HistoryTab(), _FavoritesTab()],
      ),
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    final s = ref.watch(stringsProvider);

    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_toggle_off_rounded,
              size: 72,
              color: AppTheme.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              s(S.historyEmptyTitle),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                s(S.historyEmptyBody),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textMuted),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s.fmt(S.historyCount, {'count': history.length}),
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
              TextButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppTheme.surfaceDark,
                      title: Text(s(S.clearHistoryQuestion)),
                      content: Text(s(S.clearHistoryWarning)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(s(S.cancel)),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primaryRed,
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(s(S.clearAll)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    ref.read(historyProvider.notifier).clearHistory();
                  }
                },
                icon: const Icon(
                  Icons.delete_outline,
                  size: 16,
                  color: AppTheme.textMuted,
                ),
                label: Text(
                  s(S.clearAll),
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: history.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = history[index];
              return _HistoryCard(item: item);
            },
          ),
        ),
      ],
    );
  }
}

class _HistoryCard extends ConsumerWidget {
  final WatchHistoryItem item;

  const _HistoryCard({required this.item});

  String _formatTime(int ms) {
    final dur = Duration(milliseconds: ms);
    final m = dur.inMinutes;
    final s = dur.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final epNumStr = item.episode.number % 1 == 0
        ? item.episode.number.toInt().toString()
        : item.episode.number.toString();

    final dateStr = DateFormat('MMM d, h:mm a').format(item.updatedAt);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetailScreen(show: item.show)),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                SizedBox(
                  width: 90,
                  height: 110,
                  child: CachedNetworkImage(
                    imageUrl: item.show.poster,
                    httpHeaders: const {
                      'Referer': 'https://animexin.dev/',
                      'User-Agent':
                          'Mozilla/5.0 (Linux; Android 11; Pixel 5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
                    },
                    fit: BoxFit.cover,
                    placeholder: (_, _) => const SkeletonBox(),
                    errorWidget: (_, _, _) => Container(
                      color: AppTheme.surfaceDark,
                      child: const Icon(Icons.movie, color: AppTheme.textMuted),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.show.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          historyEpisodeLabel(
                            epNumStr,
                            item.episode.title,
                            episodeWord: s(S.episode),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.primaryRed,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_formatTime(item.positionMs)} / ${_formatTime(item.durationMs)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Actions
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.play_circle_fill_rounded,
                        color: AppTheme.primaryRed,
                        size: 36,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlayerScreen(
                              show: item.show,
                              episodes: [item.episode],
                              initialEpisodeIndex: 0,
                              initialPositionMs: item.positionMs,
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: AppTheme.textMuted,
                      ),
                      onPressed: () {
                        ref
                            .read(historyProvider.notifier)
                            .removeItem(item.episode.id);
                      },
                    ),
                  ],
                ),
                const SizedBox(width: 4),
              ],
            ),
            // Progress Bar
            LinearProgressIndicator(
              value: item.progressPercentage,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.primaryRed,
              ),
              minHeight: 3,
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoritesTab extends ConsumerWidget {
  const _FavoritesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final s = ref.watch(stringsProvider);

    if (favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 72,
              color: AppTheme.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              s(S.favoritesEmptyTitle),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                s(S.favoritesEmptyBody),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textMuted),
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final show = favorites[index];
        return _FavoriteCard(show: show);
      },
    );
  }
}

class _FavoriteCard extends ConsumerWidget {
  final Show show;

  const _FavoriteCard({required this.show});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetailScreen(show: show)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: show.poster,
                    httpHeaders: const {
                      'Referer': 'https://animexin.dev/',
                      'User-Agent':
                          'Mozilla/5.0 (Linux; Android 11; Pixel 5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
                    },
                    fit: BoxFit.cover,
                    placeholder: (_, _) => const SkeletonBox(),
                    errorWidget: (_, _, _) => Container(
                      color: AppTheme.surfaceDark,
                      child: const Icon(Icons.movie, color: AppTheme.textMuted),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () {
                        DLog.event('library.favoriteToggle', show.title);
                        ref
                            .read(favoritesProvider.notifier)
                            .toggleFavorite(show);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: AppTheme.primaryRed,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    show.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    show.episodeCount ?? 'Donghua',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
