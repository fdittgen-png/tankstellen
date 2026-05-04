import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/domain/fill_up_variance.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

/// Pure-dart unit tests for the OBD2 fill-up reconciliation helpers
/// (#1401 phase 7b). The variance prompt and verified-by-adapter
/// badge both rely on these predicates — keeping the rules in pure
/// dart means CI can fail fast on logic regressions without pumping
/// a widget tree.
void main() {
  FillUp build({double? before, double? after}) => FillUp(
        id: 'fv_test',
        date: DateTime(2026, 5, 1),
        liters: 40,
        totalCost: 70,
        odometerKm: 10000,
        fuelType: FuelType.e10,
        fuelLevelBeforeL: before,
        fuelLevelAfterL: after,
      );

  group('FillUpVariance.hasAdapterCapture', () {
    test('false when both fields null', () {
      expect(FillUpVariance.hasAdapterCapture(build()), isFalse);
    });

    test('false when only before is set', () {
      expect(
        FillUpVariance.hasAdapterCapture(build(before: 5)),
        isFalse,
      );
    });

    test('false when only after is set', () {
      expect(
        FillUpVariance.hasAdapterCapture(build(after: 50)),
        isFalse,
      );
    });

    test('true when both fields are set', () {
      expect(
        FillUpVariance.hasAdapterCapture(build(before: 5, after: 50)),
        isTrue,
      );
    });
  });

  group('FillUpVariance.adapterDeltaL', () {
    test('returns null when either capture is missing', () {
      expect(FillUpVariance.adapterDeltaL(build()), isNull);
      expect(FillUpVariance.adapterDeltaL(build(before: 5)), isNull);
      expect(FillUpVariance.adapterDeltaL(build(after: 50)), isNull);
    });

    test('returns after minus before (litres pumped)', () {
      // Tank went from 5 L to 50 L → 45 L pumped.
      expect(
        FillUpVariance.adapterDeltaL(build(before: 5, after: 50)),
        45.0,
      );
    });

    test('does NOT clamp negative deltas — caller must guard', () {
      // Sensor noise can produce after < before. The helper is
      // deliberately raw so the dialog can show the user what the
      // adapter actually said.
      expect(
        FillUpVariance.adapterDeltaL(build(before: 50, after: 45)),
        -5.0,
      );
    });
  });

  group('FillUpVariance.isVarianceAbove5Percent', () {
    test('false when adapter delta is exactly the user value', () {
      expect(
        FillUpVariance.isVarianceAbove5Percent(40.0, 40.0),
        isFalse,
      );
    });

    test('false at exactly 5 % delta — strict greater-than', () {
      // 40 ± 2 L = 5 % exactly → still acceptable, no prompt.
      expect(
        FillUpVariance.isVarianceAbove5Percent(42.0, 40.0),
        isFalse,
      );
      expect(
        FillUpVariance.isVarianceAbove5Percent(38.0, 40.0),
        isFalse,
      );
    });

    test('true just above 5 % delta', () {
      // 40 ± 2.001 L → fires the prompt.
      expect(
        FillUpVariance.isVarianceAbove5Percent(42.001, 40.0),
        isTrue,
      );
      expect(
        FillUpVariance.isVarianceAbove5Percent(37.999, 40.0),
        isTrue,
      );
    });

    test('true on a large delta (e.g. wrong-pump scenario)', () {
      // User typed 60 L into the form but adapter only sees 40 L
      // pumped — way past 5 %.
      expect(
        FillUpVariance.isVarianceAbove5Percent(60.0, 40.0),
        isTrue,
      );
    });

    test('false when adapter delta is non-positive (no baseline)', () {
      // Avoid division-by-zero / negative-baseline weirdness — the
      // dialog isn't useful when the adapter saw no fill or a dip.
      expect(
        FillUpVariance.isVarianceAbove5Percent(40.0, 0.0),
        isFalse,
      );
      expect(
        FillUpVariance.isVarianceAbove5Percent(40.0, -3.0),
        isFalse,
      );
    });
  });
}
