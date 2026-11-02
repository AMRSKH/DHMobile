import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/search/search_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: DonghuaApp(),
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
      home: const SearchScreen(),
    );
  }
}
