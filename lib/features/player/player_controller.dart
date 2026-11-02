import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/stream_source.dart';
import '../search/search_controller.dart';

final episodeStreamsProvider =
    FutureProvider.autoDispose.family<List<StreamSource>, String>((ref, episodeId) async {
  final provider = ref.watch(streamProvider);
  return provider.streams(episodeId);
});

