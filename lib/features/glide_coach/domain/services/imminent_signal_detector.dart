// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/utils/geo_utils.dart' as geo;
import '../../data/traffic_signal_repository.dart';
import '../entities/traffic_signal.dart';

/// Forward-cone half-angle (degrees) — a signal must lie within
/// ±[_kForwardConeHalfDeg] of the user's heading vector to count as
/// "ahead". Tight enough that signals on parallel streets are excluded;
/// loose enough that a slight path curvature still surfaces the next
/// signal on the user's road. Tunable in phase-3 user-test.
const double _kForwardConeHalfDeg = 20.0;

/// Default search horizon (metres) — how far ahead of the user we
/// consider signals "imminent". 200 m at urban speeds (50 km/h ≈
/// 14 m/s) gives the user ~14 s of lead before the signal — enough to
/// lift off throttle and coast in.
const double _kDefaultHorizonMeters = 200.0;

/// Lateral padding (metres) added around the horizon when building the
/// search bounding box. Generous enough to absorb GPS noise (typical
/// urban accuracy 5–15 m) and a few metres of cone-edge slop on the
/// flanks; the forward-cone filter rejects anything spurious that
/// sneaks in.
const double _kBboxLateralPaddingMeters = 50.0;

/// Input record for [ImminentSignalDetector] — the minimal GPS shape
/// the detector needs. Adapter providers (phase 3) will marshal a
/// `geolocator` `Position` into this record so the detector stays free
/// of platform-channel coupling and is unit-testable with hand-built
/// inputs. `headingDegrees` follows compass convention: 0° = north,
/// 90° = east.
typedef GpsReading = ({
  double latitude,
  double longitude,
  double headingDegrees,
});

/// Service that locates the next traffic signal ahead of a moving user
/// (#1125 phase 2). Input: a [GpsReading] (position + heading) plus an
/// optional horizon. Output: the closest signal that lies within the
/// forward cone and the horizon, or `null` when no signal qualifies.
///
/// Pure logic — no platform channels, no UI, no Riverpod state. The
/// caller owns: GPS subscription, repository instance, throttling, and
/// downstream actions (phase 3 correlates the result with throttle and
/// fires the haptic).
///
/// ### Forward-cone filter
///
/// A signal qualifies as "ahead" iff the bearing from the user to the
/// signal is within ±[_kForwardConeHalfDeg] of the user's heading.
/// Bearings wrap at 360°; the comparison uses the shortest arc.
///
/// ### Distance metric
///
/// Great-circle distance via the haversine formula on the WGS-84
/// sphere (mean radius 6 371 000 m). Accurate to ~0.5 % at urban
/// distances; well below the resolution that matters for fuel-coast
/// decisions.
///
/// ### Why no `velocity` input
///
/// Phase-3 will use velocity to compute time-to-arrival; phase-2 just
/// returns the closest signal so callers can spike on a static input
/// (a queued GPS reading) or a live stream identically.
///
/// ### Under-trigger preference
///
/// This service feeds a distraction-warning (haptic-on-coast) so a
/// false positive is worse than a missed signal. Whenever geometry is
/// ambiguous — empty cache, repository error, NaN bearings, signals
/// past the horizon — we bias toward `null` (nothing ahead) rather
/// than guess. Phase 3's correlation step adds a second gate before
/// any actual buzz fires.
class ImminentSignalDetector {
  final TrafficSignalRepository _repo;
  final double _horizonMeters;

  ImminentSignalDetector({
    required TrafficSignalRepository repo,
    double horizonMeters = _kDefaultHorizonMeters,
  }) : _repo = repo,
       _horizonMeters = horizonMeters;

  /// Returns the closest [TrafficSignal] ahead of [reading] within the
  /// horizon, or `null` when none qualify. The repository call is
  /// awaited; the caller is responsible for throttling invocations
  /// (e.g. once per N seconds of GPS samples).
  ///
  /// Repository errors are swallowed (and `debugPrint`-ed) so a brief
  /// network blip does not throw inside a GPS callback. Under-trigger
  /// is the safe default for a distraction-warning feature.
  Future<TrafficSignal?> nextSignalAhead(GpsReading reading) async {
    final user = LatLng(reading.latitude, reading.longitude);
    final bbox = searchBoundingBox(user, _horizonMeters);

    final List<TrafficSignal> signals;
    try {
      signals = await _repo.getSignalsForBoundingBox(
        south: bbox.south,
        west: bbox.west,
        north: bbox.north,
        east: bbox.east,
      );
    } catch (e, st) {
      debugPrint(
        'ImminentSignalDetector: repo lookup failed, '
        'returning null: $e\n$st',
      );
      return null;
    }

    if (signals.isEmpty) return null;

    final heading = reading.headingDegrees;
    TrafficSignal? best;
    double bestDistance = double.infinity;

    for (final signal in signals) {
      final pos = LatLng(signal.lat, signal.lng);
      final distance = distanceMeters(user, pos);
      if (distance > _horizonMeters) continue;
      if (distance == 0.0) continue; // user standing on the signal

      final bearing = bearingDegrees(user, pos);
      if (!bearing.isFinite || !heading.isFinite) continue;

      final delta = bearingDeltaDegrees(heading, bearing);
      if (delta > _kForwardConeHalfDeg) continue;

      if (distance < bestDistance) {
        bestDistance = distance;
        best = signal;
      }
    }

    return best;
  }

