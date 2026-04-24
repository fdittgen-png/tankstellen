import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/vehicle/domain/fuzzy_classifier.dart';

void main() {
  const classifier = FuzzyClassifier();

  // Convenience: baseline neutral sample. Individual tests override
  // just the fields they care about.
  Map<Situation, double> classify({
    double speed = 0,
    double accel = 0,
    double grade = 0,
    double throttle = 10,
    double rpm = 800,
    bool stopAndGo = false,
  }) =>
      classifier.classify(
        speedKmh: speed,
        accel: accel,
        grade: grade,
        throttlePct: throttle,
        rpm: rpm,
        isStopAndGoContext: stopAndGo,
      );

  double sumOf(Map<Situation, double> m) =>
      m.values.fold<double>(0, (acc, v) => acc + v);

  group('FuzzyClassifier membership', () {
    test('speed=0 → idle ≈ 1.0 (normalised)', () {
      final m = classify();
      // At 0 km/h idle is the only non-zero bucket → normalised 1.0.
      expect(m[Situation.idle]!, closeTo(1.0, 1e-3));
      expect(m[Situation.urban]!, closeTo(0.0, 1e-3));
      expect(m[Situation.highway]!, closeTo(0.0, 1e-3));
    });

    test('speed=25 plateau → urban wins', () {
      // 25 km/h is inside the urban plateau (25-45) and just at the
      // idle shoulder tail (>5 → 0). Highway ramp starts at 70.
      final m = classify(speed: 25);
      expect(m[Situation.urban]!, closeTo(1.0, 1e-3));
      expect(m[Situation.idle]!, closeTo(0.0, 1e-3));
    });

    test('speed=120 plateau → highway wins', () {
      final m = classify(speed: 120);
      expect(m[Situation.highway]!, closeTo(1.0, 1e-3));
      expect(m[Situation.urban]!, closeTo(0.0, 1e-3));
    });

    test('speed=60 → urban shoulder exactly meets highway zero', () {
      // Urban shoulder ends at 60 (trapezoid 5-25-45-60) so
      // membership is 0 there; highway ramp starts at 70 so it's
      // also 0. No other memberships fire → fallback to urban 1.0.
      final m = classify(speed: 60);
      expect(m[Situation.urban]!, closeTo(1.0, 1e-3));
    });

    test('speed=80 → partial urban-to-highway blend', () {
      // Urban trapezoid closed at 60 → 0 at 80.
      // Highway trapezoid ramp 70-90 → (80-70)/(90-70) = 0.5 at 80.
      // Normalised: highway = 1.0 (only non-zero).
      final m = classify(speed: 80);
      expect(m[Situation.highway]!, closeTo(1.0, 1e-3));
    });

    test('grade=8 with neutral speed still normalises to 1', () {
      // At 0 km/h + 8% grade, both idle (=1) and climbing (=1) fire.
      // Normalised: each gets 0.5.
      final m = classify(grade: 8);
      expect(m[Situation.idle]!, closeTo(0.5, 1e-3));
      expect(m[Situation.climbing]!, closeTo(0.5, 1e-3));
      expect(sumOf(m), closeTo(1.0, 1e-6));
    });

    test('grade=4 → climbing membership 0.5 (before normalisation)', () {
      // Climb ramp 0-8%. At 4 % raw membership is 4/8 = 0.5.
      // At neutral speed=0 idle=1 also fires, so normalised:
      // climbing = 0.5 / 1.5 ≈ 0.333, idle ≈ 0.667.
      final m = classify(grade: 4);
      expect(m[Situation.climbing]!, closeTo(1 / 3, 1e-3));
      expect(m[Situation.idle]!, closeTo(2 / 3, 1e-3));
    });

    test('stop-and-go flag mixes urban bucket into stopAndGo', () {
      // At 20 km/h urban = (20-5)/(25-5) = 0.75, stopAndGo = 0.75.
      // After L1 normalise: each = 0.5.
      final m = classify(speed: 20, stopAndGo: true);
      expect(m[Situation.urban]!, closeTo(0.5, 1e-3));
      expect(m[Situation.stopAndGo]!, closeTo(0.5, 1e-3));
    });

    test('decel fires when accel<-0.5 and throttle<5', () {
      // At 30 km/h urban = 1.0 raw; decel = 1.0 raw; others 0 →
      // each normalised to 0.5.
      final m = classify(speed: 30, accel: -1.0, throttle: 0);
      expect(m[Situation.decel]!, closeTo(0.5, 1e-3));
      expect(m[Situation.urban]!, closeTo(0.5, 1e-3));
    });

    test('fuel-cut overrides decel even when both conditions apply', () {
      // accel<-0.5, throttle<5 would fire decel.
      // BUT speed>20 && rpm>1500 && throttle<5 fires fuelCut too.
      // Per spec, fuelCut zeroes decel.
      final m = classify(
        speed: 60, // urban shoulder = 0, highway = 0 (fallback to urban)
        accel: -1.5,
        throttle: 0,
        rpm: 2000,
      );
      expect(m[Situation.fuelCut]!, greaterThan(0));
      expect(m[Situation.decel]!, 0);
    });

    test('fuel-cut does not fire below threshold', () {
      // RPM 1000 is below fuel-cut threshold (1500).
      final m = classify(speed: 60, throttle: 0, rpm: 1000);
      expect(m[Situation.fuelCut]!, 0);
    });

    test('normalises to 1.0 for every sensible combination', () {
      // Sweep a grid of inputs and assert normalisation holds.
      for (var speed = 0.0; speed <= 200; speed += 10) {
        for (var grade = 0.0; grade <= 10; grade += 2) {
          for (final throttle in [0.0, 10.0, 40.0, 80.0]) {
            for (final accel in [-2.0, 0.0, 1.5]) {
              for (final rpm in [800.0, 2200.0]) {
                final m = classifier.classify(
                  speedKmh: speed,
                  accel: accel,
                  grade: grade,
                  throttlePct: throttle,
                  rpm: rpm,
                );
                expect(sumOf(m), closeTo(1.0, 1e-6),
                    reason:
                        'sum≠1 for speed=$speed grade=$grade throttle=$throttle accel=$accel rpm=$rpm');
                for (final v in m.values) {
                  expect(v, inInclusiveRange(0, 1));
                }
              }
            }
          }
        }
      }
    });

    test('no-match cruising falls back to urban', () {
      // 65 km/h is on neither urban (closed at 60) nor highway (starts
      // at 70) ramps. Classifier should default to urban = 1.0.
      final m = classify(speed: 65);
      expect(m[Situation.urban]!, closeTo(1.0, 1e-3));
      expect(sumOf(m), closeTo(1.0, 1e-6));
    });

    test('returns entries for all seven situations', () {
      final m = classify(speed: 30);
      expect(m.length, Situation.values.length);
      for (final s in Situation.values) {
        expect(m.containsKey(s), isTrue, reason: 'missing $s');
      }
    });
  });
}
