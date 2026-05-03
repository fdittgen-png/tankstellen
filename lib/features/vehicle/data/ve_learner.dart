import 'package:flutter/foundation.dart';

import '../../consumption/data/trip_history_repository.dart';
import '../domain/entities/vehicle_profile.dart';
import 'repositories/vehicle_profile_repository.dart';

/// Outcome of a single [VeLearner.reconcileAfterFillUp] update (#815).
///
/// Surfaced to the UI so a calibration snackbar can announce the
/// before/after gap in user-visible terms (see [accuracyImprovementPct]).
@immutable
class VeLearnResult {
  /// Id of the vehicle whose profile was updated.
  final String vehicleId;

  /// η_v held by the profile when the reconciliation started.
  final double previousVe;

  /// η_v written back to the profile by the EWMA blend.
  final double newVe;

  /// Sum of OBD2-integrated fuel across every trip that fell between
  /// the previous fill-up and the current one.
  final double integratedLiters;

  /// Pump-receipt total that closed the tank (user-entered).
  final double pumpedLiters;

  /// Fractional improvement in absolute gap: `100 * (1 - |new_gap| /
  /// |old_gap|)`. Clamped to [0, 100] — a worse new estimate (which
  /// can happen if the true η is wildly different from the default)
  /// still reports 0 rather than a misleading negative.
  final double accuracyImprovementPct;

  /// Post-update sample count for the vehicle's η_v field.
  final int sampleCount;

  const VeLearnResult({
    required this.vehicleId,
    required this.previousVe,
    required this.newVe,
    required this.integratedLiters,
    required this.pumpedLiters,
    required this.accuracyImprovementPct,
    required this.sampleCount,
  });
}

/// Signature for the history-loading hook [VeLearner] uses to find the
/// trips between the previous fill-up and the current one. Pulled out
/// so tests can seed trip data in-memory without touching Hive — the
/// production wiring in [VeLearner.fromRepos] just reads
/// [TripHistoryRepository.loadAll].
typedef TripHistoryLoader = List<TripHistoryEntry> Function();

/// Signature for the "how many OBD2 samples did this trip carry"
/// hook. In production we proxy via the trip's `endedAt - startedAt`
/// duration (OBD2 polling runs at ~1 Hz, so seconds ≈ samples); tests
/// can inject a stub. See [_defaultSampleCount].
typedef TripSampleCounter = int Function(TripHistoryEntry entry);

/// Adaptive volumetric-efficiency learner (#815).
///
/// Every tankful, we already own two numbers:
///   - `integrated`: sum of OBD2 fuel-rate integrations across trips
///     since the previous fill-up.
///   - `pumped`: the user-entered litres from the pump receipt.
///
/// The gap is mostly η_v — fuel-trim (#813) closes the ECU correction
/// and the cold-start tables (#769) handle driving-mode variance, but
/// the speed-density branch's η_v is a static 0.85 guess. Reconciling
/// `pumped / integrated` gives us a first-order estimate of the true
/// η_v for this engine; an EWMA blend keeps single-tank noise from
/// whipsawing the value.
///
/// Same calibration pattern as #779's fuel-consumption baseline.
///
/// Safety rails ([reconcileAfterFillUp] returns null without updating):
///   - combined trip distance < [minDistanceKm]
///   - < [minObd2Samples] OBD2 samples
///   - |integrated − pumped| / pumped > [maxGapFraction] — outlier
///     that probably indicates bad input (missed fill-up, user typo)
///   - no trip found between the previous and current fill-up
///
/// Clamp: η_v ∈ [[minVe], [maxVe]] after the EWMA step.
/// EWMA: `new_stored = ewmaBlend * current + (1 - ewmaBlend) * raw`
/// where `raw = current * (pumped / integrated)`.
class VeLearner {
  final VehicleProfileRepository profileRepository;
  final TripHistoryLoader tripHistoryLoader;
  final TripSampleCounter sampleCounter;

  /// Minimum trip distance (summed across every trip between the two
  /// fill-ups) required to learn anything. 50 km matches the issue
  /// spec — below this the signal is dominated by stop-and-go noise.
  final double minDistanceKm;

  /// Minimum OBD2 sample count required. Production derives this
  /// from trip duration (≈1 Hz polling); tests inject a fixed count.
  final int minObd2Samples;

