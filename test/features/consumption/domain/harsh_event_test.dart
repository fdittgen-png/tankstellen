import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/harsh_event.dart';
import 'package:tankstellen/features/consumption/domain/harsh_event_detector.dart';

void main() {
  group('HarshEvent (#2029)', () {
    test('JSON round-trip preserves every field', () {
      final original = HarshEvent(
        timestamp: DateTime.utc(2026, 5, 24, 14, 30, 5),
        magnitudeG: 0.42,
        speedKmh: 87.3,
        type: HarshEventType.brake,
      );
      final json = original.toJson();
      final round = HarshEvent.fromJson(json);
      expect(round.timestamp, original.timestamp);
      expect(round.magnitudeG, closeTo(original.magnitudeG, 1e-9));
      expect(round.speedKmh, closeTo(original.speedKmh, 1e-9));
      expect(round.type, original.type);
    });

    test('HarshEventType.fromWireName defaults to brake for unknown', () {
      expect(HarshEventType.fromWireName(null), HarshEventType.brake);
      expect(HarshEventType.fromWireName('xyz'), HarshEventType.brake);
      expect(
          HarshEventType.fromWireName('accel'), HarshEventType.acceleration);
      expect(HarshEventType.fromWireName('brake'), HarshEventType.brake);
    });
  });

  group('accelGForInterval (#2022)', () {
    test('positive g for acceleration', () {
      // 0 → 30 km/h in 2 s → 8.333 m/s / 2 s = 4.166 m/s² ≈ 0.425 g
      final g = accelGForInterval(
        prevSpeedKmh: 0,
        currSpeedKmh: 30,
        dtSeconds: 2,
      );
      expect(g, isNotNull);
      expect(g!, closeTo(0.425, 0.01));
    });

    test('negative g for braking', () {
      // 80 → 50 km/h in 1.5 s → -8.333 m/s / 1.5 s = -5.555 m/s² ≈ -0.566 g
      final g = accelGForInterval(
        prevSpeedKmh: 80,
        currSpeedKmh: 50,
        dtSeconds: 1.5,
      );
      expect(g, isNotNull);
      expect(g!, closeTo(-0.566, 0.01));
    });

    test('null when dtSeconds is zero or negative', () {
      expect(
          accelGForInterval(prevSpeedKmh: 0, currSpeedKmh: 30, dtSeconds: 0),
          isNull);
      expect(
          accelGForInterval(prevSpeedKmh: 0, currSpeedKmh: 30, dtSeconds: -1),
          isNull);
    });
  });

  group('HarshEventDetector.events (#2029)', () {
    test('emits a HarshEvent on threshold crossing with the magnitude in g',
        () {
      final detector = HarshEventDetector(
        brakeThresholdMps2: 3.5,
        accelThresholdMps2: 3.0,
      );
      final t0 = DateTime.utc(2026, 5, 24, 14, 0);
      detector.onSample(80, t0);
      // 1 s later: 80 → 60 km/h = -5.56 m/s² → harsh brake
      detector.onSample(60, t0.add(const Duration(seconds: 1)));
      expect(detector.events, hasLength(1));
      expect(detector.events.first.type, HarshEventType.brake);
      // magnitude ≈ |(-5.56)| / 9.80665 ≈ 0.566 g
      expect(detector.events.first.magnitudeG, closeTo(0.566, 0.02));
      expect(detector.events.first.speedKmh, 60);
    });

    test('reset clears events as well as anchor', () {
      final detector = HarshEventDetector();
      final t0 = DateTime.utc(2026, 5, 24);
      detector.onSample(80, t0);
      detector.onSample(60, t0.add(const Duration(seconds: 1)));
      expect(detector.brakes, 1);
      detector.reset();
      expect(detector.brakes, 0);
      expect(detector.events, isEmpty);
    });
  });
}
