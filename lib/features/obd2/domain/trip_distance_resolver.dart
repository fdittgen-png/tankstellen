// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../core/telemetry/health_counters.dart';
import '../../consumption/domain/gps_track_distance.dart';
import 'trip_distance_source.dart';
import 'virtual_odometer.dart';

/// Owns the trip's distance-resolution concern — the pure, async-free,
/// stream-free three-tier selection between the car's odometer delta, a
/// haversine-summed GPS track, and the trapezoidal virtual-odometer
/// integral — extracted from [TripRecordingController] as the first slice
/// of the #2187 god-class decomposition.
///
/// ## Why this is a clean, isolated unit
///
/// The resolver holds the two rolling sample buffers it integrates over
/// (`_speedSamples` for the virtual odometer, `_gpsTrack` for the GPS
/// source) and nothing else — no timers, no streams, no Hive, no
/// Riverpod. It mirrors the pure-Dart collaborator pattern already
/// established for this class (`TripDropDetector`, `TripSampleBuffer`,
/// #1679).
///
/// ## What it deliberately does NOT own
///
/// The odometer readings (`odometerStartKm` / `odometerLatestKm`) stay on
/// the controller — they are shared state read and written at six other
/// sites unrelated to distance (`start`, `refreshOdometer`, the public
/// getters, paused-trip persistence, the live emit loop). Pulling them in
/// here would widen the blast radius well beyond a behaviour-preserving
/// extraction, so instead they are passed into [distanceKm] / [distanceSource]
/// as arguments (#2187 adversarial-verification scoping).
///
/// ## Trimming asymmetry (preserved verbatim)
///
/// The production ingress paths [addSpeedSample] / [addGpsFix] cap the
/// buffers at [kVirtualOdometerSampleCap], dropping the oldest slice. The
/// `@visibleForTesting` ingress paths [debugAddSpeedSample] /
/// [debugAddGpsFix] intentionally do NOT trim — they let a test build an
/// arbitrarily long deterministic buffer. That deliberate asymmetry is
/// preserved exactly as it was on the controller.
class TripDistanceResolver {
  /// Maximum Δt (seconds) between virtual-odometer samples that the
  /// integrator bridges (#1927). Passed in from the controller so the
  /// resolver shares the same integration-gap cap the recorder uses.
  final double maxIntegrationGapSeconds;

  /// Clock used to timestamp speed samples appended via [addSpeedSample].
  /// Injected so the resolver matches whatever clock the controller was
  /// constructed with (real or test fake).
  final DateTime Function() _now;

  /// Rolling buffer of `(timestamp, speedKmh)` samples used by the
  /// virtual odometer (#800). Populated by the 5 Hz speed subscription
  /// callback via [addSpeedSample]; capped at [kVirtualOdometerSampleCap]
  /// so a forgotten recording can't eat unbounded memory. Fed to
  /// [VirtualOdometer] at finalisation when the car doesn't expose a real
  /// odometer.
  final List<VirtualOdometerSample> _speedSamples = <VirtualOdometerSample>[];

  /// Rolling buffer of GPS fixes for the #1979 GPS-distance source.
  /// Appended by [addGpsFix] (one entry per Geolocator fix);
  /// haversine-summed at finalisation when a usable track exists. Capped
  /// at [kVirtualOdometerSampleCap] — the same generous bound the speed
  /// buffer uses — so a forgotten recording stays bounded.
  final List<GpsTrackPoint> _gpsTrack = <GpsTrackPoint>[];

  TripDistanceResolver({
    required this.maxIntegrationGapSeconds,
    required DateTime Function() now,
  }) : _now = now;

  /// Append a speed sample to the virtual-odometer buffer, dropping the
  /// oldest entry when the cap is hit. Called from the 5 Hz vehicle-speed
  /// subscription.
  void addSpeedSample(double speedKmh) {
    _speedSamples.add(VirtualOdometerSample(
      timestamp: _now(),
      speedKmh: speedKmh,
    ));
    if (_speedSamples.length > kVirtualOdometerSampleCap) {
      // Drop the oldest slice to keep memory bounded. Losing the early
      // stretch biases the virtual-odometer low by the km we dropped; on
      // a typical trip the cap is never hit.
      _speedSamples.removeRange(
        0,
        _speedSamples.length - kVirtualOdometerSampleCap,
      );
    }
  }

