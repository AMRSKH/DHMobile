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
import '../../domain/models/player_engine.dart';
import '../../domain/models/stream_source.dart';
import '../../core/debug_log.dart';
import '../../core/l10n/app_strings.dart';
import '../library/library_controller.dart';
import '../settings/settings_controller.dart';
import 'player_controller.dart';
import 'prefetch.dart';
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

  // The engine of the current load. Every new load starts on the engine from
  // Settings (ExoPlayer by default). When VLC fails on a source, the same
  // source is loaded again on ExoPlayer before the player moves on.
  PlayerEngine _engine = PlayerEngine.defaultEngine;
  // True once the current load has played. The Android VLC plugin reports
  // its buffering events as "not buffering", so for VLC this, and not
  // `_isBuffering`, tells a load that never started (QA TASK-020 M1).
  bool _loadHasPlayed = false;
  // Automatic fresh resolutions of the sources since a load last played
  // for real (see `hasRealProgress`).
  int _autoReresolves = 0;
  // Where the current load first reported playing.
  Duration? _playedFrom;
  // A fresh resolution of the sources is running. An empty answer then keeps
  // the old list and shows Retry Stream (QA TASK-025).
  bool _reresolving = false;
  // Keeps the next episode's servers resolved while this one plays, so
  // "Next" starts at once (TASK-031). Closed when the episode changes.
  ProviderSubscription<AsyncValue<List<StreamSource>>>? _prefetch;
  String? _prefetchedId;
  DateTime? _prefetchedAt;
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
    _prefetch?.close();
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
        _pauseVlc();
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
    // The listeners read the current controller fields. A controller that is
    // being torn down must not report into the load that replaces it.
    _vlcController?.removeListener(_vlcListener);
    _vpController?.removeListener(_vpListener);
    final vlc = _vlcController;
    if (vlc != null) {
      _vlcController = null;
      // `dispose()` also throws for a controller that never got its view.
      // Both are async, so their errors arrive as Future errors.
      if (vlc.value.isInitialized) _vlcCall('player.vlcStop', vlc.stop);
      _vlcCall('player.vlcDispose', vlc.dispose);
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
      DLog.event('player.failover', 'exhausted tried=${_failedSources.length}');
      if (canAutoReresolve(_autoReresolves)) {
        _autoReresolves++;
        _reresolveSources(automatic: true);
        return;
      }
      setState(() {
        _isBuffering = false;
        _isPlaying = false;
        _errorMessage = ref.read(stringsProvider)(S.playerNoServer);
      });
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

  /// Asks for the episode's sources again instead of trying the same URLs:
  /// they may have expired or be bound to an old public IP. The new list
  /// starts in `build()`, from the server the user picked or the settings,
  /// at the carried position.
  void _reresolveSources({required bool automatic}) {
    DLog.event(
      'player.reresolve',
      'ep=${_currentEpisode.number.toInt()} '
          '${automatic ? 'auto=$_autoReresolves' : 'manual'}',
    );
    _reresolving = true;
    setState(() {
      _errorMessage = null;
      _isBuffering = true;
      _isPlaying = false;
    });
    ref.invalidate(episodeStreamsProvider(_currentEpisode.id));
  }

  /// The current load failed on [_engine]. Loads the same source on the
  /// fallback engine, or fails over to the next source when there is none.
  /// In the background the failure says nothing about the engine, so
  /// [_failover] defers it.
  void _onEngineFailed(StreamSource source) {
    final fallback = _engine.fallbackEngine();
    if (fallback == null || _inBackground) {
      _failover();
      return;
    }
    DLog.event(
      'player.engineFallback',
      'src=$_currentSourceIndex from=${_engine.code} to=${fallback.code}',
    );
    _carryPositionToNextLoad();
    _initializeStream(source, engine: fallback);
  }

  /// A load that played for real earns a new automatic re-resolve.
  void _notePlaying(Duration position) {
    final from = _playedFrom ??= position;
    if (_autoReresolves > 0 && hasRealProgress(from: from, now: position)) {
      _autoReresolves = 0;
    }
  }

  /// VLC throws when it is paused before it is initialized.
  void _pauseVlc() {
    final vlc = _vlcController;
    if (vlc == null || !vlc.value.isInitialized) return;
    _vlcCall('player.vlcPause', vlc.pause);
  }

  /// Runs a VLC platform call and logs its error. Every VLC call is async
  /// and can fail on the platform side, so none is left unhandled.
  void _vlcCall(String tag, Future<void> Function() call) {
    try {
      call().then<void>(
        (_) {},
        onError: (Object e, StackTrace st) => DLog.error(tag, e, st),
      );
    } catch (e, st) {
      DLog.error(tag, e, st);
    }
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

  /// Loads [source] on [engine], or on the engine from Settings when it is
  /// not given.
  Future<void> _initializeStream(
    StreamSource source, {
    PlayerEngine? engine,
  }) async {
    if (!mounted) return;
    _disposePlayers();
    // A later teardown (source switch, next episode, failover) makes this
    // load stale. It must then neither touch the state nor fail over.
    final load = _loadGeneration;
    setState(() {
      _engine = engine ?? ref.read(settingsProvider).playerEngine;
      _loadHasPlayed = false;
      _playedFrom = null;
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
          'engine=${_engine.code} '
          'ep=${_currentEpisode.number.toInt()} url=${source.url}',
    );

    try {
      if (_engine == PlayerEngine.vlc) {
        // VLC Player. It can send only these two headers; the streams of
        // the supported hosts load without the others (checked for the
        // Dailymotion cookie on 2026-11-10, TASK-020).
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
          // Software decoding. With MediaCodec (auto) libVLC drew a corrupt
          // picture on the SM-A546E ("Timestamp conversion failed ... no
          // reference clock"), and `decoding` drew black (TASK-023).
          hwAcc: HwAcc.disabled,
          autoPlay: true,
          options: vlcOptions,
          // Without this the package adds its own lifecycle observer, which
          // plays again on return from the background. This screen pauses
          // and stays paused by itself (QA TASK-020 M3).
          allowBackgroundPlayback: true,
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
      _onEngineFailed(source);
    }
  }

  void _resetBufferingWatchdog() {
    _bufferingWatchdog?.cancel();
    // A slow CDN can need more than 10 s before the first frame. Give the
    // current source time to start instead of discarding a working stream.
    // VLC gets less, because the same source still has ExoPlayer after it.
    final wait = _engine.fallbackEngine() != null
        ? const Duration(seconds: 15)
        : const Duration(seconds: 20);
    _bufferingWatchdog = Timer(wait, () {
      DLog.event(
        'player.watchdog',
        'src=$_currentSourceIndex buffering=$_isBuffering '
            'playing=$_isPlaying',
      );
      if (!mounted || _isPlaying) return;
      final stalled = _engine == PlayerEngine.vlc
          ? !_loadHasPlayed
          : _isBuffering;
      if (!stalled || _availableSources.isEmpty) return;
      // Also at the last source, so the spinner cannot stay forever.
      _onEngineFailed(_availableSources[_currentSourceIndex]);
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
    final vlc = _vlcController;
    if (vlc == null || !mounted) return;
    final value = vlc.value;
    final wasPlaying = _isPlaying;
    // libVLC can report 0 as the time of its "ended" event.
    final lastPosition = _position;

    // Read the last good position before the error state overwrites it.
    if (value.hasError) _carryPositionToNextLoad();

    if (value.isPlaying) {
      _loadHasPlayed = true;
      _notePlaying(value.position);
      _maybePrefetchNext(value.position, value.duration);
    }
    setState(() {
      _isPlaying = value.isPlaying;
      // Until the first frame the load counts as buffering, so the spinner
      // shows even though VLC reports its buffering as "not buffering".
      _isBuffering = value.isBuffering || (!_loadHasPlayed && !value.hasError);
      _position = value.position;
      _duration = value.duration;
    });

    if (value.isPlaying) {
      _bufferingWatchdog?.cancel();
      if (!wasPlaying) {
        // Playback just started: the control overlay is opaque to taps and
        // dims the video, so it must hide on its own.
        _startHideControlsTimer();
        // A new controller starts at 1.0x.
        if (_speed != 1.0) {
          _vlcCall('player.vlcSpeed', () => vlc.setPlaybackSpeed(_speed));
        }
      }
      // VLC plays by itself once it is ready. A load that became ready while
      // the app is in the background must not play behind another app.
      if (_inBackground) _pauseVlc();
    }

    if (value.isInitialized && _positionPollTimer == null) {
      _startPositionPolling();
    }

    if (value.isPlaying && _pendingResumeMs > 0) {
      _checkAndApplyResume();
    }

    if (value.hasError) {
      if (_availableSources.isEmpty) return;
      DLog.error(
        'player.vlc',
        'src=$_currentSourceIndex err=${value.errorDescription}',
      );
      _onEngineFailed(_availableSources[_currentSourceIndex]);
    } else if (value.isEnded && !_endHandled) {
      final endPosition = value.position > lastPosition
          ? value.position
          : lastPosition;
      if (isNearEnd(position: endPosition, duration: value.duration)) {
        _endHandled = true;
        _handleNextEpisode();
      } else if (_availableSources.isNotEmpty) {
        // libVLC can report "end reached" when an HLS input dies in the
        // middle (QA TASK-020 M2).
        DLog.event(
          'player.vlc',
          'early end pos=${value.position} dur=${value.duration}',
        );
        _carryPositionToNextLoad();
        _onEngineFailed(_availableSources[_currentSourceIndex]);
      }
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
      _notePlaying(value.position);
      _maybePrefetchNext(value.position, value.duration);
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
    final vlc = _vlcController;
    if (vlc != null) {
      if (!vlc.value.isInitialized) return;
      _vlcCall('player.vlcSeek', () => vlc.seekTo(duration));
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
    if (vlc != null && !vlc.value.isInitialized) return;
    final pause = _effectivePlaying;
    DLog.event(
      'player.playPause',
      'pause=$pause playing=$_isPlaying buffering=$_isBuffering '
          'want=$_wantPlaying',
    );
    if (vlc != null || vp != null) {
      if (pause) {
        if (vlc != null) {
          _vlcCall('player.vlcPause', vlc.pause);
        } else {
          vp!.pause();
        }
        _saveProgress(syncHistory: true);
      } else {
        if (vlc != null) {
          _vlcCall('player.vlcPlay', vlc.play);
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
    final vlc = _vlcController;
    if (vlc != null) {
      // A VLC load that is not ready yet gets the speed when it plays.
      if (vlc.value.isInitialized) {
        _vlcCall('player.vlcSpeed', () => vlc.setPlaybackSpeed(s));
      }
    } else if (_vpController != null) {
      _vpController!.setPlaybackSpeed(s);
    }
  }

  /// Starts resolving the next episode's servers in the background, once.
  void _maybePrefetchNext(Duration position, Duration duration) {
    if (_prefetch != null) return;
    final next = _currentEpisodeIndex + 1;
    if (next >= widget.episodes.length) return;
    if (!shouldPrefetchNext(position: position, duration: duration)) return;
    final episode = widget.episodes[next];
    DLog.event('player.prefetch', 'ep=${episode.number.toInt()}');
    _prefetchedId = episode.id;
    _prefetchedAt = DateTime.now();
    // An autoDispose provider stays alive while it has a listener.
    _prefetch = ref.listenManual(episodeStreamsProvider(episode.id), (_, _) {});
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
      final nextId = widget.episodes[_currentEpisodeIndex + 1].id;
      // Only a prefetched list that has servers and is still fresh is used.
      // An empty answer (network gone) or old URLs (expired, or bound to an
      // old IP) are resolved again, as before prefetching (TASK-031 QA).
      final prefetched =
          _prefetchedId == nextId &&
          usePrefetched(
            sources: ref.read(episodeStreamsProvider(nextId)).value,
            fetchedAt: _prefetchedAt,
            now: DateTime.now(),
          );
      final subscription = _prefetch;
      _prefetch = null;
      _prefetchedId = null;
      _prefetchedAt = null;
      setState(() {
        _currentEpisodeIndex++;
        _autoReresolves = 0;
        // Only a safe index for the old list. The source for the new episode
        // is chosen in build(), when its list arrives.
        _currentSourceIndex = 0;
        _pendingResumeMs = 0;
        _position = Duration.zero;
        _duration = Duration.zero;
      });
      DLog.event('player.next', 'prefetched=$prefetched');
      if (prefetched) {
        // build() now watches the prefetched list, so the background
        // listener can go once that frame is built.
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => subscription?.close(),
        );
      } else {
        subscription?.close();
        ref.invalidate(episodeStreamsProvider(_currentEpisode.id));
      }
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
    final s = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: streamsAsync.when(
        loading: () => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFFE50914)),
              const SizedBox(height: 16),
              Text(
                s(S.playerResolving),
                style: const TextStyle(color: Colors.white70),
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
                s.fmt(S.playerError, {'error': err}),
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(episodeStreamsProvider(_currentEpisode.id)),
                child: Text(s(S.retry)),
              ),
            ],
          ),
        ),
        data: (sources) {
          // While a refresh runs, `when` passes the provider's previous list;
          // only a finished answer counts.
          final answered =
              sources != _availableSources && !streamsAsync.isLoading;
          if (answered &&
              _reresolving &&
              sources.isEmpty &&
              _availableSources.isNotEmpty) {
            // A fresh resolution found nothing (offline, page down). Keep the
            // old list, so the player keeps Retry Stream instead of the dead
            // end of "no streams".
            _reresolving = false;
            DLog.event('player.reresolve', 'empty, keeping old list');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                _isBuffering = false;
                _isPlaying = false;
                _errorMessage = ref.read(stringsProvider)(S.playerNoServer);
              });
            });
          } else if (answered) {
            _reresolving = false;
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

          if (_availableSources.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s(S.playerNoStreams),
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(s(S.goBack)),
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
                  child: (_engine == PlayerEngine.vlc && _vlcController != null)
                      ? VlcPlayer(
                          // VLC initializes when its platform view is
                          // created. Without a key Flutter keeps the old
                          // view for a new controller, which then never
                          // starts (QA TASK-020 H1).
                          key: ObjectKey(_vlcController),
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
                          s.fmt(S.playerConnecting, {
                            'server':
                                _availableSources[_currentSourceIndex].server ??
                                s(S.playerServerWord),
                            'index': _currentSourceIndex + 1,
                            'total': _availableSources.length,
                          }),
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
                          // Every source was tried with its old URL. Fresh
                          // ones may work, so resolve the sources again; the
                          // new list starts from the source the user or the
                          // settings prefer.
                          onPressed: () {
                            _carryPositionToNextLoad();
                            _reresolveSources(automatic: false);
                          },
                          child: Text(s(S.retryStream)),
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
