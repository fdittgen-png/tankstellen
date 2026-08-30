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
