// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #4366 (Epic #4358, work package G) — the TYPED raw evidence a driving
/// pattern comparison may aggregate.
///
/// ## Why the existing calculator outputs cannot be aggregated
///
/// [DrivingDimension] carries exactly two numbers, and neither of them
/// survives a sum across trips:
///
///  * `value` is **clipped and composite**. The acceleration dimension is
///    `clamp01(1 - eventsPerKm * 0.5 - fullThrottleShare * 2)` — two
///    different quantities folded into one 0..1 figure and then clamped.
///    Averaging it over a history averages a saturation artefact: two
///    trips at 0.0 may be ten times apart in real behaviour, and the mean
///    of the clipped scores is not the score of the mean behaviour.
///  * `evidenceCount` is **not a uniform event count**. For
///    `accelerationDemand` it is `accelEvents + fullThrottleSeconds.round()`
///    — an event count added to a rounded duration. For `speedStability`
///    and `avoidableIdle` it is seconds; for `brakingAnticipation` and
///    `energyOscillation` it is events; for `curveApproach` it is curves.
///    Dividing it by distance would produce "60 hard accelerations per
///    trip" out of one minute of steady full throttle.
///
/// So this library adds the missing half of the contract: numerators
/// **typed by what they measure** ([DrivingEventCounter] counts events,
/// [DrivingDurationCounter] counts seconds, and the two live in separate
/// maps so no addition can ever mix them) and the **eligible exposure**
/// each one may be divided by ([DrivingExposureBasis]), which accrues
/// only over the stretch where the required signal was actually present.
///
/// That last point is the whole missing-is-unknown rule expressed in
/// arithmetic: a GPS-only recording accrues zero *exposure* for
/// RPM-denominated measures, so those measures come back
/// [MetricEligibility.unavailable] — never a flattering zero.
library;

import 'package:meta/meta.dart';

/// Bump when a counter's meaning, a threshold behind it, or the set of
/// measures changes: every cached per-trip total keyed under an older
/// version is a miss, so a model change re-derives rather than silently
/// mixing two definitions in one average (#4366).
const int kDrivingPatternModelVersion = 1;

/// A numerator that counts **discrete events**. Never seconds.
enum DrivingEventCounter {
  hardAccelEvents,
  hardBrakeEvents,
  avoidableHardBrakeEvents,
  energyOscillationEpisodes,
  judgedCurves,
  lateBrakeCurves,
  longIdleEpisodes,
}

/// A numerator that counts **seconds**. Never events.
enum DrivingDurationCounter {
  fullThrottleSeconds,
  longIdleSeconds,
  highRpmSeconds,
  sustainedHighSpeedSeconds,
  fuelCutSeconds,
  climbFullThrottleSeconds,
  flatFullThrottleSeconds,
}

/// An eligible denominator — the exposure over which a numerator was
/// even *observable*.
///
/// Each basis accrues only while its signal was present. `pedalKnownSeconds`
/// does not advance through a stretch with no pedal/throttle PID, and
/// `rpmKnownMovingSeconds` does not advance on a GPS-only trip. A measure
/// whose basis is zero has no value at all.
enum DrivingExposureBasis {
  /// Distance covered while actually moving, in km.
  movingDistanceKm,

  /// Seconds spent moving.
  movingSeconds,

  /// Seconds with a pedal or throttle reading.
  pedalKnownSeconds,

  /// Seconds — moving or stationary — with an RPM reading, i.e. seconds
  /// in which the engine state was KNOWN.
  engineKnownSeconds,

  /// Seconds moving with an RPM reading.
  rpmKnownMovingSeconds,

  /// Hard-brake events, as the denominator of the avoidable share.
  hardBrakeEvents,

  /// Curves whose approach could be judged at all.
  judgedCurves,

  /// Seconds decelerating with a fuel-rate reading.
  decelWithFuelRateSeconds,

  /// Seconds on a confidently-measured climb.
  confidentClimbSeconds,

  /// Seconds on confidently-measured flat road.
  confidentFlatSeconds,

  /// Seconds with a coolant reading. Not a measure denominator — it is
  /// what separates an OBSERVED warm start from absent coolant evidence
  /// (`TripSummary.coldStartSurcharge` defaults to false either way).
  coolantKnownSeconds,
}

