// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/gps_calibration_matrix.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/core/utils/price_formatter.dart';
import 'package:tankstellen/features/driving/providers/driving_coach_voice_listener_provider.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_up.dart';
import 'package:tankstellen/features/fill_ups/domain/services/fuel_behaviour_evidence_log.dart';
import 'package:tankstellen/features/fill_ups/domain/services/monthly_insights_aggregator.dart';
import 'package:tankstellen/features/fill_ups/domain/services/tank_report.dart';
import 'package:tankstellen/features/trips/data/trip_history_entry.dart';
import 'package:tankstellen/features/trips/domain/calibrated_trip_figures.dart';
import 'package:tankstellen/features/trips/domain/services/trip_consumed_liters.dart';
import 'package:tankstellen/features/trips/domain/services/trip_length_aggregator.dart';
import 'package:tankstellen/features/trips/domain/trip_consumption_estimate.dart';
import 'package:tankstellen/features/trips/domain/trip_recorder.dart';

/// #4234 acceptance box 1 — *"static audit finds no production consumer
/// selecting a legacy estimator"* — as an **executable** audit rather than
/// a claim or a regex.
///
/// A source scan proves the text, not the code: four regex-over-source
/// guards in this repository once reported green while never running at
/// all. So this file does not scan. It **drives the real production
/// consumers** named in #4234 — trip summaries, tank report, fill-up
/// insights, coaching, the trajets/carbon aggregates and the background
/// reconciliation basis — against fixtures engineered so that a consumer
/// which still selects a legacy estimator produces a *different number*.
///
/// The companion static half — the files that may so much as *name* a
/// legacy estimator — is `test/lint/legacy_consumption_estimator_test.dart`.
/// What neither can see is listed in ADR 0027 §"What the audit cannot see".
///
/// ## The two properties
///
/// **A — legacy independence.** Four vehicle profiles differ *only* in
/// legacy-estimator state: no GPS matrix, a matrix with `physicsScale`
/// 1.9 and a fat baseline, a matrix with `physicsScale` 0.6, and
/// `calibrationMode: fuzzy`. Every consumer must return the **same**
/// figure for all four. A consumer that re-reads `GpsCalibrationMatrix`
/// at display time, rescales by `physicsScale`, or branches on the
/// `rule | fuzzy` setting cannot satisfy that — the matrix is a
/// *producer-side* input already baked into the stored figure.
///
/// **B — canonical parity.** Every consumer's figure equals the one
/// [tripConsumptionEstimate] produces. Divergences are not tolerated
/// silently: each one is pinned in [_knownDivergences] with its reason and
/// issue, and the map is **exact both ways** — a pinned pair that stops
/// diverging fails the test, so the count can only shrink.
///
/// Both properties are mutation-checked at the bottom of this file
/// against three fake consumers that deliberately reach for a legacy
/// path.
// ─────────────────────────── fixtures ────────────────────────────────

final _t0 = DateTime.utc(2026, 9, 18, 7, 30);

TripSummary _trip({
  double? avg,
  double? liters,
  double? eAvg,
  String? dfs,
  double? pg,
  TripKind kind = TripKind.gpsPlusObd2,
}) =>
    TripSummary(
      distanceKm: 120,
      maxRpm: 3000,
      highRpmSeconds: 0,
      idleSeconds: 60,
      harshBrakes: 0,
      harshAccelerations: 0,
      avgLPer100Km: avg,
      fuelLitersConsumed: liters,
      estimatedAvgLPer100Km: eAvg,
      startedAt: _t0,
      endedAt: _t0.add(const Duration(hours: 2)),
      dominantFuelSource: dfs,
      pumpGainApplied: pg,
      kind: kind,
    );

