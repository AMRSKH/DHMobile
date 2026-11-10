import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../explore/explore_screen.dart';
import '../library/library_screen.dart';
import '../settings/settings_controller.dart';
import '../settings/settings_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  static const int _settingsIndex = 2;

  @override
  void initState() {
    super.initState();
    // Owner's choice (TASK-033): a cache above 500 MB is cleared at start, in
    // the background. Settings measures again when it is done.
    ref.read(cacheServiceProvider).clearIfOverLimit().then((_) {
      if (mounted) ref.invalidate(cacheSizeProvider);
    });
  }

  final List<Widget> _pages = const [
    ExploreScreen(),
    LibraryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          // Settings stays built in the IndexedStack, so its cache size is
          // measured again whenever it is opened (TASK-033 QA).
          if (index == _settingsIndex) ref.invalidate(cacheSizeProvider);
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: AppTheme.surfaceDark,
        indicatorColor: AppTheme.primaryRed.withValues(alpha: 0.2),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.explore_outlined),
            selectedIcon: const Icon(Icons.explore, color: AppTheme.primaryRed),
            label: s(S.explore),
          ),
          NavigationDestination(
            icon: const Icon(Icons.video_library_outlined),
            selectedIcon: const Icon(
              Icons.video_library,
              color: AppTheme.primaryRed,
            ),
            label: s(S.library),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(
              Icons.settings,
              color: AppTheme.primaryRed,
            ),
            label: s(S.settings),
          ),
        ],
      ),
    );
  }
}
