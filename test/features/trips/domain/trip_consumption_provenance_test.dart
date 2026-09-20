// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/consumption_estimate.dart';
import 'package:tankstellen/core/domain/pump_gain_resolution.dart';
import 'package:tankstellen/features/obd2/domain/services/obd2_gps_estimate_fallback.dart';
import 'package:tankstellen/features/trips/data/trip_history_entry.dart';
import 'package:tankstellen/features/trips/data/trip_summary_codec.dart';
import 'package:tankstellen/features/trips/data/trips_sync_json.dart';
import 'package:tankstellen/features/trips/domain/services/gps_live_estimate_folder.dart';
import 'package:tankstellen/features/trips/domain/trip_consumption_provenance.dart';
import 'package:tankstellen/features/trips/domain/trip_recorder.dart';
import 'package:tankstellen/features/trips/providers/gps_trip_fuel_backfill.dart';

/// #4233 — the fuzzy model / rules / calibration version travels on the
/// trip (ADR 0024 §5): stamped by the pure provenance function at the two
/// non-lifecycle finalisers, only on the figure each produced; persisted
/// under `cmv` through the one codec every store and TankSync share; absent
/// or malformed → null, never an invented version.
const _base = TripSummary(
  distanceKm: 1.2,
  maxRpm: 0,
  highRpmSeconds: 0,
  idleSeconds: 0,
  harshBrakes: 0,
  harshAccelerations: 0,
);

List<TripSample> _moving({double? fuelRate}) {
  final t0 = DateTime.utc(2026, 9, 16, 7);
  return [
    for (var i = 0; i < 12; i++)
      TripSample(
        timestamp: t0.add(Duration(seconds: i)),
        speedKmh: 10.0 + 4 * i,
        fuelRateLPerHour: fuelRate,
      ),
  ];
}

GpsLiveEstimateFolder _foldedFolder(List<TripSample> samples) {
  final folder = GpsLiveEstimateFolder.forVehicle(null, null);
  for (final s in samples) {
    folder.fold(s);
  }
  return folder;
}

