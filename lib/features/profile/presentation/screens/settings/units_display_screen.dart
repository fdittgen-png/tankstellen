// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/country/country_config.dart';
import '../../../../../core/navigation/app_routes.dart';
import '../../../../../core/theme/theme_mode_provider.dart';
import '../../../../../core/widgets/scope_badge.dart';
import '../../../../../core/widgets/section_card.dart';
import '../../../../../core/widgets/settings_menu_tile.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../trips/api.dart' show ConsumptionUnitSettingTile;
import '../../../../widget/api.dart' show WidgetHelpSection;
import '../../../providers/profile_provider.dart';
import 'settings_topic_scaffold.dart';

/// Settings → Units & display (#3884): the Theme tile (#897), a
/// read-only Distance-unit row derived from the active profile's country
/// (no unit conversion is built here — #3883 adds the consumption-unit
/// row), and the home-screen widget section (per-profile colour +
/// variant, hence the "This profile" badge).
class UnitsDisplayScreen extends ConsumerWidget {
  const UnitsDisplayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final countryCode = ref.watch(activeProfileProvider)?.countryCode;
    final country = countryCode == null ? null : Countries.byCode(countryCode);
    // Language-neutral unit mask ("km" / "mi") straight from the country
    // config — the same value `UnitFormatter` renders distances with.
    final distanceUnit = country?.distanceUnit ?? 'km';

    return SettingsTopicScaffold(
      title: l.settingsTopicUnitsTitle,
      children: [
        // Theme — light / dark / eco / follow system (#752, #897).
        SettingsMenuTile(
          key: const Key('settingsThemeTile'),
          icon: Icons.palette_outlined,
          title: l.themeCardTitle,
          subtitle: themeSubtitle(ref, l),
          onTap: () => context.push(RoutePaths.themeSettings),
        ),
        const SizedBox(height: 8),
        SectionCard(
          padding: EdgeInsets.zero,
          child: ListTile(
            key: const Key('settingsDistanceUnitRow'),
            leading: const Icon(Icons.straighten_outlined, size: 20),
            title: Text(l.settingsDistanceUnitTitle),
            subtitle: Text(l.settingsDistanceUnitSubtitle),
            trailing: Text(
              distanceUnit,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // #3883 — app-wide consumption unit (automatic = country convention).
        const SectionCard(
          padding: EdgeInsets.zero,
          child: ConsumptionUnitSettingTile(),
        ),
        const SizedBox(height: 16),
        // #1806 — home-screen widget help + #2106 defaults editor. The
        // Android widget's per-widget config is OS-mediated (long-press →
        // Reconfigure) and can't be launched from the app, so this is
        // the in-app discoverable surface for it.
        SettingsGroupHeader(
          icon: Icons.widgets_outlined,
          title: l.widgetHelpSectionTitle,
          trailing: const ScopeBadge(SettingsScope.thisProfile),
        ),
        const SectionCard(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: WidgetHelpSection(),
        ),
      ],
    );
  }
}

/// Active-mode subtitle on the Theme `SettingsMenuTile` (#897).
String themeSubtitle(WidgetRef ref, AppLocalizations l) {
  final choice = ref.watch(themeModeSettingProvider);
  switch (choice) {
    case AppThemeChoice.light:
      return l.themeCardSubtitleLight;
    case AppThemeChoice.dark:
      return l.themeCardSubtitleDark;
    case AppThemeChoice.eco:
      return l.themeSettingsEcoLabel;
    case AppThemeChoice.system:
      return l.themeCardSubtitleSystem;
  }
}
