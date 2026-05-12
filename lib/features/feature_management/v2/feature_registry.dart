import 'feature_class.dart';
import 'known_features.dart';

/// Central registry of every [FeatureClass] the app ships.
///
/// Phase 1 (compatibility layer): the entries below mirror the
/// existing `Feature` enum values 1:1 via `known_features.dart`.
/// Phase 2 onward: each new feature lives in its own module file
/// (`lib/features/<area>/feature.dart`) and is appended to this list.
///
/// Adding a feature = one new file + one line here. The Settings
/// screen, profile bundles, and FeatureGate primitives all read from
/// this list, so no other file needs to know about the addition.
const List<FeatureClass> featureRegistry = <FeatureClass>[
  // Top-level (no parent in either presentation or activation)
  kFeatureObd2TripRecording,
  kFeatureTankSync,
  kFeatureUnifiedSearchResults,
  kFeaturePriceAlerts,
  kFeaturePriceHistory,
  kFeatureRoutePlanning,
  kFeatureEvCharging,
  kFeatureShowFuel,
  kFeatureShowElectric,
  kFeatureManualConsumption,
  kFeatureLoyaltyCards,

  // Children of obd2TripRecording
  kFeatureGamification,
  kFeatureHapticEcoCoach,
  kFeatureConsumptionAnalytics,
  kFeatureGlideCoach,
  kFeatureGpsTripPath,
  kFeatureAutoRecord,
  kFeatureShowConsumptionTab,

  // Child of tankSync
  kFeatureBaselineSync,

  // Child of priceHistory
  kFeatureTflitePricePrediction,
];

/// O(1)-after-init lookup of a [FeatureClass] by its [FeatureClass.id].
///
/// Returns `null` for unknown ids — callers should treat that as
/// "feature was deleted in a recent app version" and fall back to
/// "disabled".
FeatureClass? featureById(String id) => _idIndex[id];

final Map<String, FeatureClass> _idIndex = {
  for (final fc in featureRegistry) fc.id: fc,
};

/// Throws [StateError] when the registry contains a cycle reachable
/// via `requires` edges. Acyclic is the activation contract — see
/// `feature_dependency_graph.dart` (v1) for the same invariant on the
/// legacy manifest. Run at app boot once so a bad const literal
/// crashes loudly in dev / CI instead of silently looping in
/// `isEffectivelyEnabled` at runtime.
void assertNoCycles() {
  // White-grey-black DFS; grey set is the in-progress stack.
  final black = <FeatureClass>{};
  final grey = <FeatureClass>{};
  void visit(FeatureClass node) {
    if (black.contains(node)) return;
    if (grey.contains(node)) {
      throw StateError(
        'FeatureRegistry: cycle detected through ${node.id}. '
        'Check the `requires:` edges in known_features.dart / any '
        'feature module file.',
      );
    }
    grey.add(node);
    for (final r in node.requires) {
      visit(r);
    }
    grey.remove(node);
    black.add(node);
  }

  for (final f in featureRegistry) {
    visit(f);
  }
}

/// Throws [StateError] when two registry entries share an `id`.
/// Duplicate ids would silently merge persistence state across two
/// FeatureClass declarations — instant data corruption.
void assertUniqueIds() {
  final seen = <String>{};
  for (final f in featureRegistry) {
    if (!seen.add(f.id)) {
      throw StateError(
        'FeatureRegistry: duplicate id "${f.id}". Every FeatureClass '
        'must declare a unique id — the id is the Hive persistence '
        'key and conflicts silently merge state.',
      );
    }
  }
}