/// One trip's (or one cohort's) additive raw evidence.
///
/// Additive by construction: `a + b` sums each counter and each basis
/// independently, and the three maps cannot cross-contaminate because
/// their keys are different types. This is the property `DrivingDimension`
/// lacks and the reason this type exists.
@immutable
class DrivingPatternTotals {
  DrivingPatternTotals({
    Map<DrivingEventCounter, int> events = const {},
    Map<DrivingDurationCounter, double> seconds = const {},
    Map<DrivingExposureBasis, double> exposure = const {},
    this.modelVersion = kDrivingPatternModelVersion,
  })  : events = Map.unmodifiable({
          for (final e in events.entries)
            if (e.value != 0) e.key: e.value,
        }),
        seconds = Map.unmodifiable({
          for (final e in seconds.entries)
            if (e.value != 0) e.key: e.value,
        }),
        exposure = Map.unmodifiable({
          for (final e in exposure.entries)
            if (e.value != 0) e.key: e.value,
        });

  /// No evidence at all — distinct from "measured zero", which carries
  /// exposure.
  static final DrivingPatternTotals empty = DrivingPatternTotals();

  final Map<DrivingEventCounter, int> events;
  final Map<DrivingDurationCounter, double> seconds;
  final Map<DrivingExposureBasis, double> exposure;

  /// The [kDrivingPatternModelVersion] these numbers were produced under.
  final int modelVersion;

  int eventCount(DrivingEventCounter c) => events[c] ?? 0;
  double durationSeconds(DrivingDurationCounter c) => seconds[c] ?? 0;
  double exposureOf(DrivingExposureBasis b) => exposure[b] ?? 0;

  bool get isEmpty =>
      events.isEmpty && seconds.isEmpty && exposure.isEmpty;

  /// Sum of two trips' evidence. Only totals of the same
  /// [modelVersion] may be added — mixing definitions inside one average
  /// is exactly the silent drift the version stamp exists to prevent.
  DrivingPatternTotals operator +(DrivingPatternTotals other) {
    if (other.modelVersion != modelVersion) {
      throw ArgumentError.value(
          other.modelVersion,
          'modelVersion',
          'cannot add driving-pattern totals of model version '
              '${other.modelVersion} to version $modelVersion');
    }
    return DrivingPatternTotals(
      modelVersion: modelVersion,
      events: {
        for (final k in {...events.keys, ...other.events.keys})
          k: eventCount(k) + other.eventCount(k),
      },
      seconds: {
        for (final k in {...seconds.keys, ...other.seconds.keys})
          k: durationSeconds(k) + other.durationSeconds(k),
      },
      exposure: {
        for (final k in {...exposure.keys, ...other.exposure.keys})
          k: exposureOf(k) + other.exposureOf(k),
      },
    );
  }

  Map<String, Object?> toJson() => {
        'modelVersion': modelVersion,
        'events': {for (final e in events.entries) e.key.name: e.value},
        'seconds': {for (final e in seconds.entries) e.key.name: e.value},
        'exposure': {for (final e in exposure.entries) e.key.name: e.value},
      };

  @override
  String toString() => 'DrivingPatternTotals(${toJson()})';
}

/// How a measure's value is expressed.
enum DrivingMeasureUnit {
  /// Events per 100 km — the comparable rate. 10 events over 100 km and
  /// 100 over 1 000 km are the SAME rate; the exposure beside it is what
  /// says how much evidence each rests on.
  eventsPer100Km,

  /// A 0..1 share of the eligible exposure.
  share,
}

/// The measures this comparison is willing to state.
enum DrivingMeasureId {
  hardAccelRate,
  fullThrottleShare,
  hardBrakeRate,
  avoidableBrakeShare,
  engineIdleShare,
  highRpmShare,
  sustainedHighSpeedShare,
  energyOscillationRate,
  coastingFuelCutShare,
  lateCurveShare,
  climbFullThrottleShare,
  flatFullThrottleShare,
}

/// A measure's definition: exactly one typed numerator over exactly one
/// eligible denominator.
///
/// The constructor asserts the numerator is one or the other, so the
/// events-plus-rounded-seconds conflation in `DrivingDimension.evidenceCount`
/// cannot be reproduced here even by accident.
@immutable
class DrivingMeasureSpec {
  const DrivingMeasureSpec({
    required this.id,
    required this.unit,
    required this.exposureBasis,
    required this.minimumExposure,
    this.eventNumerator,
    this.durationNumerator,
    this.contextDependent = false,
  }) : assert((eventNumerator == null) != (durationNumerator == null),
            'a measure counts events or seconds, never both');

  final DrivingMeasureId id;
  final DrivingMeasureUnit unit;

  /// Set exactly when the numerator counts events.
  final DrivingEventCounter? eventNumerator;

  /// Set exactly when the numerator counts seconds.
  final DrivingDurationCounter? durationNumerator;

  final DrivingExposureBasis exposureBasis;

  /// Below this much exposure the measure is not stated at all.
  final double minimumExposure;

  /// True when a higher figure is NOT automatically worse driving: a
  /// climb, a curve and a necessary brake are context, not a verdict
  /// (#4366 acceptance). The surface must say so beside the number.
  final bool contextDependent;
}

