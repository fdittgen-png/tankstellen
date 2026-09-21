// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// #4220 — a trip's estimated fuel is re-expressed at the gain of the fuel
// it was RECORDED on, never at whatever grade the tank holds today. The
// flex-fuel failure: an E10 trip (gain 1.05) shown × 0.62 / 1.05 = −41 %
// once the tank switched to E85.
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/pump_gain_entry.dart';
import 'package:tankstellen/core/domain/pump_gain_resolution.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/trips/data/trip_summary_codec.dart';
import 'package:tankstellen/features/trips/domain/calibrated_trip_figures.dart';
import 'package:tankstellen/features/trips/domain/trip_summary.dart';

TripSummary _mafTrip({double? gain, String? fuelKey}) => TripSummary(
      distanceKm: 100,
      maxRpm: 3000,
      highRpmSeconds: 0,
      idleSeconds: 0,
      harshBrakes: 0,
      harshAccelerations: 0,
      fuelLitersConsumed: 10.5,
      avgLPer100Km: 10.5,
      startedAt: DateTime(2026, 8, 20, 8),
      pumpGainApplied: gain,
      pumpGainFuelKey: fuelKey,
      dominantFuelSource: 'maf',
    );

VehicleProfile _flex({double e10Gain = 1.05}) => VehicleProfile(
      id: 'flex',
      name: 'Flex',
      multiFuelCapable: true,
      tankFuelKey: 'e85',
      pumpGain: 0.9,
      pumpGainSamples: 4,
      pumpGainByFuel: {
        'e10': PumpGainEntry(gain: e10Gain, samples: 2),
        'e85': const PumpGainEntry(gain: 0.62, samples: 3),
      },
    );

void main() {
  group('CalibratedTripFigures uses the trip\'s own fuel (#4220)', () {
    test('an E10 trip stays at the E10 gain while the tank holds E85', () {
      final f = CalibratedTripFigures.of(
          _mafTrip(gain: 1.05, fuelKey: 'e10'), _flex());

      expect(f.liters, closeTo(10.5, 1e-9),
          reason: 'before #4220: 10.5 × 0.62 / 1.05 = 6.2 L — the E85 gain '
              'applied to a trip that burned E10');
      expect(f.reExpressed, isFalse);
      expect(f.resolution.fuelKey, 'e10');
    });

    test('a later E10 recalibration re-expresses it at the new E10 gain', () {
      final f = CalibratedTripFigures.of(
          _mafTrip(gain: 1.05, fuelKey: 'e10'), _flex(e10Gain: 1.10));

      expect(f.liters, closeTo(10.5 * 1.10 / 1.05, 1e-9));
      expect(f.reExpressed, isTrue);
    });

    test('an explicit fuelKey still overrides (the tank report)', () {
      final f = CalibratedTripFigures.of(
          _mafTrip(gain: 1.05, fuelKey: 'e10'), _flex(),
          fuelKey: 'e85');

      expect(f.liters, closeTo(10.5 * 0.62 / 1.05, 1e-9));
    });

    test('a legacy trip without a key on a per-fuel vehicle is left alone',
        () {
      final f = CalibratedTripFigures.of(_mafTrip(gain: 1.05), _flex());

      expect(f.liters, closeTo(10.5, 1e-9),
          reason: 'which grade it burned is unknown — never guess one');
      expect(f.reExpressed, isFalse);
    });

    test('a legacy trip on a single-fuel vehicle keeps the scalar re-expression',
        () {
      const single = VehicleProfile(
          id: 's', name: 'Single', pumpGain: 0.72, pumpGainSamples: 1);
      final f = CalibratedTripFigures.of(_mafTrip(gain: 1.0), single);

      expect(f.liters, closeTo(10.5 * 0.72, 1e-9));
    });
  });

  group('resolvePumpGain reports the key it looked up (#4220)', () {
    test('uncalibrated, scalar and per-fuel answers all carry it', () {
      const bare = VehicleProfile(id: 'b', name: 'Bare');
      final none = resolvePumpGain(bare, fuelKey: ' E10 ');
      expect(none.source, PumpGainSource.uncalibrated);
      expect(none.gain, 1.0);
      expect(none.requestedFuelKey, 'e10',
          reason: 'a trip recorded before the first calibration must still '
              'know its grade once one lands');

      const scalar = VehicleProfile(
          id: 's', name: 'S', pumpGain: 0.8, pumpGainSamples: 2);
      expect(resolvePumpGain(scalar, fuelKey: 'diesel').requestedFuelKey,
          'diesel');

      expect(resolvePumpGain(_flex(), fuelKey: 'e85').requestedFuelKey, 'e85');
      expect(resolvePumpGain(bare), same(PumpGainResolution.none));
    });
  });

  test('the fuel key survives the codec; legacy JSON reads as null', () {
    final json = tripSummaryToJson(_mafTrip(gain: 1.05, fuelKey: 'e10'));
    expect(json['pgk'], 'e10');
    expect(tripSummaryFromJson(json).pumpGainFuelKey, 'e10');

    final legacy = tripSummaryToJson(_mafTrip(gain: 1.05))..remove('pgk');
    expect(legacy.containsKey('pgk'), isFalse, reason: 'absent, not null');
    expect(tripSummaryFromJson(legacy).pumpGainFuelKey, isNull);
  });
}
