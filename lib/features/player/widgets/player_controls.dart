import 'package:flutter/material.dart';
import '../../../domain/models/stream_source.dart';

class PlayerControls extends StatelessWidget {
  final String title;
  final String episodeTitle;
  final bool isPlaying;
  final bool isBuffering;
  final Duration position;
  final Duration duration;
  final double speed;
  final List<StreamSource> sources;
  final int currentSourceIndex;
  final bool hasNextEpisode;
  final VoidCallback onPlayPause;
  final ValueChanged<Duration> onSeek;
  final VoidCallback onSeekBack10;
  final VoidCallback onSeekForward10;
  final ValueChanged<double> onSpeedChanged;
  final ValueChanged<int> onSourceChanged;
  final VoidCallback onNextEpisode;
  final VoidCallback onBack;

  const PlayerControls({
    super.key,
    required this.title,
    required this.episodeTitle,
    required this.isPlaying,
    required this.isBuffering,
    required this.position,
    required this.duration,
    required this.speed,
    required this.sources,
    required this.currentSourceIndex,
    required this.hasNextEpisode,
    required this.onPlayPause,
    required this.onSeek,
    required this.onSeekBack10,
    required this.onSeekForward10,
    required this.onSpeedChanged,
    required this.onSourceChanged,
    required this.onNextEpisode,
    required this.onBack,
  });

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.45),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    onPressed: onBack,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          episodeTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (sources.isNotEmpty)
                    PopupMenuButton<int>(
                      tooltip: 'Select Server / Quality',
                      icon: const Icon(Icons.high_quality, color: Colors.white),
                      onSelected: onSourceChanged,
                      itemBuilder: (context) => List.generate(
                        sources.length,
                        (i) => PopupMenuItem(
                          value: i,
                          child: Row(
                            children: [
                              if (i == currentSourceIndex)
                                const Icon(Icons.check, size: 18, color: Color(0xFFE50914))
                              else
                                const SizedBox(width: 18),
                              const SizedBox(width: 8),
                              Text('${sources[i].server ?? "Server ${i + 1}"} (${sources[i].quality})'),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Center Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 42,
                  icon: const Icon(Icons.replay_10, color: Colors.white),
                  onPressed: onSeekBack10,
                ),
                const SizedBox(width: 32),
                if (isBuffering)
                  const SizedBox(
                    width: 56,
                    height: 56,
                    child: CircularProgressIndicator(
                      color: Color(0xFFE50914),
                      strokeWidth: 3,
                    ),
                  )
                else
                  IconButton(
                    iconSize: 64,
                    icon: Icon(
                      isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                      color: Colors.white,
                    ),
                    onPressed: onPlayPause,
                  ),
                const SizedBox(width: 32),
                IconButton(
                  iconSize: 42,
                  icon: const Icon(Icons.forward_10, color: Colors.white),
                  onPressed: onSeekForward10,
                ),
              ],
            ),

            // Bottom Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      activeTrackColor: const Color(0xFFE50914),
                      inactiveTrackColor: Colors.white24,
                      thumbColor: const Color(0xFFE50914),
                    ),
                    child: Slider(
                      min: 0.0,
                      max: duration.inMilliseconds > 0
                          ? duration.inMilliseconds.toDouble()
                          : 1.0,
                      value: position.inMilliseconds
                          .clamp(0, duration.inMilliseconds > 0 ? duration.inMilliseconds : 1)
                          .toDouble(),
                      onChanged: (val) {
                        onSeek(Duration(milliseconds: val.toInt()));
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_formatDuration(position)} / ${_formatDuration(duration)}',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      Row(
                        children: [
                          PopupMenuButton<double>(
                            tooltip: 'Playback Speed',
                            onSelected: onSpeedChanged,
                            itemBuilder: (context) => [
                              0.5,
                              0.75,
                              1.0,
                              1.25,
                              1.5,
                              2.0,
                            ].map((s) => PopupMenuItem(
                              value: s,
                              child: Row(
                                children: [
                                  if (speed == s)
                                    const Icon(Icons.check, size: 18, color: Color(0xFFE50914))
                                  else
                                    const SizedBox(width: 18),
                                  const SizedBox(width: 8),
                                  Text('${s}x'),
                                ],
                              ),
                            )).toList(),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Text(
                                '${speed}x',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          if (hasNextEpisode)
                            IconButton(
                              icon: const Icon(Icons.skip_next, color: Colors.white),
                              tooltip: 'Next Episode',
                              onPressed: onNextEpisode,
                            ),
                        ],
                      ),
                    ],
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
