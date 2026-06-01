// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../feature_management/application/app_profile_provider.dart';
import '../../../feature_management/application/feature_flags_provider.dart';
import '../../../feature_management/domain/conso_mode.dart';
import '../../../feature_management/domain/feature.dart';
import '../../../feature_management/domain/feature_dependency_graph.dart';
import '../../../feature_management/domain/feature_manifest.dart';

/// Settings-screen section that exposes every [Feature] as a toggle
/// (#1373 phase 2; #1440 grouping; #1447 cascading-disable).
///
/// Renders one [SwitchListTile] per entry in [featureManifestProvider],
/// VISUALLY GROUPED so dependent features sit indented under the parent
/// they require (#1440). Each group is a [Card] containing the parent
/// row at full width followed by indented dependent rows separated by a
/// subtle divider.
///
/// Cascading-disable model (#1447): disabling a parent always succeeds.
/// Children stay in the stored set so re-enabling the parent restores the
/// user's previous setup, but they render as disabled-with-tooltip while
/// any ancestor is off — the tooltip names the missing prerequisite via
/// `featureBlockedEnable_<feature.name>`. A single tap on a blocked row
/// also surfaces the same message via [SnackBar] (#1440).
///
/// Enabling a child still requires its parent to be on; that path
/// surfaces the same blocked-enable tooltip when the user taps a disabled
/// child whose stored value is `false`.
class FeatureManagementSection extends ConsumerWidget {
  const FeatureManagementSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final manifest = ref.watch(featureManifestProvider);
    final enabled = ref.watch(enabledFeaturesProvider);

    // #1675 — a feature not available in the current build channel
    // (e.g. a beta-only feature in a production build) never renders in
    // the feature-management list.
    final channel = ref.watch(buildChannelProvider);
    bool availableInChannel(Feature f) =>
        manifest.entries[f]?.isAvailableIn(channel) ?? false;

    // Build groups in manifest declaration order (#1440). A feature with
    // no `requires` (or whose `requires` does not reference an already-
    // seen parent) becomes a new group; otherwise it is appended to the
    // first matching parent's group. Most dependents in the active
    // manifest depend on a single parent, but multi-parent dependents
    // attach to the first parent they reference in declaration order so
    // grouping placement is deterministic.
    final groups = _buildGroups(manifest);

    // #1571 — Conso surface owns its own card with a 3-way segmented
    // control (Off / Fuel / Fuel + Trips). Suppress the underlying
    // flag toggles from the manifest list so the user only sees the
    // mode selector + its Trajets-tier dependents grouped together.
    final consoModeFlags = <Feature>{
      Feature.obd2TripRecording,
      Feature.manualConsumption,
      Feature.showConsumptionTab,
    };
    // Dependents that visually belong inside the Conso card (Trajets
    // tier) — they only become tappable when consoMode == fuelAndTrips
    // because their manifest `requires` chain includes obd2TripRecording.
    final consoDependents = <Feature>[
      Feature.consumptionAnalytics,
      Feature.gamification,
      Feature.hapticEcoCoach,
      Feature.glideCoach,
      Feature.gpsTripPath,
      Feature.autoRecord,
      // #1615 — the OEM-PID exact-fuel-level read only runs inside a
      // trip recording, so it belongs to the Trajets tier just like
      // glideCoach / gpsTripPath.
      Feature.experimentalOemPids,
    ].where(availableInChannel).toList();

    // Filter the regular group rendering: drop the Conso "parent" flags
    // (replaced by the segmented control) AND drop the Conso dependents
    // (re-rendered inside the Conso card). Other groups (TankSync,
    // priceAlerts, …) flow through unchanged.
    final filteredGroups = <_FeatureGroup>[
      for (final group in groups)
        if (!consoModeFlags.contains(group.parent) &&
            availableInChannel(group.parent))
          _FeatureGroup(
            parent: group.parent,
            children: [
              for (final c in group.children)
                if (!consoDependents.contains(c) &&
                    !consoModeFlags.contains(c) &&
                    availableInChannel(c))
                  c,
            ],
          ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Text(
              l?.featureManagementSectionSubtitle ??
                  'Turn individual features on or off. Some features '
                      'depend on others — switches are disabled until '
                      'prerequisites are met.',
              style: theme.textTheme.bodySmall,
            ),
          ),
          // Conso group card (#1571) — sits at the top because every
          // other Conso-tier dependent reads from its current mode.
          _ConsoFeatureCard(
            mode: consoModeFromFlags(enabled),
            dependents: consoDependents,
            manifest: manifest,
            currentlyEnabled: enabled,
          ),
          for (final group in filteredGroups)
            _FeatureGroupCard(
              group: group,
              manifest: manifest,
              currentlyEnabled: enabled,
            ),
        ],
      ),
    );
  }
}

