import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../library/library_controller.dart';
import 'settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          const _SectionHeader(title: 'PLAYBACK PREFERENCES'),
          // Quality
          ListTile(
            leading: const Icon(Icons.hd_outlined, color: AppTheme.primaryRed),
            title: const Text('Default Stream Quality'),
            subtitle: Text(settings.defaultQuality, style: const TextStyle(color: AppTheme.textMuted)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textMuted),
            onTap: () async {
              final chosen = await showDialog<String>(
                context: context,
                builder: (ctx) => SimpleDialog(
                  backgroundColor: AppTheme.surfaceDark,
                  title: const Text('Choose Default Quality'),
                  children: ['Auto', '1080p', '720p', '480p'].map((q) {
                    final selected = q == settings.defaultQuality;
                    return SimpleDialogOption(
                      onPressed: () => Navigator.pop(ctx, q),
                      child: Row(
                        children: [
                          Icon(
                            selected ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: selected ? AppTheme.primaryRed : AppTheme.textMuted,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Text(q, style: TextStyle(color: selected ? Colors.white : AppTheme.textMuted)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
              if (chosen != null) {
                await settingsNotifier.setDefaultQuality(chosen);
              }
            },
          ),
          // Subtitles
          ListTile(
            leading: const Icon(Icons.subtitles_outlined, color: AppTheme.primaryRed),
            title: const Text('Preferred Subtitle Language'),
            subtitle: Text(settings.preferredSubtitle, style: const TextStyle(color: AppTheme.textMuted)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textMuted),
            onTap: () async {
              final chosen = await showDialog<String>(
                context: context,
                builder: (ctx) => SimpleDialog(
                  backgroundColor: AppTheme.surfaceDark,
                  title: const Text('Preferred Subtitle'),
                  children: ['English', 'Indonesian', 'None'].map((s) {
                    final selected = s == settings.preferredSubtitle;
                    return SimpleDialogOption(
                      onPressed: () => Navigator.pop(ctx, s),
                      child: Row(
                        children: [
                          Icon(
                            selected ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: selected ? AppTheme.primaryRed : AppTheme.textMuted,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Text(s, style: TextStyle(color: selected ? Colors.white : AppTheme.textMuted)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
              if (chosen != null) {
                await settingsNotifier.setPreferredSubtitle(chosen);
              }
            },
          ),

          const Divider(height: 32, indent: 16, endIndent: 16, color: Colors.white12),
          const _SectionHeader(title: 'DATA & STORAGE'),

          // Clear history
          ListTile(
            leading: const Icon(Icons.delete_sweep_outlined, color: Colors.amber),
            title: const Text('Clear Watch History'),
            subtitle: const Text('Remove all watched progress and history entries', style: TextStyle(color: AppTheme.textMuted)),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppTheme.surfaceDark,
                  title: const Text('Clear History?'),
                  content: const Text('This will erase all recorded watch progress.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryRed),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(historyProvider.notifier).clearHistory();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Watch history cleared')),
                  );
                }
              }
            },
          ),

          // Clear favorites
          ListTile(
            leading: const Icon(Icons.heart_broken_outlined, color: Colors.amber),
            title: const Text('Clear Favorites'),
            subtitle: const Text('Remove all saved donghua favorites', style: TextStyle(color: AppTheme.textMuted)),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppTheme.surfaceDark,
                  title: const Text('Clear Favorites?'),
                  content: const Text('All saved shows will be removed from your library.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryRed),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(favoritesProvider.notifier).clearFavorites();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Favorites cleared')),
                  );
                }
              }
            },
          ),

          // Clear image cache
          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined, color: Colors.blueAccent),
            title: const Text('Clear Cache'),
            subtitle: const Text('Free up memory and temporary image cache', style: TextStyle(color: AppTheme.textMuted)),
            onTap: () async {
              await settingsNotifier.clearCache();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Image and memory cache cleared')),
                );
              }
            },
          ),

          const Divider(height: 32, indent: 16, endIndent: 16, color: Colors.white12),
          const _SectionHeader(title: 'ABOUT'),

          const ListTile(
            leading: Icon(Icons.info_outline, color: AppTheme.textMuted),
            title: Text('DonghuaPlayer'),
            subtitle: Text('Version 1.0.0 (Release)\nBuilt with Flutter & libVLC', style: TextStyle(color: AppTheme.textMuted)),
          ),
          const ListTile(
            leading: Icon(Icons.shield_outlined, color: AppTheme.textMuted),
            title: Text('Privacy'),
            subtitle: Text('No ads • No tracking • 100% offline local storage', style: TextStyle(color: AppTheme.textMuted)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.primaryRed,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
