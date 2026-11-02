import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/episode.dart';
import '../search/search_controller.dart';

final showEpisodesProvider =
    FutureProvider.autoDispose.family<List<Episode>, String>((ref, showId) async {
  final provider = ref.watch(streamProvider);
  return provider.episodes(showId);
});

