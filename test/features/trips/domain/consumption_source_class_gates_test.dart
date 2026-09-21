// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// #4236 (parent #4235) — the suite-integration gate for consumption
// provenance and calibration semantics.
//
// ## What this file is for
//
// The semantics #4236 lists are each covered somewhere:
// `calibrated_trip_figures_test`, `calibrated_trip_figures_fuel_key_test`,
// `tank_report_calibrated_test`, `pump_gain_learner_test`,
// `physics_scale_calibrator_test`. What did NOT exist is one place that
// fails when a mutation crosses those semantics — which is what the
// issue's acceptance list actually asks for ("a deliberate X mutation
// fails"). These are those mutation gates, parameterized by source
// class, and they are deliberately assertion-dense rather than
// scenario-pretty.
//
// ## What is NOT here, and why
//
// #4236 also asks that "model/rule/calibration versions survive
// persistence and replay". There is no such field to gate: nothing in
// lib/features/trips, lib/core/domain or lib/features/fill_ups carries a
// modelVersion / ruleVersion / calibrationVersion, and
// `GpsCalibrationMatrix` tracks maturity through
// `fillUpReconciliationCount` + `residualVariance` + `lastReconciledAt`
// instead. Making versions first-class is #4230's acceptance item ("Model
// and calibration versions are first-class"), so that bullet belongs
// AFTER #4230 lands, not invented here under a test issue.
//
// The corpus-backed accuracy thresholds (integrated-litres error by
// source/coverage class, hold-out journeys) need #4231's replay corpus,
// which does not exist yet: `test/fixtures` holds 38 provider fixtures
// and zero trip traces. Those thresholds stay with #4231's successor.
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/pump_gain_entry.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/trips/data/trip_summary_codec.dart';
import 'package:tankstellen/features/trips/domain/calibrated_trip_figures.dart';
import 'package:tankstellen/features/trips/domain/trip_fuel_source.dart';
import 'package:tankstellen/features/trips/domain/trip_summary.dart';

final _t0 = DateTime(2026, 9, 15, 8);

/// The fuel-source provenance strings the recorder actually stamps.
/// `pid5E`/`pid9D` are native ECU fuel rate; the rest are inferred.
const _measuredSources = ['pid5E', 'pid9D', 'pidA2'];
const _estimatedSources = ['maf', 'speedDensity'];

