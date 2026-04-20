import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/situation_classifier.dart';

void main() {
  final t0 = DateTime(2026, 4, 20, 12, 0, 0);
  DateTime at(int secs) => t0.add(Duration(seconds: secs));

  group('SituationClassifier (#768)', () {
    test('cold start — seeded to idle before any sample', () {
      final c = SituationClassifier();
      expect(c.current, DrivingSituation.idle);
    });

    test('idle: stationary with engine on ≥ 5 s', () {
      final c = SituationClassifier();
      // Feed 6 seconds of zero speed + low throttle + RPM 800.
      for (var s = 0; s < 6; s++) {
        c.onSample(DrivingSample(
          timestamp: at(s),
          speedKmh: 0,
          rpm: 800,
          throttlePercent: 0,
        ));
      }
      expect(c.current, DrivingSituation.idle);
    });

    test('highway cruise: 110 km/h sustained', () {
      final c = SituationClassifier();
      for (var s = 0; s < 12; s++) {
        c.onSample(DrivingSample(
          timestamp: at(s),
          speedKmh: 110,
          rpm: 2200,
          throttlePercent: 20,
        ));
      }
      // Account for 3 s debounce from the initial idle seed.
      expect(c.current, DrivingSituation.highwayCruise);
    });

    test('urban cruise: 35 km/h modest throttle variance', () {
      final c = SituationClassifier();
      for (var s = 0; s < 10; s++) {
        c.onSample(DrivingSample(
          timestamp: at(s),
          speedKmh: 35 + (s % 3),
          rpm: 1800,
          throttlePercent: 15,
        ));
      }
      expect(c.current, DrivingSituation.urbanCruise);
    });

    test('stop-and-go: low avg speed with repeated zero crossings', () {
      final c = SituationClassifier();
      // 10 s sequence: drive 10→0→drive→0→drive, 2 zero-crossings.
      final speeds = [10.0, 15.0, 5.0, 0.0, 8.0, 12.0, 0.0, 10.0, 15.0, 12.0];
      for (var s = 0; s < 10; s++) {
        c.onSample(DrivingSample(
          timestamp: at(s),
          speedKmh: speeds[s],
          rpm: 1200,
          throttlePercent: 10,
        ));
      }
      expect(c.current, DrivingSituation.stopAndGo);
    });

    test('hard accel: sustained >1.5 m/s² with throttle > 50% — '
        'transient event, does not replace the steady-state mode',
        () {
      final c = SituationClassifier();
      // Seed a steady-state cruise.
      for (var s = 0; s < 10; s++) {
        c.onSample(DrivingSample(
          timestamp: at(s),
          speedKmh: 30,
          rpm: 1800,
          throttlePercent: 15,
        ));
      }
      expect(c.current, DrivingSituation.urbanCruise);

      // Now ramp 30 → 60 km/h over 3 s (~2.8 m/s²) with throttle 70%.
      var situation = c.current;
      for (var s = 10; s < 14; s++) {
        situation = c.onSample(DrivingSample(
          timestamp: at(s),
          speedKmh: 30 + (s - 10) * 10.0,
          rpm: 3000,
          throttlePercent: 70,
        ));
      }
      expect(situation, DrivingSituation.hardAccel);
      // Steady-state still cruise (transient doesn't overwrite).
      expect(c.current, DrivingSituation.urbanCruise);
    });

    test('fuel-cut coast: fuelRate ≈ 0 while moving > 20 km/h', () {
      final c = SituationClassifier();
      for (var s = 0; s < 6; s++) {
        c.onSample(DrivingSample(
          timestamp: at(s),
          speedKmh: 80,
          rpm: 2200,
          throttlePercent: 0,
          fuelRateLPerHour: 0,
        ));
      }
      final situation = c.onSample(DrivingSample(
        timestamp: at(6),
        speedKmh: 80,
        rpm: 2200,
        throttlePercent: 0,
        fuelRateLPerHour: 0,
      ));
      expect(situation, DrivingSituation.fuelCutCoast);
    });

    test('transition debounce: a brief mode-change < 3 s does not '
        'commit', () {
      final c = SituationClassifier();
      // Seed urban cruise.
      for (var s = 0; s < 10; s++) {
        c.onSample(DrivingSample(
          timestamp: at(s),
          speedKmh: 35,
          rpm: 1800,
          throttlePercent: 15,
        ));
      }
      expect(c.current, DrivingSituation.urbanCruise);

      // 2 s of highway-speed samples — not enough to flip.
      for (var s = 10; s < 12; s++) {
        c.onSample(DrivingSample(
          timestamp: at(s),
          speedKmh: 95,
          rpm: 2400,
          throttlePercent: 20,
        ));
      }
      expect(c.current, DrivingSituation.urbanCruise,
          reason: '2 s of highway speeds must not commit — debounce is 3 s');

      // Back to urban — debounce clock resets.
      for (var s = 12; s < 14; s++) {
        c.onSample(DrivingSample(
          timestamp: at(s),
          speedKmh: 35,
          rpm: 1800,
          throttlePercent: 15,
        ));
      }
      expect(c.current, DrivingSituation.urbanCruise);
    });

    test('transition debounce: a ≥ 3 s hold DOES commit the new mode',
        () {
      final c = SituationClassifier();
      // Seed urban cruise. Short window so the classifier can start
      // seeing a clean highway signal quickly.
      for (var s = 0; s < 5; s++) {
        c.onSample(DrivingSample(
          timestamp: at(s),
          speedKmh: 35,
          rpm: 1800,
          throttlePercent: 15,
        ));
      }
      expect(c.current, DrivingSituation.urbanCruise);

      // 25 s of highway speeds — plenty of time for the rolling
      // window to fully flush to highway AND for the 3 s debounce
      // to elapse past that point.
      for (var s = 5; s < 30; s++) {
        c.onSample(DrivingSample(
          timestamp: at(s),
          speedKmh: 95,
          rpm: 2400,
          throttlePercent: 20,
        ));
      }
      expect(c.current, DrivingSituation.highwayCruise);
    });
  });
}
