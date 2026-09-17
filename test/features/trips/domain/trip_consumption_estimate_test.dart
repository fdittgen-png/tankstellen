// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/consumption_estimate.dart';
import 'package:tankstellen/core/domain/data_value.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/trips/domain/calibrated_trip_figures.dart';
import 'package:tankstellen/features/trips/domain/trip_consumption_estimate.dart';
import 'package:tankstellen/features/trips/domain/trip_recorder.dart';

/// #4233 — the trip → `ConsumptionEstimate` adapter (ADR 0024 §6): one
/// classification (`tripFuelSourceKind`), one number (the one every trip
/// surface already showed), the pump-gain rule of ADR 0022 and the stored
/// version, re-generationed only when the figure is re-expressed.
const _v1 = ConsumptionModelVersion(model: 1, rules: 1);
final _t0 = DateTime.utc(2026, 9, 16, 7, 30);

TripSummary _trip({
  double? avg,
  double? eAvg,
  String? dfs,
  double? pg,
  TripKind kind = TripKind.gpsPlusObd2,
  ConsumptionModelVersion? cmv,
}) =>
    TripSummary(
      distanceKm: 12,
      maxRpm: 3000,
      highRpmSeconds: 0,
      idleSeconds: 0,
      harshBrakes: 0,
      harshAccelerations: 0,
      avgLPer100Km: avg,
      fuelLitersConsumed: avg == null ? null : avg * 0.12,
      estimatedAvgLPer100Km: eAvg,
      startedAt: _t0,
      dominantFuelSource: dfs,
      pumpGainApplied: pg,
      kind: kind,
      consumptionVersion: cmv,
    );

const _gain11 = VehicleProfile(
    id: 'v', name: 'v', pumpGain: 1.1, pumpGainSamples: 4);

void main() {
  test('measured: the stored figure, and never a gain — whatever pg says', () {
    final e = tripConsumptionEstimate(
        _trip(avg: 6.2, dfs: 'pid5E', pg: 0.8), _gain11,
        recordingId: 'trip-1');
    expect(e.sourceClass, ConsumptionSourceClass.measured);
    expect(e.litresPer100Km, DataValue<double>.measured(6.2, at: _t0));
    expect(e.pumpGain, isNull);
    expect(e.isConsistent, isTrue);
    expect(e.recordedAt, _t0);
    expect(e.recordingId, 'trip-1');
  });

  test('estimated at the recorded gain: stored value, stored version', () {
    const same = VehicleProfile(
        id: 'v', name: 'v', pumpGain: 0.9, pumpGainSamples: 2);
    final e = tripConsumptionEstimate(
        _trip(avg: 7.0, dfs: 'maf', pg: 0.9, cmv: _v1), same);
    expect(e.sourceClass, ConsumptionSourceClass.estimated);
    expect(e.litresPer100Km,
        const DataValue<double>.estimated(7.0, basis: DataBasis.derived));
    expect(e.pumpGain, 0.9);
    expect(e.version, _v1);
    expect(e.isConsistent, isTrue);
  });

  test('estimated, re-expressed: today\'s gain and its generation', () {
    final trip = _trip(avg: 7.0, dfs: 'speedDensity', pg: 1.0, cmv: _v1);
    final e = tripConsumptionEstimate(trip, _gain11);
    expect(e.litresPer100Km.valueOrNull,
        CalibratedTripFigures.of(trip, _gain11).lPer100Km);
    expect(e.pumpGain, 1.1);
    expect(e.version,
        const ConsumptionModelVersion(model: 1, rules: 1, calibration: 4));
  });

  test('an unstamped estimated trip stays unversioned when re-expressed', () {
    final e = tripConsumptionEstimate(
        _trip(avg: 7.0, dfs: 'maf', pg: 1.0), _gain11);
    expect(e.version, isNull, reason: 'no invented model: 1');
  });

  test('GPS batch and live-folder figures: estimated, no gain', () {
    final batch = tripConsumptionEstimate(
        _trip(avg: 5.5, kind: TripKind.gpsOnly), _gain11);
    expect(batch.sourceClass, ConsumptionSourceClass.gpsOnly);
    expect(batch.litresPer100Km,
        const DataValue<double>.estimated(5.5, basis: DataBasis.derived));
    expect(batch.pumpGain, isNull);
    expect(batch.version, isNull, reason: 'the batch estimator is F5');

    final live = tripConsumptionEstimate(
        _trip(eAvg: 5.9, kind: TripKind.gpsOnly, cmv: _v1), _gain11);
    expect(live.sourceClass, ConsumptionSourceClass.gpsOnly);
    expect(live.litresPer100Km.valueOrNull, 5.9);
    expect(live.version, _v1);
    expect(live.isConsistent, isTrue);
  });

  test('F4: an OBD2 trip with the GPS fallback figure is none, estimated', () {
    final e = tripConsumptionEstimate(_trip(avg: 6.8, cmv: _v1), null);
    expect(e.sourceClass, ConsumptionSourceClass.none);
    expect(e.litresPer100Km,
        const DataValue<double>.estimated(6.8, basis: DataBasis.derived));
    expect(e.version, _v1);
  });

  test('no figure: unknown with its reason, no version', () {
    final e = tripConsumptionEstimate(_trip(), _gain11);
    expect(e.sourceClass, ConsumptionSourceClass.none);
    expect(e.litresPer100Km,
        const DataValue<double>.unknown(
            reason: DataUnknownReason.notMeasuredYet));
    expect(e.version, isNull);
  });

  test('the value is exactly the number trip surfaces showed before', () {
    for (final trip in [
      _trip(avg: 6.2, dfs: 'pid9D', pg: 0.8),
      _trip(avg: 7.0, dfs: 'maf', pg: 1.0),
      _trip(avg: 5.5, kind: TripKind.gpsOnly),
      _trip(eAvg: 5.9, kind: TripKind.gpsOnly),
      _trip(avg: 6.8),
      _trip(),
    ]) {
      for (final vehicle in [null, _gain11]) {
        final before = CalibratedTripFigures.of(trip, vehicle).lPer100Km ??
            trip.estimatedAvgLPer100Km;
        expect(tripConsumptionEstimate(trip, vehicle).litresPer100Km
            .valueOrNull, before);
      }
    }
  });
}
