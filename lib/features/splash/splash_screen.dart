import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_info.dart';
import '../../core/theme/app_theme.dart';
import '../explore/explore_controller.dart';
import '../home/main_screen.dart';

/// The only splash of the app: the red app name on black, which fades in,
/// holds, and then zooms towards the viewer while it fades out. The Android
/// launch window in front of it is plain black, so nothing else is seen.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  /// Key of the widget that scales the logo. The tests read the scale there.
  static const Key logoKey = ValueKey('splash-logo');

  /// Length of the logo animation.
  static const Duration animationDuration = Duration(milliseconds: 2000);

  /// Length of the fade into the app that follows it.
  static const Duration handoverDuration = Duration(milliseconds: 350);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: SplashScreen.animationDuration,
    );

    // 0 to 30%: settle in. 30 to 70%: a slow push. 70 to 100%: the zoom.
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.80,
          end: 1.00,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 30,
      ),
      TweenSequenceItem(tween: Tween(begin: 1.00, end: 1.08), weight: 40),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.08,
          end: 8.0,
        ).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 30,
      ),
    ]).animate(_controller);

    // Fades in over the first 30% and out over the last 15%.
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 15),
    ]).animate(_controller);

    _controller.addStatusListener(_onStatus);
    _controller.forward();

    // Starts the schedule request, so Explore has a head start. The splash
    // never waits for the network.
    ref.read(exploreControllerProvider);
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, _, _) => const MainScreen(),
        transitionDuration: SplashScreen.handoverDuration,
        transitionsBuilder: (context, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            // The fade is in the text color. An Opacity widget would need
            // an extra layer around the zoomed text on every frame.
            final opacity = _opacity.value.clamp(0.0, 1.0);
            return Transform.scale(
              key: SplashScreen.logoKey,
              scale: _scale.value,
              child: Text(
                AppInfo.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                softWrap: false,
                // The size is part of the design, so it does not follow
                // the font scale of the system.
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  color: AppTheme.primaryRed.withValues(alpha: opacity),
                  fontSize: 46,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