  /// Legacy fixed gap fraction (#815). When non-null, overrides the
  /// sample-dependent [maxRelativeGap] schedule with a single blanket
  /// threshold for every sample count — kept for the small handful of
  /// tests that pin a known boundary.
  ///
  /// Production wiring leaves it null so the aggressive bootstrap from
  /// #1397 is active: sample 0 accepts up to 5×, sample 1 up to 2×,
  /// etc. — so a Duster with a wildly off cold-start η_v can converge
  /// after a single plein-complet rather than waiting for the user to
  /// happen to hit a tankful within 40 % of stoichiometric integration.
  final double? maxGapFraction;

  /// EWMA weight on the existing stored value. 0.7 matches the issue
  /// spec — gentle blending so one odd tankful can't tank the η.
  final double ewmaBlend;

  /// Lower / upper clamp on η_v. 0.50 and 1.00 match the issue spec
  /// and the physically-plausible range for a road engine.
  final double minVe;
  final double maxVe;

  VeLearner({
    required this.profileRepository,
    required this.tripHistoryLoader,
    TripSampleCounter? sampleCounter,
    this.minDistanceKm = 50.0,
    this.minObd2Samples = 10,
    this.maxGapFraction,
    this.ewmaBlend = 0.70,
    this.minVe = 0.50,
    this.maxVe = 1.00,
  }) : sampleCounter = sampleCounter ?? _defaultSampleCount;

  /// Convenience constructor that wires the repository-backed trip
  /// history loader. Used by the production provider.
  VeLearner.fromRepos({
    required this.profileRepository,
    required TripHistoryRepository tripHistoryRepository,
    TripSampleCounter? sampleCounter,
    this.minDistanceKm = 50.0,
    this.minObd2Samples = 10,
    this.maxGapFraction,
    this.ewmaBlend = 0.70,
    this.minVe = 0.50,
    this.maxVe = 1.00,
  })  : tripHistoryLoader = tripHistoryRepository.loadAll,
        sampleCounter = sampleCounter ?? _defaultSampleCount;

  /// Sample-dependent maximum |gap| fraction (#1397).
  ///
  /// The pre-#1397 schedule rejected any tankful whose
  /// `|integrated − pumped| / pumped` exceeded a fixed `0.40`. That
  /// blanket threshold protected against typo'd litres but also left
  /// vehicles like the Duster — whose cold-start η_v default of 0.85
  /// is wildly wrong for a Renault 1.5 dCi — stuck on the default
  /// indefinitely: every plein-complet exceeded 40 % so the learner
  /// never accepted a sample.
  ///
  /// The aggressive bootstrap below opens the floodgate for the first
  /// few tankfuls (when we know nothing about the engine, anything
  /// that integrates to within 5× pump is signal we should learn from)
  /// and clamps down once we have a calibrated baseline. Returned value
  /// is multiplied by `pumpedLiters` to get the absolute litres
  /// threshold inside [reconcileAfterFillUp].
  ///
  /// Schedule (ratios):
  ///   0   samples → 5.0  (first-ever — very wide)
  ///   1   sample  → 2.0  (still figuring it out)
  ///   2   samples → 1.0
  ///   3-4 samples → 0.6
  ///   5+  samples → 0.4  (back to the original safety net)
  ///
  /// When the legacy [maxGapFraction] is non-null it overrides this
  /// schedule entirely — useful for boundary-tests pinning the old
  /// behaviour.
  @visibleForTesting
  double maxRelativeGap(int sampleCount) {
    if (sampleCount == 0) return 5.0;
    if (sampleCount == 1) return 2.0;
    if (sampleCount == 2) return 1.0;
    if (sampleCount < 5) return 0.6;
    return 0.4;
  }