TripSummary _trip({
  double km = 100,
  double? liters = 10.0,
  String? dominant,
  double? gain,
  double? veUsed,
  String? fuelKey,
  TripKind kind = TripKind.gpsPlusObd2,
  double? estimatedAvg,
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
      pumpGainFuelKey: fuelKey,
      kind: kind,
    );

void main() {
  const calibrated =
      VehicleProfile(id: 'v', name: 'x', pumpGain: 0.72, pumpGainSamples: 1);

  group('source class decides whether fuel may be rescaled at all', () {
    for (final source in _measuredSources) {
      test('$source is measured and is NEVER pump-gain scaled', () {
        final f = CalibratedTripFigures.of(
            _trip(dominant: source, gain: 0.9), calibrated);
        expect(tripFuelSourceKind(_trip(dominant: source)),
            TripFuelSourceKind.measured);
        expect(f.reExpressed, isFalse,
            reason: 'the ECU metered this fuel; a pump gain describes an '
                'ESTIMATE, so applying it would corrupt a measurement');
        expect(f.liters, 10.0);
        expect(f.scale, 1.0);
      });
    }

    for (final source in _estimatedSources) {
      test('$source is estimated and enters the single scaled path', () {
        final f = CalibratedTripFigures.of(
            _trip(dominant: source, gain: 0.9), calibrated);
        expect(tripFuelSourceKind(_trip(dominant: source)),
            TripFuelSourceKind.estimated);
        expect(f.scale, closeTo(0.72 / 0.9, 1e-9));
      });
    }

    test('GPS-only and unknown-provenance trips are not rescaled', () {
      expect(
          CalibratedTripFigures.of(_trip(kind: TripKind.gpsOnly), calibrated)
              .reExpressed,
          isFalse);
      expect(CalibratedTripFigures.of(_trip(), calibrated).reExpressed, isFalse,
          reason: 'a legacy trip with no recorded provenance must never be '
              'GUESSED into the estimated path');
    });
  });

  group('pump gain is applied exactly once', () {
    test('a trip recorded at gain g shows at gainNow, not g x gainNow', () {
      final f = CalibratedTripFigures.of(
          _trip(dominant: 'speedDensity', gain: 0.9), calibrated);
      // The mutation this catches: scale = gainNow (0.72) instead of
      // gainNow/recorded (0.8), i.e. re-applying a gain already baked in.
      expect(f.scale, closeTo(0.8, 1e-9));
      expect(f.liters, closeTo(8.0, 1e-9));
      expect(f.liters, isNot(closeTo(10.0 * 0.72, 1e-6)),
          reason: 'that figure is the double application');
    });

    test('recorded gain == gain now leaves the stored figure untouched', () {
      final f = CalibratedTripFigures.of(
          _trip(dominant: 'maf', gain: 0.72), calibrated);
      expect(f.scale, 1.0);
      expect(f.liters, 10.0);
      expect(f.calibrated, isTrue, reason: 'still calibrated, just unchanged');
    });
  });

  group('per-fuel calibration stays isolated', () {
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

    test('E85 cannot silently borrow the E10 gain, or vice versa', () {
      final t = _trip(dominant: 'speedDensity');
      expect(CalibratedTripFigures.of(t.copyWith(pumpGainFuelKey: 'e85'), flex)
              .scale,
          closeTo(0.7, 1e-9));
      expect(CalibratedTripFigures.of(t.copyWith(pumpGainFuelKey: 'e10'), flex)
              .scale,
          closeTo(0.8, 1e-9));
    });

    test('an unknown grade falls back to the scalar, never to the tank\'s '
        'grade today (#4220)', () {
      final t = _trip(dominant: 'speedDensity');
      expect(CalibratedTripFigures.of(t, flex).scale, 1.0,
          reason: 'no recorded grade: re-expressing at whatever is in the '
              'tank NOW is the #4220 defect');
      expect(CalibratedTripFigures.of(t, flex, fuelKey: 'e98').scale,
          closeTo(0.9, 1e-9), reason: 'no per-fuel entry -> scalar');
    });
  });

  group('retro-calibration never rewrites what was recorded', () {
    test('the stored summary is untouched by re-expression', () {
      final stored = _trip(dominant: 'speedDensity', gain: 0.9);
      final f = CalibratedTripFigures.of(stored, calibrated);
      expect(f.liters, closeTo(8.0, 1e-9));
      expect(stored.fuelLitersConsumed, 10.0,
          reason: 'calibration is a VIEW; mutating the recording would '
              'destroy the evidence the learner needs');
      expect(stored.pumpGainApplied, 0.9);
      expect(stored.dominantFuelSource, 'speedDensity');
    });

    test('provenance and gain survive the persistence round trip', () {
      final stored = _trip(
          dominant: 'pid5E', gain: 0.9, veUsed: 0.85, fuelKey: 'e10');
      final back = tripSummaryFromJson(tripSummaryToJson(stored));
      expect(back.dominantFuelSource, 'pid5E');
      expect(back.pumpGainApplied, 0.9);
      expect(back.volumetricEfficiencyUsed, 0.85);
      expect(back.pumpGainFuelKey, 'e10');
      expect(back.fuelLitersConsumed, 10.0);
      // The point of the round trip: the source class a replay computes
      // must equal the one the live path computed.
      expect(tripFuelSourceKind(back), tripFuelSourceKind(stored));
      expect(tripFuelSourceKind(back), TripFuelSourceKind.measured);
    });

    test('a measured trip stays measured after persistence, so it stays '
        'unscalable', () {
      final back = tripSummaryFromJson(
          tripSummaryToJson(_trip(dominant: 'pid5E', gain: 0.9)));
      expect(CalibratedTripFigures.of(back, calibrated).reExpressed, isFalse);
    });
  });
}
