import 'feature.dart';
import 'feature_dependency_graph.dart';
import 'feature_manifest.dart';

/// True when the Consumption bottom-nav tab + Settings → Consumption
/// section should be reachable to the user (#1517 / #1520).
///
/// The manifest's `requires` is AND-only, so this OR-extension lives
/// outside the manifest: the Consumption tab earns its place when
/// `Feature.showConsumptionTab` is effectively enabled AND at least
/// one data source is on — either manual fill-up logging
/// ([Feature.manualConsumption], the Medium profile entry-point) or
/// OBD2 trip recording ([Feature.obd2TripRecording], the Full profile
/// entry-point).
///
/// Without this OR check a Medium-tier user who never paired an OBD2
/// adapter would see no Consumption tab even though manualConsumption
/// is on — the manifest dependency on `obd2TripRecording` would gate
/// the tab off via `isEffectivelyEnabled`.
bool isConsumptionTabReachable(
  FeatureManifest manifest,
  Set<Feature> enabled,
) {
  // The user-facing master toggle is `showConsumptionTab`. The current
  // manifest declares it as default-true with `requires:
  // {obd2TripRecording}`. We DON'T walk the dependency chain here —
  // that's exactly what we're loosening — but we DO honour the user's
  // direct preference: if `showConsumptionTab` is missing from the
  // stored set, the user explicitly disabled the surface.
  if (!enabled.contains(Feature.showConsumptionTab)) return false;
  return enabled.contains(Feature.manualConsumption) ||
      isEffectivelyEnabled(Feature.obd2TripRecording, manifest, enabled);
}