  /// Append one real GPS fix to the #1979 track buffer, dropping the
  /// oldest slice when the cap is hit. The controller calls this only for
  /// non-null coordinate pairs — a null-coord call clears the per-tick
  /// latch and is not a fix.
  ///
  /// [hAccuracyM] (the fix's reported horizontal accuracy) and [at] (its
  /// timestamp) are forwarded onto the buffered point so
  /// [GpsTrackDistance.haversineKm] can reject a parked car's jitter
  /// (accuracy gate) and a cold-start position jump (teleport gate) at
  /// finalisation (#2963). Both are optional: a null `at` falls back to the
  /// resolver clock, a null `hAccuracyM` is "unknown, accept", so a caller
  /// passing only coordinates behaves exactly as before.
  void addGpsFix(
    double latitude,
    double longitude, {
    double? hAccuracyM,
    DateTime? at,
  }) {
    _gpsTrack.add(GpsTrackPoint(
      latitude,
      longitude,
      hAccuracyM: hAccuracyM,
      at: at ?? _now(),
    ));
    if (_gpsTrack.length > kVirtualOdometerSampleCap) {
      _gpsTrack.removeRange(
        0,
        _gpsTrack.length - kVirtualOdometerSampleCap,
      );
    }
  }

  /// Distance covered by the current trip so far (#800), resolved against
  /// the controller-held odometer readings passed in.
  ///
  /// Resolution order (#800 / #1979):
  ///   1. the ground-truth `odometerLatest - odometerStart` when both
  ///      readings are present AND moved forward by more than a
  ///      noise-floor epsilon (odometer PIDs are quantised to 0.1 km on
  ///      most cars — a 0.09-km delta is a sensor artefact);
  ///   2. the haversine-summed GPS track, when a usable one was recorded
  ///      — true road distance, free of the speed sensor's over-read;
  ///   3. the trapezoidal integral of buffered speed samples via
  ///      [VirtualOdometer], when the car exposes no odometer (Peugeot 107
  ///      class) and no GPS track was captured.
  double distanceKm({
    required double? odometerStartKm,
    required double? odometerLatestKm,
  }) {
    final real = _realOdometerDeltaKm(odometerStartKm, odometerLatestKm);
    if (real != null) return real;
    final gps = _gpsTrackDistanceKm();
    if (gps != null) return gps;
    return VirtualOdometer(
      samples: _speedSamples,
      maxGapSeconds: maxIntegrationGapSeconds,
    ).integrateKm();
  }

  /// [kDistanceSourceReal] when [distanceKm] came from the car's odometer,
  /// [kDistanceSourceGps] when it came from the haversine-summed GPS track
  /// (#1979), [kDistanceSourceVirtual] when it came from [VirtualOdometer]
  /// integration (#800). Persisted on the finalised [TripSummary] so the
  /// fill-up flow and eco-analytics know whether to treat the km as a
  /// ground truth or as an estimate.
  String distanceSource({
    required double? odometerStartKm,
    required double? odometerLatestKm,
  }) {
    if (_realOdometerDeltaKm(odometerStartKm, odometerLatestKm) != null) {
      return kDistanceSourceReal;
    }
    if (_gpsTrackDistanceKm() != null) return kDistanceSourceGps;
    return kDistanceSourceVirtual;
  }

  /// `odometerLatest - odometerStart` if both are present and the delta is
  /// above a small noise-floor epsilon (0.05 km — half the 0.1 km
  /// quantisation most cars apply to PID A6). Returns null otherwise so
  /// callers can fall back to the GPS / virtual odometer.
  double? _realOdometerDeltaKm(double? start, double? latest) {
    if (start == null || latest == null) return null;
    final delta = latest - start;
    if (delta < 0.05) return null;
    return delta;
  }