/// One trip per production source class, plus the no-fuel-PID trip
/// #4330 now classifies correctly and the pre-#4330 shape of the same
/// trip, which only exists in already-stored histories.
///
/// The *estimated* trip carries `pumpGainApplied: 1.0` against a vehicle
/// whose current gain is 1.1, so its canonical figure is re-expressed
/// (7.0 → 7.7). A consumer reading the raw stored average shows 7.0 and
/// fails property B — that is the trap for a consumer that skipped the
/// contract.
final _trips = <String, TripSummary>{
  // Native ECU fuel rate: measured, never gain-scaled.
  'measured': _trip(avg: 6.2, liters: 7.44, dfs: 'pid5E', pg: 0.8),
  // MAF / speed-density: the estimated class, re-expressed at 1.1.
  'estimated': _trip(avg: 7.0, liters: 8.4, dfs: 'maf', pg: 1.0),
  // GPS road load, folded onto the stored average.
  'gpsOnly': _trip(avg: 5.4, liters: 6.48, kind: TripKind.gpsOnly),
  // GPS road load that only ever reached `estimatedAvgLPer100Km`.
  'gpsEstimateOnly': _trip(eAvg: 5.9, kind: TripKind.gpsOnly),
  // #4330 closed the F4 gap: a no-fuel-PID OBD2 trip is stamped
  // `gpsPhysics` by `Obd2GpsEstimateFallback.fillWhenNoFuelPid` and
  // classes as `gps`. Shaped exactly as that finaliser writes it — avg,
  // litres and the tag together. Kept as a fixture so a regression in
  // the mapping shows up here as a fresh divergence.
  'noFuelPidGpsPhysics':
      _trip(avg: 5.9, liters: 7.08, dfs: 'gpsPhysics'),
  // The pre-#4330 shape: litres and an estimate, no tag, no average.
  // Such rows exist in users' histories and can no longer be produced,
  // so their divergences are frozen, not open bugs.
  'preMigrationUnclassified': _trip(liters: 7.1, eAvg: 5.9),
};

/// The gain every vehicle variant resolves to — held constant so the only
/// thing that changes between variants is legacy-estimator state.
const _gain = 1.1;
const _gainSamples = 4;

VehicleProfile _vehicle({
  GpsCalibrationMatrix? matrix,
  VehicleCalibrationMode mode = VehicleCalibrationMode.rule,
}) =>
    VehicleProfile(
      id: 'car',
      name: 'Audit',
      pumpGain: _gain,
      pumpGainSamples: _gainSamples,
      gpsCalibration: matrix,
      calibrationMode: mode,
    );

/// Four profiles that a *correct* consumer cannot tell apart.
final _vehicles = <String, VehicleProfile>{
  'noMatrix': _vehicle(),
  'matrixHigh': _vehicle(
    matrix: GpsCalibrationMatrix(
      baseline: 12.0,
      idleCost: 9.0,
      highSpeedPenalty: 8.0,
      accelEventCost: 4.0,
      physicsScale: 1.9,
      fillUpReconciliationCount: 11,
      residualVariance: 0.2,
      lastReconciledAt: _t0,
    ),
  ),
  'matrixLow': _vehicle(
    matrix: const GpsCalibrationMatrix(baseline: 2.0, physicsScale: 0.6),
  ),
  'fuzzyMode': _vehicle(mode: VehicleCalibrationMode.fuzzy),
};

TripHistoryEntry _entry(TripSummary s) =>
    TripHistoryEntry(id: 'trip-1', vehicleId: 'car', summary: s);

// ──────────────────────── the consumer registry ──────────────────────

/// One production consumer, as the audit drives it.
typedef _Consumer = ({
  /// `<area>/<surface>` — the area must be one #4234 names.
  String name,

  /// The real production call, reduced to the L/100 km it shows.
  double? Function(TripSummary, VehicleProfile?) read,
});

/// The figure #4234 says every consumer must receive.
double? _canonical(TripSummary s, VehicleProfile? v) =>
    tripConsumptionEstimate(s, v).litresPer100Km.valueOrNull;

