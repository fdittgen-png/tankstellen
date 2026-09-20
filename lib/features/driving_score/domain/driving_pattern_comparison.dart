// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #4366 (Epic #4358, work package G) — the read model of a driving-pattern
/// comparison across the driver's own vehicles.
///
/// ## What this is NOT
///
/// It is not a league table, not a score, and not an input to any fuel
/// figure. There is deliberately no litre and no money anywhere in this
/// file: a behaviour observation may not be turned into "you wasted
/// 3 L" without its own validated counterfactual, which production does
/// not have (#4366 acceptance 8, and the limits the fuel-behaviour
/// evidence log already states). The comparison reports **observed
/// rates with their exposure**, and leaves causation alone.
///
/// ## The shape
///
///  * [VehicleDrivingPattern] — one vehicle's typed totals and the
///    measures those totals support, each an eligibility-carrying
///    [ComparableMetric] from #4364.
///  * [DrivingPatternMatching] — which cohorts (distance band × observed
///    cold/warm start) every selected vehicle has trips in, how many
///    trips that matched, and how many it left out.
///  * [DrivingPatternDifference] — the largest supported differences,
///    each one an observation with its evidence, never a verdict.
///
/// Selection and period are INPUTS (#4365 owns that flow); nothing here
/// picks vehicles.
library;

import 'package:meta/meta.dart';

import '../../../core/domain/comparison_eligibility.dart';
import 'driving_pattern_evidence.dart';

export 'driving_pattern_evidence.dart';

/// Trip-length band, the coarse condition axis a trip can be matched on
/// without any sensor at all. A 3 km errand and a 400 km motorway run
/// are not the same driving, and comparing their raw rates is the
/// confound #4366 exists to stop.
enum TripDistanceBand {
  /// Under 5 km — dominated by the start, junctions and parking.
  short,

  /// 5–30 km — the ordinary commute.
  medium,

  /// Over 30 km — long-distance, mostly steady-state.
  long;

  static TripDistanceBand fromKm(double km) => km < 5
      ? TripDistanceBand.short
      : km <= 30
          ? TripDistanceBand.medium
          : TripDistanceBand.long;
}

/// What is actually KNOWN about a trip's start temperature.
///
/// `TripSummary.coldStartSurcharge` is a two-state bool with a
/// three-state meaning: it is set true only when coolant telemetry says
/// the engine was warming, and stays **false both when the engine was
/// demonstrably warm and when no coolant was ever read** (cars without
/// PID 0x05, every GPS-only trip). `false` alone therefore cannot place
/// a trip in a verified warm-start cohort, so this enum splits the two
/// and the cohort key carries the distinction.
enum ColdStartEvidence {
  /// Coolant telemetry indicated a cold start.
  coldObserved,

  /// Coolant telemetry existed and did NOT indicate a cold start.
  warmObserved,

  /// No coolant evidence at all. Not warm — unknown.
  unknown,
}

/// The conditions a trip is matched on. Only context that is actually
/// known takes part: grade, traffic and expected consumption are not
/// available per trip in production, which is why no matched subset here
/// may ever be called condition-ADJUSTED.
@immutable
class DrivingPatternCohort {
  const DrivingPatternCohort({
    required this.distanceBand,
    required this.coldStart,
  });

  final TripDistanceBand distanceBand;
  final ColdStartEvidence coldStart;

  @override
  bool operator ==(Object other) =>
      other is DrivingPatternCohort &&
      other.distanceBand == distanceBand &&
      other.coldStart == coldStart;

  @override
  int get hashCode => Object.hash(distanceBand, coldStart);

  Map<String, Object?> toJson() =>
      {'distanceBand': distanceBand.name, 'coldStart': coldStart.name};

  @override
  String toString() => '${distanceBand.name}/${coldStart.name}';
}

