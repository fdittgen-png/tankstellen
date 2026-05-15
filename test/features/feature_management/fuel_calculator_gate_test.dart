import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/feature_management/domain/feature_manifest.dart';

/// Pins the `Feature.fuelCalculator` gate (epic #1613, child #1636).
///
/// The fuel-cost Calculator screen + `/calculator` route already exist
/// and are tested; this feature flag gates the navigation entry point
/// added to the search-results header that finally makes the route
/// reachable. The manifest contract is what `SearchResultsList` checks.
void main() {
  const manifest = FeatureManifest.defaultManifest;

  group('Feature.fuelCalculator manifest entry', () {
    test('the default manifest declares an entry for fuelCalculator', () {
      final entry = manifest.entries[Feature.fuelCalculator];
      expect(entry, isNotNull);
      expect(entry!.feature, Feature.fuelCalculator);
    });

    test('is default-enabled — the Calculator must be reachable', () {
      expect(
        manifest.entries[Feature.fuelCalculator]!.defaultEnabled,
        isTrue,
      );
      expect(manifest.defaultEnabledSet(), contains(Feature.fuelCalculator));
    });

    test('has no prerequisites — it depends on nothing', () {
      expect(manifest.entries[Feature.fuelCalculator]!.requires, isEmpty);
    });
  });
}
