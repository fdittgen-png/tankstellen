// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/fuel_event_attribution.dart';
import 'package:tankstellen/features/consumption/domain/trip_sample.dart';

/// #3432 (epic #3416) — per-event fuel-cost attribution, one group per
/// event class, on constructed 1 Hz sample fixtures.
void main() {
  final t0 = DateTime.utc(2026, 7, 1, 8);

  TripSample s(
    int second, {
    required double speed,
    double? rpm,
    double? rate,
    double? pedal,
  }) =>
      TripSample(
        timestamp: t0.add(Duration(seconds: second)),
        speedKmh: speed,
        rpm: rpm,
        fuelRateLPerHour: rate,
        pedalPercent: pedal,
      );

  group('idle events', () {
    test('stationary engine-on ≥ 30 s becomes ONE idle event with the '
        'integrated litres', () {
      final samples = [
        for (var i = 0; i <= 60; i++) s(i, speed: 0, rpm: 800, rate: 0.9),
      ];
      final a = FuelAttribution.fromSamples(samples);
      final idles = a.eventsOf(FuelEventType.idle).toList();
      expect(idles, hasLength(1));
      expect(idles.single.seconds, closeTo(60, 0.001));
      // 0.9 L/h × 60 s = 0.015 L.
      expect(a.idleLiters, closeTo(0.9 * 60 / 3600, 1e-9));
    });

    test('a short 20 s stop is NOT an event', () {
      final samples = [
        for (var i = 0; i <= 20; i++) s(i, speed: 0, rpm: 800, rate: 0.9),
        for (var i = 21; i <= 40; i++) s(i, speed: 50, rpm: 2000, rate: 5),
      ];
      final a = FuelAttribution.fromSamples(samples);
      expect(a.eventsOf(FuelEventType.idle), isEmpty);
    });

    test('unmeasured rate falls back to the 0.6 L/h idle assumption', () {
      final samples = [
        for (var i = 0; i <= 60; i++) s(i, speed: 0, rpm: 800),
      ];
      final a = FuelAttribution.fromSamples(samples);
      expect(a.idleLiters,
          closeTo(kIdleFuelRateAssumptionLPerHour * 60 / 3600, 1e-9));
    });

    test('GPS-only standstill (null RPM = no engine signal) is never idle',
        () {
      final samples = [
        for (var i = 0; i <= 60; i++) s(i, speed: 0),
      ];
      final a = FuelAttribution.fromSamples(samples);
      expect(a.eventsOf(FuelEventType.idle), isEmpty);
    });
  });

  group('harsh-accel events', () {
    test('a pedal spike attributes the excess over the pre-event baseline',
        () {
      final samples = [
        // 6 s cruise baseline at 5 L/h, pedal 20 %.
        for (var i = 0; i <= 5; i++)
          s(i, speed: 50, rpm: 2000, rate: 5, pedal: 20),
        // 4 s pedal-to-the-floor at 20 L/h.
        for (var i = 6; i <= 9; i++)
          s(i, speed: 55.0 + i, rpm: 3500, rate: 20, pedal: 95),
        // Back to cruise.
        for (var i = 10; i <= 15; i++)
          s(i, speed: 70, rpm: 2200, rate: 6, pedal: 20),
      ];
      final a = FuelAttribution.fromSamples(samples);
      final events = a.eventsOf(FuelEventType.harshAccel).toList();
      expect(events, hasLength(1));
      // Excess = (20 − 5) L/h over the 3 attributed intervals (6→9 s).
      expect(a.harshAccelLiters, closeTo(15.0 * 3 / 3600, 1e-9));
    });

    test('without a measured rate the literature 0.05 L/event constant is '
        'used', () {
      final samples = [
        for (var i = 0; i <= 5; i++) s(i, speed: 50, rpm: 2000, pedal: 20),
        for (var i = 6; i <= 9; i++)
          s(i, speed: 55.0 + i, rpm: 3500, pedal: 95),
        for (var i = 10; i <= 15; i++) s(i, speed: 70, rpm: 2200, pedal: 20),
      ];
      final a = FuelAttribution.fromSamples(samples);
      expect(a.harshAccelLiters, closeTo(kAccelFallbackLitersPerEvent, 1e-9));
    });

    test('sustained full throttle without a spike edge is not an event', () {
      final samples = [
        for (var i = 0; i <= 20; i++)
          s(i, speed: 100, rpm: 4000, rate: 18, pedal: 95),
      ];
      final a = FuelAttribution.fromSamples(samples);
      expect(a.eventsOf(FuelEventType.harshAccel), isEmpty);
    });
  });

  group('high-RPM cruise events', () {
    test('steady-speed cruising at ≥ 2800 RPM yields the upshift-saving '
        'estimate (25% of the cruise burn)', () {
      final samples = [
        for (var i = 0; i <= 60; i++)
          s(i, speed: 80, rpm: 3000, rate: 8, pedal: 20),
      ];
      final a = FuelAttribution.fromSamples(samples);
      final events = a.eventsOf(FuelEventType.highRpmCruise).toList();
      expect(events, hasLength(1));
      // 8 L/h × 25 % × 60 s.
      expect(a.highRpmCruiseLiters,
          closeTo(8 * kUpshiftRateSavingRatio * 60 / 3600, 1e-9));
    });

    test('accelerating hard at high RPM is NOT a cruise (no upshift '
        'coaching during a deliberate pull)', () {
      final samples = [
        for (var i = 0; i <= 20; i++)
          // +10 km/h per second — way past the steady bound.
          s(i, speed: 30.0 + i * 10, rpm: 4000, rate: 15, pedal: 40),
      ];
      final a = FuelAttribution.fromSamples(samples);
      expect(a.eventsOf(FuelEventType.highRpmCruise), isEmpty);
    });

    test('high throttle vetoes the cruise event (intentional acceleration)',
        () {
      final samples = [
        for (var i = 0; i <= 20; i++)
          s(i, speed: 80, rpm: 3000, rate: 8, pedal: 70),
      ];
      final a = FuelAttribution.fromSamples(samples);
      expect(a.eventsOf(FuelEventType.highRpmCruise), isEmpty);
    });
  });

  group('coasting / fuel-cut events', () {
    test('measured rate ≈ 0 while moving is recognised and credited with '
        'the idle-counterfactual saving', () {
      final samples = [
        for (var i = 0; i <= 10; i++)
          s(i, speed: 80, rpm: 2500, rate: 7, pedal: 15),
        // 30 s of engine-braking fuel cut downhill.
        for (var i = 11; i <= 41; i++)
          s(i, speed: 75, rpm: 2200, rate: 0.0, pedal: 0),
        for (var i = 42; i <= 50; i++)
          s(i, speed: 70, rpm: 2000, rate: 6, pedal: 15),
      ];
      final a = FuelAttribution.fromSamples(samples);
      final events = a.eventsOf(FuelEventType.coasting).toList();
      expect(events, hasLength(1));
      expect(a.coastingSavedLiters,
          closeTo(kIdleFuelRateAssumptionLPerHour * 31 / 3600, 1e-6));
    });

    test('an ABSENT fuel signal is never praised as coasting', () {
      final samples = [
        for (var i = 0; i <= 60; i++) s(i, speed: 80),
      ];
      final a = FuelAttribution.fromSamples(samples);
      expect(a.eventsOf(FuelEventType.coasting), isEmpty);
    });

    test('rate ≈ 0 at crawl speed is not coasting (below the 20 km/h '
        'floor)', () {
      final samples = [
        for (var i = 0; i <= 30; i++) s(i, speed: 10, rpm: 900, rate: 0.0),
      ];
      final a = FuelAttribution.fromSamples(samples);
      expect(a.eventsOf(FuelEventType.coasting), isEmpty);
    });
  });

  group('breakdown shape', () {
    test('percentOfTrip + toJson expose the per-class story', () {
      final samples = [
        for (var i = 0; i <= 60; i++) s(i, speed: 0, rpm: 800, rate: 0.9),
        for (var i = 61; i <= 120; i++)
          s(i, speed: 80, rpm: 3000, rate: 8, pedal: 20),
      ];
      final a = FuelAttribution.fromSamples(samples);
      expect(a.totalSeconds, closeTo(120, 0.001));
      // 61 of 120 s idle (the 60→61 s boundary interval is attributed
      // to its idle start sample).
      expect(a.percentOfTrip(FuelEventType.idle), closeTo(50.8, 0.1));

      final json = a.toJson();
      expect(json['idleLiters'], isNonZero);
      expect(json['highRpmCruiseLiters'], isNonZero);
      expect((json['events'] as List), isNotEmpty);
    });

    test('too-short input returns the empty attribution', () {
      expect(FuelAttribution.fromSamples(const []), FuelAttribution.empty);
      expect(
        FuelAttribution.fromSamples([s(0, speed: 0, rpm: 800)]).events,
        isEmpty,
      );
    });
  });
}
