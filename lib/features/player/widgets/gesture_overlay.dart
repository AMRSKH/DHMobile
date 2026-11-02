import 'package:flutter/material.dart';
import 'package:screen_brightness/screen_brightness.dart';

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
  final ScreenBrightness _screenBrightness = ScreenBrightness();
  double _currentBrightness = 0.5;
  double _currentVolume = 0.5;
  String? _indicatorText;
  IconData? _indicatorIcon;
  bool _showIndicator = false;

  @override
  void initState() {
    super.initState();
    _initBrightness();
  }

  Future<void> _initBrightness() async {
    try {
      _currentBrightness = await _screenBrightness.application;
    } catch (_) {}
  }

  void _onVerticalDragUpdate(DragUpdateDetails details, double screenWidth) {
    final isLeft = details.globalPosition.dx < screenWidth / 2;
    final delta = -details.primaryDelta! / 200.0;

    setState(() {
      _showIndicator = true;
      if (isLeft) {
        _currentBrightness = (_currentBrightness + delta).clamp(0.0, 1.0);
        _screenBrightness.setApplicationScreenBrightness(_currentBrightness);
        _indicatorIcon = Icons.brightness_6;
        _indicatorText = '${(_currentBrightness * 100).round()}%';
      } else {
        _currentVolume = (_currentVolume + delta).clamp(0.0, 1.0);
        _indicatorIcon = _currentVolume == 0 ? Icons.volume_off : Icons.volume_up;
        _indicatorText = '${(_currentVolume * 100).round()}%';
      }
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    Future.delayed(const Duration(milliseconds: 800), () {
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
        widget.child,
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: widget.onToggleControls,
            onDoubleTapDown: (details) {
              if (details.globalPosition.dx < size.width / 2) {
                widget.onDoubleTapLeft();
              } else {
                widget.onDoubleTapRight();
              }
            },
            onVerticalDragUpdate: (details) => _onVerticalDragUpdate(details, size.width),
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
