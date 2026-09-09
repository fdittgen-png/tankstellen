// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/panel_card.dart';
import '../../../../l10n/app_localizations.dart';

/// Dedicated Theme settings screen (#897; Eco theme added #1712).
///
/// Opened from the Theme [SettingsMenuTile] on the profile/settings
/// screen. Presents the four theme choices (System / Light / Dark /
/// Eco) as full-width radio rows with descriptive copy below each
/// option — the same layout convention as `PrivacyDashboardScreen`:
/// `PageScaffold` + `ListView` body with 16 dp padding.
class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final choice = ref.watch(themeModeSettingProvider);

    return PageScaffold(
      title: l.themeSettingsScreenTitle,
      bodyPadding: EdgeInsets.zero,
      body: RadioGroup<AppThemeChoice>(
        groupValue: choice,
        onChanged: (picked) => _select(ref, picked),
        child: ListView(
          padding: Spacing.screenPadding,
          children: [
            _ThemeChoiceOption(
              choice: AppThemeChoice.system,
              icon: Icons.smartphone,
              label: l.themeSettingsSystemLabel,
              description: l.themeSettingsSystemDescription,
              selected: choice == AppThemeChoice.system,
              onTap: () => _select(ref, AppThemeChoice.system),
              keyValue: 'themeSettingsOptionSystem',
            ),
            const SizedBox(height: Spacing.md),
            _ThemeChoiceOption(
              choice: AppThemeChoice.light,
              icon: Icons.light_mode,
              label: l.themeSettingsLightLabel,
              description: l.themeSettingsLightDescription,
              selected: choice == AppThemeChoice.light,
              onTap: () => _select(ref, AppThemeChoice.light),
              keyValue: 'themeSettingsOptionLight',
            ),
            const SizedBox(height: Spacing.md),
            _ThemeChoiceOption(
              choice: AppThemeChoice.dark,
              icon: Icons.dark_mode,
              label: l.themeSettingsDarkLabel,
              description: l.themeSettingsDarkDescription,
              selected: choice == AppThemeChoice.dark,
              onTap: () => _select(ref, AppThemeChoice.dark),
              keyValue: 'themeSettingsOptionDark',
            ),
            const SizedBox(height: Spacing.md),
            _ThemeChoiceOption(
              choice: AppThemeChoice.eco,
              icon: Icons.energy_savings_leaf,
              label: l.themeSettingsEcoLabel,
              description: l.themeSettingsEcoDescription,
              selected: choice == AppThemeChoice.eco,
              onTap: () => _select(ref, AppThemeChoice.eco),
              keyValue: 'themeSettingsOptionEco',
            ),
            SizedBox(
              height: MediaQuery.of(context).viewPadding.bottom + Spacing.xl,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _select(WidgetRef ref, AppThemeChoice? picked) async {
    if (picked == null) return;
    await ref.read(themeModeSettingProvider.notifier).set(picked);
  }
}

/// A single radio row on the theme settings screen — card-wrapped
/// for visual parity with the rest of the profile surface.
class _ThemeChoiceOption extends StatelessWidget {
  final AppThemeChoice choice;
  final bool selected;
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;
  final String keyValue;

  const _ThemeChoiceOption({
    required this.choice,
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
    return PanelCard(
      key: Key(keyValue),
      margin: EdgeInsets.zero,
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(
        Spacing.md,
        Spacing.md,
        Spacing.xl,
        Spacing.lg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Radio<AppThemeChoice>(value: choice),
          const SizedBox(width: Spacing.sm),
          Icon(icon, size: 20),
          const SizedBox(width: Spacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: Spacing.md),
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                Text(description, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
