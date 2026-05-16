import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/feature_management/domain/build_channel.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/feature_management/domain/feature_manifest.dart';

/// Pins the `Feature.carbonDashboard` gate (epic #1613, child #1637).
///
/// The Carbon dashboard already shipped live and reachable; this flag
/// brings it under central feature management so it can be toggled per
/// profile. It gates the Consumption-tab AppBar eco action and the
/// `/carbon` route. Default-on preserves current behaviour.
void main() {
  const manifest = FeatureManifest.defaultManifest;

  group('Feature.carbonDashboard manifest entry', () {
    test('the default manifest declares an entry for carbonDashboard', () {
      final entry = manifest.entries[Feature.carbonDashboard];
      expect(entry, isNotNull);
      expect(entry!.feature, Feature.carbonDashboard);
    });

    test('is default-enabled — preserves the dashboard being reachable', () {
      expect(
        manifest.entries[Feature.carbonDashboard]!
            .defaultEnabledIn(BuildChannel.production),
        isTrue,
      );
      expect(
        manifest.defaultEnabledSet(),
        contains(Feature.carbonDashboard),
      );
    });

    test('has no prerequisites — it depends on nothing', () {
      expect(manifest.entries[Feature.carbonDashboard]!.requires, isEmpty);
    });
  });
}
