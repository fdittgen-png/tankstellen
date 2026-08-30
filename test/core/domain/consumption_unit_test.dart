// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3883 — every consumption figure is computed in L/100 km and only
// RENDERED in the user's unit; the reciprocal units guard zero.
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/consumption_unit.dart';
import 'package:tankstellen/core/utils/unit_formatter.dart';
import 'package:tankstellen/features/driving_score/domain/driving_coaching.dart';
import 'package:tankstellen/features/obd2/domain/trip_live_reading.dart';

void main() {
  test('conversions from L/100 km', () {
    expect(ConsumptionUnit.lPer100Km.fromLPer100Km(8.0), 8.0);
    expect(ConsumptionUnit.kmPerL.fromLPer100Km(8.0), closeTo(12.5, 1e-9));
    expect(ConsumptionUnit.mpgUs.fromLPer100Km(8.0), closeTo(29.4, 0.05));
    expect(ConsumptionUnit.mpgUk.fromLPer100Km(8.0), closeTo(35.3, 0.05));
    expect(ConsumptionUnit.mpgUk.fromLPer100Km(0), isNull);
  });

  test('country defaults: GB → mpg (UK), US → mpg (US), else L/100 km', () {
    expect(ConsumptionUnit.defaultFor('GB'), ConsumptionUnit.mpgUk);
    expect(ConsumptionUnit.defaultFor('us'), ConsumptionUnit.mpgUs);
    expect(ConsumptionUnit.defaultFor('DE'), ConsumptionUnit.lPer100Km);
    expect(ConsumptionUnit.defaultFor(null), ConsumptionUnit.lPer100Km);
  });

  test('UnitFormatter keeps the L/100 km mask by default and renders the '
      'chosen unit otherwise', () {
    expect(UnitFormatter.formatConsumption(6.4, isEv: false), '6.4 L/100 km');
    expect(
        UnitFormatter.formatConsumption(6.4, isEv: false, unit: ConsumptionUnit.mpgUk),
        '44 mpg (UK)');
    expect(
        UnitFormatter.formatConsumption(6.4, isEv: false, unit: ConsumptionUnit.kmPerL),
        '15.6 km/L');
    expect(
        UnitFormatter.formatConsumption(18.0, isEv: true, unit: ConsumptionUnit.mpgUs),
        '18.0 kWh/100 km',
        reason: 'EV figures ignore the fuel unit');
  });

  group('resolveLiveConsumption', () {
    test('prefers the rolling window over the EMA instant, in the unit', () {
      const r = TripLiveReading(
        distanceKmSoFar: 1,
        elapsed: Duration(minutes: 1),
        instantLPer100Km: 12.0,
        instantLPerHour: 7.2,
        instantIsIdle: false,
        windowLPer100Km: 10.0,
        windowLPerHour: 6.0,
        windowIsIdle: false,
        windowSeconds: 5,
      );
      final f = resolveLiveConsumption(r)!;
      expect(f.figure, '10.0');
      expect(f.shortUnit, 'L/100');
      expect(f.unitMask, 'L/100 km');
      expect(f.windowSeconds, 5);
      expect(formatInstantConsumption(r), '10.0 L/100');
      final mpg = resolveLiveConsumption(r, unit: ConsumptionUnit.mpgUk)!;
      expect(mpg.figure, '28');
      expect(mpg.shortUnit, 'mpg');
      expect(formatInstantConsumption(r, unit: ConsumptionUnit.mpgUk), '28 mpg');
    });

    test('idle window → L/h; no window → EMA; nothing → null', () {
      const idle = TripLiveReading(
        distanceKmSoFar: 1,
        elapsed: Duration(minutes: 1),
        windowLPerHour: 0.8,
        windowIsIdle: true,
        windowSeconds: 5,
      );
      expect(formatInstantConsumption(idle), '0.8 L/h');
      const ema = TripLiveReading(
        distanceKmSoFar: 1,
        elapsed: Duration(minutes: 1),
        instantLPer100Km: 9.5,
        instantLPerHour: 5.7,
        instantIsIdle: false,
      );
      final f = resolveLiveConsumption(ema)!;
      expect(f.figure, '9.5');
      expect(f.windowSeconds, isNull);
      expect(
          resolveLiveConsumption(
              const TripLiveReading(distanceKmSoFar: 0, elapsed: Duration.zero)),
          isNull);
    });

    test('estimate figure carries the ~ marker in the unit', () {
      expect(formatEstimatedConsumptionFigure(7.0, ConsumptionUnit.lPer100Km), '~7.0');
      expect(formatEstimatedConsumptionFigure(7.0, ConsumptionUnit.mpgUs), '~34');
    });
  });
}
