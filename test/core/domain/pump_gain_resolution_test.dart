// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3918 — the pump-gain resolution order every fuel-rate reader follows:
// pumpGainByFuel[fuelKey] → scalar pumpGain → 1.0, and the fuel-key
// order tank grade → ECU session key → profile fuel.
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/pump_gain_entry.dart';
import 'package:tankstellen/core/domain/pump_gain_resolution.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';

final _at = DateTime(2026, 9, 1, 10);

void main() {
  const flex = VehicleProfile(
    id: 'v',
    name: 'Flex',
    multiFuelCapable: true,
    preferredFuelType: 'e85',
    pumpGain: 0.9,
    pumpGainSamples: 2,
    pumpGainByFuel: {
      'e85': PumpGainEntry(gain: 0.72, samples: 1),
      'e10': PumpGainEntry(gain: 0.8, samples: 1),
    },
  );

  test('per-fuel entry wins for its key', () {
    final r = resolvePumpGain(flex, fuelKey: 'e85');
    expect(r.gain, 0.72);
    expect(r.source, PumpGainSource.perFuel);
    expect(r.fuelKey, 'e85');
    expect(r.samples, 1);
    expect(r.correctionPercent, -28);
    expect(resolvePumpGain(flex, fuelKey: 'e10').gain, 0.8);
  });

  test('key lookup is case/whitespace-insensitive', () {
    expect(resolvePumpGain(flex, fuelKey: ' E85 ').gain, 0.72);
    expect(normalizePumpGainFuelKey('  '), isNull);
    expect(normalizePumpGainFuelKey(null), isNull);
  });

  test('a grade without an entry falls back to the scalar', () {
    final r = resolvePumpGain(flex, fuelKey: 'e98');
    expect(r.gain, 0.9);
    expect(r.source, PumpGainSource.vehicle);
    expect(r.fuelKey, isNull);
    expect(r.samples, 2);
    expect(resolvePumpGain(flex).gain, 0.9, reason: 'no key → scalar');
  });

  test('an unlearned default entry must not shadow a learned scalar', () {
    const v = VehicleProfile(
      id: 'v',
      name: 'x',
      pumpGain: 0.8,
      pumpGainSamples: 1,
      pumpGainByFuel: {'e10': PumpGainEntry()},
    );
    expect(resolvePumpGain(v, fuelKey: 'e10').source, PumpGainSource.vehicle);
    expect(resolvePumpGain(v, fuelKey: 'e10').gain, 0.8);
  });

  test('nothing learned → 1.0, uncalibrated; null vehicle likewise', () {
    const v = VehicleProfile(id: 'v', name: 'x');
    expect(resolvePumpGain(v, fuelKey: 'e10'), PumpGainResolution.none);
    expect(resolvePumpGain(v).isCalibrated, isFalse);
    expect(resolvePumpGain(null, fuelKey: 'e10').gain, 1.0);
  });

  test('a restored scalar ≠ 1.0 with zero samples still counts as the '
      'vehicle gain (backup without the counter)', () {
    const v = VehicleProfile(id: 'v', name: 'x', pumpGain: 1.1);
    expect(resolvePumpGain(v).source, PumpGainSource.vehicle);
    expect(resolvePumpGain(v).gain, 1.1);
  });

  test('fuel-key order: tank grade → ECU session key → profile fuel', () {
    final withTank = flex.copyWith(tankFuelKey: 'E10');
    expect(pumpGainFuelKeyFor(withTank, sessionFuelKey: 'e85'), 'e10');
    expect(pumpGainFuelKeyFor(flex, sessionFuelKey: 'petrol'), 'petrol');
    expect(pumpGainFuelKeyFor(flex), 'e85');
    expect(pumpGainFuelKeyFor(null), isNull);
    expect(pumpGainFuelKeyFor(const VehicleProfile(id: 'v', name: 'x')), isNull);
  });

  test('updatedAt rides along for the "recalculated after the fill of …" line', () {
    final v = flex.copyWith(pumpGainByFuel: {
      'e85': PumpGainEntry(gain: 0.7, samples: 1, updatedAt: _at),
    });
    expect(resolvePumpGain(v, fuelKey: 'e85').updatedAt, _at);
  });

  test('PumpGainEntry JSON round-trip (JSONB field on the profile)', () {
    final e = PumpGainEntry(gain: 0.72, samples: 3, updatedAt: _at);
    final back = PumpGainEntry.fromJson(e.toJson());
    expect(back, e);
    final v = flex.copyWith(tankFuelKey: 'e85');
    final restored = VehicleProfile.fromJson(v.toJson());
    expect(restored.pumpGainByFuel['e85']?.gain, 0.72);
    expect(restored.tankFuelKey, 'e85');
    // Legacy JSON without the fields → defaults.
    final legacy = VehicleProfile.fromJson({'id': 'v', 'name': 'x'});
    expect(legacy.pumpGainByFuel, isEmpty);
    expect(legacy.tankFuelKey, isNull);
  });
}
