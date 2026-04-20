import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/cold_start_baselines.dart';
import 'package:tankstellen/features/consumption/domain/situation_classifier.dart';

void main() {
  group('coldStartBaseline (#768)', () {
    test('idle uses L/h units, not L/100 km — avoids divide-by-zero',
        () {
      final b = coldStartBaseline(
        ConsumptionFuelFamily.gasoline,
        DrivingSituation.idle,
      );
      expect(b.unit, BaselineUnit.lPerHour);
      expect(b.value, 0.8);
    });

    test('diesel consistently lower than gasoline for every situation',
        () {
      const drivingSituations = [
        DrivingSituation.idle,
        DrivingSituation.stopAndGo,
        DrivingSituation.urbanCruise,
        DrivingSituation.highwayCruise,
        DrivingSituation.deceleration,
        DrivingSituation.climbingOrLoaded,
      ];
      for (final s in drivingSituations) {
        final petrol =
            coldStartBaseline(ConsumptionFuelFamily.gasoline, s);
        final diesel =
            coldStartBaseline(ConsumptionFuelFamily.diesel, s);
        expect(diesel.value, lessThan(petrol.value),
            reason: '$s: diesel ${diesel.value} !< petrol ${petrol.value}');
        expect(diesel.unit, petrol.unit);
      }
    });

    test('transients return a zero placeholder — no meaningful baseline',
        () {
      expect(
        coldStartBaseline(
          ConsumptionFuelFamily.gasoline,
          DrivingSituation.hardAccel,
        ).value,
        0,
      );
      expect(
        coldStartBaseline(
          ConsumptionFuelFamily.gasoline,
          DrivingSituation.fuelCutCoast,
        ).value,
        0,
      );
    });
  });

  group('classifyBand (#768)', () {
    const baseline = SituationBaseline(8.0, BaselineUnit.lPer100Km);

    test('eco: live ≤ 0.80 × baseline', () {
      expect(
        classifyBand(
          situation: DrivingSituation.urbanCruise,
          live: 6.4,
          baseline: baseline,
        ),
        ConsumptionBand.eco,
      );
    });

    test('normal: between 0.80 and 1.20 × baseline', () {
      expect(
        classifyBand(
          situation: DrivingSituation.urbanCruise,
          live: 8.5,
          baseline: baseline,
        ),
        ConsumptionBand.normal,
      );
    });

    test('heavy: between 1.20 and 1.60 × baseline', () {
      expect(
        classifyBand(
          situation: DrivingSituation.urbanCruise,
          live: 11.0,
          baseline: baseline,
        ),
        ConsumptionBand.heavy,
      );
    });

    test('veryHeavy: ≥ 1.60 × baseline', () {
      expect(
        classifyBand(
          situation: DrivingSituation.urbanCruise,
          live: 14.0,
          baseline: baseline,
        ),
        ConsumptionBand.veryHeavy,
      );
    });

    test('transient: returns the transient band regardless of numbers',
        () {
      expect(
        classifyBand(
          situation: DrivingSituation.hardAccel,
          live: 100.0,
          baseline: baseline,
        ),
        ConsumptionBand.transient,
      );
      expect(
        classifyBand(
          situation: DrivingSituation.fuelCutCoast,
          live: 0.0,
          baseline: baseline,
        ),
        ConsumptionBand.transient,
      );
    });

    test('zero baseline falls back to normal — prevents div-by-zero',
        () {
      const zero = SituationBaseline(0, BaselineUnit.lPer100Km);
      expect(
        classifyBand(
          situation: DrivingSituation.urbanCruise,
          live: 10.0,
          baseline: zero,
        ),
        ConsumptionBand.normal,
      );
    });
  });
}
