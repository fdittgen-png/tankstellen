// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/trip_live_reading.dart';
import 'package:tankstellen/features/consumption/domain/cold_start_baselines.dart';
import 'package:tankstellen/features/consumption/domain/driving_coaching.dart';
import 'package:tankstellen/features/consumption/domain/situation_classifier.dart';

TripLiveReading _r({
  double? speed,
  double? rpm,
  double? throttle,
  double? fuelRate,
}) =>
    TripLiveReading(
      speedKmh: speed,
      rpm: rpm,
      throttlePercent: throttle,
      fuelRateLPerHour: fuelRate,
      distanceKmSoFar: 0,
      elapsed: Duration.zero,
    );

void main() {
  group('coachingHint (#2007)', () {
    test('silent in the default mid-cruise case (no hint fires)', () {
      final hint = coachingHint(
        _r(speed: 60, rpm: 2200, throttle: 20),
        situation: DrivingSituation.urbanCruise,
        band: ConsumptionBand.normal,
      );
      expect(hint, isNull,
          reason: 'silence is the default — false coaching is worse '
              'than missed coaching');
    });

    test('shiftUp fires on high RPM + cruising speed + moderate throttle',
        () {
      final hint = coachingHint(
        _r(speed: 55, rpm: 3200, throttle: 25),
        situation: DrivingSituation.urbanCruise,
        band: ConsumptionBand.normal,
      );
      expect(hint, DrivingCoachingHint.shiftUp);
    });

    test('shiftUp does NOT fire when throttle is wide open '
        '(the driver is intentionally winding the engine out — '
        'merging, overtaking)', () {
      final hint = coachingHint(
        _r(speed: 55, rpm: 3200, throttle: 80),
        situation: DrivingSituation.urbanCruise,
        band: ConsumptionBand.normal,
      );
      expect(hint, isNull);
    });

    test('shiftUp does NOT fire below the cruise-speed floor '
        '(low-gear pull-away is fine)', () {
      final hint = coachingHint(
        _r(speed: 20, rpm: 3200, throttle: 25),
        situation: DrivingSituation.urbanCruise,
        band: ConsumptionBand.normal,
      );
      expect(hint, isNull);
    });

    test('shiftDown fires on low RPM with high throttle (lugging)', () {
      final hint = coachingHint(
        _r(speed: 70, rpm: 1100, throttle: 65),
        situation: DrivingSituation.highwayCruise,
        band: ConsumptionBand.normal,
      );
      expect(hint, DrivingCoachingHint.shiftDown);
    });

    test('shiftDown does NOT fire on low RPM with light throttle '
        '(coasting / cruising, no lugging)', () {
      final hint = coachingHint(
        _r(speed: 70, rpm: 1100, throttle: 20),
        situation: DrivingSituation.highwayCruise,
        band: ConsumptionBand.eco,
      );
      expect(hint, isNull);
    });

    test('easePedal fires on hardAccel + wide-open throttle + heavy band',
        () {
      final hint = coachingHint(
        _r(speed: 60, rpm: 2500, throttle: 85),
        situation: DrivingSituation.hardAccel,
        band: ConsumptionBand.heavy,
      );
      expect(hint, DrivingCoachingHint.easePedal);
    });

    test('easePedal wins over shiftUp when both could fire — the '
        'heavy-throttle waste signal is more user-visible', () {
      // High RPM AND high throttle AND hardAccel AND heavy band.
      final hint = coachingHint(
        _r(speed: 60, rpm: 3200, throttle: 85),
        situation: DrivingSituation.hardAccel,
        band: ConsumptionBand.veryHeavy,
      );
      expect(hint, DrivingCoachingHint.easePedal);
    });

    test('easePedal does NOT fire below pull-away speed '
        '(legitimate stop-and-go pull-away)', () {
      final hint = coachingHint(
        _r(speed: 25, rpm: 2500, throttle: 85),
        situation: DrivingSituation.hardAccel,
        band: ConsumptionBand.heavy,
      );
      expect(hint, isNull);
    });

    test('silent when key signals are missing (no fuel-rate-only PIDs)',
        () {
      final hint = coachingHint(
        _r(speed: null, rpm: null, throttle: null),
        situation: DrivingSituation.urbanCruise,
        band: ConsumptionBand.normal,
      );
      expect(hint, isNull,
          reason: 'a car with no RPM / throttle PIDs must never trip a '
              'coaching chip — the inputs simply do not exist');
    });
  });

  group('formatInstantConsumption (#2007)', () {
    test('renders L/100 km at cruising speed', () {
      // 6 L/h ÷ 60 km/h × 100 = 10.0 L/100
      final out = formatInstantConsumption(_r(speed: 60, fuelRate: 6));
      expect(out, '10.0 L/100');
    });

    test('falls back to L/h near standstill (below 5 km/h)', () {
      final out = formatInstantConsumption(_r(speed: 2, fuelRate: 1.2));
      expect(out, '1.2 L/h');
    });

    test('null when the car does not surface fuel rate', () {
      final out = formatInstantConsumption(_r(speed: 60, fuelRate: null));
      expect(out, isNull,
          reason: 'cars without a fuel-rate PID must silently hide the '
              'value — no placeholder, no 0.0 reading');
    });
  });

  group('formatInstantConsumption prefers the smoothed instant (#3431)', () {
    test('the EMA-stamped L/100 km wins over the raw rate/speed figure', () {
      const reading = TripLiveReading(
        elapsed: Duration(minutes: 1),
        distanceKmSoFar: 1,
        speedKmh: 60,
        fuelRateLPerHour: 6, // raw would render 10.0
        instantLPer100Km: 8.4,
        instantLPerHour: 5.0,
        instantIsIdle: false,
      );
      expect(formatInstantConsumption(reading), '8.4 L/100');
    });

    test('the idle mode flag renders the smoothed L/h', () {
      const reading = TripLiveReading(
        elapsed: Duration(minutes: 1),
        distanceKmSoFar: 1,
        speedKmh: 0,
        fuelRateLPerHour: 1.1,
        instantLPerHour: 0.9,
        instantIsIdle: true,
      );
      expect(formatInstantConsumption(reading), '0.9 L/h');
    });

    test('readings without the stamped fields keep the raw fallback', () {
      final out = formatInstantConsumption(_r(speed: 60, fuelRate: 6));
      expect(out, '10.0 L/100');
    });
  });
}