/// The measure table. The single place a rate's numerator and its
/// denominator are paired, so every displayed figure is traceable.
const List<DrivingMeasureSpec> kDrivingMeasures = [
  DrivingMeasureSpec(
    id: DrivingMeasureId.hardAccelRate,
    unit: DrivingMeasureUnit.eventsPer100Km,
    eventNumerator: DrivingEventCounter.hardAccelEvents,
    exposureBasis: DrivingExposureBasis.movingDistanceKm,
    minimumExposure: 1,
  ),
  DrivingMeasureSpec(
    id: DrivingMeasureId.fullThrottleShare,
    unit: DrivingMeasureUnit.share,
    durationNumerator: DrivingDurationCounter.fullThrottleSeconds,
    exposureBasis: DrivingExposureBasis.pedalKnownSeconds,
    minimumExposure: 60,
  ),
  DrivingMeasureSpec(
    id: DrivingMeasureId.hardBrakeRate,
    unit: DrivingMeasureUnit.eventsPer100Km,
    eventNumerator: DrivingEventCounter.hardBrakeEvents,
    exposureBasis: DrivingExposureBasis.movingDistanceKm,
    minimumExposure: 1,
    contextDependent: true,
  ),
  DrivingMeasureSpec(
    id: DrivingMeasureId.avoidableBrakeShare,
    unit: DrivingMeasureUnit.share,
    eventNumerator: DrivingEventCounter.avoidableHardBrakeEvents,
    exposureBasis: DrivingExposureBasis.hardBrakeEvents,
    minimumExposure: 3,
  ),
  DrivingMeasureSpec(
    id: DrivingMeasureId.engineIdleShare,
    unit: DrivingMeasureUnit.share,
    durationNumerator: DrivingDurationCounter.longIdleSeconds,
    exposureBasis: DrivingExposureBasis.engineKnownSeconds,
    minimumExposure: 120,
  ),
  DrivingMeasureSpec(
    id: DrivingMeasureId.highRpmShare,
    unit: DrivingMeasureUnit.share,
    durationNumerator: DrivingDurationCounter.highRpmSeconds,
    exposureBasis: DrivingExposureBasis.rpmKnownMovingSeconds,
    minimumExposure: 120,
    contextDependent: true,
  ),
  DrivingMeasureSpec(
    id: DrivingMeasureId.sustainedHighSpeedShare,
    unit: DrivingMeasureUnit.share,
    durationNumerator: DrivingDurationCounter.sustainedHighSpeedSeconds,
    exposureBasis: DrivingExposureBasis.movingSeconds,
    minimumExposure: 120,
  ),
  DrivingMeasureSpec(
    id: DrivingMeasureId.energyOscillationRate,
    unit: DrivingMeasureUnit.eventsPer100Km,
    eventNumerator: DrivingEventCounter.energyOscillationEpisodes,
    exposureBasis: DrivingExposureBasis.movingDistanceKm,
    minimumExposure: 5,
    contextDependent: true,
  ),
  DrivingMeasureSpec(
    id: DrivingMeasureId.coastingFuelCutShare,
    unit: DrivingMeasureUnit.share,
    durationNumerator: DrivingDurationCounter.fuelCutSeconds,
    exposureBasis: DrivingExposureBasis.decelWithFuelRateSeconds,
    minimumExposure: 30,
  ),
  DrivingMeasureSpec(
    id: DrivingMeasureId.lateCurveShare,
    unit: DrivingMeasureUnit.share,
    eventNumerator: DrivingEventCounter.lateBrakeCurves,
    exposureBasis: DrivingExposureBasis.judgedCurves,
    minimumExposure: 3,
    contextDependent: true,
  ),
  DrivingMeasureSpec(
    id: DrivingMeasureId.climbFullThrottleShare,
    unit: DrivingMeasureUnit.share,
    durationNumerator: DrivingDurationCounter.climbFullThrottleSeconds,
    exposureBasis: DrivingExposureBasis.confidentClimbSeconds,
    minimumExposure: 60,
    contextDependent: true,
  ),
  DrivingMeasureSpec(
    id: DrivingMeasureId.flatFullThrottleShare,
    unit: DrivingMeasureUnit.share,
    durationNumerator: DrivingDurationCounter.flatFullThrottleSeconds,
    exposureBasis: DrivingExposureBasis.confidentFlatSeconds,
    minimumExposure: 60,
  ),
];

/// The spec for [id]. Total over [DrivingMeasureId] by construction.
DrivingMeasureSpec measureSpec(DrivingMeasureId id) =>
    kDrivingMeasures.firstWhere((m) => m.id == id);