  // ---------- helpers ----------
  // Static so unit tests can exercise them in isolation without
  // constructing the repo.

  /// Initial bearing from `from` to `to` in degrees [0, 360).
  /// Forward-azimuth on the WGS-84 sphere.
  ///
  /// Returns `0.0` when both points are identical (the standard
  /// great-circle formula yields `atan2(0, 0)` which is well-defined
  /// as 0, but we short-circuit to keep the contract explicit).
  @visibleForTesting
  static double bearingDegrees(LatLng from, LatLng to) {
    if (from.latitude == to.latitude && from.longitude == to.longitude) {
      return 0.0;
    }

    final lat1 = _degToRad(from.latitude);
    final lat2 = _degToRad(to.latitude);
    final deltaLng = _degToRad(to.longitude - from.longitude);

    final y = math.sin(deltaLng) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(deltaLng);

    final bearingRad = math.atan2(y, x);
    final bearingDeg = _radToDeg(bearingRad);
    // Normalise to [0, 360). `(x % 360 + 360) % 360` handles negative
    // bearings without conditionals.
    return (bearingDeg % 360 + 360) % 360;
  }

  /// Great-circle distance in metres via the haversine formula.
  /// Delegates to the shared [geo.distanceMeters] (#2169).
  @visibleForTesting
  static double distanceMeters(LatLng from, LatLng to) =>
      geo.distanceMeters(
        from.latitude,
        from.longitude,
        to.latitude,
        to.longitude,
      );

  /// Smallest absolute arc between two bearings in degrees [0, 180].
  /// Wraps correctly at 360°: `bearingDeltaDegrees(355, 5)` is 10, not
  /// 350.
  @visibleForTesting
  static double bearingDeltaDegrees(double a, double b) {
    final diff = ((a - b) % 360 + 360) % 360;
    return diff > 180 ? 360 - diff : diff;
  }

  /// Build a tight bounding box around the user that covers the
  /// horizon distance plus enough lateral padding to absorb GPS noise.
  ///
  /// The box is square in metre-space (axis-aligned, no rotation) —
  /// picking up a small superset is fine because the forward-cone
  /// filter rejects irrelevant signals. We translate the metre padding
  /// into degree-space using a flat-earth approximation: 1° latitude
  /// ≈ 111 320 m everywhere; 1° longitude shrinks with `cos(lat)` so
  /// near-equator and mid-latitude users get the same metric horizon.
  ///
  /// Near the poles `cos(lat)` approaches 0, which would blow the
  /// longitude delta to infinity; we clamp the cosine away from zero
  /// so the bbox stays finite. (The detector is not meant for polar
  /// driving and the upstream repository would refuse such a bbox
  /// anyway — this is purely so the math doesn't emit `NaN`.)
  @visibleForTesting
  static ({double south, double west, double north, double east})
  searchBoundingBox(LatLng center, double horizonMeters) {
    final padded = horizonMeters + _kBboxLateralPaddingMeters;

    const metresPerDegLat = 111320.0;
    final latDelta = padded / metresPerDegLat;

    final cosLat = math.cos(_degToRad(center.latitude));
    // Clamp |cos| ≥ 1e-6 so `padded / (metres * cosLat)` stays finite
    // at the poles.
    final clampedCosLat = cosLat.abs() < 1e-6 ? 1e-6 : cosLat.abs();
    final lngDelta = padded / (metresPerDegLat * clampedCosLat);

    return (
      south: center.latitude - latDelta,
      west: center.longitude - lngDelta,
      north: center.latitude + latDelta,
      east: center.longitude + lngDelta,
    );
  }

  static double _degToRad(double deg) => deg * math.pi / 180.0;
  static double _radToDeg(double rad) => rad * 180.0 / math.pi;
}
