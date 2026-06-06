// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../domain/gps_track_distance.dart';
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
  double? _gpsTrackDistanceKm() {
    if (_gpsTrack.length < kMinGpsFixesForDistanceSource) return null;
    final km = GpsTrackDistance.haversineKm(_gpsTrack);
    if (km < 0.05) return null;
    return km;
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

  /// Count of GPS fixes buffered so far (#2509). Used by the controller +
  /// persist guard to tell a genuinely-stationary trip (no movement, no
  /// signal) apart from a real GPS-tracked drive whose OBD2 link was dead
  /// — the latter has fixes here even when no speed/RPM sample ever
  /// reached the recorder. Not the distance: a parked car can scatter a
  /// handful of fixes, so callers pair this with [distanceKm].
  int get gpsFixCount => _gpsTrack.length;
}
