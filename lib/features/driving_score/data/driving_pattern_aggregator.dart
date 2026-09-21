// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// #4366 — bounded, summaries-first aggregation of driving patterns
/// across the driver's own vehicles.
///
/// ## The performance contract
///
/// Everything that can be decided from a [TripSummary] is decided from a
/// [TripSummary]: strict attribution (#4364), the period filter, the
/// exclusions and the cohort a trip belongs to. Only the trips that
/// survive all of that are ever handed to [DrivingPatternTotalsLoader],
/// and the first of those loads happens **after** an `await`, so no
/// widget `build()` can pull a single sample synchronously. Loading then
/// proceeds in chunks that yield to the event loop between them.
///
/// ## The honesty contract
///
/// A rate is `numerator / eligible exposure`, and the exposure only
/// advances where the signal was present. That is why a GPS-only
/// history comes back with RPM- and idle-denominated measures
/// UNAVAILABLE rather than at a flattering zero, and why a matched
/// cohort is still only *matched*, never *adjusted*: production has no
/// blend-independent expected consumption and no per-trip grade or
/// traffic, so [DrivingPatternComparison.conditionAdjustedRanking] is
/// refused with the reason that says which input is missing.
library;

import 'dart:async';

import '../../../core/domain/comparison_eligibility.dart';
import '../../trips/api.dart';
import '../domain/driving_pattern_comparison.dart';
import 'driving_pattern_measures.dart';

/// Loads one trip's typed totals, decoding its samples. Returns null
/// when the trip has no usable samples.
typedef DrivingPatternTotalsLoader = FutureOr<DrivingPatternTotals?> Function(
    TripHistoryEntry entry);

/// The `trip_sample_codec` column key for coolant temperature. Read off
/// the v2 meta row (`TripHistoryEntry.columnsPresent`), so "was coolant
/// ever recorded?" is answered without decoding a single sample.
const String _kCoolantColumn = 'ct';

/// Build the driving-pattern comparison for [selectedVehicleIds].
///
/// [selectedVehicleIds] and the period are INPUTS — #4365 owns the
/// selection flow; this function never picks a vehicle and never touches
/// the active one. [asOf] is injected rather than read from the wall
/// clock and stamps the reported period end when none was given.
Future<DrivingPatternComparison> aggregateDrivingPatterns({
  required List<String> selectedVehicleIds,
  required Iterable<TripHistoryEntry> summaries,
  required DrivingPatternTotalsLoader loadTotals,
  required DateTime asOf,
  DateTime? periodStart,
  DateTime? periodEnd,
  int chunkSize = 25,
}) async {
  final all = summaries.toList(growable: false);
  bool inPeriod(TripHistoryEntry t) {
    final at = t.summary.startedAt;
    if (at == null) return periodStart == null && periodEnd == null;
    if (periodStart != null && at.isBefore(periodStart)) return false;
    if (periodEnd != null && at.isAfter(periodEnd)) return false;
    return true;
  }

  final windowed = [
    for (final t in all)
      if (inPeriod(t)) t,
  ];
  final unassigned = windowed.where((t) => t.vehicleId == null).length;

  // ── summaries only from here to the first await ────────────────────
  final eligible = <String, List<TripHistoryEntry>>{};
  final exclusions = <String, Map<ComparisonExclusion, int>>{};
  for (final id in selectedVehicleIds) {
    final drops = <ComparisonExclusion, int>{
      ComparisonExclusion.unassignedVehicle: unassigned,
    };
    final kept = <TripHistoryEntry>[];
    for (final t in windowed) {
      if (!tripIsAttributedTo(t, id)) continue;
      if (t.summary.isVirtual) {
        drops.update(ComparisonExclusion.virtualRecord, (n) => n + 1,
            ifAbsent: () => 1);
        continue;
      }
      if (isEngineOffTransport(t.summary)) {
        drops.update(ComparisonExclusion.engineOffTransport, (n) => n + 1,
            ifAbsent: () => 1);
        continue;
      }
      if (t.summary.distanceKm <= 0) {
        drops.update(ComparisonExclusion.noFigure, (n) => n + 1,
            ifAbsent: () => 1);
        continue;
      }
      kept.add(t);
    }
    eligible[id] = kept;
    exclusions[id] = drops;
  }

  final matching = _match(selectedVehicleIds, eligible);
  final matched = <String, List<TripHistoryEntry>>{
    for (final id in selectedVehicleIds)
      id: matching.isMatched
          ? [
              for (final t in eligible[id]!)
                if (matching.cohorts.contains(cohortOf(t))) t,
            ]
          : eligible[id]!,
  };
  // ── the boundary: nothing above decoded a sample, and nothing below
  // runs inside a build() frame ───────────────────────────────────────
  await Future<void>.delayed(Duration.zero);

  final subjects = <VehicleDrivingPattern>[];
  for (final id in selectedVehicleIds) {
    subjects.add(await _subject(
      vehicleId: id,
      trips: matched[id]!,
      attributedCount: eligible[id]!.length,
      exclusions: exclusions[id]!,
      loadTotals: loadTotals,
      chunkSize: chunkSize,
      matched: matching.isMatched,
      periodStart: periodStart,
      periodEnd: periodEnd ?? asOf,
    ));
  }

  return DrivingPatternComparison(
    subjects: subjects,
    matching: matching,
    differences: largestDifferences(subjects),
    // Production supplies no blend-independent expected consumption and
    // no per-trip grade/traffic context, so "who drives more
    // efficiently, conditions equal" is not a claim this data can make.
    conditionAdjustedRanking: ComparableMetric.unavailable(
      ComparisonUnavailableReason.noExpectedConsumption,
      qualifications: const {
        ComparisonQualification.partialConditionCoverage,
      },
    ),
    unassignedTripCount: unassigned,
    periodStart: periodStart,
    periodEnd: periodEnd ?? asOf,
    modelVersion: kDrivingPatternModelVersion,
  );
}

