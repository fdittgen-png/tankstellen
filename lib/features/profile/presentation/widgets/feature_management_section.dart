import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../feature_management/application/feature_flags_provider.dart';
import '../../../feature_management/domain/feature.dart';
import '../../../feature_management/domain/feature_dependency_graph.dart';
import '../../../feature_management/domain/feature_manifest.dart';

/// Settings-screen section that exposes every [Feature] as a toggle
/// (#1373 phase 2).
///
/// Renders one [SwitchListTile] per entry in [featureManifestProvider]. The
/// dependency graph is consulted BEFORE attempting a transition so the
/// provider's `StateError` never reaches the UI:
/// - When a disabled feature's prerequisites are missing the switch is
///   disabled and wrapped in a [Tooltip] naming the missing prerequisite
///   via `featureBlockedEnable_<feature.name>`.
/// - When an enabled feature has dependents that are still on, the switch
///   is disabled and the tooltip lists the dependents using the
///   `featureBlockedDisable_<feature.name>` template.
///
/// Phase 1 of #1373 ships the engine in PARALLEL with the existing
/// scattered toggles — this section therefore does NOT yet replace
/// `autoRecord` / `gamificationEnabled` / etc. Phase 3 will migrate
/// them one PR at a time.
class FeatureManagementSection extends ConsumerWidget {
  const FeatureManagementSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final manifest = ref.watch(featureManifestProvider);
    final enabled = ref.watch(featureFlagsProvider);

    // Iterate in manifest declaration order so the UI matches the order
    // chosen in [FeatureManifest.defaultManifest] (foundation features
    // first, follow-on / future features last).
    final features = manifest.entries.keys.toList(growable: false);

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
          for (final feature in features)
            _FeatureToggle(
              feature: feature,
              isEnabled: enabled.contains(feature),
              manifest: manifest,
              currentlyEnabled: enabled,
            ),
        ],
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

    // Pre-check the next transition. If turning the switch will throw,
    // we render the row disabled and wrap it in a Tooltip naming the
    // blocker so the user understands why.
    String? blockedReason;
    if (isEnabled) {
      // A user tap would call `disable(feature)` — find dependents.
      final dependents = blockingDisable(feature, manifest, currentlyEnabled);
      if (dependents.isNotEmpty) {
        final names = dependents.map((f) => _featureLabel(l, f)).join(', ');
        blockedReason = _blockedDisableMessage(l, feature, names);
      }
    } else {
      // A user tap would call `enable(feature)` — check prerequisites.
      if (!canEnable(feature, manifest, currentlyEnabled)) {
        blockedReason = _blockedEnableMessage(l, feature);
      }
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
              unawaited(next ? notifier.enable(feature) : notifier.disable(feature));
            },
    );

    if (blockedReason == null) {
      return tile;
    }
    return Tooltip(
      message: blockedReason,
      child: tile,
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
      return 'Prerequisites not met';
  }
}

String _blockedDisableMessage(
  AppLocalizations? l,
  Feature f,
  String dependents,
) {
  switch (f) {
    case Feature.obd2TripRecording:
      return l?.featureBlockedDisable_obd2TripRecording(dependents) ??
          'Disable dependent features first: $dependents';
    case Feature.tankSync:
      return l?.featureBlockedDisable_tankSync(dependents) ??
          'Disable dependent features first: $dependents';
    // Features that nothing depends on never reach this branch — the
    // graph helpers short-circuit. Generic fallback for safety.
    case Feature.gamification:
    case Feature.hapticEcoCoach:
    case Feature.consumptionAnalytics:
    case Feature.baselineSync:
    case Feature.unifiedSearchResults:
    case Feature.priceAlerts:
    case Feature.priceHistory:
    case Feature.routePlanning:
    case Feature.evCharging:
    case Feature.glideCoach:
    case Feature.gpsTripPath:
    case Feature.autoRecord:
      return 'Disable dependent features first: $dependents';
  }
}
