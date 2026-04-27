import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/achievements/domain/trip_metrics.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';

TripSummary _summary({
  required Duration duration,
  double idleSeconds = 0,
  double highRpmSeconds = 0,
  int harshBrakes = 0,
  int harshAccels = 0,
  double distanceKm = 20,
}) {
  final start = DateTime(2026, 1, 1);
  return TripSummary(
    distanceKm: distanceKm,
    maxRpm: 2000,
    highRpmSeconds: highRpmSeconds,
    idleSeconds: idleSeconds,
    harshBrakes: harshBrakes,
    harshAccelerations: harshAccels,
    startedAt: start,
    endedAt: start.add(duration),
  );
}

void main() {
  group('TripMetrics.drivingScore (#1041 phase 5)', () {
    test('clean trip with no penalties scores 100', () {
      final s = _summary(duration: const Duration(minutes: 30));
      expect(TripMetrics.drivingScore(s), 100);
    });

    test('trip with no startedAt/endedAt returns 100 (no signal)', () {
      const s = TripSummary(
        distanceKm: 20,
        maxRpm: 2000,
        highRpmSeconds: 30,
        idleSeconds: 30,
        harshBrakes: 5,
        harshAccelerations: 5,
      );
      expect(TripMetrics.drivingScore(s), 100);
    });

    test('trip <1 minute returns 100 (insufficient data)', () {
      final s = _summary(
        duration: const Duration(seconds: 30),
        idleSeconds: 30,
        harshBrakes: 5,
      );
      expect(TripMetrics.drivingScore(s), 100);
    });

    test('100% idle trip drops at least 30 points (idle penalty cap)',
        () {
      final s = _summary(
        duration: const Duration(minutes: 10),
        idleSeconds: 600,
      );
      expect(TripMetrics.drivingScore(s), 70);
    });

    test('two harsh events take 10 points off (5 per event)', () {
      final s = _summary(
        duration: const Duration(minutes: 30),
        harshBrakes: 1,
        harshAccels: 1,
      );
      expect(TripMetrics.drivingScore(s), 90);
    });

    test('many harsh events cap at 25 points off', () {
      final s = _summary(
        duration: const Duration(minutes: 30),
        harshBrakes: 10,
        harshAccels: 10,
      );
      // 20 events × 5 = 100 → capped at 25.
      expect(TripMetrics.drivingScore(s), 75);
    });

    test('compound penalties never push the score below 0', () {
      // 100% idle (-30) + 100% high RPM (-25) + 20 harsh events
      // (cap -25) = -80; still leaves 20.
      final s = _summary(
        duration: const Duration(minutes: 10),
        idleSeconds: 600,
        highRpmSeconds: 600,
        harshBrakes: 10,
        harshAccels: 10,
      );
      expect(TripMetrics.drivingScore(s), 20);
    });
  });

  group('TripMetrics.coldStartExcessLiters (#1041 phase 5)', () {
    TripSample sample(
      int seconds, {
      double? fuelRate,
      double speed = 50,
    }) {
      return TripSample(
        timestamp: DateTime(2026, 1, 1).add(Duration(seconds: seconds)),
        speedKmh: speed,
        rpm: 2000,
        fuelRateLPerHour: fuelRate,
      );
    }

    test('empty samples returns 0', () {
      expect(TripMetrics.coldStartExcessLiters(const []), 0);
    });

    test('single sample returns 0 (no interval)', () {
      expect(TripMetrics.coldStartExcessLiters([sample(0, fuelRate: 8)]), 0);
    });

    test('trip entirely inside cold-start window returns 0', () {
      // 4-minute trip — all inside the 5-minute cold-start window.
      final samples = [
        for (var i = 0; i <= 4; i++) sample(i * 60, fuelRate: 8),
      ];
      expect(TripMetrics.coldStartExcessLiters(samples), 0);
    });

    test('cold rate higher than steady rate yields positive excess',
        () {
      // 10-minute trip: minutes 0-5 burn 12 L/h, minutes 5-10 burn 6
      // L/h. The interval starting at minute 5 is attributed to
      // steady (its `prev` timestamp is exactly the cold-window end,
      // and `isBefore` is strict), so cold totals 5×0.2 = 1.0 L
      // over 300 s and steady totals 0.2 + 4×0.1 = 0.6 L over
      // 300 s. Excess ≈ (1.0 − 0.6) = 0.4 L.
      final samples = <TripSample>[
        for (var i = 0; i <= 5; i++) sample(i * 60, fuelRate: 12),
        for (var i = 6; i <= 10; i++) sample(i * 60, fuelRate: 6),
      ];
      final excess = TripMetrics.coldStartExcessLiters(samples);
      expect(excess, closeTo(0.4, 0.01));
    });

    test('cold rate <= steady rate returns 0 (no penalty)', () {
      // Cold = 5 L/h, steady = 8 L/h — no excess to attribute.
      final samples = <TripSample>[
        for (var i = 0; i <= 5; i++) sample(i * 60, fuelRate: 5),
        for (var i = 6; i <= 10; i++) sample(i * 60, fuelRate: 8),
      ];
      expect(TripMetrics.coldStartExcessLiters(samples), 0);
    });

    test('null fuel-rate samples are skipped without crashing', () {
      // Mix of measured + null samples — null intervals attributed
      // to neither bucket; the result is non-zero only if measured
      // intervals show a cold-start signal.
      final samples = <TripSample>[
        sample(0, fuelRate: 12),
        sample(60, fuelRate: null),
        sample(120, fuelRate: 12),
        sample(300, fuelRate: 12),
        sample(360, fuelRate: 6),
        sample(540, fuelRate: 6),
      ];
      final excess = TripMetrics.coldStartExcessLiters(samples);
      expect(excess, greaterThan(0));
    });
  });

  group('TripMetrics.speedStdDev (#1041 phase 5)', () {
    TripSample sampleAt(double speedKmh) {
      return TripSample(
        timestamp: DateTime(2026, 1, 1),
        speedKmh: speedKmh,
        rpm: 2000,
      );
    }

    test('empty samples returns infinity', () {
      expect(TripMetrics.speedStdDev(const []), double.infinity);
    });

    test('all idle samples returns infinity (insufficient moving '
        'samples)', () {
      final samples = [for (var i = 0; i < 5; i++) sampleAt(2)];
      expect(TripMetrics.speedStdDev(samples), double.infinity);
    });

    test('constant speed yields std-dev 0', () {
      final samples = [for (var i = 0; i < 10; i++) sampleAt(110)];
      expect(TripMetrics.speedStdDev(samples), closeTo(0, 0.001));
    });

    test('symmetric spread around mean yields expected std-dev', () {
      // Speeds 100, 110, 120 — mean 110, variance = ((10² + 0 +
      // 10²) / 3) ≈ 66.66, std-dev ≈ 8.165.
      final samples = [sampleAt(100), sampleAt(110), sampleAt(120)];
      final stdDev = TripMetrics.speedStdDev(samples);
      expect(stdDev, closeTo(8.165, 0.01));
    });

    test('idle samples are excluded from the std-dev', () {
      // Two idle samples (speed 0) plus three highway samples at
      // 110 km/h. Idles are filtered out; std-dev is 0.
      final samples = [
        sampleAt(0),
        sampleAt(0),
        sampleAt(110),
        sampleAt(110),
        sampleAt(110),
      ];
      expect(TripMetrics.speedStdDev(samples), closeTo(0, 0.001));
    });
  });
}
