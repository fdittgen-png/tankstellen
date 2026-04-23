import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../l10n/app_localizations.dart';

/// Dedicated Theme settings screen (#897).
///
/// Opened from the Theme [SettingsMenuTile] on the profile/settings
/// screen. Presents the three theme-mode choices (System / Light /
/// Dark) as full-width radio rows with descriptive copy below each
/// option — the same layout convention as `PrivacyDashboardScreen`:
/// `Scaffold` + `AppBar` + `ListView` body with 16 dp padding.
///
/// The picker was previously inlined on the Settings screen as a
/// `Card` + bottom sheet (`ThemeModeTile`). Extracting it here lets
/// the Theme entry match the Privacy and Storage entries, which both
/// push to a dedicated screen rather than opening a sheet.
class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final mode = ref.watch(themeModeSettingProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l?.themeSettingsScreenTitle ?? 'Theme'),
      ),
      body: RadioGroup<ThemeMode>(
        groupValue: mode,
        onChanged: (picked) => _select(ref, picked),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ThemeModeOption(
              mode: ThemeMode.system,
              icon: Icons.smartphone,
              label: l?.themeSettingsSystemLabel ?? 'Follow system',
              description: l?.themeSettingsSystemDescription ??
                  'Match the current device appearance.',
              selected: mode == ThemeMode.system,
              onTap: () => _select(ref, ThemeMode.system),
              keyValue: 'themeSettingsOptionSystem',
            ),
            const SizedBox(height: 8),
            _ThemeModeOption(
              mode: ThemeMode.light,
              icon: Icons.light_mode,
              label: l?.themeSettingsLightLabel ?? 'Light',
              description: l?.themeSettingsLightDescription ??
                  'Bright backgrounds — best for daytime use.',
              selected: mode == ThemeMode.light,
              onTap: () => _select(ref, ThemeMode.light),
              keyValue: 'themeSettingsOptionLight',
            ),
            const SizedBox(height: 8),
            _ThemeModeOption(
              mode: ThemeMode.dark,
              icon: Icons.dark_mode,
              label: l?.themeSettingsDarkLabel ?? 'Dark',
              description: l?.themeSettingsDarkDescription ??
                  'Dark backgrounds — easier on the eyes at night and '
                      'saves battery on OLED screens.',
              selected: mode == ThemeMode.dark,
              onTap: () => _select(ref, ThemeMode.dark),
              keyValue: 'themeSettingsOptionDark',
            ),
            SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 16),
          ],
        ),
      ),
    );
  }

  Future<void> _select(WidgetRef ref, ThemeMode? picked) async {
    if (picked == null) return;
    await ref.read(themeModeSettingProvider.notifier).set(picked);
  }
}

/// A single radio row on the theme settings screen — card-wrapped
/// for visual parity with the rest of the profile surface.
class _ThemeModeOption extends StatelessWidget {
  final ThemeMode mode;
  final bool selected;
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;
  final String keyValue;

  const _ThemeModeOption({
    required this.mode,
    required this.selected,
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
    required this.keyValue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: Key(keyValue),
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Radio<ThemeMode>(value: mode),
              const SizedBox(width: 4),
              Icon(icon, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
