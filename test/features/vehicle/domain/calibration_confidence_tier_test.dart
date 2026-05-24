import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/vehicle/domain/calibration_confidence_tier.dart';

void main() {
  group('calibrationConfidenceTier (#2027)', () {
    test('A — no fill-up anchor regardless of OBD2 history', () {
      expect(
        calibrationConfidenceTier(
          volumetricEfficiencySamples: 0,
          hasGpsPlusObd2Trip: false,
        ),
        CalibrationConfidenceTier.a,
      );
      expect(
        calibrationConfidenceTier(
          volumetricEfficiencySamples: 0,
          hasGpsPlusObd2Trip: true,
        ),
        CalibrationConfidenceTier.a,
      );
    });

    test('B — fill-up anchor present but no OBD2 trip yet', () {
      expect(
        calibrationConfidenceTier(
          volumetricEfficiencySamples: 3,
          hasGpsPlusObd2Trip: false,
        ),
        CalibrationConfidenceTier.b,
      );
    });

    test('C — fill-up anchor + at least one OBD2 trip', () {
      expect(
        calibrationConfidenceTier(
          volumetricEfficiencySamples: 5,
          hasGpsPlusObd2Trip: true,
        ),
        CalibrationConfidenceTier.c,
      );
    });

    test('label is a single uppercase letter per tier', () {
      expect(CalibrationConfidenceTier.a.label, 'A');
      expect(CalibrationConfidenceTier.b.label, 'B');
      expect(CalibrationConfidenceTier.c.label, 'C');
    });
  });
}