/// One measure of one vehicle: a typed numerator over its eligible
/// exposure, with the eligibility contract around it.
///
/// Exactly one of [eventNumerator] / [durationSeconds] is non-null. The
/// constructor enforces it, so no caller can hand a rounded duration to
/// a field that means "events" — the conflation that
/// `DrivingDimension.evidenceCount` invites.
@immutable
class DrivingPatternMeasure {
  DrivingPatternMeasure({
    required this.spec,
    required this.metric,
    required this.exposure,
    required this.supportingTripCount,
    this.eventNumerator,
    this.durationSeconds,
    this.representativeTripId,
  }) {
    if ((eventNumerator == null) == (durationSeconds == null)) {
      throw ArgumentError(
          'a measure numerator counts events or seconds, never both '
          'and never neither (${spec.id.name})');
    }
  }

  final DrivingMeasureSpec spec;

  /// The figure with its eligibility. Unavailable when the exposure that
  /// would have made it observable was never there.
  final ComparableMetric<double> metric;

  /// The eligible denominator this measure was divided by, in the unit
  /// of [DrivingMeasureSpec.exposureBasis]. Displayed beside the rate:
  /// 10 events over 100 km and 100 over 1 000 km are the same rate and
  /// very different evidence.
  final double exposure;

  /// Trips that contributed any exposure to this measure — always ≤ the
  /// vehicle's attributed trip count, because a GPS-only trip supports
  /// fewer measures than an OBD-equipped one.
  final int supportingTripCount;

  final int? eventNumerator;
  final double? durationSeconds;

  /// A trip that contributed the most to this numerator, for "show me
  /// where this came from". Null when nothing contributed.
  final String? representativeTripId;

  DrivingMeasureId get id => spec.id;

  bool get isSupported => metric.isComparable;

  Map<String, Object?> toJson() => {
        'id': spec.id.name,
        'unit': spec.unit.name,
        'exposureBasis': spec.exposureBasis.name,
        'exposure': exposure,
        'events': eventNumerator,
        'seconds': durationSeconds,
        'supportingTrips': supportingTripCount,
        'representativeTrip': representativeTripId,
        'metric': metric.toJson(),
      };
}

/// One selected vehicle's observed driving pattern.
@immutable
class VehicleDrivingPattern {
  const VehicleDrivingPattern({
    required this.vehicleId,
    required this.totals,
    required this.coverage,
    required this.measures,
    required this.attributedTripCount,
    required this.analysedTripCount,
  });

  final String vehicleId;

  /// The summed typed evidence — the audit trail behind every measure.
  final DrivingPatternTotals totals;

  final ComparisonCoverage coverage;

  /// Every measure, supported or not. An unsupported one is kept so the
  /// surface can say WHY a dimension is missing for this vehicle rather
  /// than silently showing fewer rows.
  final Map<DrivingMeasureId, DrivingPatternMeasure> measures;

  /// Trips strictly attributed to this vehicle inside the period.
  final int attributedTripCount;

  /// Of those, the ones whose samples were actually aggregated.
  final int analysedTripCount;

  DrivingPatternMeasure? measure(DrivingMeasureId id) => measures[id];

  Map<String, Object?> toJson() => {
        'vehicleId': vehicleId,
        'attributedTrips': attributedTripCount,
        'analysedTrips': analysedTripCount,
        'totals': totals.toJson(),
        'coverage': coverage.toJson(),
        'measures': {
          for (final m in measures.values) m.id.name: m.toJson(),
        },
      };
}

/// The matched-conditions statement: what was matched on, and what that
/// cost in excluded history.
@immutable
class DrivingPatternMatching {
  const DrivingPatternMatching({
    required this.isMatched,
    required this.cohorts,
    required this.matchedTripCount,
    required this.unmatchedTripCount,
  });

  /// Whether a shared cohort existed at all. When false the comparison
  /// is DESCRIPTIVE: raw observed patterns over unequal conditions, and
  /// every measure carries
  /// [ComparisonQualification.uncontrolledConditions].
  final bool isMatched;

