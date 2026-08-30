// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/navigation/app_routes.dart';
import '../../../../../core/widgets/scope_badge.dart';
import '../../../../../core/widgets/section_card.dart';
import '../../../../../core/widgets/settings_menu_tile.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../driving/api.dart' show DrivingSettingsSection;
import '../../../../feature_management/api.dart';
import '../../../../trips/api.dart' show LiveConsumptionWindowSettingTile;
import 'settings_topic_scaffold.dart';

/// Settings → Driving & consumption (#3884): the Fuel Station Radar
/// tile (active profile), then the existing [DrivingSettingsSection]
/// expanded — vehicles link, coaching while driving, rewards & savings,
/// troubleshooting. When the consumption surface is not reachable
/// (#1517 / #1520 gate) the section is replaced by a hint that links to
/// Features & use mode instead of vanishing silently.
class DrivingConsumptionScreen extends ConsumerWidget {
  const DrivingConsumptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final manifest = ref.watch(featureManifestProvider);
    final enabledFlags = ref.watch(enabledFeaturesProvider);
    // #1517 / #1520 — reachable when `showConsumptionTab` is on AND at
    // least one data source is on (manualConsumption OR obd2TripRecording).
    final consumptionOn = isConsumptionTabReachable(manifest, enabledFlags);

    return SettingsTopicScaffold(
      title: l.settingsTopicDrivingTitle,
      children: [
        // #3883 — the live "Last N s" consumption window (the unit itself
        // lives under Units & display: one home per parameter).
        const SectionCard(
          padding: EdgeInsets.zero,
          child: LiveConsumptionWindowSettingTile(),
        ),
        const SizedBox(height: 8),
        SettingsMenuTile(
          key: const Key('settingsRadarTile'),
          icon: Icons.radar,
          title: l.approachOverlaySection,
          subtitle: l.settingsRadarTileSubtitle,
          badge: const ScopeBadge(SettingsScope.thisProfile),
          onTap: () => context.push(RoutePaths.settingsRadar),
        ),
        const SizedBox(height: 16),
        if (consumptionOn)
          const DrivingSettingsSection()
        else ...[
          SettingsHintText(l.settingsConsumptionOffHint),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: const Key('settingsOpenFeaturesLink'),
              onPressed: () => context.push(RoutePaths.settingsFeatures),
              icon: const Icon(Icons.dashboard_customize_outlined, size: 18),
              label: Text(l.settingsOpenFeaturesLink),
            ),
          ),
        ],
      ],
    );
  }
}