/// The cohort of [trip], from its summary alone.
DrivingPatternCohort cohortOf(TripHistoryEntry trip) => DrivingPatternCohort(
      distanceBand: TripDistanceBand.fromKm(trip.summary.distanceKm),
      coldStart: coldStartEvidenceOf(trip),
    );

/// What is KNOWN about [trip]'s start temperature.
///
/// `coldStartSurcharge == false` is not warm: the recorder leaves it
/// false when no coolant was ever read (no PID 0x05, GPS-only, legacy
/// row). Only a trip that actually carries a coolant column and is not
/// flagged can go in a verified warm cohort.
ColdStartEvidence coldStartEvidenceOf(TripHistoryEntry trip) {
  if (trip.summary.coldStartSurcharge) return ColdStartEvidence.coldObserved;
  final cols = trip.columnsPresent;
  final coolant = cols != null
      ? cols.contains(_kCoolantColumn)
      : trip.samples.any((s) => s.coolantTempC != null);
  return coolant ? ColdStartEvidence.warmObserved : ColdStartEvidence.unknown;
}

DrivingPatternMatching _match(
    List<String> ids, Map<String, List<TripHistoryEntry>> eligible) {
  if (ids.length < 2) {
    return const DrivingPatternMatching(
        isMatched: false,
        cohorts: [],
        matchedTripCount: 0,
        unmatchedTripCount: 0);
  }
  Set<DrivingPatternCohort>? shared;
  for (final id in ids) {
    final present = {for (final t in eligible[id]!) cohortOf(t)};
    shared = shared == null ? present : shared.intersection(present);
  }
  final cohorts = (shared ?? const <DrivingPatternCohort>{}).toList()
    ..sort((a, b) {
      final byBand = a.distanceBand.index.compareTo(b.distanceBand.index);
      return byBand != 0
          ? byBand
          : a.coldStart.index.compareTo(b.coldStart.index);
    });
  if (cohorts.isEmpty) {
    final total = ids.fold<int>(0, (n, id) => n + eligible[id]!.length);
    return DrivingPatternMatching(
        isMatched: false,
        cohorts: const [],
        matchedTripCount: 0,
        unmatchedTripCount: total);
  }
  var inside = 0, outside = 0;
  for (final id in ids) {
    for (final t in eligible[id]!) {
      cohorts.contains(cohortOf(t)) ? inside++ : outside++;
    }
  }
  return DrivingPatternMatching(
      isMatched: true,
      cohorts: cohorts,
      matchedTripCount: inside,
      unmatchedTripCount: outside);
}

Future<VehicleDrivingPattern> _subject({
  required String vehicleId,
  required List<TripHistoryEntry> trips,
  required int attributedCount,
  required Map<ComparisonExclusion, int> exclusions,
  required DrivingPatternTotalsLoader loadTotals,
  required int chunkSize,
  required bool matched,
  required DateTime? periodStart,
  required DateTime? periodEnd,
}) async {
  var totals = DrivingPatternTotals.empty;
  final support = <DrivingMeasureId, int>{};
  final best = <DrivingMeasureId, _Representative>{};
  var analysed = 0;
  var km = 0.0;
  var time = Duration.zero;

  for (var i = 0; i < trips.length; i++) {
    if (i > 0 && i % chunkSize == 0) {
      await Future<void>.delayed(Duration.zero);
    }
    final trip = trips[i];
    final one = await loadTotals(trip);
    if (one == null || one.isEmpty) continue;
    analysed++;
    totals = totals + one;
    km += trip.summary.distanceKm;
    final start = trip.summary.startedAt;
    final end = trip.summary.endedAt;
    if (start != null && end != null && end.isAfter(start)) {
      time += end.difference(start);
    }
    for (final spec in kDrivingMeasures) {
      if (one.exposureOf(spec.exposureBasis) <= 0) continue;
      support.update(spec.id, (n) => n + 1, ifAbsent: () => 1);
      final numerator = numeratorOf(one, spec);
      final current = best[spec.id];
      if (current == null || numerator > current.numerator) {
        best[spec.id] = _Representative(trip.id, numerator);
      }
    }
  }

  final coverage = ComparisonCoverage(
    tripCount: analysed,
    coveredKm: km,
    coveredTime: time > Duration.zero ? time : null,
    periodStart: periodStart,
    periodEnd: periodEnd,
    // Cold starts are the only confounder production records; grade,
    // traffic and expected consumption are not evaluated at all, so no
    // drive here has its FULL context known.
    conditionCoverage: 0,
    exclusions: exclusions,
  );

  return VehicleDrivingPattern(
    vehicleId: vehicleId,
    totals: totals,
    coverage: coverage,
    attributedTripCount: attributedCount,
    analysedTripCount: analysed,
    measures: buildMeasures(
      totals: totals,
      coverage: coverage,
      support: support,
      representatives: {
        for (final e in best.entries) e.key: e.value.tripId,
      },
      matched: matched,
      excludedRecords: coverage.excludedCount > 0,
    ),
  );
}

class _Representative {
  const _Representative(this.tripId, this.numerator);
  final String tripId;
  final double numerator;
}