  /// The cohorts every selected vehicle has trips in — the stated
  /// matching criteria.
  final List<DrivingPatternCohort> cohorts;

  /// Trips inside the matched cohorts.
  final int matchedTripCount;

  /// Eligible trips dropped because their cohort was not shared.
  final int unmatchedTripCount;

  Map<String, Object?> toJson() => {
        'matched': isMatched,
        'cohorts': [for (final c in cohorts) c.toJson()],
        'matchedTrips': matchedTripCount,
        'unmatchedTrips': unmatchedTripCount,
      };
}

/// A supported difference between two vehicles on one measure.
///
/// An OBSERVATION. [DrivingMeasureSpec.contextDependent] marks the ones
/// where a higher figure is not even presumptively worse — necessary
/// braking in traffic, a climb, an engine that simply turns faster.
@immutable
class DrivingPatternDifference {
  const DrivingPatternDifference({
    required this.id,
    required this.higherVehicleId,
    required this.lowerVehicleId,
    required this.higher,
    required this.lower,
    required this.qualifications,
    required this.contextDependent,
  });

  final DrivingMeasureId id;
  final String higherVehicleId;
  final String lowerVehicleId;
  final double higher;
  final double lower;
  final Set<ComparisonQualification> qualifications;
  final bool contextDependent;

  double get absoluteDelta => higher - lower;

  /// Delta relative to the lower figure, the ordering key. Infinite when
  /// the lower figure is zero and the higher is not.
  double get relativeDelta => lower > 0
      ? (higher - lower) / lower
      : (higher > 0 ? double.infinity : 0);

  Map<String, Object?> toJson() => {
        'id': id.name,
        'higher': {'vehicleId': higherVehicleId, 'value': higher},
        'lower': {'vehicleId': lowerVehicleId, 'value': lower},
        'contextDependent': contextDependent,
        'qualifications': [for (final q in qualifications) q.name],
      };
}

/// The whole comparison.
@immutable
class DrivingPatternComparison {
  const DrivingPatternComparison({
    required this.subjects,
    required this.matching,
    required this.differences,
    required this.conditionAdjustedRanking,
    required this.unassignedTripCount,
    required this.periodStart,
    required this.periodEnd,
    required this.modelVersion,
  });

  final List<VehicleDrivingPattern> subjects;
  final DrivingPatternMatching matching;

  /// Largest supported differences, widest first.
  final List<DrivingPatternDifference> differences;

  /// The condition-ADJUSTED ranking — i.e. "who drives more efficiently
  /// once route, terrain and traffic are accounted for".
  ///
  /// Always [MetricEligibility.unavailable] on today's data, and the
  /// reason says which input is missing. Kept as a field rather than
  /// omitted so the surface states the refusal instead of letting a
  /// reader mistake the descriptive rates above for an adjusted verdict.
  final ComparableMetric<String> conditionAdjustedRanking;

  /// Trips belonging to no vehicle: counted once, credited to none
  /// (#4364). Counting them per vehicle would inflate every side at once.
  final int unassignedTripCount;

  final DateTime? periodStart;
  final DateTime? periodEnd;

  /// [kDrivingPatternModelVersion] the aggregation ran under.
  final int modelVersion;

  bool get hasEvidence =>
      subjects.any((s) => s.measures.values.any((m) => m.isSupported));

  Map<String, Object?> toJson() => {
        'modelVersion': modelVersion,
        'periodStart': periodStart?.toIso8601String(),
        'periodEnd': periodEnd?.toIso8601String(),
        'unassignedTrips': unassignedTripCount,
        'matching': matching.toJson(),
        'subjects': [for (final s in subjects) s.toJson()],
        'differences': [for (final d in differences) d.toJson()],
        'conditionAdjustedRanking': conditionAdjustedRanking.toJson(),
      };
}
