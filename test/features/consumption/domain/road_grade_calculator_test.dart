import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/road_grade_calculator.dart';

/// Unit tests for [RoadGradeCalculator] (#1941, epic #1935 child B).
void main() {
  group('RoadGradeCalculator (#1941)', () {
    test('a flat road yields grade ~0 and is confident once the window '
        'fills', () {
      final calc = RoadGradeCalculator();
      // 30 samples, 20 m apart, constant 100 m altitude.
      for (var i = 0; i < 30; i++) {
        calc.addSample(cumulativeDistanceKm: i * 0.02, altitudeM: 100);
      }
      final g = calc.current;
      expect(g.gradeFraction, closeTo(0.0, 1e-9));
      expect(g.confident, isTrue);
    });

    test('a steady 5% climb yields grade ~0.05', () {
      final calc = RoadGradeCalculator();
      // 60 samples 20 m apart; +5 m per 100 m. Enough samples for the
      // exponential smoothing to converge — once converged its constant
      // lag cancels in the windowed difference, so the grade is exact.
      for (var i = 0; i < 60; i++) {
        final distM = i * 20.0;
        calc.addSample(
          cumulativeDistanceKm: distM / 1000.0,
          altitudeM: 100 + 0.05 * distM,
        );
      }
      final g = calc.current;
      expect(g.gradeFraction, closeTo(0.05, 0.002));
      expect(g.confident, isTrue);
    });

    test('a steady 4% descent yields a negative grade', () {
      final calc = RoadGradeCalculator();
      for (var i = 0; i < 60; i++) {
        final distM = i * 20.0;
        calc.addSample(
          cumulativeDistanceKm: distM / 1000.0,
          altitudeM: 500 - 0.04 * distM,
        );
      }
      expect(calc.current.gradeFraction, closeTo(-0.04, 0.002));
    });

    test('noisy altitude on a flat road still reads ~flat — smoothing '
        'works', () {
      final calc = RoadGradeCalculator();
      // Flat 100 m road, but every fix is ±12 m off (alternating) —
      // raw differencing of adjacent fixes would give a ~120% grade.
      for (var i = 0; i < 40; i++) {
        final noise = (i.isEven ? 12.0 : -12.0);
        calc.addSample(
          cumulativeDistanceKm: i * 0.02,
          altitudeM: 100 + noise,
        );
      }
      final g = calc.current;
      expect(g.gradeFraction.abs(), lessThan(0.04),
          reason: 'exponential smoothing must damp the ±12 m noise to a '
              'near-flat grade');
      expect(g.confident, isTrue);
    });

    test('too little distance — not confident', () {
      final calc = RoadGradeCalculator();
      // Three samples spanning only 40 m — far short of the 150 m
      // window, so no anchor exists yet.
      calc.addSample(cumulativeDistanceKm: 0.00, altitudeM: 100);
      calc.addSample(cumulativeDistanceKm: 0.02, altitudeM: 101);
      calc.addSample(cumulativeDistanceKm: 0.04, altitudeM: 102);
      final g = calc.current;
      expect(g.confident, isFalse);
      expect(g.gradeFraction, 0.0);
    });

    test('a GPS-altitude dropout leaves the window too sparse to trust',
        () {
      final calc = RoadGradeCalculator();
      // Samples every 20 m across 300 m, but altitude only every 60 m
      // (a dropout nulls the rest). The window then holds too few
      // points to be confident, even though it is distance-full.
      for (var i = 0; i <= 15; i++) {
        final distM = i * 20.0;
        calc.addSample(
          cumulativeDistanceKm: distM / 1000.0,
          altitudeM: (distM % 60 == 0) ? 100.0 : null,
        );
      }
      expect(calc.current.confident, isFalse);
    });

    test('reset clears all accumulated state', () {
      final calc = RoadGradeCalculator();
      for (var i = 0; i < 30; i++) {
        calc.addSample(cumulativeDistanceKm: i * 0.02, altitudeM: 100);
      }
      expect(calc.current.confident, isTrue);

      calc.reset();
      expect(calc.current.confident, isFalse);
      expect(calc.current.gradeFraction, 0.0);
    });

    test('RoadGrade.flat is the neutral value', () {
      expect(RoadGrade.flat.gradeFraction, 0.0);
      expect(RoadGrade.flat.confident, isFalse);
    });
  });
}
