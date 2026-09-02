// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3887 — the pump is the truth: a full-to-full tank window re-anchors the
// estimated fuel on the pump's litres PER KM (coverage cancels), strips
// the gain each trip already carried, blends with sample-dependent
// weight, and refuses partial fills / thin coverage / implausible ratios.
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/pump_gain_entry.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_up.dart';
import 'package:tankstellen/features/trips/domain/trip_summary.dart';
import 'package:tankstellen/features/fill_ups/domain/services/pump_gain_learner.dart';
import 'package:tankstellen/features/vehicle/data/repositories/vehicle_profile_repository.dart';

final _t0 = DateTime(2026, 8, 1, 8);

FillUp _fill(String id, int day, double odo, double liters,
        {bool full = true, List<String> trips = const []}) =>
    FillUp(
      id: id,
      date: _t0.add(Duration(days: day)),
      vehicleId: 'car',
      odometerKm: odo,
      liters: liters,
      totalCost: liters * 0.9,
      fuelType: FuelType.e85,
      isFullTank: full,
      linkedTripIds: trips,
    );

TripSummary _trip(double km, double liters, {double? gain}) => TripSummary(
      distanceKm: km,
      maxRpm: 3000,
      highRpmSeconds: 0,
      idleSeconds: 0,
      harshBrakes: 0,
      harshAccelerations: 0,
      fuelLitersConsumed: liters,
      avgLPer100Km: liters / km * 100,
      startedAt: _t0,
      pumpGainApplied: gain,
    );

