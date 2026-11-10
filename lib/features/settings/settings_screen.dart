import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_info.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/content_source.dart';
import '../../domain/models/player_engine.dart';
import '../library/library_controller.dart';
import 'settings_controller.dart';

// Stored values. `source_selection.dart` reads them as they are, so only the
// label on screen is translated.
const List<String> _qualityValues = ['Auto', '1080p', '720p', '480p'];
const List<String> _subtitleValues = ['English', 'Indonesian', 'None'];

String _qualityLabel(AppStrings s, String value) {
  return value == 'Auto' ? s(S.qualityAuto) : value;
}

String _subtitleLabel(AppStrings s, String value) {
  switch (value) {
    case 'English':
      return s(S.subtitleEnglish);
    case 'Indonesian':
      return s(S.subtitleIndonesian);
    case 'None':
      return s(S.subtitleNone);
    default:
      return value;
  }
}

/// A dialog with one radio row per value. Returns the tapped value, or null
/// when the dialog is dismissed.
Future<T?> _showChoiceDialog<T>({
  required BuildContext context,
  required String title,
  required List<T> values,
  required T selected,
  required String Function(T value) labelOf,
}) {
  return showDialog<T>(
    context: context,
    builder: (ctx) => SimpleDialog(
      backgroundColor: AppTheme.surfaceDark,
      title: Text(title),
      children: values.map((value) {
        final isSelected = value == selected;
        return SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, value),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: isSelected ? AppTheme.primaryRed : AppTheme.textMuted,
                size: 18,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  labelOf(value),
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    ),
  );
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final s = ref.watch(stringsProvider);
    // Khmer has no capitals to space out, and wide tracking breaks its
    // stacked letters apart.
    final headerSpacing = settings.language == AppLanguage.km ? 0.0 : 1.1;
    const muted = TextStyle(color: AppTheme.textMuted);
    const chevron = Icon(
      Icons.arrow_forward_ios,
      size: 14,
      color: AppTheme.textMuted,
    );

    return Scaffold(
      appBar: AppBar(title: Text(s(S.settings))),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          _SectionHeader(
            title: s(S.sectionGeneral),
            letterSpacing: headerSpacing,
          ),
          // Display language
          ListTile(
            leading: const Icon(Icons.language, color: AppTheme.primaryRed),
            title: Text(s(S.displayLanguage)),
            subtitle: Text(settings.language.label, style: muted),
            trailing: chevron,
            onTap: () async {
              final chosen = await _showChoiceDialog<AppLanguage>(
                context: context,
                title: s(S.chooseLanguage),
                values: AppLanguage.values,
                selected: settings.language,
                labelOf: (language) => language.label,
              );
              if (chosen != null) {
                await settingsNotifier.setLanguage(chosen);
              }
            },
          ),

          const Divider(
            height: 32,
            indent: 16,
            endIndent: 16,
            color: Colors.white12,
          ),
          _SectionHeader(
            title: s(S.sectionPlayback),
            letterSpacing: headerSpacing,
          ),
          // Quality
          ListTile(
            leading: const Icon(Icons.hd_outlined, color: AppTheme.primaryRed),
            title: Text(s(S.defaultQuality)),
            subtitle: Text(
              _qualityLabel(s, settings.defaultQuality),
              style: muted,
            ),
            trailing: chevron,
            onTap: () async {
              final chosen = await _showChoiceDialog<String>(
                context: context,
                title: s(S.chooseQuality),
                values: _qualityValues,
                selected: settings.defaultQuality,
                labelOf: (value) => _qualityLabel(s, value),
              );
              if (chosen != null) {
                await settingsNotifier.setDefaultQuality(chosen);
              }
            },
          ),
          // Subtitles
          ListTile(
            leading: const Icon(
              Icons.subtitles_outlined,
              color: AppTheme.primaryRed,
            ),
            title: Text(s(S.preferredSubtitle)),
            subtitle: Text(
              _subtitleLabel(s, settings.preferredSubtitle),
              style: muted,
            ),
            trailing: chevron,
            onTap: () async {
              final chosen = await _showChoiceDialog<String>(
                context: context,
                title: s(S.chooseSubtitle),
                values: _subtitleValues,
                selected: settings.preferredSubtitle,
                labelOf: (value) => _subtitleLabel(s, value),
              );
              if (chosen != null) {
                await settingsNotifier.setPreferredSubtitle(chosen);
              }
            },
          ),
          // Player engine
          ListTile(
            leading: const Icon(
              Icons.smart_display_outlined,
              color: AppTheme.primaryRed,
            ),
            title: Text(s(S.videoPlayer)),
            subtitle: Text(settings.playerEngine.label, style: muted),
            trailing: chevron,
            onTap: () async {
              final chosen = await _showChoiceDialog<PlayerEngine>(
                context: context,
                title: s(S.chooseVideoPlayer),
                values: PlayerEngine.values,
                selected: settings.playerEngine,
                labelOf: (engine) => engine.label,
              );
              if (chosen != null) {
                await settingsNotifier.setPlayerEngine(chosen);
              }
            },
          ),

          const Divider(
            height: 32,
            indent: 16,
            endIndent: 16,
            color: Colors.white12,
          ),
          _SectionHeader(title: s(S.sectionData), letterSpacing: headerSpacing),

          // Clear history
          ListTile(
            leading: const Icon(
              Icons.delete_sweep_outlined,
              color: Colors.amber,
            ),
            title: Text(s(S.clearHistory)),
            subtitle: Text(s(S.clearHistoryDesc), style: muted),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppTheme.surfaceDark,
                  title: Text(s(S.clearHistoryConfirmTitle)),
                  content: Text(s(S.clearHistoryConfirmBody)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(s(S.cancel)),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryRed,
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(s(S.clear)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(historyProvider.notifier).clearHistory();
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(s(S.historyCleared))));
                }
              }
            },
          ),

          // Clear favorites
          ListTile(
            leading: const Icon(
              Icons.heart_broken_outlined,
              color: Colors.amber,
            ),
            title: Text(s(S.clearFavorites)),
            subtitle: Text(s(S.clearFavoritesDesc), style: muted),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppTheme.surfaceDark,
                  title: Text(s(S.clearFavoritesConfirmTitle)),
                  content: Text(s(S.clearFavoritesConfirmBody)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(s(S.cancel)),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryRed,
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(s(S.clear)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(favoritesProvider.notifier).clearFavorites();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(s(S.favoritesCleared))),
                  );
                }
              }
            },
          ),

          // Clear image cache
          ListTile(
            leading: const Icon(
              Icons.cleaning_services_outlined,
              color: Colors.blueAccent,
            ),
            title: Text(s(S.clearCache)),
            subtitle: Text(s(S.clearCacheDesc), style: muted),
            onTap: () async {
              await settingsNotifier.clearCache();
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(s(S.cacheCleared))));
              }
            },
          ),

          const Divider(
            height: 32,
            indent: 16,
            endIndent: 16,
            color: Colors.white12,
          ),
          _SectionHeader(
            title: s(S.sectionAbout),
            letterSpacing: headerSpacing,
          ),

          ListTile(
            leading: const Icon(Icons.info_outline, color: AppTheme.textMuted),
            title: const Text(AppInfo.name),
            subtitle: Text(
              s.fmt(S.versionLine, {
                'version': AppInfo.version,
                'build': AppInfo.buildNumber,
              }),
              style: muted,
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.play_circle_outline,
              color: AppTheme.textMuted,
            ),
            title: Text(s(S.aboutPlayer)),
            subtitle: Text(settings.playerEngine.chain, style: muted),
          ),
          ListTile(
            leading: const Icon(Icons.public, color: AppTheme.textMuted),
            title: Text(s(S.aboutContentSource)),
            subtitle: Text(
              kContentSources.map((s) => s.name).join(', '),
              style: muted,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.code_outlined, color: AppTheme.textMuted),
            title: Text(s(S.credits)),
            subtitle: const Text(
              'Development by AMSCenter\nDeveloper by AMSDev',
              style: muted,
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.shield_outlined,
              color: AppTheme.textMuted,
            ),
            title: Text(s(S.privacy)),
            subtitle: Text(s(S.privacyBody), style: muted),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final double letterSpacing;

  const _SectionHeader({required this.title, required this.letterSpacing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Text(
        title,
        style: TextStyle(
          color: AppTheme.primaryRed,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: letterSpacing,
        ),
      ),
    );
  }
}
