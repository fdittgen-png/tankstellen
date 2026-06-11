// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../feature_management/application/feature_flags_provider.dart';
import '../../../feature_management/domain/conso_mode.dart';
import '../../../feature_management/domain/feature.dart';
import '../../../feature_management/domain/feature_category.dart';
import '../../../feature_management/domain/feature_manifest.dart';
import 'feature_management/conso_feature_card.dart';
import 'feature_management/feature_group_card.dart';
import 'feature_management/feature_grouping.dart';
import 'feature_management/feature_section_header.dart';

/// Settings-screen section that exposes every [Feature] as a toggle
/// (#1373 phase 2; #1440 grouping; #1447 cascading-disable; #2681
/// ordered category sections).
///
/// Renders one [SwitchListTile] per entry in [featureManifestProvider],
/// VISUALLY GROUPED so dependent features sit indented under the parent
/// they require (#1440), and the groups are bucketed under ordered
/// category section headers ([FeatureSectionHeader]) sequenced by user
/// value/frequency (#2681). The grouping/category mapping is
/// presentation-only — the [Feature] enum and the manifest keep their
/// persistence order.
///
/// Cascading-disable model (#1447): disabling a parent always succeeds.
/// Children stay in the stored set so re-enabling the parent restores the
/// user's previous setup, but they render as disabled-with-tooltip while
/// any ancestor is off — the tooltip names the missing prerequisite via
/// `featureBlockedEnable_<feature.name>`. A single tap on a blocked row
/// also surfaces the same message via [SnackBar] (#1440).
class FeatureManagementSection extends ConsumerWidget {
  const FeatureManagementSection({super.key});

  // #1571 — Conso surface owns its own card with a 3-way segmented
  // control (Off / Fuel / Fuel + Trips). These flags are driven by the
  // segmented control and never render as stand-alone toggles.
  static const _consoModeFlags = <Feature>{
    Feature.obd2TripRecording,
    Feature.manualConsumption,
    Feature.showConsumptionTab,
  };

  // Dependents that visually belong inside the Conso card (Trajets tier)
  // — only tappable when consoMode == fuelAndTrips because their manifest
  // `requires` chain includes obd2TripRecording.
  static const _consoDependents = <Feature>[
    Feature.consumptionAnalytics,
    Feature.gamification,
    Feature.hapticEcoCoach,
    Feature.glideCoach,
    Feature.gpsTripPath,
    Feature.autoRecord,
    // #1615 — the OEM-PID exact-fuel-level read only runs inside a trip
    // recording, so it belongs to the Trajets tier.
    Feature.experimentalOemPids,
  ];

  // #2681 — `obd2Optional` renders as an always-enabled indented row in
  // the Conso card (it has no manifest `requires` edge — presentation-
  // only placement, not a dependency).
  static const _consoExtraRows = <Feature>[Feature.obd2Optional];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final manifest = ref.watch(featureManifestProvider);
    final enabled = ref.watch(enabledFeaturesProvider);

    // #1675 — a feature not available in the current build channel never
    // renders in the feature-management list.
    final channel = ref.watch(buildChannelProvider);
    bool availableInChannel(Feature f) =>
        manifest.entries[f]?.isAvailableIn(channel) ?? false;

    final groups = buildGroups(manifest);
    final consoDependents = _consoDependents.where(availableInChannel).toList();
    final consoExtraRows = _consoExtraRows.where(availableInChannel).toList();

    // Filter the regular group rendering: drop the Conso "parent" flags,
    // the Conso dependents (re-rendered inside the Conso card), and the
    // Conso extra rows (`obd2Optional`, re-rendered inside the Conso
    // card). Other groups flow through unchanged.
    final filteredGroups = <FeatureGroup>[
      for (final group in groups)
        if (!_consoModeFlags.contains(group.parent) &&
            !consoExtraRows.contains(group.parent) &&
            availableInChannel(group.parent))
          FeatureGroup(
            parent: group.parent,
            children: [
              for (final c in group.children)
                if (!consoDependents.contains(c) &&
                    !_consoModeFlags.contains(c) &&
                    !consoExtraRows.contains(c) &&
                    availableInChannel(c))
                  c,
            ],
          ),
    ];

    // Bucket the filtered groups by category (#2681), keyed by the
    // group's parent feature. Render order follows [categoryOrder].
    final byCategory = <FeatureCategory, List<FeatureGroup>>{};
    for (final group in filteredGroups) {
      byCategory.putIfAbsent(categoryOf(group.parent), () => []).add(group);
    }

    final consoCard = ConsoFeatureCard(
      mode: consoModeFromFlags(enabled),
      dependents: consoDependents,
      extraRows: consoExtraRows,
      manifest: manifest,
      currentlyEnabled: enabled,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Text(
              l.featureManagementSectionSubtitle,
              style: theme.textTheme.bodySmall,
            ),
          ),
          for (final category in categoryOrder)
            ..._buildSection(
              category,
              byCategory[category] ?? [],
              consoCard,
              manifest,
              enabled,
            ),
        ],
      ),
    );
  }

  /// Builds one category section: its header (skipped when the bucket is
  /// empty and the section owns no pinned card) followed by the bucket's
  /// group cards. The Conso card is pinned to the top of the
  /// [FeatureCategory.consumption] section.
  List<Widget> _buildSection(
    FeatureCategory category,
    List<FeatureGroup> bucket,
    ConsoFeatureCard consoCard,
    FeatureManifest manifest,
    Set<Feature> enabled,
  ) {
    final isConsumption = category == FeatureCategory.consumption;
    // Skip headers for empty buckets — but the consumption section always
    // renders because it owns the pinned Conso card.
    if (bucket.isEmpty && !isConsumption) return const [];
    return [
      FeatureSectionHeader(category: category),
      if (isConsumption) consoCard,
      for (final group in bucket)
        FeatureGroupCard(
          group: group,
          manifest: manifest,
          currentlyEnabled: enabled,
        ),
    ];
  }
}
