// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/obd2/domain/obd2_fuzzy_context.dart';
import 'package:tankstellen/features/obd2/domain/signal_latch_store.dart';
import 'package:tankstellen/features/obd2/domain/vehicle_signal.dart';

/// #4233 — the OBD2 side of the fuzzy wiring: the context handed to the
/// stage carries each latch's REAL age (#4159), the η_v profile rule, and —
/// as a structural guard beside the identity goldens — that only the
/// estimated branches call the stage.
class _Clock {
  _Clock(this.now);
  DateTime now;
  DateTime call() => now;
}

void main() {
  final t0 = DateTime.utc(2026, 9, 16, 9);

  group('obd2LiveFuzzyContext', () {
    test('each reading carries the age of its latch, not zero', () {
      final clock = _Clock(t0);
      final store = SignalLatchStore(clock: clock.call);
      store.write(VehicleSignal.engineRpm, 2400);
      clock.now = t0.add(const Duration(milliseconds: 2500));
      store.write(VehicleSignal.vehicleSpeed, 64);
      store.write(VehicleSignal.coolantTemp, 71);
      final now = t0.add(const Duration(seconds: 5));

      final ctx = obd2LiveFuzzyContext(store,
          now: now,
          vehicle: const VehicleProfile(id: 'v', name: 'v', curbWeightKg: 1180));

      expect(ctx.rpm?.value, 2400);
      expect(ctx.rpm?.ageSeconds, 5.0);
      expect(ctx.speedKmh?.value, 64);
      expect(ctx.speedKmh?.ageSeconds, 2.5);
      expect(ctx.coolantTempC?.ageSeconds, 2.5);
      expect(ctx.vehicleMassKg?.value, 1180);
    });

    test('what never landed, and what OBD2 cannot supply, stays missing', () {
      final ctx = obd2LiveFuzzyContext(SignalLatchStore(clock: () => t0),
          now: t0, vehicle: null);
      expect(ctx.speedKmh, isNull);
      expect(ctx.rpm, isNull);
      expect(ctx.engineLoadPercent, isNull);
      expect(ctx.throttlePercent, isNull);
      expect(ctx.oilTempC, isNull);
      expect(ctx.vehicleMassKg, isNull);
      expect(ctx.accelMps2, isNull);
      expect(ctx.gradePercent, isNull);
      expect(ctx.yawRateRadPerS, isNull);
      expect(ctx.stopsPerMinute, isNull);
      expect(ctx.physicsFuelRateLPerHour, isNull,
          reason: 'the stage owns the physics input');
    });
  });

  group('profileVolumetricEfficiency (#1422)', () {
    const cold = VehicleProfile(id: 'v', name: 'v');
    test('no profile → null', () {
      expect(profileVolumetricEfficiency(null, hasReferenceVehicle: true),
          isNull);
    });
    test('no reference row → the stored value, even the legacy 0.85', () {
      expect(profileVolumetricEfficiency(cold, hasReferenceVehicle: false),
          0.85);
    });
    test('cold-start 0.85 with nothing learned → null (helper applies)', () {
      expect(profileVolumetricEfficiency(cold, hasReferenceVehicle: true),
          isNull);
    });
    test('learned or non-default → the stored value', () {
      expect(
          profileVolumetricEfficiency(
              cold.copyWith(volumetricEfficiencySamples: 2),
              hasReferenceVehicle: true),
          0.85);
      expect(
          profileVolumetricEfficiency(
              cold.copyWith(volumetricEfficiency: 0.91),
              hasReferenceVehicle: true),
          0.91);
    });
  });

  group('only the estimated branches reach the stage (structural)', () {
    const snapshot =
        'lib/features/obd2/data/session/live_sample_snapshot_fuel_rate.dart';

    /// Violations in [source]: the stage must be called exactly for MAF and
    /// speed-density, and never before the last measured-branch return.
    List<String> check(String source, {required String lastMeasured}) {
      final problems = <String>[];
      final calls = RegExp(
              r'estimatedFuelRateLPerHour\([\s\S]*?FuzzyPhysicsBasis\.(\w+)')
          .allMatches(source)
          .map((m) => m.group(1))
          .toList();
      if (calls.join(',') != 'maf,speedDensity') {
        problems.add('stage calls by basis: $calls');
      }
      final firstCall = source.indexOf('estimatedFuelRateLPerHour(');
      final measured = source.lastIndexOf(lastMeasured);
      if (measured < 0 || firstCall < measured) {
        problems.add('a measured branch reaches the stage');
      }
      return problems;
    }

    // #4315 — the pull reader was the second case; it was deleted, so the
    // live snapshot is the only producer to check.
    final cases = {
      snapshot: 'FuelRateSourceTag.pid5E;',
    };

    for (final c in cases.entries) {
      test(c.key, () {
        expect(check(File(c.key).readAsStringSync(), lastMeasured: c.value),
            isEmpty);
      });
    }

    test('the check can fail (mutation)', () {
      final real = File(snapshot).readAsStringSync();
      // A measured branch routed through the stage.
      final measuredMutant = real.replaceFirst(
          'return lph;',
          'return estimatedFuelRateLPerHour(lph, FuzzyPhysicsBasis.maf, '
              'pumpGain: pumpGain);');
      expect(check(measuredMutant, lastMeasured: cases[snapshot]!),
          isNotEmpty);
      // The speed-density branch bypassing it.
      final bypassMutant = real.replaceFirst(
          'FuzzyPhysicsBasis.speedDensity', 'FuzzyPhysicsBasis.maf');
      expect(check(bypassMutant, lastMeasured: cases[snapshot]!), isNotEmpty);
    });
  });
}
