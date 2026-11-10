import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen_brightness/screen_brightness.dart';
import '../../../core/debug_log.dart';

class GestureOverlay extends StatefulWidget {
  final Widget child;
  final VoidCallback onToggleControls;
  final VoidCallback onDoubleTapLeft;
  final VoidCallback onDoubleTapRight;

  const GestureOverlay({
    super.key,
    required this.child,
    required this.onToggleControls,
    required this.onDoubleTapLeft,
    required this.onDoubleTapRight,
  });

  @override
  State<GestureOverlay> createState() => _GestureOverlayState();
}

class _GestureOverlayState extends State<GestureOverlay> {
  static const MethodChannel _volumeChannel = MethodChannel(
    'dev.amscenter.donghua_player/volume',
  );

  final ScreenBrightness _screenBrightness = ScreenBrightness();
  double _currentBrightness = 0.5;
  double _currentVolume = 0.5;
  String? _indicatorText;
  IconData? _indicatorIcon;
  bool _showIndicator = false;
  Timer? _indicatorTimer;

  @override
  void initState() {
    super.initState();
    _initBrightness();
    _initVolume();
  }

  @override
  void dispose() {
    _indicatorTimer?.cancel();
    super.dispose();
  }

  Future<void> _initBrightness() async {
    try {
      final value = await _screenBrightness.application;
      if (mounted) {
        setState(() {
          _currentBrightness = value;
        });
      }
    } catch (_) {}
  }

  Future<void> _initVolume() async {
    try {
      final value = await _volumeChannel.invokeMethod<double>('getVolume');
      if (value != null && mounted) {
        setState(() {
          _currentVolume = value;
        });
      }
    } catch (_) {}
  }

  void _setVolume(double value) {
    _volumeChannel
        .invokeMethod<double>('setVolume', {'value': value})
        .catchError((_) => null);
  }

  void _onVerticalDragUpdate(DragUpdateDetails details, double screenWidth) {
    final isLeft = details.globalPosition.dx < screenWidth / 2;
    final delta = -(details.primaryDelta ?? 0) / 200.0;

    setState(() {
      _showIndicator = true;
      if (isLeft) {
        _currentBrightness = (_currentBrightness + delta).clamp(0.0, 1.0);
        unawaited(
          _screenBrightness.setApplicationScreenBrightness(_currentBrightness),
        );
        _indicatorIcon = Icons.brightness_6;
        _indicatorText = '${(_currentBrightness * 100).round()}%';
      } else {
        _currentVolume = (_currentVolume + delta).clamp(0.0, 1.0);
        _setVolume(_currentVolume);
        _indicatorIcon = _currentVolume == 0
            ? Icons.volume_off
            : Icons.volume_up;
        _indicatorText = '${(_currentVolume * 100).round()}%';
      }
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    _indicatorTimer?.cancel();
    _indicatorTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _showIndicator = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // The video surface sits at the bottom; the gesture layer goes on top
        // of it so taps and swipes are always received. Interactive overlays
        // (controls, error actions) must be placed above this widget.
        widget.child,
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              DLog.event('gesture.tap', '');
              widget.onToggleControls();
            },
            onDoubleTapDown: (details) {
              DLog.event(
                'gesture.doubleTap',
                details.globalPosition.dx < size.width / 2 ? 'left' : 'right',
              );
              if (details.globalPosition.dx < size.width / 2) {
                widget.onDoubleTapLeft();
              } else {
                widget.onDoubleTapRight();
              }
            },
            onVerticalDragUpdate: (details) =>
                _onVerticalDragUpdate(details, size.width),
            onVerticalDragEnd: _onVerticalDragEnd,
          ),
        ),
        if (_showIndicator)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_indicatorIcon, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    _indicatorText ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