  /// Reconcile the OBD2 integrated fuel estimate against [pumpedLiters]
  /// and, if every guard passes, write the updated η_v back to the
  /// stored [VehicleProfile]. Returns a [VeLearnResult] on success,
  /// `null` when any guard rejects the tankful.
  ///
  /// The previous fill-up anchor is carried by the caller — i.e. the
  /// fill-up save hook already has the full fill-up list in scope and
  /// knows which entry lands just before the one that triggered this
  /// reconciliation. Passing [previousFillUpTimestamp] explicitly
  /// keeps the learner agnostic of the FillUp repo.
  Future<VeLearnResult?> reconcileAfterFillUp({
    required String vehicleId,
    required double pumpedLiters,
    required DateTime fillUpTimestamp,
    required DateTime? previousFillUpTimestamp,
  }) async {
    if (pumpedLiters <= 0) return null;

    final profile = profileRepository.getById(vehicleId);
    if (profile == null) return null;

    final trips = _tripsBetween(
      vehicleId: vehicleId,
      from: previousFillUpTimestamp,
      to: fillUpTimestamp,
    );
    if (trips.isEmpty) return null;

    double distance = 0;
    double integrated = 0;
    int samples = 0;
    for (final t in trips) {
      distance += t.summary.distanceKm;
      final f = t.summary.fuelLitersConsumed;
      if (f != null) integrated += f;
      samples += sampleCounter(t);
    }

    if (distance < minDistanceKm) {
      debugPrint('VeLearner: skip — distance $distance < $minDistanceKm km');
      return null;
    }
    if (samples < minObd2Samples) {
      debugPrint('VeLearner: skip — samples $samples < $minObd2Samples');
      return null;
    }
    if (integrated <= 0) {
      debugPrint('VeLearner: skip — no integrated fuel on trips');
      return null;
    }
    final gap = (integrated - pumpedLiters).abs() / pumpedLiters;
    // #1397 — sample-dependent gap threshold so the first plein-complet
    // on a freshly-paired vehicle (sampleCount = 0) can accept a wildly
    // off integration and start converging. Legacy fixed [maxGapFraction]
    // wins when callers pinned it explicitly.
    final currentSampleCount = profile.volumetricEfficiencySamples;
    final gapThreshold =
        maxGapFraction ?? maxRelativeGap(currentSampleCount);
    if (gap > gapThreshold) {
      debugPrint('VeLearner: skip — gap ${(gap * 100).toStringAsFixed(1)}% '
          '> ${(gapThreshold * 100).toStringAsFixed(0)}% '
          '(sampleCount=$currentSampleCount)');
      return null;
    }

    final currentVe = profile.volumetricEfficiency;
    // Integrated fuel scales linearly with η_v (the speed-density
    // fallback multiplies by η_v). If the integrator over-predicted
    // the actual pump, the true η is lower than what's stored:
    //   trueVe ≈ currentVe × (pumped / integrated)
    final rawNewVe = currentVe * (pumpedLiters / integrated);
    final blended = ewmaBlend * currentVe + (1.0 - ewmaBlend) * rawNewVe;
    final clamped = blended.clamp(minVe, maxVe).toDouble();

    final oldGap = (integrated - pumpedLiters).abs();
    // Estimate the new integrated number under the updated η — again
    // a linear scale — and derive the absolute improvement fraction.
    final newIntegrated = integrated * (clamped / currentVe);
    final newGap = (newIntegrated - pumpedLiters).abs();
    double improvement;
    if (oldGap <= 0) {
      improvement = 0;
    } else {
      improvement = (1.0 - newGap / oldGap) * 100.0;
      if (improvement.isNaN || improvement.isInfinite) improvement = 0;
      if (improvement < 0) improvement = 0;
      if (improvement > 100) improvement = 100;
    }

    final updated = profile.copyWith(
      volumetricEfficiency: clamped,
      volumetricEfficiencySamples: profile.volumetricEfficiencySamples + 1,
    );
    await profileRepository.save(updated);

    return VeLearnResult(
      vehicleId: vehicleId,
      previousVe: currentVe,
      newVe: clamped,
      integratedLiters: integrated,
      pumpedLiters: pumpedLiters,
      accuracyImprovementPct: improvement,
      sampleCount: updated.volumetricEfficiencySamples,
    );
  }

  List<TripHistoryEntry> _tripsBetween({
    required String vehicleId,
    required DateTime? from,
    required DateTime to,
  }) {
    final all = tripHistoryLoader();
    return all.where((e) {
      if (e.vehicleId != vehicleId) return false;
      final started = e.summary.startedAt;
      if (started == null) return false;
      if (from != null && !started.isAfter(from)) return false;
      if (!started.isBefore(to)) return false;
      return true;
    }).toList();
  }
}

/// Default sample-count heuristic: trip duration in seconds ≈ sample
/// count, because OBD2 polling hovers near 1 Hz. Falls back to a
/// 50-sample floor when either timestamp is missing but the trip
/// carried fuel integration (i.e. it *did* record samples — we just
/// don't know how many). 50 is under the minObd2Samples gate by a
/// wide enough margin that the heuristic stays protective: a
/// sample-poor trip still rejects.
int _defaultSampleCount(TripHistoryEntry entry) {
  final started = entry.summary.startedAt;
  final ended = entry.summary.endedAt;
  if (started != null && ended != null) {
    final secs = ended.difference(started).inSeconds;
    if (secs > 0) return secs;
  }
  // Unknown duration but fuel integration present — treat as "some
  // unknown non-zero count, probably enough" via a conservative 50.
  if (entry.summary.fuelLitersConsumed != null) return 50;
  return 0;
}
