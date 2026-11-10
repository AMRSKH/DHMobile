import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/app_info.dart';
import 'core/theme/app_theme.dart';
import 'core/debug_log.dart';
import 'data/storage/storage_service.dart';
import 'features/splash/splash_screen.dart';
import 'features/library/library_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storageService = StorageService();
  await storageService.init();
  DLog.event('app.start', 'storage ready');

  runApp(
    ProviderScope(
      overrides: [storageServiceProvider.overrideWithValue(storageService)],
      child: const DonghuaApp(),
    ),
  );
}

class DonghuaApp extends StatelessWidget {
  const DonghuaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppInfo.name,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
