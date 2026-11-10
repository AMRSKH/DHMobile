import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/debug_log.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/source_badge.dart';
import '../../domain/models/show.dart';
import '../detail/detail_screen.dart';
import '../settings/settings_controller.dart';
import 'search_controller.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final void Function(Show show)? onShowSelected;

  /// Opens the keyboard on the search field at once, for a search that the
  /// user just asked for.
  final bool autofocus;

  const SearchScreen({super.key, this.onShowSelected, this.autofocus = false});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _queryController = TextEditingController();

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _onSearch() {
    DLog.event('search.query', _queryController.text);
    ref.read(searchControllerProvider.notifier).search(_queryController.text);
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchControllerProvider);
    final s = ref.watch(stringsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s(S.search)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: s(S.refresh),
            onPressed: () {
              DLog.event('search.refresh', _queryController.text);
              ref
                  .read(searchControllerProvider.notifier)
                  .search(_queryController.text);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _queryController,
              autofocus: widget.autofocus,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _onSearch(),
              decoration: InputDecoration(
                hintText: s(S.searchHint),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF757B88)),
                suffixIcon: _queryController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _queryController.clear();
                          _onSearch();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (val) {
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: searchState.when(
              loading: () => const SkeletonPosterGrid(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                childAspectRatio: 0.65,
                mainAxisSpacing: 14,
              ),
              // The controller writes the error to the debug log.
              error: (_, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        s(S.loadFailed),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _onSearch,
                        icon: const Icon(Icons.refresh),
                        label: Text(s(S.retry)),
                      ),
                    ],
                  ),
                ),
              ),
              data: (shows) {
                if (shows.isEmpty) {
                  return Center(
                    child: Text(
                      s(S.searchEmpty),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: shows.length,
                  itemBuilder: (context, index) {
                    final show = shows[index];
                    return _ShowCard(
                      show: show,
                      onTap: () {
                        if (widget.onShowSelected != null) {
                          widget.onShowSelected!(show);
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DetailScreen(show: show),
                            ),
                          );
                        }
                      },
                    );
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

class _ShowCard extends StatelessWidget {
  final Show show;
  final VoidCallback onTap;

  const _ShowCard({required this.show, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: show.poster.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: show.poster,
                          httpHeaders: const {
                            'Referer': 'https://animexin.dev/',
                            'User-Agent':
                                'Mozilla/5.0 (Linux; Android 11; Pixel 5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
                          },
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const SkeletonBox(),
                          errorWidget: (context, url, error) => Container(
                            color: const Color(0xFF1C1F26),
                            child: const Icon(
                              Icons.movie_outlined,
                              size: 40,
                              color: Colors.white24,
                            ),
                          ),
                        )
                      : Container(
                          color: const Color(0xFF1C1F26),
                          child: const Icon(
                            Icons.movie_outlined,
                            size: 40,
                            color: Colors.white24,
                          ),
                        ),
                ),
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: SourceBadge(providerId: show.providerId),
                ),
                if (show.episodeCount != null && show.episodeCount!.isNotEmpty)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        show.episodeCount!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            show.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
