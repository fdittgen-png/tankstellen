import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/trip_live_reading.dart';

void main() {
  group('TripLiveReading constructor', () {
    test('optional fields default to null when only required are supplied',
        () {
      const reading = TripLiveReading(
        distanceKmSoFar: 1.5,
        elapsed: Duration(seconds: 45),
      );
      expect(reading.distanceKmSoFar, 1.5);
      expect(reading.elapsed, const Duration(seconds: 45));
      expect(reading.speedKmh, isNull);
      expect(reading.rpm, isNull);
      expect(reading.fuelRateLPerHour, isNull);
      expect(reading.fuelLevelPercent, isNull);
      expect(reading.engineLoadPercent, isNull);
      expect(reading.throttlePercent, isNull);
      expect(reading.coolantTempC, isNull);
      expect(reading.fuelLitersSoFar, isNull);
      expect(reading.odometerStartKm, isNull);
      expect(reading.odometerNowKm, isNull);
    });

    test('coolantTempC stores the value supplied by the controller (#1262)',
        () {
      const reading = TripLiveReading(
        coolantTempC: 78.5,
        distanceKmSoFar: 0,
        elapsed: Duration.zero,
      );
      expect(reading.coolantTempC, 78.5);
    });
  });

  group('TripLiveReading.liveAvgLPer100Km', () {
    test('returns null when fuelLitersSoFar is null', () {
      const reading = TripLiveReading(
        distanceKmSoFar: 10.0,
        elapsed: Duration(minutes: 5),
      );
      expect(reading.liveAvgLPer100Km, isNull);
    });

    test('returns null when distanceKmSoFar is exactly 0.0', () {
      const reading = TripLiveReading(
        distanceKmSoFar: 0.0,
        elapsed: Duration(seconds: 10),
        fuelLitersSoFar: 0.2,
      );
      expect(reading.liveAvgLPer100Km, isNull);
    });

    test('returns null when distanceKmSoFar is below the 0.01 km floor', () {
      const reading = TripLiveReading(
        distanceKmSoFar: 0.005,
        elapsed: Duration(seconds: 5),
        fuelLitersSoFar: 0.01,
      );
      expect(reading.liveAvgLPer100Km, isNull);
    });

    test('returns a value at the boundary distanceKmSoFar == 0.01 km', () {
      // Boundary: the guard is `< 0.01`, so 0.01 exactly is *not* rejected.
      const reading = TripLiveReading(
        distanceKmSoFar: 0.01,
        elapsed: Duration(seconds: 5),
        fuelLitersSoFar: 0.001,
      );
      final value = reading.liveAvgLPer100Km;
      expect(value, isNotNull);
      expect(value, closeTo(10.0, 1e-9));
    });

    test('realistic values: 1 L over 20 km → 5.0 L/100km', () {
      const reading = TripLiveReading(
        distanceKmSoFar: 20.0,
        elapsed: Duration(minutes: 15),
        fuelLitersSoFar: 1.0,
      );
      expect(reading.liveAvgLPer100Km, closeTo(5.0, 1e-9));
    });

    test('free-coast case: 0 L over 10 km → 0.0 L/100km', () {
      const reading = TripLiveReading(
        distanceKmSoFar: 10.0,
        elapsed: Duration(minutes: 5),
        fuelLitersSoFar: 0.0,
      );
      expect(reading.liveAvgLPer100Km, 0.0);
    });

    test('very small distance above floor: 0.01 L over 0.02 km → 50.0 L/100km',
        () {
      const reading = TripLiveReading(
        distanceKmSoFar: 0.02,
        elapsed: Duration(seconds: 2),
        fuelLitersSoFar: 0.01,
      );
      expect(reading.liveAvgLPer100Km, closeTo(50.0, 1e-9));
    });
  });
}
