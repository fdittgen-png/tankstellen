import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../l10n/app_localizations.dart';

/// Dedicated settings screen for the app's theme mode (#897).
///
/// Mirrors the layout/style of `PrivacyDashboardScreen` and the Storage
/// Dashboard:
///   * `Scaffold` with a plain `AppBar` titled "Theme".
///   * `ListView` body, padded 16 dp on every edge + bottom viewPadding.
///   * A coloured banner at the top explaining what the setting does.
///   * A `Card` hosting three `RadioListTile`s (Light / Dark / Follow
///     system) — extracted from the previous inline `ThemeModeTile`
///     bottom-sheet picker.
///
/// Selecting a mode updates `themeModeSettingProvider` immediately; the
/// Settings screen subtitle rebuilds live from the same provider, so the
/// user can see the change reflected without re-navigating.
class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final mode = ref.watch(themeModeSettingProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l?.themeSettingTitle ?? 'Theme'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ThemeSettingsBanner(),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      l?.themeSettingsPickerHeader ?? 'Appearance',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 4),
                  RadioGroup<ThemeMode>(
                    groupValue: mode,
                    onChanged: (v) {
                      if (v != null) {
                        ref
                            .read(themeModeSettingProvider.notifier)
                            .set(v);
                      }
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _themeOption(
                          mode: ThemeMode.light,
                          icon: Icons.light_mode,
                          label: l?.themeModeLight ?? 'Light',
                          keyValue: 'themeSettingsOptionLight',
                        ),
                        _themeOption(
                          mode: ThemeMode.dark,
                          icon: Icons.dark_mode,
                          label: l?.themeModeDark ?? 'Dark',
                          keyValue: 'themeSettingsOptionDark',
                        ),
                        _themeOption(
                          mode: ThemeMode.system,
                          icon: Icons.smartphone,
                          label: l?.themeModeSystem ?? 'Follow system',
                          keyValue: 'themeSettingsOptionSystem',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 16),
        ],
      ),
    );
  }

  Widget _themeOption({
    required ThemeMode mode,
    required IconData icon,
    required String label,
    required String keyValue,
  }) {
    return RadioListTile<ThemeMode>(
      key: Key(keyValue),
      value: mode,
      title: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

/// Top banner — same look as `PrivacyBanner` but themed with the
/// `Icons.palette_outlined` glyph.
class _ThemeSettingsBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.palette_outlined,
            color: theme.colorScheme.primary,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              l?.themeSettingsDescription ??
                  'Choose how the app looks. "Follow system" matches your '
                      'device\'s light/dark preference.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper used by `ProfileScreen` to render the "Current: X" subtitle on
/// the Theme menu tile. Kept in this file next to the screen so the mode
/// -> label mapping stays in one place.
String themeModeLabel(ThemeMode mode, AppLocalizations? l) => switch (mode) {
      ThemeMode.light => l?.themeModeLight ?? 'Light',
      ThemeMode.dark => l?.themeModeDark ?? 'Dark',
      ThemeMode.system => l?.themeModeSystem ?? 'Follow system',
    };
