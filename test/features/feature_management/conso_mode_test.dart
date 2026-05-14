import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/feature_management/domain/conso_mode.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';

void main() {
  group('consoModeFromFlags', () {
    test('empty flag set → off', () {
      expect(consoModeFromFlags(<Feature>{}), ConsoMode.off);
    });

    test('showConsumptionTab missing → off, even if other Conso flags on', () {
      expect(
        consoModeFromFlags(<Feature>{
          Feature.manualConsumption,
          Feature.obd2TripRecording,
        }),
        ConsoMode.off,
      );
    });

    test('showConsumptionTab + manualConsumption only → fuel', () {
      expect(
        consoModeFromFlags(<Feature>{
          Feature.showConsumptionTab,
          Feature.manualConsumption,
        }),
        ConsoMode.fuel,
      );
    });

    test('showConsumptionTab + obd2TripRecording (no manual) → fuelAndTrips', () {
      // obd2 implies fuel-and-trips even if manualConsumption is
      // missing — the Trajets-tier covers manual entry as a strict
      // superset.
      expect(
        consoModeFromFlags(<Feature>{
          Feature.showConsumptionTab,
          Feature.obd2TripRecording,
        }),
        ConsoMode.fuelAndTrips,
      );
    });

    test('showConsumptionTab + manual + obd2 → fuelAndTrips', () {
      expect(
        consoModeFromFlags(<Feature>{
          Feature.showConsumptionTab,
          Feature.manualConsumption,
          Feature.obd2TripRecording,
        }),
        ConsoMode.fuelAndTrips,
      );
    });

    test('showConsumptionTab alone → off (no data source)', () {
      expect(
        consoModeFromFlags(<Feature>{Feature.showConsumptionTab}),
        ConsoMode.off,
      );
    });
  });

  group('consoModeFlagDelta', () {
    test('off removes the three Conso surface flags, adds none', () {
      final delta = consoModeFlagDelta(ConsoMode.off);
      expect(delta.toAdd, isEmpty);
      expect(delta.toRemove, {
        Feature.showConsumptionTab,
        Feature.manualConsumption,
        Feature.obd2TripRecording,
      });
    });

    test('fuel adds showConsumptionTab + manualConsumption, removes obd2', () {
      final delta = consoModeFlagDelta(ConsoMode.fuel);
      expect(delta.toAdd, {
        Feature.showConsumptionTab,
        Feature.manualConsumption,
      });
      expect(delta.toRemove, {Feature.obd2TripRecording});
    });

    test('fuelAndTrips adds all three, removes none', () {
      final delta = consoModeFlagDelta(ConsoMode.fuelAndTrips);
      expect(delta.toAdd, {
        Feature.showConsumptionTab,
        Feature.manualConsumption,
        Feature.obd2TripRecording,
      });
      expect(delta.toRemove, isEmpty);
    });

    test('round-trip: applying a delta yields the expected ConsoMode', () {
      // Starting from "off" (empty), applying each mode's delta should
      // land on a flag set whose `consoModeFromFlags` returns that
      // exact mode. Locks in the contract between the two helpers.
      for (final mode in ConsoMode.values) {
        final delta = consoModeFlagDelta(mode);
        final result = <Feature>{...delta.toAdd}..removeAll(delta.toRemove);
        expect(consoModeFromFlags(result), mode,
            reason: 'applying delta for $mode should yield $mode back');
      }
    });
  });
}
