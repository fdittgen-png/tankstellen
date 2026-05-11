import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../feature_management/application/app_profile_provider.dart';
import '../../../feature_management/application/feature_flags_provider.dart';
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
    final enabled = ref.watch(featureFlagsProvider);

    // Build groups in manifest declaration order (#1440). A feature with
    // no `requires` (or whose `requires` does not reference an already-
    // seen parent) becomes a new group; otherwise it is appended to the
    // first matching parent's group. Most dependents in the active
    // manifest depend on a single parent, but multi-parent dependents
    // attach to the first parent they reference in declaration order so
    // grouping placement is deterministic.
    final groups = _buildGroups(manifest);

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
          for (final group in groups)
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
            ..showSnackBar(
              SnackBar(
                content: Text(reason),
                duration: const Duration(seconds: 3),
              ),
            );
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
// is the simplest mapping that stays static-analysis-friendly. Falls back
// to the manifest's English string when the localisation lookup is null
// (test fixtures that omit `AppLocalizations` get a sensible default).
// ---------------------------------------------------------------------------

String _featureLabel(AppLocalizations? l, Feature f) {
  switch (f) {
    case Feature.obd2TripRecording:
      return l?.featureLabel_obd2TripRecording ?? 'OBD2 trip recording';
    case Feature.gamification:
      return l?.featureLabel_gamification ?? 'Gamification';
    case Feature.hapticEcoCoach:
      return l?.featureLabel_hapticEcoCoach ?? 'Haptic eco-coach';
    case Feature.tankSync:
      return l?.featureLabel_tankSync ?? 'TankSync';
    case Feature.consumptionAnalytics:
      return l?.featureLabel_consumptionAnalytics ?? 'Consumption analytics';
    case Feature.baselineSync:
      return l?.featureLabel_baselineSync ?? 'Baseline sync';
    case Feature.unifiedSearchResults:
      return l?.featureLabel_unifiedSearchResults ??
          'Unified search results';
    case Feature.priceAlerts:
      return l?.featureLabel_priceAlerts ?? 'Price alerts';
    case Feature.priceHistory:
      return l?.featureLabel_priceHistory ?? 'Price history';
    case Feature.routePlanning:
      return l?.featureLabel_routePlanning ?? 'Route planning';
    case Feature.evCharging:
      return l?.featureLabel_evCharging ?? 'EV charging';
    case Feature.glideCoach:
      return l?.featureLabel_glideCoach ?? 'Glide-coach';
    case Feature.gpsTripPath:
      return l?.featureLabel_gpsTripPath ?? 'GPS trip path';
    case Feature.autoRecord:
      return l?.featureLabel_autoRecord ?? 'Auto-record';
    case Feature.showFuel:
      return l?.featureLabel_showFuel ?? 'Show fuel stations';
    case Feature.showElectric:
      return l?.featureLabel_showElectric ?? 'Show charging stations';
    case Feature.showConsumptionTab:
      return l?.featureLabel_showConsumptionTab ?? 'Consumption tab';
    case Feature.manualConsumption:
      // #1517: ARB strings to follow in a localisation pass; English-
      // only fallback for now so the toggle is at least readable.
      return 'Manual consumption logging';
    case Feature.loyaltyCards:
      // #1517: ARB strings to follow in a localisation pass; English-
      // only fallback for now so the toggle is at least readable.
      return 'Loyalty cards';
    case Feature.tflitePricePrediction:
      return l?.featureLabel_tflitePricePrediction ??
          'TFLite price prediction';
  }
}

String _featureDescription(AppLocalizations? l, Feature f) {
  switch (f) {
    case Feature.obd2TripRecording:
      return l?.featureDescription_obd2TripRecording ??
          'Capture trips automatically over OBD2.';
    case Feature.gamification:
      return l?.featureDescription_gamification ??
          'Driving scores and earned badges.';
    case Feature.hapticEcoCoach:
      return l?.featureDescription_hapticEcoCoach ??
          'Real-time haptic feedback during a trip.';
    case Feature.tankSync:
      return l?.featureDescription_tankSync ??
          'Cross-device sync via Supabase.';
    case Feature.consumptionAnalytics:
      return l?.featureDescription_consumptionAnalytics ??
          'Fill-up and trip analysis tab.';
    case Feature.baselineSync:
      return l?.featureDescription_baselineSync ??
          'Sync driving baselines via TankSync.';
    case Feature.unifiedSearchResults:
      return l?.featureDescription_unifiedSearchResults ??
          'Single result list combining fuel and EV stations.';
    case Feature.priceAlerts:
      return l?.featureDescription_priceAlerts ??
          'Threshold-based price-drop notifications.';
    case Feature.priceHistory:
      return l?.featureDescription_priceHistory ??
          '30-day price charts on station details.';
    case Feature.routePlanning:
      return l?.featureDescription_routePlanning ??
          'Cheapest stop along your route.';
    case Feature.evCharging:
      return l?.featureDescription_evCharging ??
          'Charging stations via OpenChargeMap.';
    case Feature.glideCoach:
      return l?.featureDescription_glideCoach ??
          'Hypermiling guidance using OSM traffic signals.';
    case Feature.gpsTripPath:
      return l?.featureDescription_gpsTripPath ??
          'Persist GPS path samples alongside each trip.';
    case Feature.autoRecord:
      return l?.featureDescription_autoRecord ??
          'Automatically start a trip when the OBD2 adapter connects to a moving vehicle.';
    case Feature.showFuel:
      return l?.featureDescription_showFuel ??
          'Display petrol/diesel station results in search and on the map.';
    case Feature.showElectric:
      return l?.featureDescription_showElectric ??
          'Display EV charging stations in search and on the map.';
    case Feature.showConsumptionTab:
      return l?.featureDescription_showConsumptionTab ??
          'Show the consumption analytics tab in the bottom navigation.';
    case Feature.manualConsumption:
      // #1517: ARB strings to follow in a localisation pass.
      return 'Track fuel fill-ups and EV charging sessions by hand (no OBD2 adapter required).';
    case Feature.loyaltyCards:
      // #1517: ARB strings to follow in a localisation pass.
      return 'Fuel-club / loyalty program cards with per-litre discounts in price comparisons.';
    case Feature.tflitePricePrediction:
      return l?.featureDescription_tflitePricePrediction ??
          'On-device price forecast model — inference runs locally; '
              'features and predictions never leave the device.';
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
    case Feature.tflitePricePrediction:
      return l?.featureBlockedEnable_tflitePricePrediction ??
          'Enable price history first';
    // Features without prerequisites can never reach this branch — the
    // dependency-graph helpers short-circuit. Return a generic fallback
    // so the function is total in case the manifest changes.
    case Feature.obd2TripRecording:
    case Feature.tankSync:
    case Feature.unifiedSearchResults:
    case Feature.priceAlerts:
    case Feature.priceHistory:
    case Feature.routePlanning:
    case Feature.evCharging:
    case Feature.showFuel:
    case Feature.showElectric:
    case Feature.manualConsumption:
    case Feature.loyaltyCards:
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
  if (next) {
    await notifier.enable(feature);
  } else {
    await notifier.disable(feature);
  }
  final newFlags = ref.read(featureFlagsProvider);
  await ref
      .read(activeAppProfileProvider.notifier)
      .reconcileWithFlags(newFlags);
}
