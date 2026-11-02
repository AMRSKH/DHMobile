import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../domain/models/show.dart';
import '../../domain/models/episode.dart';
import '../../domain/models/stream_source.dart';
import 'player_controller.dart';
import 'widgets/gesture_overlay.dart';
import 'widgets/player_controls.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final Show show;
  final List<Episode> episodes;
  final int initialEpisodeIndex;

  const PlayerScreen({
    super.key,
    required this.show,
    required this.episodes,
    this.initialEpisodeIndex = 0,
  });

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  late int _currentEpisodeIndex;
  int _currentSourceIndex = 0;
  List<StreamSource> _availableSources = [];

  // VLC Player
  VlcPlayerController? _vlcController;
  // Fallback VideoPlayer
  VideoPlayerController? _vpController;

  bool _useFallbackPlayer = false;
  bool _isPlaying = false;
  bool _isBuffering = true;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _speed = 1.0;
  bool _showControls = true;
  Timer? _hideControlsTimer;
  Timer? _positionPollTimer;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentEpisodeIndex = widget.initialEpisodeIndex;

    // Lock landscape & hide system bars
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WakelockPlus.enable();

    _startHideControlsTimer();
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _positionPollTimer?.cancel();
    _disposePlayers();

    WakelockPlus.disable();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    super.dispose();
  }

  void _disposePlayers() {
    _positionPollTimer?.cancel();
    _vlcController?.stop();
    _vlcController?.dispose();
    _vlcController = null;

    _vpController?.dispose();
    _vpController = null;
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideControlsTimer();
    }
  }

  Episode get _currentEpisode => widget.episodes[_currentEpisodeIndex];

  Future<void> _initializeStream(StreamSource source) async {
    _disposePlayers();
    setState(() {
      _isBuffering = true;
      _errorMessage = null;
    });

    try {
      if (!_useFallbackPlayer) {
        // Try VLC first
        final vlcOptions = VlcPlayerOptions(
          advanced: VlcAdvancedOptions([
            VlcAdvancedOptions.networkCaching(3000),
          ]),
          http: VlcHttpOptions([
            if (source.headers['User-Agent'] != null)
              VlcHttpOptions.httpUserAgent(source.headers['User-Agent']!),
            if (source.headers['Referer'] != null)
              VlcHttpOptions.httpReferrer(source.headers['Referer']!),
          ]),
        );

        final controller = VlcPlayerController.network(
          source.url,
          hwAcc: HwAcc.full,
          autoPlay: true,
          options: vlcOptions,
        );

        _vlcController = controller;
        controller.addListener(_vlcListener);

        _startPositionPolling();
      } else {
        // Fallback to standard video_player
        final vp = VideoPlayerController.networkUrl(
          Uri.parse(source.url),
          httpHeaders: source.headers,
        );
        _vpController = vp;
        await vp.initialize();
        vp.addListener(_vpListener);
        await vp.play();
        setState(() {
          _isBuffering = false;
          _isPlaying = true;
          _duration = vp.value.duration;
        });
      }
    } catch (e) {
      if (!_useFallbackPlayer) {
        // Automatically switch to fallback video_player
        setState(() {
          _useFallbackPlayer = true;
        });
        _initializeStream(source);
      } else {
        setState(() {
          _isBuffering = false;
          _errorMessage = 'Playback failed. Try switching servers.';
        });
      }
    }
  }

  void _vlcListener() {
    if (_vlcController == null || !mounted) return;
    final value = _vlcController!.value;

    setState(() {
      _isPlaying = value.isPlaying;
      _isBuffering = value.isBuffering;
      _position = value.position;
      _duration = value.duration;
    });

    if (value.hasError) {
      // Auto-fallback on decode error
      setState(() {
        _useFallbackPlayer = true;
      });
      if (_availableSources.isNotEmpty) {
        _initializeStream(_availableSources[_currentSourceIndex]);
      }
    } else if (value.isEnded) {
      _handleNextEpisode();
    }
  }

  void _vpListener() {
    if (_vpController == null || !mounted) return;
    final value = _vpController!.value;

    setState(() {
      _isPlaying = value.isPlaying;
      _isBuffering = value.isBuffering;
      _position = value.position;
      _duration = value.duration;
    });

    if (value.position >= value.duration && value.duration > Duration.zero) {
      _handleNextEpisode();
    }
  }

  void _startPositionPolling() {
    _positionPollTimer?.cancel();
    _positionPollTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
      if (_vlcController != null && mounted) {
        final pos = await _vlcController!.getPosition();
        final dur = await _vlcController!.getDuration();
        if (mounted) {
          setState(() {
            _position = pos;
            _duration = dur;
          });
        }
      }
    });
  }

  void _seekRelative(int seconds) {
    final target = _position + Duration(seconds: seconds);
    final clamped = Duration(
      milliseconds: target.inMilliseconds.clamp(0, _duration.inMilliseconds),
    );
    _seekTo(clamped);
  }

  void _seekTo(Duration duration) {
    if (_vlcController != null) {
      _vlcController!.seekTo(duration);
    } else if (_vpController != null) {
      _vpController!.seekTo(duration);
    }
  }

  void _togglePlayPause() {
    if (_vlcController != null) {
      if (_isPlaying) {
        _vlcController!.pause();
      } else {
        _vlcController!.play();
      }
    } else if (_vpController != null) {
      if (_isPlaying) {
        _vpController!.pause();
      } else {
        _vpController!.play();
      }
    }
    _startHideControlsTimer();
  }

  void _setSpeed(double s) {
    setState(() {
      _speed = s;
    });
    if (_vlcController != null) {
      _vlcController!.setPlaybackSpeed(s);
    } else if (_vpController != null) {
      _vpController!.setPlaybackSpeed(s);
    }
  }

  void _handleNextEpisode() {
    if (_currentEpisodeIndex < widget.episodes.length - 1) {
      setState(() {
        _currentEpisodeIndex++;
        _currentSourceIndex = 0;
      });
      ref.invalidate(episodeStreamsProvider(_currentEpisode.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final streamsAsync = ref.watch(episodeStreamsProvider(_currentEpisode.id));

    return Scaffold(
      backgroundColor: Colors.black,
      body: streamsAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFFE50914)),
              SizedBox(height: 16),
              Text(
                'Resolving stream sources...',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text('Error: $err', style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(episodeStreamsProvider(_currentEpisode.id)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (sources) {
          if (sources != _availableSources) {
            _availableSources = sources;
            if (sources.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _initializeStream(sources[_currentSourceIndex]);
              });
            }
          }

          if (sources.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No active streams available.', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          return GestureOverlay(
            onToggleControls: _toggleControls,
            onDoubleTapLeft: () => _seekRelative(-10),
            onDoubleTapRight: () => _seekRelative(10),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Video Surface
                Center(
                  child: _vlcController != null
                      ? VlcPlayer(
                          controller: _vlcController!,
                          aspectRatio: 16 / 9,
                          placeholder: const Center(
                            child: CircularProgressIndicator(color: Color(0xFFE50914)),
                          ),
                        )
                      : (_vpController != null && _vpController!.value.isInitialized)
                          ? AspectRatio(
                              aspectRatio: _vpController!.value.aspectRatio,
                              child: VideoPlayer(_vpController!),
                            )
                          : const Center(
                              child: CircularProgressIndicator(color: Color(0xFFE50914)),
                            ),
                ),

                if (_errorMessage != null)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning_amber_rounded, size: 40, color: Colors.amber),
                          const SizedBox(height: 8),
                          Text(_errorMessage!, style: const TextStyle(color: Colors.white)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {
                              _initializeStream(_availableSources[_currentSourceIndex]);
                            },
                            child: const Text('Retry Stream'),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Controls Overlay
                if (_showControls)
                  PlayerControls(
                    title: widget.show.title,
                    episodeTitle: _currentEpisode.title,
                    isPlaying: _isPlaying,
                    isBuffering: _isBuffering,
                    position: _position,
                    duration: _duration,
                    speed: _speed,
                    sources: _availableSources,
                    currentSourceIndex: _currentSourceIndex,
                    hasNextEpisode: _currentEpisodeIndex < widget.episodes.length - 1,
                    onPlayPause: _togglePlayPause,
                    onSeek: _seekTo,
                    onSeekBack10: () => _seekRelative(-10),
                    onSeekForward10: () => _seekRelative(10),
                    onSpeedChanged: _setSpeed,
                    onSourceChanged: (idx) {
                      setState(() {
                        _currentSourceIndex = idx;
                      });
                      _initializeStream(_availableSources[idx]);
                    },
                    onNextEpisode: _handleNextEpisode,
                    onBack: () => Navigator.of(context).pop(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
