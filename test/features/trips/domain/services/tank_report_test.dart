// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3616 — the per-tank insight loop: window building mirrors the #1362
// walker, behavior aggregation honors the #3599 transport exclusion and
// the #2895 IMU veto, explanations are coverage- and direction-gated,
// and the pump calibration only trusts well-covered windows.
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_up.dart';
import 'package:tankstellen/features/fill_ups/domain/services/tank_report.dart';
import 'package:tankstellen/features/trips/domain/trip_summary.dart';

void main() {
  final t0 = DateTime(2026, 7, 1);

  FillUp fill({
    required int day,
    required double liters,
    required double odo,
    bool full = true,
    bool correction = false,
    List<String> linked = const [],
    double cost = 0,
  }) =>
      FillUp(
        id: 'f$day',
        date: t0.add(Duration(days: day)),
        liters: liters,
        totalCost: cost,
        odometerKm: odo,
        fuelType: FuelType.e10,
        isFullTank: full,
        isCorrection: correction,
        linkedTripIds: linked,
      );

  TripSummary trip({
    double distanceKm = 100,
    double? avg = 10,
    double highRpmSeconds = 0,
    double idleSeconds = 0,
    int harsh = 0,
    bool coldStart = false,
    int durationMin = 60,
    double? engineRunningSeconds,
    TripKind kind = TripKind.gpsPlusObd2,
  }) =>
      TripSummary(
        distanceKm: distanceKm,
        maxRpm: 3000,
        highRpmSeconds: highRpmSeconds,
        idleSeconds: idleSeconds,
        harshBrakes: harsh,
        harshAccelerations: 0,
        avgLPer100Km: avg,
        startedAt: t0,
        endedAt: t0.add(Duration(minutes: durationMin)),
        coldStartSurcharge: coldStart,
        kind: kind,
        engineRunningSeconds: engineRunningSeconds,
      );

  test('two pleins close a window whose figures mirror the #1362 walker '
      '(partials + corrections in litres, opening excluded)', () {
    final report = buildTankReport(
      fillUps: [
        fill(day: 0, liters: 40, odo: 1000),
        fill(day: 3, liters: 10, odo: 1300, full: false, cost: 18),
        fill(day: 4, liters: 2, odo: 1350, correction: true, full: false),
        fill(day: 6, liters: 38, odo: 1600, cost: 70),
      ],
      tripSummariesById: const {},
    );
    final p = report.latest!;
    expect(p.distanceKm, 600);
    expect(p.liters, 50); // 10 + 2 + 38 — opening 40 belongs upstream
    expect(p.pumpedCost, 88);
    expect(p.lPer100Km, closeTo(8.33, 0.01));
    expect(report.evolution, isNull,
        reason: 'one closed window — no evolution yet');
  });

  test('implausible odometer windows are dropped, not reported', () {
    final report = buildTankReport(
      fillUps: [
        fill(day: 0, liters: 40, odo: 1000),
        fill(day: 6, liters: 38, odo: 999999), // typo'd odometer
      ],
      tripSummariesById: const {},
    );
    expect(report.latest, isNull);
  });

  group('evolution + explanations', () {
    // Window A: calm (8 L/100km). Window B: +2 L/100km with more
    // high-RPM time AND more harsh events in the recordings.
    List<FillUp> fills() => [
          fill(day: 0, liters: 40, odo: 1000),
          fill(day: 6, liters: 40, odo: 1500, linked: ['a1', 'a2']),
          fill(day: 12, liters: 50, odo: 2000, linked: ['b1', 'b2']),
        ];

    test('same-direction, well-covered behavior deltas become '
        'explanations, highest salience first', () {
      final report = buildTankReport(
        fillUps: fills(),
        tripSummariesById: {
          'a1': trip(distanceKm: 200, highRpmSeconds: 100, harsh: 1),
          'a2': trip(distanceKm: 200),
          'b1': trip(distanceKm: 200, highRpmSeconds: 900, harsh: 6),
          'b2': trip(distanceKm: 200, coldStart: true),
        },
      );
      final evo = report.evolution!;
      expect(evo.deltaLPer100Km, closeTo(2.0, 0.01));
      final factors = evo.explanations.map((e) => e.factor).toList();
      expect(factors, contains(TankFactor.highRpm));
      expect(factors, contains(TankFactor.harshEvents));
      expect(factors, isNot(contains(TankFactor.coldStarts)),
          reason: '+1 cold start is under the noise floor of 2');
    });

    test('thin coverage on either window yields NO explanations — '
        'silence over speculation', () {
      final report = buildTankReport(
        fillUps: fills(),
        tripSummariesById: {
          'a1': trip(distanceKm: 40), // 8% of 500 km — too thin
          'b1': trip(distanceKm: 300, highRpmSeconds: 900, harsh: 6),
        },
      );
      expect(report.evolution!.explanations, isEmpty);
    });

    test('a factor moving AGAINST the consumption delta cannot explain '
        'it', () {
      final report = buildTankReport(
        fillUps: fills(),
        tripSummariesById: {
          // Consumption went UP but the recordings got CALMER.
          'a1': trip(distanceKm: 300, highRpmSeconds: 900, harsh: 6),
          'b1': trip(distanceKm: 300, highRpmSeconds: 50, harsh: 0),
        },
      );
      expect(report.evolution!.explanations, isEmpty);
    });

    test('partial coverage sets the caveat; near-full coverage clears it',
        () {
      final partial = buildTankReport(
        fillUps: fills(),
        tripSummariesById: {
          'a1': trip(distanceKm: 200),
          'b1': trip(distanceKm: 200, highRpmSeconds: 900),
        },
      );
      expect(partial.evolution!.needsCoverageCaveat, isTrue,
          reason: '40% coverage is an incomplete story by construction');

      final full = buildTankReport(
        fillUps: fills(),
        tripSummariesById: {
          'a1': trip(distanceKm: 450),
          'b1': trip(distanceKm: 450, highRpmSeconds: 900),
        },
      );
      expect(full.evolution!.needsCoverageCaveat, isFalse);
    });

    test('engine-off transport trips are excluded from behavior wholesale',
        () {
      final report = buildTankReport(
        fillUps: fills(),
        tripSummariesById: {
          'a1': trip(distanceKm: 400),
          // A tow: huge distance, engine off — must count for NOTHING,
          // not even coverage.
          'b1': trip(
              distanceKm: 400,
              engineRunningSeconds: 30,
              durationMin: 60,
              avg: 2.0),
          'b2': trip(distanceKm: 100, highRpmSeconds: 400),
        },
      );
      final b = report.evolution!.currentBehavior;
      expect(b.tripCount, 1);
      expect(b.recordedKm, 100);
    });
  });

  test('pump calibration: EWMA over well-covered windows, thin ones '
      'skipped', () {
    // Recorded avg 8 vs pump 10 → ratio 1.25 on both covered windows.
    final report = buildTankReport(
      fillUps: [
        fill(day: 0, liters: 40, odo: 1000),
        fill(day: 6, liters: 50, odo: 1500, linked: ['a']),
        fill(day: 12, liters: 50, odo: 2000, linked: ['b']),
        fill(day: 18, liters: 50, odo: 2500, linked: ['thin']),
      ],
      tripSummariesById: {
        'a': trip(distanceKm: 400, avg: 8),
        'b': trip(distanceKm: 400, avg: 8),
        'thin': trip(distanceKm: 100, avg: 4), // 20% — below the bar
      },
    );
    final cal = report.calibration!;
    expect(cal.samples, 2);
    expect(cal.factor, closeTo(1.25, 0.001));
    expect(cal.gapPct, closeTo(25.0, 0.1),
        reason: 'recordings run 25% under pump truth');
  });

  test('fewer than two fills → empty report', () {
    expect(
      buildTankReport(
        fillUps: [fill(day: 0, liters: 40, odo: 1000)],
        tripSummariesById: const {},
      ).latest,
      isNull,
    );
  });
}