/// Conso group card (#1571). Renders the 3-way [ConsoMode] segmented
/// control at the top followed by the Trajets-tier dependent toggles
/// indented beneath it. The dependents render as [_FeatureToggle]s
/// just like in [_FeatureGroupCard] so the cascading-disable behaviour
/// (#1447) keeps applying — when mode is Off or Fuel, the dependents
/// stay visually disabled with the standard blocked-enable tooltip.
class _ConsoFeatureCard extends ConsumerWidget {
  final ConsoMode mode;
  final List<Feature> dependents;
  final FeatureManifest manifest;
  final Set<Feature> currentlyEnabled;

  const _ConsoFeatureCard({
    required this.mode,
    required this.dependents,
    required this.manifest,
    required this.currentlyEnabled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      key: const Key('featureGroup_conso'),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l?.consoFeatureGroupTitle ?? 'Conso',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l?.consoFeatureGroupDescription ??
                  'Track your consumption — manual fill-ups, or '
                      'automatic OBD2 trip recording.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<ConsoMode>(
              segments: <ButtonSegment<ConsoMode>>[
                ButtonSegment<ConsoMode>(
                  value: ConsoMode.off,
                  label: Text(l?.consoModeOff ?? 'Off'),
                ),
                ButtonSegment<ConsoMode>(
                  value: ConsoMode.fuel,
                  label: Text(l?.consoModeFuel ?? 'Fuel'),
                ),
                ButtonSegment<ConsoMode>(
                  value: ConsoMode.fuelAndTrips,
                  label: Text(l?.consoModeFuelAndTrips ?? 'Fuel + Trips'),
                ),
              ],
              selected: <ConsoMode>{mode},
              showSelectedIcon: false,
              onSelectionChanged: (selected) {
                final next = selected.first;
                if (next == mode) return;
                unawaited(_applyConsoMode(ref, next));
              },
            ),
            const SizedBox(height: 8),
            Text(
              _modeDescription(l, mode),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (dependents.isNotEmpty) ...[
              const SizedBox(height: 8),
              Divider(
                height: 1,
                thickness: 1,
                color: theme.dividerColor.withValues(alpha: 0.4),
              ),
              for (final child in dependents)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: _FeatureToggle(
                    feature: child,
                    isEnabled: currentlyEnabled.contains(child),
                    manifest: manifest,
                    currentlyEnabled: currentlyEnabled,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _modeDescription(AppLocalizations? l, ConsoMode m) {
    switch (m) {
      case ConsoMode.off:
        return l?.consoModeOffDescription ??
            'No Conso tab and no Conso settings section.';
      case ConsoMode.fuel:
        return l?.consoModeFuelDescription ??
            'Manual fill-ups only. Useful without an OBD2 adapter.';
      case ConsoMode.fuelAndTrips:
        return l?.consoModeFuelAndTripsDescription ??
            'Adds automatic OBD2 trip recording. Requires a paired adapter.';
    }
  }

  Future<void> _applyConsoMode(WidgetRef ref, ConsoMode next) async {
    final delta = consoModeFlagDelta(next);
    // #1808 — capture both notifiers before the awaits. The widget's
    // `ref` must not be touched after an `await`: the user can leave
    // this screen mid-apply, which unmounts the element and makes any
    // later `ref.read` throw a disposed-ref StateError.
    final notifier = ref.read(featureFlagsProvider.notifier);
    final profile = ref.read(activeAppProfileProvider.notifier);
    for (final f in delta.toAdd) {
      await notifier.enable(f);
    }
    for (final f in delta.toRemove) {
      await notifier.disable(f);
    }
    await profile.reconcile();
  }
}

/// A parent feature plus the dependents that should render indented
/// beneath it (#1440). The parent itself is always the first row in the
/// rendered Card; [children] is empty for stand-alone parents.
class _FeatureGroup {
  final Feature parent;
  final List<Feature> children;

  const _FeatureGroup({required this.parent, required this.children});
}

/// Walks [manifest] in declaration order and produces a list of groups
/// in the same order. A feature with empty `requires` ALWAYS opens a
/// new group; a feature with `requires` is appended to the first parent
/// it references — falling back to a stand-alone group when none of its
/// prerequisites are themselves declared in [manifest] (defensive: this
/// should never happen in practice but the function stays total).
List<_FeatureGroup> _buildGroups(FeatureManifest manifest) {
  final groups = <_FeatureGroup>[];
  // Index of the group whose parent is `Feature`, for O(1) child append.
  final parentIndex = <Feature, int>{};

  for (final feature in manifest.entries.keys) {
    final entry = manifest.entries[feature]!;
    if (entry.requires.isEmpty) {
      parentIndex[feature] = groups.length;
      groups.add(_FeatureGroup(parent: feature, children: <Feature>[]));
      continue;
    }
    // Pick the first prerequisite that is itself a parent we have
    // already seen — keeps ordering stable and predictable.
    int? targetIndex;
    for (final required in entry.requires) {
      final idx = parentIndex[required];
      if (idx != null) {
        targetIndex = idx;
        break;
      }
    }
    if (targetIndex == null) {
      // Defensive: dependent whose prerequisite is missing from the
      // manifest — render as its own group so the user still sees the
      // toggle.
      parentIndex[feature] = groups.length;
      groups.add(_FeatureGroup(parent: feature, children: <Feature>[]));
    } else {
      groups[targetIndex].children.add(feature);
    }
  }
  return groups;
}

/// Renders one [_FeatureGroup] as a [Card] containing the parent toggle
/// at full width followed by any dependent rows indented beneath it
/// (#1440). When the group has no children the card collapses to just
/// the parent row — no divider, no indent.
class _FeatureGroupCard extends StatelessWidget {
  final _FeatureGroup group;
  final FeatureManifest manifest;
  final Set<Feature> currentlyEnabled;

  const _FeatureGroupCard({
    required this.group,
    required this.manifest,
    required this.currentlyEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasChildren = group.children.isNotEmpty;
    return Card(
      key: Key('featureGroup_${group.parent.name}'),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FeatureToggle(
              feature: group.parent,
              isEnabled: currentlyEnabled.contains(group.parent),
              manifest: manifest,
              currentlyEnabled: currentlyEnabled,
            ),
            if (hasChildren)
              Divider(
                height: 1,
                thickness: 1,
                color: theme.dividerColor.withValues(alpha: 0.4),
              ),
            for (final child in group.children)
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: _FeatureToggle(
                  feature: child,
                  isEnabled: currentlyEnabled.contains(child),
                  manifest: manifest,
                  currentlyEnabled: currentlyEnabled,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One row in [FeatureManagementSection]. Extracted so the per-feature
/// `Tooltip` + `SwitchListTile` block stays readable.
class _FeatureToggle extends ConsumerWidget {
  final Feature feature;
  final bool isEnabled;
  final FeatureManifest manifest;
  final Set<Feature> currentlyEnabled;

  const _FeatureToggle({
    required this.feature,
    required this.isEnabled,
    required this.manifest,
    required this.currentlyEnabled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final title = _featureLabel(l, feature);
    final subtitle = _featureDescription(l, feature);

    // Pre-check the next transition. The row is disabled with a tooltip
    // when:
    //   * the feature is OFF and its prerequisites are missing — tapping
    //     would call `enable(feature)` which throws, OR
    //   * any ancestor on the `requires` chain is OFF (cascading-disable
    //     #1447) — the row is effectively-disabled even when the stored
    //     value is `true`. We let the child stay "switch-on visually" so
    //     the user can see what their preference WAS, but the toggle is
    //     non-interactive until they re-enable the parent.
    String? blockedReason;
    if (!isEffectivelyEnabled(feature, manifest, currentlyEnabled) &&
        !canEnable(feature, manifest, currentlyEnabled)) {
      blockedReason = _blockedEnableMessage(l, feature);
    }

    final tile = SwitchListTile(
      key: Key('featureToggle_${feature.name}'),
      value: isEnabled,
      title: Text(title),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
      contentPadding: EdgeInsets.zero,
      onChanged: blockedReason != null
          ? null
          : (next) {
              final notifier = ref.read(featureFlagsProvider.notifier);
              // The pre-check above guarantees the call won't throw; the
              // future only completes the Hive write. Fire-and-forget is
              // acceptable for a settings toggle — Riverpod surfaces the
              // new state synchronously.
              unawaited(_toggleAndReconcile(ref, notifier, feature, next));
            },
    );

    if (blockedReason == null) {
      return tile;
    }
    // The switch's onChanged is null (disabled) so taps would be
    // swallowed silently. Wrap the row in a GestureDetector that
    // surfaces the blocker via SnackBar (#1440) — long-press still
    // shows the existing Tooltip.
    final reason = blockedReason;
    return Tooltip(
      message: reason,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          final messenger = ScaffoldMessenger.maybeOf(context);
          if (messenger == null) return;
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBarHelper.infoSnackBar(reason));
        },
        child: tile,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Localised-string lookup helpers.
//
// `AppLocalizations` exposes one getter per key, so a per-feature switch
// is the simplest mapping that stays static-analysis-friendly (compile-
// time exhaustiveness over `Feature`). When the localisation lookup is
// null (test fixtures that omit `AppLocalizations`) the fallback reads the
// English string straight off `FeatureManifest.defaultManifest` — the
// single source of truth — instead of re-typing the same literal here
// (#2189). The two features whose manifest text intentionally differs from
// the toggle text keep a local literal, flagged inline below.
// ---------------------------------------------------------------------------

String _featureLabel(AppLocalizations? l, Feature f) {
  final m = FeatureManifest.defaultManifest.entryFor(f);
  switch (f) {
    case Feature.obd2TripRecording:
      return l?.featureLabel_obd2TripRecording ?? m.displayName;
    case Feature.gamification:
      return l?.featureLabel_gamification ?? m.displayName;
    case Feature.hapticEcoCoach:
      return l?.featureLabel_hapticEcoCoach ?? m.displayName;
    case Feature.tankSync:
      return l?.featureLabel_tankSync ?? m.displayName;
    case Feature.consumptionAnalytics:
      return l?.featureLabel_consumptionAnalytics ?? m.displayName;
    case Feature.baselineSync:
      return l?.featureLabel_baselineSync ?? m.displayName;
    case Feature.priceAlerts:
      return l?.featureLabel_priceAlerts ?? m.displayName;
    case Feature.priceHistory:
      return l?.featureLabel_priceHistory ?? m.displayName;
    case Feature.routePlanning:
      return l?.featureLabel_routePlanning ?? m.displayName;
    case Feature.evCharging:
      return l?.featureLabel_evCharging ?? m.displayName;
    case Feature.glideCoach:
      return l?.featureLabel_glideCoach ?? m.displayName;
    case Feature.gpsTripPath:
      return l?.featureLabel_gpsTripPath ?? m.displayName;
    case Feature.autoRecord:
      return l?.featureLabel_autoRecord ?? m.displayName;
    case Feature.showFuel:
      return l?.featureLabel_showFuel ?? m.displayName;
    case Feature.showElectric:
      return l?.featureLabel_showElectric ?? m.displayName;
    case Feature.showConsumptionTab:
      return l?.featureLabel_showConsumptionTab ?? m.displayName;
    case Feature.manualConsumption:
      // #1517: ARB strings to follow in a localisation pass; English-only
      // fallback from the manifest SSoT (#2189) so the toggle is readable.
      return m.displayName;
    case Feature.loyaltyCards:
      // #1517: ARB strings to follow in a localisation pass; English-only
      // fallback from the manifest SSoT (#2189) so the toggle is readable.
      return m.displayName;
    case Feature.tflitePricePrediction:
      return l?.featureLabel_tflitePricePrediction ?? m.displayName;
    case Feature.fuelCalculator:
      return l?.featureLabel_fuelCalculator ?? m.displayName;
    case Feature.carbonDashboard:
      return l?.featureLabel_carbonDashboard ?? m.displayName;
    case Feature.experimentalOemPids:
      return l?.featureLabel_experimentalOemPids ?? m.displayName;
    case Feature.paymentQrScan:
      return l?.featureLabel_paymentQrScan ?? m.displayName;
    case Feature.communityPriceReports:
      return l?.featureLabel_communityPriceReports ?? m.displayName;
    case Feature.obd2Optional:
      return l?.featureLabel_obd2Optional ?? m.displayName;
    case Feature.addFillUpOcrReceipt:
      return l?.featureLabel_addFillUpOcrReceipt ?? m.displayName;
    case Feature.addFillUpOcrPump:
      return l?.featureLabel_addFillUpOcrPump ?? m.displayName;
    case Feature.developerPatToken:
      return l?.featureLabel_developerPatToken ?? m.displayName;
    case Feature.debugMode:
      return l?.featureLabel_debugMode ?? m.displayName;
    case Feature.approachOverlay:
      return l?.featureLabel_approachOverlay ?? m.displayName;
    case Feature.voiceAnnouncements:
      return l?.featureLabel_voiceAnnouncements ?? m.displayName;
  }
}

String _featureDescription(AppLocalizations? l, Feature f) {
  final m = FeatureManifest.defaultManifest.entryFor(f);
  switch (f) {
    case Feature.obd2TripRecording:
      return l?.featureDescription_obd2TripRecording ?? m.description;
    case Feature.gamification:
      return l?.featureDescription_gamification ?? m.description;
    case Feature.hapticEcoCoach:
      return l?.featureDescription_hapticEcoCoach ?? m.description;
    case Feature.tankSync:
      return l?.featureDescription_tankSync ?? m.description;
    case Feature.consumptionAnalytics:
      return l?.featureDescription_consumptionAnalytics ?? m.description;
    case Feature.baselineSync:
      return l?.featureDescription_baselineSync ?? m.description;
    case Feature.priceAlerts:
      return l?.featureDescription_priceAlerts ?? m.description;
    case Feature.priceHistory:
      return l?.featureDescription_priceHistory ?? m.description;
    case Feature.routePlanning:
      return l?.featureDescription_routePlanning ?? m.description;
    case Feature.evCharging:
      return l?.featureDescription_evCharging ?? m.description;
    case Feature.glideCoach:
      return l?.featureDescription_glideCoach ?? m.description;
    case Feature.gpsTripPath:
      return l?.featureDescription_gpsTripPath ?? m.description;
    case Feature.autoRecord:
      return l?.featureDescription_autoRecord ?? m.description;
    case Feature.showFuel:
      return l?.featureDescription_showFuel ?? m.description;
    case Feature.showElectric:
      return l?.featureDescription_showElectric ?? m.description;
    case Feature.showConsumptionTab:
      return l?.featureDescription_showConsumptionTab ?? m.description;
    case Feature.manualConsumption:
      // #1517: ARB strings to follow in a localisation pass; English-only
      // fallback from the manifest SSoT (#2189).
      return m.description;
    case Feature.loyaltyCards:
      // #1517: ARB strings to follow in a localisation pass; English-only
      // fallback from the manifest SSoT (#2189).
      return m.description;
    case Feature.tflitePricePrediction:
      return l?.featureDescription_tflitePricePrediction ?? m.description;
    case Feature.fuelCalculator:
      return l?.featureDescription_fuelCalculator ?? m.description;
    case Feature.carbonDashboard:
      return l?.featureDescription_carbonDashboard ?? m.description;
    case Feature.experimentalOemPids:
      return l?.featureDescription_experimentalOemPids ?? m.description;
    case Feature.paymentQrScan:
      return l?.featureDescription_paymentQrScan ?? m.description;
    case Feature.communityPriceReports:
      return l?.featureDescription_communityPriceReports ?? m.description;
    case Feature.obd2Optional:
      // note: manifest differs — the manifest description carries an extra
      // "Calibration drops to confidence tier A…" sentence the toggle
      // subtitle intentionally omits, so keep the local literal here to
      // preserve the existing user-facing text (#2189).
      return l?.featureDescription_obd2Optional ??
          'When off, the app records GPS-only trajets without needing an '
              'OBD2 adapter. Coaching is reduced — no instant L/100 km, '
              'fewer engine-derived signals.';
    case Feature.addFillUpOcrReceipt:
      return l?.featureDescription_addFillUpOcrReceipt ?? m.description;
    case Feature.addFillUpOcrPump:
      return l?.featureDescription_addFillUpOcrPump ?? m.description;
    case Feature.developerPatToken:
      // note: manifest differs — this subtitle adds a "Power-user /
      // contributor feature." sentence absent from the manifest
      // description, so keep the local literal to preserve the existing
      // user-facing text (#2189).
      return l?.featureDescription_developerPatToken ??
          'Enable the bad-scan feedback panel that auto-files GitHub '
              'issues with a Personal Access Token. Power-user / '
              'contributor feature.';
    case Feature.debugMode:
      return l?.featureDescription_debugMode ?? m.description;
    case Feature.approachOverlay:
      return l?.featureDescription_approachOverlay ?? m.description;
    case Feature.voiceAnnouncements:
      return l?.featureDescription_voiceAnnouncements ?? m.description;
  }
}

String _blockedEnableMessage(AppLocalizations? l, Feature f) {
  switch (f) {
    case Feature.gamification:
      return l?.featureBlockedEnable_gamification ??
          'Enable OBD2 trip recording first';
    case Feature.hapticEcoCoach:
      return l?.featureBlockedEnable_hapticEcoCoach ??
          'Enable OBD2 trip recording first';
    case Feature.consumptionAnalytics:
      return l?.featureBlockedEnable_consumptionAnalytics ??
          'Enable OBD2 trip recording first';
    case Feature.baselineSync:
      return l?.featureBlockedEnable_baselineSync ??
          'Enable TankSync first';
    case Feature.glideCoach:
      return l?.featureBlockedEnable_glideCoach ??
          'Enable OBD2 trip recording first';
    case Feature.gpsTripPath:
      return l?.featureBlockedEnable_gpsTripPath ??
          'Enable OBD2 trip recording first';
    case Feature.autoRecord:
      return l?.featureBlockedEnable_autoRecord ??
          'Enable OBD2 trip recording first';
    case Feature.showConsumptionTab:
      return l?.featureBlockedEnable_showConsumptionTab ??
          'Enable OBD2 trip recording first';
    case Feature.experimentalOemPids:
      return l?.featureBlockedEnable_experimentalOemPids ??
          'Enable OBD2 trip recording first';
    case Feature.tflitePricePrediction:
      return l?.featureBlockedEnable_tflitePricePrediction ??
          'Enable price history first';
    case Feature.voiceAnnouncements:
      return l?.featureBlockedEnable_voiceAnnouncements ??
          'Enable the approach overlay first';
    // Features without prerequisites can never reach this branch — the
    // dependency-graph helpers short-circuit. Return a generic fallback
    // so the function is total in case the manifest changes.
    case Feature.obd2TripRecording:
    case Feature.tankSync:
    case Feature.priceAlerts:
    case Feature.priceHistory:
    case Feature.routePlanning:
    case Feature.evCharging:
    case Feature.showFuel:
    case Feature.showElectric:
    case Feature.manualConsumption:
    case Feature.loyaltyCards:
    case Feature.fuelCalculator:
    case Feature.carbonDashboard:
    case Feature.paymentQrScan:
    case Feature.communityPriceReports:
    case Feature.obd2Optional:
    case Feature.addFillUpOcrReceipt:
    case Feature.addFillUpOcrPump:
    case Feature.developerPatToken:
    case Feature.debugMode:
    case Feature.approachOverlay:
      return 'Prerequisites not met';
  }
}

/// Toggles [feature] then asks [activeAppProfileProvider] to reconcile
/// the active profile against the new flag set (#1517 / #1519).
///
/// When the user toggles a flag manually here and the new set no
/// longer matches the active preset, the active profile flips to
/// [AppProfile.custom] and the Use-mode section above re-renders to
/// show the Custom card. Re-selecting a preset later overwrites the
/// flag set back to the canonical bundle.
Future<void> _toggleAndReconcile(
  WidgetRef ref,
  FeatureFlags notifier,
  Feature feature,
  bool next,
) async {
  // #1808 — capture the profile notifier before the await. The widget
  // `ref` is unsafe to use once the user has left the screen mid-apply.
  final profile = ref.read(activeAppProfileProvider.notifier);
  if (next) {
    await notifier.enable(feature);
  } else {
    await notifier.disable(feature);
  }
  await profile.reconcile();
}
