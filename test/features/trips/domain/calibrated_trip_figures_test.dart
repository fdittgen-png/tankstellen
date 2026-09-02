// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3918 / #3919 — the retro math (shownLitres = stored × gainNow / pg,
// estimated fuel only) and the fuel-source classification behind the
// badges.
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/pump_gain_entry.dart';
import 'package:tankstellen/core/domain/pump_gain_resolution.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/trips/domain/calibrated_trip_figures.dart';
import 'package:tankstellen/features/trips/domain/trip_fuel_source.dart';
import 'package:tankstellen/features/trips/domain/trip_sample.dart';
import 'package:tankstellen/features/trips/domain/trip_summary.dart';

final _t0 = DateTime(2026, 8, 20, 8);

TripSummary _trip({
  double km = 100,
  double? liters = 10.5,
  double? gain,
  String? dominant,
  double? veUsed,
  TripKind kind = TripKind.gpsPlusObd2,
  double? estimatedAvg,
  bool virtual = false,
}) =>
    TripSummary(
      distanceKm: km,
      maxRpm: 3000,
      highRpmSeconds: 0,
      idleSeconds: 0,
      harshBrakes: 0,
      harshAccelerations: 0,
      fuelLitersConsumed: liters,
      avgLPer100Km: liters == null ? null : liters / km * 100,
      estimatedAvgLPer100Km: estimatedAvg,
      startedAt: _t0,
      pumpGainApplied: gain,
      dominantFuelSource: dominant,
      volumetricEfficiencyUsed: veUsed,
      kind: kind,
      isVirtual: virtual,
    );

const _calibrated = VehicleProfile(
  id: 'v',
  name: 'x',
  pumpGain: 0.72,
  pumpGainSamples: 1,
);

void main() {
  group('tripFuelSourceKind', () {
    test('dominant provenance decides', () {
      expect(tripFuelSourceKind(_trip(dominant: 'pid5E')),
          TripFuelSourceKind.measured);
      expect(tripFuelSourceKind(_trip(dominant: 'pid9D')),
          TripFuelSourceKind.measured);
      expect(tripFuelSourceKind(_trip(dominant: 'maf')),
          TripFuelSourceKind.estimated);
      expect(tripFuelSourceKind(_trip(dominant: 'speedDensity')),
          TripFuelSourceKind.estimated);
    });

    test('legacy: all-speed-density (veUsed) → estimated; unknown → none', () {
      expect(tripFuelSourceKind(_trip(veUsed: 0.85)),
          TripFuelSourceKind.estimated);
      expect(tripFuelSourceKind(_trip()), TripFuelSourceKind.none,
          reason: 'a measured legacy trip must never be guessed estimated');
    });

    test('GPS: gpsOnly kind, or the #3576 estimate fields only', () {
      expect(tripFuelSourceKind(_trip(kind: TripKind.gpsOnly)),
          TripFuelSourceKind.gps);
      expect(tripFuelSourceKind(_trip(liters: null, estimatedAvg: 6.0)),
          TripFuelSourceKind.gps);
      expect(tripFuelSourceKind(_trip(liters: null)), TripFuelSourceKind.none);
      expect(tripFuelSourceKind(_trip(virtual: true)), TripFuelSourceKind.none);
    });
  });

  group('dominantFuelSourceOf', () {
    TripSample s(String? fs) =>
        TripSample(timestamp: _t0, speedKmh: 50, fuelSource: fs);
    test('majority wins, none/null ignored', () {
      expect(dominantFuelSourceOf([s('maf'), s('pid5E'), s('pid5E'), s(null), s('none')]),
          'pid5E');
      expect(dominantFuelSourceOf([s(null), s('none')]), isNull);
      expect(dominantFuelSourceOf(const []), isNull);
    });
  });

  group('CalibratedTripFigures.of', () {
    test('the field case: a pre-learner recording (pg null ≡ 1.0) shows at '
        'the gain the pump established', () {
      final f = CalibratedTripFigures.of(_trip(veUsed: 0.85), _calibrated);
      expect(f.reExpressed, isTrue);
      expect(f.scale, closeTo(0.72, 1e-9));
      expect(f.liters, closeTo(10.5 * 0.72, 1e-9));
      expect(f.lPer100Km, closeTo(10.5 * 0.72, 1e-9));
      expect(f.calibrated, isTrue);
      expect(f.correctionPercent, -28);
      expect(f.resolution.source, PumpGainSource.vehicle);
    });

    test('shownLitres = stored × gainNow / pg', () {
      final f = CalibratedTripFigures.of(
          _trip(dominant: 'speedDensity', gain: 0.9), _calibrated);
      expect(f.scale, closeTo(0.72 / 0.9, 1e-9));
      expect(f.liters, closeTo(10.5 * 0.72 / 0.9, 1e-9));
      expect(f.gainApplied, 0.9);
    });

    test('pg == gainNow → untouched, but still "calibrated" for the badge', () {
      final f = CalibratedTripFigures.of(
          _trip(dominant: 'maf', gain: 0.72), _calibrated);
      expect(f.reExpressed, isFalse);
      expect(f.scale, 1.0);
      expect(f.liters, 10.5);
      expect(f.calibrated, isTrue);
      expect(f.correctionPercent, -28);
    });

    test('measured fuel is NEVER rescaled', () {
      final f = CalibratedTripFigures.of(
          _trip(dominant: 'pid5E', gain: 0.9), _calibrated);
      expect(f.reExpressed, isFalse);
      expect(f.liters, 10.5);
      expect(f.calibrated, isFalse);
      expect(f.correctionPercent, 0);
    });

    test('unknown-branch legacy trips and GPS trips pass through', () {
      expect(CalibratedTripFigures.of(_trip(), _calibrated).reExpressed, isFalse);
      expect(
          CalibratedTripFigures.of(_trip(kind: TripKind.gpsOnly), _calibrated)
              .reExpressed,
          isFalse);
    });

    test('uncalibrated vehicle: a trip recorded at 0.9 is shown at 1.0 '
        '(the reset case) — and a null vehicle passes through', () {
      const fresh = VehicleProfile(id: 'v', name: 'x');
      final f = CalibratedTripFigures.of(
          _trip(dominant: 'maf', gain: 0.9), fresh);
      expect(f.scale, closeTo(1 / 0.9, 1e-9));
      expect(f.calibrated, isTrue, reason: 'it was recorded WITH a gain');
      final g = CalibratedTripFigures.of(_trip(dominant: 'maf', gain: 0.9), null);
      expect(g.reExpressed, isFalse);
      expect(g.liters, 10.5);
    });

    test('a multi-fuel vehicle resolves the per-fuel gain by fuelKey, else '
        'the tank grade', () {
      const flex = VehicleProfile(
        id: 'v',
        name: 'Flex',
        multiFuelCapable: true,
        tankFuelKey: 'e85',
        pumpGain: 0.9,
        pumpGainSamples: 1,
        pumpGainByFuel: {
          'e85': PumpGainEntry(gain: 0.7, samples: 1),
          'e10': PumpGainEntry(gain: 0.8, samples: 1),
        },
      );
      final t = _trip(dominant: 'speedDensity');
      expect(CalibratedTripFigures.of(t, flex).scale, closeTo(0.7, 1e-9));
      expect(CalibratedTripFigures.of(t, flex, fuelKey: 'e10').scale,
          closeTo(0.8, 1e-9));
      expect(CalibratedTripFigures.of(t, flex, fuelKey: 'e98').scale,
          closeTo(0.9, 1e-9),
          reason: 'no entry → scalar');
    });
  });
}