  /// Haversine-summed distance of the buffered GPS track, or null when the
  /// track is too sparse to trust (#1979): fewer than
  /// [kMinGpsFixesForDistanceSource] fixes, or a sub-50 m total (a parked
  /// car's GPS scatter). Callers then fall back to the virtual odometer.
  ///
  /// The track is decimated to ~1 Hz BEFORE haversine-summing (#3004). The
  /// trip GPS stream runs at `LocationAccuracy.high` with no `distanceFilter`
  /// (= every OS fix), so on a SLOW drive the OS delivers ~4-5 fixes/s. The
  /// per-fix lateral GPS wander (~5-12 m, good accuracy) clears the 3 m
  /// jitter floor and is well under the #2963 accuracy / teleport gates, so
  /// the full-rate sum accumulates every sub-second zig-zag vertex — a true
  /// ~1.72 km drive inflates to ~3.5 km (~2×). Those in-between vertices add
  /// only jitter, not net displacement, so dropping them down to one fix per
  /// ~second collapses the inflation while leaving the true road distance.
  /// A genuine 1 Hz track (highway, where the OS thins fast motion) keeps
  /// every fix, so it is unaffected — no under-count.
  ///
  /// The [kMinGpsFixesForDistanceSource] gate is intentionally checked on the
  /// RAW buffer (a real drive always has plenty of raw fixes); decimation
  /// only changes which vertices the haversine sums.
  double? _gpsTrackDistanceKm() {
    if (_gpsTrack.length < kMinGpsFixesForDistanceSource) return null;
    final km = GpsTrackDistance.haversineKm(_decimatedTrack());
    if (km < 0.05) return null;
    return km;
  }

  /// Minimum gap (ms) between two KEPT GPS fixes when decimating the track
  /// to ~1 Hz before haversine-summing (#3004). Mirrors the 950 ms gate
  /// [TripSampleBuffer.maybeCapture] uses for the trip-detail charts — the
  /// slack below 1000 ms lets a slightly-jittered 1 Hz fix (998 ms) still
  /// count, so a genuine 1 Hz track is never thinned.
  static const int _gpsDecimationGapMs = 950;

  /// [_gpsTrack] thinned to ~1 Hz: a fix is kept only when its timestamp is
  /// at least [_gpsDecimationGapMs] after the last KEPT fix (#3004). Two
  /// timestamp cases keep the full legacy haversine behaviour
  /// (backward-compatible) — the fix is always kept and the gate is NOT
  /// advanced:
  ///
  ///   * a null timestamp ([GpsTrackPoint.at] == null) — a pre-#2970 /
  ///     coordinate-only caller carries no fix time to decimate by;
  ///   * a non-advancing clock (Δt ≤ 0 vs the last kept fix) — the
  ///     timestamps carry no thinning information (a frozen test clock, or a
  ///     same-instant duplicate burst), so they cannot be decimated.
  ///
  /// In production the injected clock is the real wall clock (`DateTime.now`,
  /// strictly increasing), so a ~4-5 Hz slow drive yields ~200 ms gaps
  /// (0 < Δt < 950 ⇒ thinned) while a genuine 1 Hz track keeps every fix.
  List<GpsTrackPoint> _decimatedTrack() {
    final kept = <GpsTrackPoint>[];
    DateTime? lastKeptAt;
    for (final p in _gpsTrack) {
      final at = p.at;
      final keep = at == null ||
          lastKeptAt == null ||
          at.difference(lastKeptAt).inMilliseconds >= _gpsDecimationGapMs ||
          !at.isAfter(lastKeptAt);
      if (keep) {
        kept.add(p);
        if (at != null) lastKeptAt = at;
      }
    }
    // Always retain the final raw fix. A time-compressed burst — a device
    // that coalesces a batch of fixes onto one sub-second timestamp, or a
    // synchronous test feed — otherwise decimates to the single first point
    // and haversine-sums to 0 km, silently dropping a real drive (the #3004
    // regression the #2509 journey invariant catches). Keeping the endpoint
    // never re-inflates jitter: the tail segment spans <1 s of real motion
    // (or ~0 m when the car is parked at trip end).
    if (_gpsTrack.isNotEmpty && !identical(kept.last, _gpsTrack.last)) {
      kept.add(_gpsTrack.last);
    }
    return kept;
  }