/// A one-trip tank window, so the tank report can be driven per trip.
FillUp _fill(String id, double odo, {List<String> trips = const []}) => FillUp(
      id: id,
      date: _t0.add(Duration(days: id == 'open' ? 0 : 3)),
      vehicleId: 'car',
      liters: 40,
      totalCost: 70,
      odometerKm: odo,
      fuelType: FuelType.e10,
      linkedTripIds: trips,
    );

double? _tankReportFigure(TripSummary s, VehicleProfile? v) {
  final period = TankPeriod(
    opening: _fill('open', 100000),
    closing: _fill('close', 100120, trips: const ['trip-1']),
    distanceKm: 120,
    liters: 8.0,
    pumpedCost: 14,
  );
  return calibratedTankRecording(period, {'trip-1': s}, v)?.recordedLPer100Km;
}

double? _monthlyInsightsFigure(TripSummary s, VehicleProfile? v) =>
    aggregateMonthlyInsights(
      [_entry(s)],
      _t0.add(const Duration(days: 2)),
      vehicle: v,
    ).currentMonthAvgConsumptionLPer100km;

double? _evidenceLogFigure(TripSummary s, VehicleProfile? v) =>
    tripFuelEvidenceFor(vehicleId: 'car', vehicle: v, trips: [_entry(s)])
        .singleOrNull
        ?.litresPer100Km
        .valueOrNull;

double? _consumedLitresFigure(TripSummary s, VehicleProfile? v) {
  final l = tripConsumedLitersOrNull(s);
  return l == null ? null : l / s.distanceKm * 100.0;
}

double? _tripLengthFigure(TripSummary s, VehicleProfile? v) =>
    aggregateByTripLength([_entry(s)], vehicleId: 'car').long.avgLPer100Km;

/// Every consumer #4234 names that can be driven as a pure call.
///
/// The surfaces that cannot are not thereby exempt: they are listed in
/// [_undrivenSurfaces] with where they *are* covered.
final _consumers = <_Consumer>[
  // Trip summaries — `trip_summary_card.dart:86` / `trajet_row.dart:70`.
  (name: 'trips/trip-summary-card', read: _canonical),
  // The choke point every surface goes through (#3918).
  (
    name: 'trips/calibrated-trip-figures',
    read: (s, v) => CalibratedTripFigures.of(s, v).lPer100Km,
  ),
  (name: 'fill_ups/tank-report', read: _tankReportFigure),
  (name: 'fill_ups/monthly-insights', read: _monthlyInsightsFigure),
  (name: 'fill_ups/fuel-behaviour-evidence-log', read: _evidenceLogFigure),
  // Coaching — the spoken end-of-trip figure (#3504).
  (
    name: 'coaching/voice-trip-summary',
    read: (s, v) => coachSpokenAvgLPer100Km(_entry(s), v),
  ),
  // Background processing — the reconciliation / trajets-total basis.
  (name: 'background/trip-consumed-litres', read: _consumedLitresFigure),
  // Widgets — the carbon trip-length breakdown card's figure.
  (name: 'widgets/trip-length-breakdown', read: _tripLengthFigure),
];

