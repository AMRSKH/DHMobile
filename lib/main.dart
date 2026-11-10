import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/debug_log.dart';
import 'data/storage/storage_service.dart';
import 'features/splash/splash_screen.dart';
import 'features/library/library_controller.dart';

class _AppHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _AppHttpOverrides();
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
      title: 'DonghuaPlayer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
