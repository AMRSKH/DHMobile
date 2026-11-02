import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/models/show.dart';
import 'search_controller.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final void Function(Show show)? onShowSelected;

  const SearchScreen({super.key, this.onShowSelected});

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
    ref.read(searchControllerProvider.notifier).search(_queryController.text);
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('DonghuaPlayer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.read(searchControllerProvider.notifier).search(_queryController.text);
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
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _onSearch(),
              decoration: InputDecoration(
                hintText: 'Search Donghua (e.g. BTTH, Soul Land)...',
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
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load: $error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _onSearch,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (shows) {
                if (shows.isEmpty) {
                  return const Center(
                    child: Text(
                      'No donghua found. Try another title.',
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Selected: ${show.title}'),
                              duration: const Duration(seconds: 1),
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
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: const Color(0xFF1C1F26),
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: const Color(0xFF1C1F26),
                            child: const Icon(Icons.movie_outlined,
                                size: 40, color: Colors.white24),
                          ),
                        )
                      : Container(
                          color: const Color(0xFF1C1F26),
                          child: const Icon(Icons.movie_outlined,
                              size: 40, color: Colors.white24),
                        ),
                ),
                if (show.episodeCount != null && show.episodeCount!.isNotEmpty)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