/// `<consumer>::<trip>` pairs whose figure is knowingly NOT the canonical
/// one, each with the reason it is not and the issue that owns the fix.
///
/// **Exact both ways.** A pair here that has stopped diverging fails the
/// test, so an entry can only ever be deleted. Never add one to make a
/// red test green: a new divergence is the audit doing its job.
const _knownDivergences = <String, String>{
  // ── frozen: the pre-#4330 shape of a no-fuel-PID trip ──────────────
  // A trip with litres but no average and no provenance tag classes as
  // `none`; the canonical adapter surfaces its GPS estimate while the
  // litre-based surfaces surface the litres. #4330 fixed this at the
  // PRODUCER — `fillWhenNoFuelPid` now stamps `gpsPhysics` and the trip
  // classes as `gps` — so the `noFuelPidGpsPhysics` fixture beside these
  // diverges nowhere. What remains is rows already written that way. A
  // current build cannot produce one, so these entries are frozen
  // history, not open defects. Owner: #4234.
  'fill_ups/tank-report::preMigrationUnclassified':
      '#4234 — pre-#4330 row: litres-based window figure vs the estimate',
  'fill_ups/monthly-insights::preMigrationUnclassified':
      '#4234 — pre-#4330 row: litres-based month average vs the estimate',
  'fill_ups/fuel-behaviour-evidence-log::preMigrationUnclassified':
      '#4234 — pre-#4330 row: the log reports unknown for a `none` class',
  'background/trip-consumed-litres::preMigrationUnclassified':
      '#4234 — pre-#4330 row: litres present, the estimate is not consulted',
  'widgets/trip-length-breakdown::preMigrationUnclassified':
      '#4234 — pre-#4330 row: litres present, the estimate is not consulted',
  'trips/calibrated-trip-figures::preMigrationUnclassified':
      '#4234 — pre-#4330 row: the choke point has no average to re-express',

  // ── the litres basis is deliberately the STORED litre count ────────
  // `tripConsumedLiters` is what the reconciler, the reconciliation
  // basis, tank behaviour, the blend log and the vehicle aggregates sum.
  // Re-expressing it at today's gain would feed the pump-gain learner a
  // figure derived from its own previous output, so the raw stored
  // litres stay. Not contained, and not an estimator selection: the
  // number comes from the same single production path, unscaled.
  // Owner: #4234.
  'background/trip-consumed-litres::estimated':
      '#4234 — the litres basis stays at the recorded gain; re-expressing '
          'it would make the pump-gain learner read its own output',
  'widgets/trip-length-breakdown::estimated':
      '#4234 — inherits the trip-consumed-litres basis above',

  // ── litres-only surfaces cannot see an estimate-only trip ──────────
  // `tripConsumedLitersOrNull` recovers litres from `avgLPer100Km`, never
  // from `estimatedAvgLPer100Km`, so a GPS trip whose figure only ever
  // reached the estimate field drops out of every litre aggregate.
  // Not an estimator selection — a missing field read. Owner: #4234.
  'background/trip-consumed-litres::gpsEstimateOnly':
      '#4234 — litres are not recovered from estimatedAvgLPer100Km',
  'widgets/trip-length-breakdown::gpsEstimateOnly':
      '#4234 — inherits the trip-consumed-litres gap above',
  'fill_ups/monthly-insights::gpsEstimateOnly':
      '#4234 — inherits the trip-consumed-litres gap above',
  'fill_ups/tank-report::gpsEstimateOnly':
      '#4234 — inherits the trip-consumed-litres gap above',
  'trips/calibrated-trip-figures::gpsEstimateOnly':
      '#4234 — the choke point reads avgLPer100Km only; the adapter adds '
          'the estimatedAvgLPer100Km fallback',
};

/// Consumers #4234 names that this file cannot drive as a pure call, and
/// where each is actually covered. Pinned so the list cannot quietly grow.
const _undrivenSurfaces = <String, String>{
  'trip-recording/finalise':
      'lifecycle code behind a Riverpod notifier; the figures it writes '
          'are pinned bit-for-bit by consumption_identity_goldens_test.dart',
  'trip-recording/live-average-card':
      'TripAvgConsumptionCard renders TripLiveReading, which carries no '
          'ConsumptionEstimate yet (ADR 0024 "Deferred"); its producer is '
          'the single GPS/fuzzy path',
  'exports/backup-xml':
      'a backup must round-trip the STORED row, not a re-expressed one; '
          'since #4330 it also carries pg/pgk/dfs/cmv, pinned by '
          'historical_value_reproducibility_test.dart',
  'exports/driving-analysis-trace':
      'already reads tripConsumptionEstimate (driving_analysis_trace.dart'
          ':142), with a null vehicle so the trace records what was stored',
};

/// The profile property B drives every consumer against — the one with no
/// legacy-estimator state at all. Named once so the per-pair tests and the
/// whole-matrix ratchet below cannot drift apart.
VehicleProfile get _referenceVehicle => _vehicles['noMatrix']!;