  /// Test seam: append a speed sample to the virtual-odometer buffer
  /// WITHOUT the cap trim, so tests can build a deterministic buffer +
  /// read [distanceKm] / [distanceSource] (#800). Mirrors the controller's
  /// pre-extraction `debugRecordSpeedSample` semantics, which deliberately
  /// skipped trimming. Not marked `@visibleForTesting` because the
  /// controller's own (test-only) `debugRecordSpeedSample` pass-through
  /// delegates here.
  void debugAddSpeedSample({required double speedKmh, required DateTime at}) {
    _speedSamples.add(
      VirtualOdometerSample(timestamp: at, speedKmh: speedKmh),
    );
  }

  /// Test seam: append a GPS fix to the #1979 track buffer WITHOUT the cap
  /// trim, so tests can drive the GPS-distance path deterministically.
  /// Mirrors the controller's pre-extraction `debugAppendGpsFix`
  /// semantics. Plain (not `@visibleForTesting`) for the same reason as
  /// [debugAddSpeedSample].
  ///
  /// [hAccuracyM] / [at] are optional so a test can drive the #2963
  /// accuracy + teleport gates deterministically; null `at` falls back to
  /// the resolver clock, matching [addGpsFix].
  void debugAddGpsFix({
    required double latitude,
    required double longitude,
    double? hAccuracyM,
    DateTime? at,
  }) {
    _gpsTrack.add(GpsTrackPoint(
      latitude,
      longitude,
      hAccuracyM: hAccuracyM,
      at: at ?? _now(),
    ));
  }

  /// Read-only view of the captured speed samples. Surfaced so the
  /// controller's (test-only) `debugSpeedSamples` getter can pass it
  /// straight through.
  List<VirtualOdometerSample> get debugSpeedSamples =>
      List.unmodifiable(_speedSamples);

  /// Per-gate rejection tally over the buffered track (#3253): how many
  /// segments (and km) the #2963 accuracy / teleport gates and the #1979
  /// jitter floor dropped, plus what the #3004 ~1 Hz decimation thinned
  /// away. Pure read — safe to call repeatedly; each call re-derives the
  /// figures from the current buffer.
  ///
  /// Decimation attribution: the gates run on BOTH passes, so the delta
  /// between the raw-track sum and the decimated-track sum is exactly the
  /// jitter km the thinning collapsed (never negative — clamped against
  /// floating-point drift).
  GpsGateRejectionTally gateRejectionTally() {
    final tally = GpsGateRejectionTally();
    final decimated = _decimatedTrack();
    final keptKm = GpsTrackDistance.haversineKm(decimated, tally: tally);
    final rawKm = GpsTrackDistance.haversineKm(_gpsTrack);
    tally.decimationDroppedFixes = _gpsTrack.length - decimated.length;
    final collapsed = rawKm - keptKm;
    tally.decimationCollapsedKm = collapsed > 0 ? collapsed : 0;
    return tally;
  }

  /// One-shot publish latch: [publishGateRejectionTally] fires at most
  /// once per resolver (= per trip), so a re-entrant stop can't double
  /// the counters.
  bool _gateTallyPublished = false;

  /// Publish [gateRejectionTally] into the always-on #3146
  /// [HealthCounters] (`trips.gps.*`), once per trip (#3253). Called
  /// from the controller's stop path — NOT from the live distance
  /// getters, which run per emit tick and would over-count. No-op when
  /// nothing was rejected (sparse counter rows) and on every call after
  /// the first. `HealthCounters.increment` never throws by contract.
  void publishGateRejectionTally() {
    if (_gateTallyPublished) return;
    _gateTallyPublished = true;
    for (final entry in gateRejectionTally().toCounterIncrements().entries) {
      healthCounters.increment(entry.key, by: entry.value);
    }
  }

  /// Count of GPS fixes buffered so far (#2509). Used by the controller +
  /// persist guard to tell a genuinely-stationary trip (no movement, no
  /// signal) apart from a real GPS-tracked drive whose OBD2 link was dead
  /// — the latter has fixes here even when no speed/RPM sample ever
  /// reached the recorder. Not the distance: a parked car can scatter a
  /// handful of fixes, so callers pair this with [distanceKm].
  int get gpsFixCount => _gpsTrack.length;
}
