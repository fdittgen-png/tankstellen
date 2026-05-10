import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/feature_management/domain/consumption_tab_visibility.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/feature_management/domain/feature_manifest.dart';

/// #1517 / #1520 — Consumption tab earns its slot when
/// `showConsumptionTab` is on AND a data source is on (manualConsumption
/// OR obd2TripRecording). This test pins the OR contract so a manifest
/// edit doesn't silently re-tighten it.
void main() {
  const manifest = FeatureManifest.defaultManifest;

  group('isConsumptionTabReachable', () {
    test('false when showConsumptionTab is missing from the stored set', () {
      // User explicitly hid the tab — never override that.
      expect(
        isConsumptionTabReachable(manifest, {Feature.obd2TripRecording}),
        isFalse,
      );
      expect(
        isConsumptionTabReachable(manifest, {Feature.manualConsumption}),
        isFalse,
      );
    });

    test('false when no data source is on (Basic profile)', () {
      // showConsumptionTab on but neither manual nor obd2 — no surface
      // would render anything.
      expect(
        isConsumptionTabReachable(manifest, {Feature.showConsumptionTab}),
        isFalse,
      );
    });

    test('true when manualConsumption is on (Medium profile)', () {
      expect(
        isConsumptionTabReachable(manifest, {
          Feature.showConsumptionTab,
          Feature.manualConsumption,
        }),
        isTrue,
      );
    });

    test('true when obd2TripRecording is on (Full profile)', () {
      expect(
        isConsumptionTabReachable(manifest, {
          Feature.showConsumptionTab,
          Feature.obd2TripRecording,
        }),
        isTrue,
      );
    });

    test(
      'false when obd2TripRecording is in the stored set but cascading-'
      'disabled (showConsumptionTab via the manifest dep)',
      () {
        // showConsumptionTab requires obd2TripRecording per the
        // manifest. If obd2 is missing from the stored set, the cascade
        // hides showConsumptionTab even when both `obd2TripRecording`
        // and `showConsumptionTab` look like they'd flip the OR true.
        // Here obd2 is OFF so isEffectivelyEnabled(obd2) is false and
        // there's no manualConsumption → reachable is false.
        expect(
          isConsumptionTabReachable(manifest, {Feature.showConsumptionTab}),
          isFalse,
        );
      },
    );

    test('true when both data sources are on (Full + manual override)', () {
      expect(
        isConsumptionTabReachable(manifest, {
          Feature.showConsumptionTab,
          Feature.manualConsumption,
          Feature.obd2TripRecording,
        }),
        isTrue,
      );
    });
  });
}