/// Whether [consumer]'s figure for [trip] IS the canonical one, to the
/// tolerance the audit treats as "the same number". Two absent figures
/// agree; one absent figure never does.
bool _agreesWithCanonical(_Consumer consumer, TripSummary trip) {
  final actual = consumer.read(trip, _referenceVehicle);
  final expected = _canonical(trip, _referenceVehicle);
  if (actual == null || expected == null) return actual == expected;
  return (actual - expected).abs() < 1e-9;
}

/// Every `<consumer>::<trip>` pair that does NOT agree with the canonical
/// figure, recomputed over the WHOLE matrix on each call.
///
/// #4421 — this used to be an accumulator that the per-pair tests added to
/// and a `tearDownAll` compared. `package:test` gives `--total-shards` a
/// contiguous SLICE of each suite's test cases (test_core
/// `Runner._shardSuite`) yet runs `tearDownAll` in every shard that
/// receives any of the group, so the accumulator only ever held the
/// slice's divergences and the exact comparison failed on a partition
/// boundary — with a different pin named per shard index, and with
/// nothing about the code under test having changed. Recomputing the set
/// inside one test case makes the ratchet independent of how CI splits
/// the suite.
Set<String> _divergingPairs() => {
      for (final c in _consumers)
        for (final trip in _trips.entries)
          if (!_agreesWithCanonical(c, trip.value)) '${c.name}::${trip.key}',
    };

/// The consumer areas #4234's Scope paragraph enumerates.
const _namedAreas = <String>{
  'trip-recording',
  'trips',
  'fill_ups',
  'coaching',
  'widgets',
  'exports',
  'background',
};