void main() {
  late VehicleProfileRepository repo;
  late PumpGainLearner learner;
  setUp(() async {
    repo = VehicleProfileRepository(_FakeSettingsStorage());
    await repo.save(const VehicleProfile(id: 'car', name: 'Flex'));
    learner = PumpGainLearner(profileRepository: repo, now: () => _t0);
  });

  test('the field case: 559 km · 35.7 L pumped, recordings at 10.5 L/100 km '
      'over 81 % → gain 0.61, estimates come down 39 %', () async {
    // Recordings: 453 km (81 %) burning 47.6 L raw (10.5 L/100 km).
    final trips = {'a': _trip(300, 31.5), 'b': _trip(153, 16.07)};
    final r = await learner.reconcileAfterFillUp(
      vehicleId: 'car',
      closing: _fill('f2', 10, 100559, 35.7, trips: ['a', 'b']),
      fillUps: [_fill('f1', 0, 100000, 40), _fill('f2', 10, 100559, 35.7, trips: ['a', 'b'])],
      tripSummariesById: trips,
    );
    expect(r, isNotNull);
    expect(r!.pumpLPer100Km, closeTo(6.39, 0.01));
    expect(r.rawRecordedLPer100Km, closeTo(10.5, 0.01));
    expect(r.coverageShare, closeTo(0.81, 0.01));
    expect(r.newGain, closeTo(0.608, 0.005), reason: 'first window: face value');
    expect(r.changePct, closeTo(-39, 1));
    final p = repo.getById('car')!;
    expect(p.pumpGain, closeTo(0.608, 0.005));
    expect(p.pumpGainSamples, 1);
    expect(p.pumpGainUpdatedAt, _t0);
    expect(p.volumetricEfficiency, 0.85, reason: 'η_v is not the knob any more');
  });

  test('a trip already recorded with a gain is divided back to raw, so a '
      'second window converges instead of compounding', () async {
    await repo.save(const VehicleProfile(
        id: 'car', name: 'Flex', pumpGain: 0.6, pumpGainSamples: 1));
    // Recorded WITH gain 0.6: 6.3 L/100 km shown → raw 10.5; pump 6.39.
    final trips = {'a': _trip(500, 31.5, gain: 0.6)};
    final r = await learner.reconcileAfterFillUp(
      vehicleId: 'car',
      closing: _fill('f2', 10, 100559, 35.7, trips: ['a']),
      fillUps: [_fill('f1', 0, 100000, 40), _fill('f2', 10, 100559, 35.7, trips: ['a'])],
      tripSummariesById: trips,
    );
    expect(r!.rawRecordedLPer100Km, closeTo(10.5, 0.01));
    // target 0.608, blended 0.5/0.5 with 0.6 → ≈ 0.604
    expect(r.newGain, closeTo(0.604, 0.005));
    expect(r.sampleCount, 2);
  });

  test('partial fill, thin coverage, and implausible ratios are refused', () async {
    final trips = {'a': _trip(100, 10.5)};
    final fills = [_fill('f1', 0, 100000, 40), _fill('f2', 10, 100559, 35.7, trips: ['a'])];
    expect(
        await learner.reconcileAfterFillUp(
            vehicleId: 'car',
            closing: _fill('f2', 10, 100559, 35.7, full: false, trips: ['a']),
            fillUps: fills,
            tripSummariesById: trips),
        isNull,
        reason: 'partial fill');
    expect(
        await learner.reconcileAfterFillUp(
            vehicleId: 'car', closing: fills.last, fillUps: fills, tripSummariesById: trips),
        isNull,
        reason: '100 km of 559 = 18 % coverage');
    final bogus = {'a': _trip(500, 0.5)}; // 0.1 L/100 km recorded → ratio 64
    expect(
        await learner.reconcileAfterFillUp(
            vehicleId: 'car', closing: fills.last, fillUps: fills, tripSummariesById: bogus),
        isNull,
        reason: 'implausible');
    expect(repo.getById('car')!.pumpGainSamples, 0);
  });

  test('blend weight schedule and bounds', () {
    expect(PumpGainLearner.blendWeight(0), 1.0);
    expect(PumpGainLearner.blendWeight(1), 0.5);
    expect(PumpGainLearner.blendWeight(7), 0.4);
  });

  // #3917 — every skip carries its reason (and the window figures when a
  // window closed) so the "Bilan du plein" can explain itself.
  group('evaluate — skip reasons', () {
    final trips = {'a': _trip(100, 10.5)};
    final fills = [_fill('f1', 0, 100000, 40), _fill('f2', 10, 100559, 35.7, trips: ['a'])];

    Future<PumpGainOutcome> eval(FillUp closing,
            {List<FillUp>? fillUps, Map<String, TripSummary>? summaries}) =>
        learner.evaluate(
            vehicleId: 'car',
            closing: closing,
            fillUps: fillUps ?? fills,
            tripSummariesById: summaries ?? trips);

    test('partial fill', () async {
      final o = await eval(_fill('f2', 10, 100559, 35.7, full: false));
      expect(o.skipReason, PumpGainSkipReason.notFullTank);
      expect(o.result, isNull);
      expect(o.fuelKey, 'e85');
    });

    test('correction', () async {
      final o = await eval(fills.last.copyWith(isCorrection: true));
      expect(o.skipReason, PumpGainSkipReason.correction);
    });

    test('unknown vehicle', () async {
      final o = await learner.evaluate(
          vehicleId: 'ghost', closing: fills.last, fillUps: fills, tripSummariesById: trips);
      expect(o.skipReason, PumpGainSkipReason.noVehicle);
    });

    test('first full tank — no window closes', () async {
      final only = _fill('f1', 0, 100000, 40);
      final o = await eval(only, fillUps: [only]);
      expect(o.skipReason, PumpGainSkipReason.noWindow);
      expect(o.period, isNull);
    });

    test('coverage too low keeps the window figures', () async {
      final o = await eval(fills.last);
      expect(o.skipReason, PumpGainSkipReason.coverageTooLow);
      expect(o.period, isNotNull);
      expect(o.coverageShare, closeTo(0.18, 0.01));
      expect(o.recordedKm, 100);
      expect(o.rawRecordedLPer100Km, closeTo(10.5, 0.01));
    });

    test('recorded distance too short', () async {
      final o = await eval(fills.last, summaries: {'a': _trip(30, 3.15)});
      expect(o.skipReason, PumpGainSkipReason.recordedTooShort);
    });

    test('no recorded fuel', () async {
      final o = await eval(fills.last, summaries: {
        'a': TripSummary(
            distanceKm: 500,
            maxRpm: 3000,
            highRpmSeconds: 0,
            idleSeconds: 0,
            harshBrakes: 0,
            harshAccelerations: 0,
            startedAt: _t0),
      });
      // No litres → the trip never counts as recorded km either.
      expect(o.skipReason, PumpGainSkipReason.recordedTooShort);
    });

    test('implausible target', () async {
      final o = await eval(fills.last, summaries: {'a': _trip(500, 0.5)});
      expect(o.skipReason, PumpGainSkipReason.implausibleTarget);
      expect(o.period, isNotNull);
    });

    test('calibrated → result, no reason', () async {
      final closing = _fill('f2', 10, 100559, 35.7, trips: ['a', 'b']);
      final o = await eval(closing,
          summaries: {'a': _trip(300, 31.5), 'b': _trip(153, 16.07)},
          fillUps: [_fill('f1', 0, 100000, 40), closing]);
      expect(o.skipReason, isNull);
      expect(o.calibrated, isTrue);
      expect(o.result!.fuelKey, isNull, reason: 'single-fuel: scalar only');
      expect(repo.getById('car')!.pumpGainByFuel, isEmpty);
    });
  });

  // #3918 — a multi-fuel vehicle learns per grade AND keeps blending the
  // scalar as the fallback.
  group('multi-fuel keying', () {
    final trips = {'a': _trip(300, 31.5), 'b': _trip(153, 16.07)};
    final fills = [
      _fill('f1', 0, 100000, 40),
      _fill('f2', 10, 100559, 35.7, trips: ['a', 'b'])
    ];

    test('first E85 window: per-fuel entry at face value + scalar', () async {
      await repo.save(const VehicleProfile(
          id: 'car', name: 'Flex', multiFuelCapable: true));
      final o = await learner.evaluate(
          vehicleId: 'car', closing: fills.last, fillUps: fills, tripSummariesById: trips);
      final r = o.result!;
      expect(r.fuelKey, 'e85');
      expect(r.previousGain, 1.0);
      expect(r.newGain, closeTo(0.608, 0.005));
      expect(r.sampleCount, 1);
      final p = repo.getById('car')!;
      expect(p.pumpGainByFuel['e85']!.gain, closeTo(0.608, 0.005));
      expect(p.pumpGainByFuel['e85']!.samples, 1);
      expect(p.pumpGainByFuel['e85']!.updatedAt, _t0);
      expect(p.pumpGain, closeTo(0.608, 0.005), reason: 'scalar blends too');
      expect(p.pumpGainSamples, 1);
    });

    test('an E10 window blends its own entry, not the E85 one', () async {
      await repo.save(const VehicleProfile(
          id: 'car',
          name: 'Flex',
          multiFuelCapable: true,
          pumpGain: 0.6,
          pumpGainSamples: 1,
          pumpGainByFuel: {'e85': PumpGainEntry(gain: 0.6, samples: 1)}));
      final e10Fills = [
        fills.first,
        fills.last.copyWith(fuelType: FuelType.e10),
      ];
      final o = await learner.evaluate(
          vehicleId: 'car',
          closing: e10Fills.last,
          fillUps: e10Fills,
          tripSummariesById: trips);
      final r = o.result!;
      expect(r.fuelKey, 'e10');
      expect(r.previousGain, 1.0, reason: 'fresh grade starts at 1.0');
      expect(r.newGain, closeTo(0.608, 0.005), reason: 'first sample: face value');
      final p = repo.getById('car')!;
      expect(p.pumpGainByFuel['e85']!.gain, 0.6, reason: 'untouched');
      expect(p.pumpGainByFuel['e10']!.samples, 1);
      // Scalar: 0.5 × 0.608 + 0.5 × 0.6 ≈ 0.604.
      expect(p.pumpGain, closeTo(0.604, 0.005));
    });
  });
}

class _FakeSettingsStorage implements SettingsStorage {
  final Map<String, dynamic> _data = {};
  @override
  dynamic getSetting(String key) => _data[key];
  @override
  Future<void> putSetting(String key, dynamic value) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }

  @override
  bool get isSetupComplete => false;
  @override
  bool get isSetupSkipped => false;
  @override
  Future<void> skipSetup() async {}
  @override
  Future<void> resetSetupSkip() async {}
}
