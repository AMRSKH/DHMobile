import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../data/storage/storage_service.dart';
import '../../domain/models/show.dart';
import '../../domain/models/episode.dart';
import '../../domain/models/stream_source.dart';
import '../../core/debug_log.dart';
import '../library/library_controller.dart';
import '../settings/settings_controller.dart';
import 'player_controller.dart';
import 'source_selection.dart';
import 'widgets/gesture_overlay.dart';
import 'widgets/player_controls.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final Show show;
  final List<Episode> episodes;
  final int initialEpisodeIndex;
  final int? initialPositionMs;

  const PlayerScreen({
    super.key,
    required this.show,
    required this.episodes,
    this.initialEpisodeIndex = 0,
    this.initialPositionMs,
  });

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with WidgetsBindingObserver {
  late int _currentEpisodeIndex;
  int _currentSourceIndex = 0;
  List<StreamSource> _availableSources = [];

  // VLC Player
  VlcPlayerController? _vlcController;
  // Fallback VideoPlayer
  VideoPlayerController? _vpController;

  // Fallback VideoPlayer (preferred for reliable native Android hardware decode)
  bool _useFallbackPlayer = true;
  bool _isPlaying = false;
  bool _isBuffering = true;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _speed = 1.0;
  bool _showControls = true;
  Timer? _hideControlsTimer;
  Timer? _positionPollTimer;
  Timer? _saveProgressTimer;
  Timer? _bufferingWatchdog;
  String? _errorMessage;
  int _pendingResumeMs = 0;
  bool _endHandled = false;
  // True while the speed or source popup menu is open, so the controls that
  // own the menu button are not removed under it.
  bool _menuOpen = false;
  // The source the user picked by hand. Failover never sets it.
  StreamSource? _userSource;
  // Indexes in `_availableSources` that already failed for this episode.
  final Set<int> _failedSources = {};
  // Counts player teardowns, so a load that was replaced while it awaited can
  // tell that it is stale.
  int _loadGeneration = 0;
  // What the user asked for: true after play, false after pause.
  bool _wantPlaying = false;
  // True from the moment the app leaves the foreground until it is back.
  bool _inBackground = false;
  // A load failed while the app was in the background. The same source is
  // loaded again on return.
  bool _reloadOnResume = false;

  // video_player reports `isPlaying` false while ExoPlayer buffers, although
  // playback goes on by itself afterwards. While buffering, the intent of the
  // user decides what the play/pause button shows and does.
  bool get _effectivePlaying => _isBuffering ? _wantPlaying : _isPlaying;

  // Captured in initState: `ref` cannot be read from dispose().
  late final HistoryNotifier _history;
  late final StorageService _storage;

  @override
  void initState() {
    super.initState();
    _history = ref.read(historyProvider.notifier);
    _storage = ref.read(storageServiceProvider);
    WidgetsBinding.instance.addObserver(this);
    _currentEpisodeIndex = widget.initialEpisodeIndex;
    _pendingResumeMs = widget.initialPositionMs ?? 0;

    // Lock landscape & hide system bars
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WakelockPlus.enable();

    _startHideControlsTimer();
    _startProgressSavingTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveProgress(syncHistory: true);
    _saveProgressTimer?.cancel();
    _hideControlsTimer?.cancel();
    _positionPollTimer?.cancel();
    _disposePlayers();

    WakelockPlus.disable();
    unawaited(_resetAppBrightness());
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    super.dispose();
  }

  /// Drops the brightness override set by the brightness gesture, so the rest
  /// of the app follows the system brightness again.
  Future<void> _resetAppBrightness() async {
    try {
      await ScreenBrightness.instance.resetApplicationScreenBrightness();
    } catch (e, st) {
      DLog.error('player.brightnessReset', e, st);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    DLog.event('player.lifecycle', '$state playing=$_isPlaying pos=$_position');
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _inBackground = true;
      _saveProgress(syncHistory: true);
      // A video that is buffering reports "not playing", and would start
      // its audio in the background when the buffer fills.
      if (_effectivePlaying) {
        _vlcController?.pause();
        _vpController?.pause();
      }
      if (mounted) setState(() => _wantPlaying = false);
    } else if (state == AppLifecycleState.resumed) {
      _inBackground = false;
      if (_reloadOnResume) {
        _reloadOnResume = false;
        if (mounted && _availableSources.isNotEmpty) {
          DLog.event('player.failover', 'reload src=$_currentSourceIndex');
          _initializeStream(_availableSources[_currentSourceIndex]);
        }
        return;
      }
      // A load that is still pending gets its full time again: the time in
      // the background says nothing about the source.
      if (_bufferingWatchdog?.isActive ?? false) _resetBufferingWatchdog();
      // Playback stays paused after a return from the background. Show the
      // controls so the screen does not look frozen.
      if (mounted && !_isPlaying) setState(() => _showControls = true);
    }
  }

  void _disposePlayers() {
    _loadGeneration++;
    _positionPollTimer?.cancel();
    _positionPollTimer = null;
    _bufferingWatchdog?.cancel();
    _bufferingWatchdog = null;
    if (_vlcController != null) {
      if (_vlcController!.value.isInitialized) {
        try {
          _vlcController!.stop();
        } catch (_) {}
      }
      try {
        _vlcController!.dispose();
      } catch (_) {}
      _vlcController = null;
    }

    _vpController?.dispose();
    _vpController = null;
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    if (_menuOpen) return;
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _startProgressSavingTimer() {
    _saveProgressTimer?.cancel();
    _saveProgressTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _saveProgress();
    });
  }

  Future<void> _saveProgress({bool syncHistory = false}) async {
    if (_position.inSeconds <= 2 || _duration.inSeconds <= 5) return;

    final isFinished = _position.inSeconds >= (_duration.inSeconds - 3);
    final pos = isFinished ? 0 : _position.inMilliseconds;
    final show = widget.show;
    final episode = _currentEpisode;
    final durationMs = _duration.inMilliseconds;

    try {
      if (syncHistory) {
        await _history.saveProgress(
          show: show,
          episode: episode,
          positionMs: pos,
          durationMs: durationMs,
        );
      } else {
        await _storage.saveHistory(
          show: show,
          episode: episode,
          positionMs: pos,
          durationMs: durationMs,
        );
      }
    } catch (e, st) {
      DLog.error('player.saveProgress', e, st);
    }
  }

  void _onMenuOpened() {
    _menuOpen = true;
    _hideControlsTimer?.cancel();
  }

  void _onMenuClosed() {
    _menuOpen = false;
    _startHideControlsTimer();
  }

  /// Keeps the playback position when the same episode is loaded again from
  /// another source. A larger resume point that was not applied yet wins.
  void _carryPositionToNextLoad() {
    _pendingResumeMs = carriedResumeMs(
      positionMs: _position.inMilliseconds,
      pendingMs: _pendingResumeMs,
    );
  }

  /// Marks the current source as failed and loads the best one that is left.
  /// Shows an error when every source of the episode has failed.
  void _failover() {
    if (_availableSources.isEmpty) return;
    _saveProgress(syncHistory: true);
    _carryPositionToNextLoad();

    // Android can cut the network of an app in the background, so a failure
    // there says nothing about the source. Trying the other sources now
    // would mark all of them as failed. Load the same one again on return.
    if (_inBackground) {
      _disposePlayers();
      _reloadOnResume = true;
      DLog.event('player.failover', 'deferred src=$_currentSourceIndex');
      return;
    }

    _failedSources.add(_currentSourceIndex);
    final settings = ref.read(settingsProvider);
    final next = pickFailoverSourceIndex(
      _availableSources,
      failed: _failedSources,
      quality: settings.defaultQuality,
      subtitle: settings.preferredSubtitle,
    );

    if (next < 0) {
      _disposePlayers();
      setState(() {
        _isBuffering = false;
        _isPlaying = false;
        _errorMessage =
            'No server could play this episode. '
            'Check your connection and retry.';
      });
      DLog.event('player.failover', 'exhausted tried=${_failedSources.length}');
      return;
    }

    DLog.event(
      'player.failover',
      'from=$_currentSourceIndex to=$next/${_availableSources.length}',
    );
    setState(() {
      _currentSourceIndex = next;
    });
    _initializeStream(_availableSources[next]);
  }

  void _toggleControls() {
    _menuOpen = false;
    setState(() {
      _showControls = !_showControls;
    });
    DLog.event(
      'player.controls',
      'show=$_showControls playing=$_isPlaying '
          'ep=${_currentEpisode.number.toInt()}',
    );
    if (_showControls) {
      _startHideControlsTimer();
    }
  }

  Episode get _currentEpisode => widget.episodes[_currentEpisodeIndex];

  Future<void> _initializeStream(StreamSource source) async {
    if (!mounted) return;
    _disposePlayers();
    // A later teardown (source switch, next episode, failover) makes this
    // load stale. It must then neither touch the state nor fail over.
    final load = _loadGeneration;
    setState(() {
      _isBuffering = true;
      _isPlaying = false;
      // A load starts playing by itself, unless the app goes to the
      // background before it is ready.
      _wantPlaying = true;
      _errorMessage = null;
      _position = Duration.zero;
      _duration = Duration.zero;
      _endHandled = false;
    });

    _resetBufferingWatchdog();

    DLog.event(
      'player.init',
      'src=$_currentSourceIndex/${_availableSources.length} '
          'server=${source.server} quality=${source.quality} '
          'ep=${_currentEpisode.number.toInt()} url=${source.url}',
    );

    try {
      if (!_useFallbackPlayer) {
        // VLC Player
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
          hwAcc: HwAcc.auto,
          autoPlay: true,
          options: vlcOptions,
        );

        _vlcController = controller;
        controller.addListener(_vlcListener);
      } else {
        // Fallback VideoPlayer
        final Map<String, String> httpHeaders = Map<String, String>.from(
          source.headers,
        );

        final vp = VideoPlayerController.networkUrl(
          Uri.parse(source.url),
          httpHeaders: httpHeaders,
        );
        _vpController = vp;
        await vp.initialize();
        if (!mounted || load != _loadGeneration) return;
        DLog.event(
          'player.ready',
          'src=$_currentSourceIndex dur=${vp.value.duration} '
              'server=${source.server}',
        );
        // A new controller starts at 1.0x. video_player stores the speed and
        // applies it on play.
        await vp.setPlaybackSpeed(_speed);
        if (!mounted || load != _loadGeneration) return;
        vp.addListener(_vpListener);
        // The app went to the background while this was loading: stay
        // paused, so the audio does not start behind another app.
        final autoPlay = _wantPlaying;
        if (autoPlay) {
          await vp.play();
          if (!mounted || load != _loadGeneration) return;
        }
        // The app can also leave during the `play()` call above. The
        // lifecycle handler has paused the player then.
        final playing = autoPlay && _wantPlaying;
        setState(() {
          _isBuffering = false;
          _isPlaying = playing;
          _duration = vp.value.duration;
          if (!playing) _showControls = true;
        });
        _bufferingWatchdog?.cancel();
        _checkAndApplyResume();
      }
    } catch (e) {
      // The controller of a replaced load was disposed under it. Its error
      // says nothing about the source that is loading now.
      if (!mounted || load != _loadGeneration) return;
      DLog.error('player.init', 'src=$_currentSourceIndex $e');
      if (!_useFallbackPlayer) {
        setState(() {
          _useFallbackPlayer = true;
        });
        _carryPositionToNextLoad();
        _initializeStream(source);
      } else {
        _failover();
      }
    }
  }

  void _resetBufferingWatchdog() {
    _bufferingWatchdog?.cancel();
    // A slow CDN can need more than 10 s before the first frame. Give the
    // current source time to start instead of discarding a working stream.
    _bufferingWatchdog = Timer(const Duration(seconds: 20), () {
      DLog.event(
        'player.watchdog',
        'src=$_currentSourceIndex buffering=$_isBuffering '
            'playing=$_isPlaying',
      );
      if (!mounted || !_isBuffering || _isPlaying) return;
      if (_availableSources.isEmpty) return;
      if (!_useFallbackPlayer) {
        setState(() {
          _useFallbackPlayer = true;
        });
        _carryPositionToNextLoad();
        _initializeStream(_availableSources[_currentSourceIndex]);
      } else {
        // Also at the last source, so the spinner cannot stay forever.
        _failover();
      }
    });
  }

  void _checkAndApplyResume() {
    if (_pendingResumeMs > 3000) {
      final resumeMs = _pendingResumeMs;
      _pendingResumeMs = 0;
      if (_duration.inSeconds > 5 &&
          resumeMs >= _duration.inMilliseconds - 3000) {
        return;
      }
      _seekTo(Duration(milliseconds: resumeMs));
    }
  }

  void _vlcListener() {
    if (_vlcController == null || !mounted) return;
    final value = _vlcController!.value;
    final wasPlaying = _isPlaying;

    // Read the last good position before the error state overwrites it.
    if (value.hasError) _carryPositionToNextLoad();

    setState(() {
      _isPlaying = value.isPlaying;
      _isBuffering = value.isBuffering;
      _position = value.position;
      _duration = value.duration;
    });

    if (value.isPlaying) {
      _bufferingWatchdog?.cancel();
      if (!wasPlaying) {
        // Playback just started: the control overlay is opaque to taps and
        // dims the video, so it must hide on its own.
        _startHideControlsTimer();
      }
    }

    if (value.isInitialized && _positionPollTimer == null) {
      _startPositionPolling();
    }

    if (value.isPlaying && _pendingResumeMs > 0) {
      _checkAndApplyResume();
    }

    if (value.hasError) {
      if (_availableSources.isEmpty) return;
      if (!_useFallbackPlayer) {
        setState(() {
          _useFallbackPlayer = true;
        });
        _carryPositionToNextLoad();
        _initializeStream(_availableSources[_currentSourceIndex]);
      } else {
        _failover();
      }
    } else if (value.isEnded && !_endHandled) {
      _endHandled = true;
      _handleNextEpisode();
    }
  }

  void _vpListener() {
    if (_vpController == null || !mounted) return;
    final value = _vpController!.value;
    final wasPlaying = _isPlaying;

    if (value.hasError) {
      DLog.error(
        'player.vp',
        'src=$_currentSourceIndex err=${value.errorDescription}',
      );
      _failover();
      return;
    }

    setState(() {
      _isPlaying = value.isPlaying;
      _isBuffering = value.isBuffering;
      _position = value.position;
      _duration = value.duration;
    });

    if (value.isPlaying) {
      _bufferingWatchdog?.cancel();
      if (!wasPlaying) {
        // Playback just started: the control overlay is opaque to taps and
        // dims the video, so it must hide on its own.
        _startHideControlsTimer();
        // video_player skips the platform call for a speed that is set
        // while `isPlaying` is false, which it is during buffering. Also
        // for 1.0x: the player may still run at an older, faster speed.
        _vpController!.setPlaybackSpeed(_speed);
      }
    }

    if (!_endHandled &&
        value.duration > Duration.zero &&
        value.position >= value.duration) {
      _endHandled = true;
      _handleNextEpisode();
    }
  }

  void _startPositionPolling() {
    _positionPollTimer?.cancel();
    _positionPollTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (_vlcController != null &&
          mounted &&
          _vlcController!.value.isInitialized) {
        try {
          final pos = await _vlcController!.getPosition();
          final dur = await _vlcController!.getDuration();
          if (mounted) {
            setState(() {
              _position = pos;
              _duration = dur;
            });
          }
        } catch (_) {}
      }
    });
  }

  void _seekRelative(int seconds) {
    DLog.event('player.seek', 'by=$seconds from=$_position dur=$_duration');
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
    // The button stays tappable while buffering. A video_player controller
    // that is still initializing cannot take play or pause yet.
    final vp = _vpController;
    if (vp != null && !vp.value.isInitialized) return;
    final vlc = _vlcController;
    final pause = _effectivePlaying;
    DLog.event(
      'player.playPause',
      'pause=$pause playing=$_isPlaying buffering=$_isBuffering '
          'want=$_wantPlaying',
    );
    if (vlc != null || vp != null) {
      if (pause) {
        if (vlc != null) {
          vlc.pause();
        } else {
          vp!.pause();
        }
        _saveProgress(syncHistory: true);
      } else {
        if (vlc != null) {
          vlc.play();
        } else {
          vp!.play();
        }
      }
      // The intent goes into the state at once, so the icon does not wait
      // for the player to report back.
      setState(() {
        _wantPlaying = !pause;
      });
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
    _saveProgress(syncHistory: true);
    DLog.event(
      'player.next',
      'from=${_currentEpisode.number.toInt()} '
          'of=${widget.episodes.length}',
    );
    if (_currentEpisodeIndex < widget.episodes.length - 1) {
      // Stop the finished episode first. Its listener would keep writing the
      // old position into `_position` while the next sources resolve, and
      // that position would then be saved or resumed on the new episode.
      _disposePlayers();
      _menuOpen = false;
      setState(() {
        _currentEpisodeIndex++;
        // Only a safe index for the old list. The source for the new episode
        // is chosen in build(), when its list arrives.
        _currentSourceIndex = 0;
        _pendingResumeMs = 0;
        _position = Duration.zero;
        _duration = Duration.zero;
      });
      ref.invalidate(episodeStreamsProvider(_currentEpisode.id));
    }
  }

  int _findInitialSourceIndex(List<StreamSource> sources) {
    final settings = ref.read(settingsProvider);
    return pickInitialSourceIndex(
      sources,
      quality: settings.defaultQuality,
      subtitle: settings.preferredSubtitle,
    );
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
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 12),
              Text(
                'Error: $err',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(episodeStreamsProvider(_currentEpisode.id)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (sources) {
          if (sources != _availableSources) {
            _availableSources = sources;
            // Indexes of the old list mean nothing in the new one, and a
            // menu that was open belongs to the old list.
            _failedSources.clear();
            _menuOpen = false;
            DLog.event(
              'player.sources',
              'ep=${_currentEpisode.number.toInt()} count=${sources.length}',
            );
            if (sources.isNotEmpty) {
              // Keep the server and quality the user picked by hand, when the
              // new list has it. Otherwise fall back to the settings.
              final sticky = stickySourceIndex(sources, _userSource);
              _currentSourceIndex = sticky >= 0
                  ? sticky
                  : _findInitialSourceIndex(sources);
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
                  const Text(
                    'No active streams available.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              GestureOverlay(
                onToggleControls: _toggleControls,
                onDoubleTapLeft: () => _seekRelative(-10),
                onDoubleTapRight: () => _seekRelative(10),
                // Only the video lives under the gesture layer; the controls
                // and dialogs stay above it so their buttons stay tappable.
                child: Center(
                  child: (!_useFallbackPlayer && _vlcController != null)
                      ? VlcPlayer(
                          controller: _vlcController!,
                          aspectRatio: 16 / 9,
                          placeholder: Container(color: Colors.black),
                        )
                      : (_vpController != null &&
                            _vpController!.value.isInitialized)
                      ? AspectRatio(
                          aspectRatio: _vpController!.value.aspectRatio,
                          child: VideoPlayer(_vpController!),
                        )
                      : Container(color: Colors.black),
                ),
              ),

              // Single Buffering Indicator when controls are hidden
              if (_isBuffering && !_showControls)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: Color(0xFFE50914),
                        strokeWidth: 3,
                      ),
                      if (_availableSources.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Connecting to '
                          '${_availableSources[_currentSourceIndex].server ?? 'server'}'
                          ' (${_currentSourceIndex + 1}/${_availableSources.length})',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
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
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 40,
                          color: Colors.amber,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            // Every source was tried, so the index is on
                            // the last and worst one. Start over from the
                            // source the user or the settings prefer.
                            _failedSources.clear();
                            _carryPositionToNextLoad();
                            final sticky = stickySourceIndex(
                              _availableSources,
                              _userSource,
                            );
                            final index = sticky >= 0
                                ? sticky
                                : _findInitialSourceIndex(_availableSources);
                            setState(() {
                              _currentSourceIndex = index;
                            });
                            _initializeStream(_availableSources[index]);
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
                  isPlaying: _effectivePlaying,
                  isBuffering: _isBuffering,
                  position: _position,
                  duration: _duration,
                  speed: _speed,
                  sources: _availableSources,
                  currentSourceIndex: _currentSourceIndex,
                  hasNextEpisode:
                      _currentEpisodeIndex < widget.episodes.length - 1,
                  onPlayPause: _togglePlayPause,
                  onSeek: _seekTo,
                  onSeekBack10: () => _seekRelative(-10),
                  onSeekForward10: () => _seekRelative(10),
                  onSpeedChanged: _setSpeed,
                  onSourceChanged: (idx) {
                    DLog.event(
                      'player.sourceSwitch',
                      'to=$idx/${_availableSources.length} '
                          'server=${_availableSources[idx].server}',
                    );
                    _failedSources.clear();
                    _saveProgress(syncHistory: true);
                    _carryPositionToNextLoad();
                    setState(() {
                      _currentSourceIndex = idx;
                      _userSource = _availableSources[idx];
                    });
                    _initializeStream(_availableSources[idx]);
                  },
                  onMenuOpened: _onMenuOpened,
                  onMenuClosed: _onMenuClosed,
                  onNextEpisode: _handleNextEpisode,
                  onBack: () {
                    DLog.event(
                      'player.back',
                      'ep=${_currentEpisode.number.toInt()}',
                    );
                    Navigator.of(context).pop();
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