void main() {
  // #4421 — the one piece of process-wide state a consumer on these paths
  // could plausibly reach for is the active country, because #4364 made
  // the evidence log currency-aware. The audit therefore STAMPS it rather
  // than inheriting whatever ran before: a deliberately hostile,
  // zero-decimal, non-EUR country, restored afterwards. Every figure the
  // audit checks must be blind to it — if one is not, this file goes red
  // on its own instead of on a shard boundary. Nothing else in the driven
  // paths reads a static: the fixtures are built here, the consumers are
  // pure calls, and no clock, Hive box or provider container is touched.
  late String ambientCountry;
  setUpAll(() {
    ambientCountry = PriceFormatter.activeCountry;
    PriceFormatter.setCountry('KR');
  });
  tearDownAll(() => PriceFormatter.setCountry(ambientCountry));

  group('#4234 · every named consumer area is audited', () {
    test('the registry plus the undriven list covers every named area', () {
      final covered = {
        for (final c in _consumers) c.name.split('/').first,
        for (final k in _undrivenSurfaces.keys) k.split('/').first,
      };
      expect(covered, containsAll(_namedAreas),
          reason: 'an area #4234 names is audited by nothing');
    });

    test('the audit actually drove something', () {
      // The scanner-proves-nothing guard, applied to an executable audit:
      // if every consumer returned null for every fixture, both properties
      // below would pass vacuously.
      final produced = [
        for (final c in _consumers)
          for (final s in _trips.values)
            for (final v in _vehicles.values)
              if (c.read(s, v) != null) c.name,
      ];
      expect(produced, isNotEmpty);
      expect(produced.toSet().length, _consumers.length,
          reason: 'a registered consumer produced no figure at all for any '
              'fixture — it is not being exercised');
    });
  });

  group('#4234 property A · no consumer selects a legacy estimator', () {
    for (final c in _consumers) {
      for (final trip in _trips.entries) {
        test('${c.name} · ${trip.key} ignores the GPS matrix and the '
            'rule|fuzzy mode', () {
          final figures = {
            for (final v in _vehicles.entries) v.key: c.read(trip.value, v.value)
          };
          final reference = figures['noMatrix'];
          for (final e in figures.entries) {
            expect(e.value, reference,
                reason: '${c.name} returned a different figure for the '
                    '"${e.key}" profile — it is reading a legacy estimator '
                    'input (physicsScale / GPS matrix / calibrationMode) at '
                    'read time');
          }
        });
      }
    }
  });

  group('#4234 property B · every consumer receives the canonical figure',
      () {
    for (final c in _consumers) {
      for (final trip in _trips.entries) {
        final key = '${c.name}::${trip.key}';
        test('$key matches tripConsumptionEstimate', () {
          final vehicle = _referenceVehicle;
          final actual = c.read(trip.value, vehicle);
          final expected = _canonical(trip.value, vehicle);
          final agrees = _agreesWithCanonical(c, trip.value);
          if (_knownDivergences.containsKey(key)) {
            expect(agrees, isFalse,
                reason: '$key is pinned as a known divergence '
                    '("${_knownDivergences[key]}") but now agrees with the '
                    'canonical figure — delete the entry in the same commit');
            return;
          }
          expect(agrees, isTrue,
              reason: '$key shows $actual where the canonical '
                  'ConsumptionEstimate says $expected. Fix the consumer, or '
                  'pin it in _knownDivergences with its issue number.');
        });
      }
    }

    // The ratchet's both-ways half, as ONE self-contained case (#4421):
    // the pinned set must be exactly the set that diverges — never a
    // superset kept around for comfort, and never a pin naming a pair the
    // matrix no longer has. It recomputes the whole matrix itself, so its
    // verdict does not depend on which of its sibling cases ran in the
    // same shard.
    test('the pinned divergences are exactly the pairs that diverge', () {
      expect(_divergingPairs(), _knownDivergences.keys.toSet());
    });
  });

  group('#4234 · the audit is proven able to fail (mutation check)', () {
    List<Object?> figuresAcross(
        double? Function(TripSummary, VehicleProfile?) read, String trip) {
      return [for (final v in _vehicles.values) read(_trips[trip]!, v)];
    }

    test('property A goes red for a consumer that rescales by physicsScale',
        () {
      double? fake(TripSummary s, VehicleProfile? v) {
        final scale = v?.gpsCalibration?.physicsScale ?? 1.0;
        final base = _canonical(s, v);
        return base == null ? null : base * scale;
      }

      final across = figuresAcross(fake, 'estimated');
      expect(across.toSet().length, greaterThan(1),
          reason: 'the physicsScale fake must produce different figures '
              'across the profiles, or property A cannot catch it');
    });

    test('property A goes red for a consumer that branches on '
        'calibrationMode', () {
      double? fake(TripSummary s, VehicleProfile? v) =>
          v?.calibrationMode == VehicleCalibrationMode.fuzzy
              ? 0.0
              : _canonical(s, v);

      expect(figuresAcross(fake, 'measured').toSet().length, greaterThan(1));
    });

    test('property B goes red for a consumer that reads the raw stored '
        'average', () {
      double? fake(TripSummary s, VehicleProfile? v) => s.avgLPer100Km;
      final vehicle = _vehicles['noMatrix'];
      final trip = _trips['estimated']!;
      // The trip is re-expressed 7.0 → 7.7, so the raw read differs.
      expect(fake(trip, vehicle), isNot(_canonical(trip, vehicle)));
      expect(_canonical(trip, vehicle), closeTo(7.7, 1e-9));
    });

    test('a GPS matrix genuinely changes nothing for a real consumer', () {
      // The counterpart assertion: the fixture profiles differ enough that
      // a matrix-reading consumer WOULD be caught, yet every real consumer
      // is blind to them. Without this, property A could pass because the
      // profiles are indistinguishable rather than because the code is
      // correct.
      expect(_vehicles['matrixHigh']!.gpsCalibration!.physicsScale,
          isNot(_vehicles['matrixLow']!.gpsCalibration!.physicsScale));
      expect(_vehicles['fuzzyMode']!.calibrationMode,
          VehicleCalibrationMode.fuzzy);
      expect(_vehicles['noMatrix']!.gpsCalibration, isNull);
    });
  });
}