void main() {
  group('tripConsumptionVersion', () {
    const calibrated = PumpGainResolution(
        gain: 0.92, source: PumpGainSource.vehicle, samples: 5);

    test('model and rules come from the one production engine', () {
      final v = tripConsumptionVersion();
      expect(v.model, 1);
      expect(v.rules, 1);
      expect(v.calibration, isNull,
          reason: 'no gain on the figure → not attributable');
    });

    test('calibration only when the calibrated gain IS the applied gain', () {
      expect(
          tripConsumptionVersion(
                  pumpGainApplied: 0.92, resolution: calibrated)
              .calibration,
          5);
      expect(
          tripConsumptionVersion(pumpGainApplied: 0.9, resolution: calibrated)
              .calibration,
          isNull,
          reason: 'the gain moved since the trip was integrated');
      expect(
          tripConsumptionVersion(
                  pumpGainApplied: 1.0, resolution: PumpGainResolution.none)
              .calibration,
          isNull,
          reason: 'an uncalibrated gain is no generation');
    });
  });

  group('the cmv codec key', () {
    const v = ConsumptionModelVersion(model: 1, rules: 1, calibration: 3);

    test('round-trips, and is omitted when null', () {
      final json = tripSummaryToJson(_base.copyWith(consumptionVersion: v));
      expect(json['cmv'], {'model': 1, 'rules': 1, 'calibration': 3});
      expect(tripSummaryFromJson(json).consumptionVersion, v);
      expect(tripSummaryToJson(_base).containsKey('cmv'), isFalse);
    });

    test('a legacy or malformed record decodes to null', () {
      final legacy = tripSummaryToJson(_base);
      expect(tripSummaryFromJson(legacy).consumptionVersion, isNull);
      for (final bad in [
        'v1',
        {'model': 0, 'rules': 1},
        {'rules': 1},
      ]) {
        expect(
            tripSummaryFromJson({...legacy, 'cmv': bad}).consumptionVersion,
            isNull,
            reason: '$bad');
      }
    });

    test('survives the history entry and the TankSync summary payload', () {
      final entry = TripHistoryEntry(
        id: 't1',
        vehicleId: 'v1',
        summary: _base.copyWith(consumptionVersion: v),
        samples: _moving(),
      );
      final synced = compactSummaryJson(entry);
      expect(TripHistoryEntry.fromJson(synced).summary.consumptionVersion, v);
      expect(TripHistoryEntry.fromJson(entry.toJson()).summary
          .consumptionVersion, v);
    });
  });

  group('the finalisers stamp only the figure they produced', () {
    test('no-fuel-PID fallback: stamped when it fills', () {
      final fill = Obd2GpsEstimateFallback.fillWhenNoFuelPid(
          summary: _base, samples: _moving(), vehicle: null);
      expect(fill.summary.avgLPer100Km, isNotNull);
      expect(fill.summary.consumptionVersion, tripConsumptionVersion());
    });

    test('no-fuel-PID fallback: a measured trip is returned unstamped', () {
      final fill = Obd2GpsEstimateFallback.fillWhenNoFuelPid(
          summary: _base, samples: _moving(fuelRate: 4.2), vehicle: null);
      expect(fill.summary.consumptionVersion, isNull);
    });

    test('backfill: the live-folder figure is stamped', () {
      final samples = _moving();
      final s = backfillGpsTripFuel(_base,
          samples: samples,
          vehicleCalibration: null,
          liveFolder: _foldedFolder(samples));
      expect(s.estimatedAvgLPer100Km, isNotNull);
      expect(s.consumptionVersion, tripConsumptionVersion());
    });

    test('backfill: the batch figure stays unversioned (F5)', () {
      final samples = _moving();
      final s = backfillGpsTripFuel(_base.copyWith(kind: TripKind.gpsOnly),
          samples: samples,
          vehicleCalibration: null,
          liveFolder: _foldedFolder(samples));
      expect(s.avgLPer100Km, isNotNull, reason: 'the batch path must run');
      expect(s.consumptionVersion, isNull);
    });

    test('backfill: no figure at all, no stamp', () {
      final s = backfillGpsTripFuel(_base,
          samples: const [], vehicleCalibration: null, liveFolder: null);
      expect(s.consumptionVersion, isNull);
    });
  });

  group('the stamping call sites still exist (structural)', () {
    // If a pipeline stops calling its finaliser, its trips silently lose the
    // version stamp — no behaviour test of the finaliser would notice.
    const sites = {
      'lib/features/obd2/providers/obd2_recording_pipeline.dart':
          'Obd2GpsEstimateFallback.fillWhenNoFuelPid(',
      'lib/features/trips/providers/gps_only_recording_pipeline.dart':
          'backfillGpsTripFuel(',
      'lib/features/obd2/domain/services/obd2_gps_estimate_fallback.dart':
          'tripConsumptionVersion(',
      'lib/features/trips/providers/gps_trip_fuel_backfill.dart':
          'tripConsumptionVersion(',
      // #4330 — the finalise path the #4233 note called "the documented
      // follow-up": OBD2 measured/estimated trips, grace-window expiry,
      // recovered snapshots and paused recovery all come through here.
      'lib/features/obd2/data/session/trip_recording_controller_summary.dart':
          'tripConsumptionVersion(',
    };

    /// Files in [sources] that no longer call their site (comments ignored).
    List<String> missing(Map<String, String> sources) => [
          for (final e in sites.entries)
            if (!sources[e.key]!
                .split('\n')
                .where((l) => !l.trimLeft().startsWith('//'))
                .join('\n')
                .contains(e.value))
              e.key,
        ];

    Map<String, String> real() =>
        {for (final p in sites.keys) p: File(p).readAsStringSync()};

    test('every finaliser call site is present', () {
      expect(missing(real()), isEmpty);
    });

    test('a dropped call site is caught (mutation)', () {
      for (final e in sites.entries) {
        final sources = real();
        sources[e.key] = sources[e.key]!
            .split('\n')
            .map((l) => l.contains(e.value) ? '// removed' : l)
            .join('\n');
        expect(missing(sources), [e.key]);
      }
    });
  });
}
