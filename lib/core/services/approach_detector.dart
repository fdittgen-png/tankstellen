// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../domain/fuel_type.dart';
import '../domain/station.dart';
import '../logging/error_logger.dart';
import '../telemetry/health_counters.dart';
import '../utils/geo_utils.dart' as geo;
import '../utils/num_extensions.dart';
import '../utils/station_extensions.dart';
import 'approach_state.dart';

// The [ApproachState] sealed hierarchy lives in `approach_state.dart` (#3092
// keeps this file under the line cap); re-export it so callers that import
// `approach_detector.dart` still get ApproachIdle/Polling/InRadius/Leaving.
export 'approach_state.dart';

/// Which station the detector targets when more than one is inside
/// the radius (#2067 profile setting drives this — see ADR 0011).
enum ApproachPriceMode {
  /// Lock onto the first station the driver crossed the radius for.
  /// Stable: no flicker if a cheaper station enters mid-approach.
  nearest,

  /// Re-evaluate on every poll — target = lowest-priced station in
  /// the radius. May flip mid-approach.
  cheapestInRadius,
}

/// Configuration the [ApproachDetector] reads from the user's profile
/// (#2067) at start time. The detector does NOT watch the profile for
/// changes — callers re-create the detector when the user edits
/// settings to keep the runtime predictable.
class ApproachDetectorConfig {
  /// Geo-fence radius in metres. From `profile.approachRadiusKm × 1000`.
  final int radiusMeters;

  /// Which station the overlay targets when multiple are in range.
  final ApproachPriceMode priceMode;

  /// Floor on the poll cadence in seconds. From
  /// `profile.approachMinPollSeconds`. Clamped to [1, 10] by the
  /// profile UI; this layer trusts the value.
  final int minPollSeconds;

  /// Fuel type to query the search chain with, in canonical API form
  /// (e.g. `'e10'`, `'diesel'`). Resolved from vehicle preference,
  /// fallback to profile preference, by the caller.
  final String fuelTypeApiValue;

  const ApproachDetectorConfig({
    required this.radiusMeters,
    required this.priceMode,
    required this.minPollSeconds,
    required this.fuelTypeApiValue,
  });
}

/// Speed-aware geofence detector that watches a GPS stream and
/// emits [ApproachState] transitions when the driver enters / leaves
/// the configured radius of a fuel station (ADR 0011 / Epic #2065).
///
/// **Decoupled from the search-chain provider on purpose** — takes
/// the `fetchStations` callback as a constructor parameter. This
/// makes the state machine unit-testable without a Riverpod
/// container, and lets a future caller (route-planning, favourites
/// quick-glance) wire its own data source without changing this file.
class ApproachDetector {
  /// Grace period before [ApproachLeaving] → [ApproachPolling].
  /// Suppresses UI flicker when the GPS sample stutters across the
  /// radius boundary.
  static const Duration exitGrace = Duration(seconds: 5);

  /// Hard ceiling on the poll cadence (ADR 0011 §"polling formula").
  /// At 0 m/s the formula would emit `∞`; the ceiling forces a poll
  /// every 30 s regardless.
  static const int maxPollSeconds = 30;

  /// Fraction of the radius the detector aims to refresh inside —
  /// `pollInterval = clamp(safetyFactor × radius / speed, min, max)`.
  /// Per ADR 0011 a 0.2 factor gives ≥ 4× the minimum needed time
  /// between samples to react before reaching the radius.
  static const double safetyFactor = 0.2;

  final Stream<Position> _gps;
  final Future<List<Station>> Function(
    double lat,
    double lng,
    double radiusKm,
    String fuelType, {
    double? headingDegrees,
  }) _fetchStations;
  final ApproachDetectorConfig _config;
  final StreamController<ApproachState> _out =
      StreamController<ApproachState>.broadcast();

  final List<double> _recentSpeeds = []; // m/s, last 3 samples
  StreamSubscription<Position>? _gpsSub;
  Timer? _pollTimer;
  Timer? _graceTimer;
  Position? _lastGps;
  Station? _lockedStation; // for ApproachPriceMode.nearest
  ApproachState _state = const ApproachIdle();
  bool _disposed = false;

  ApproachDetector({
    required Stream<Position> gpsStream,
    required Future<List<Station>> Function(
      double lat,
      double lng,
      double radiusKm,
      String fuelType, {
      double? headingDegrees,
    }) fetchStations,
    required ApproachDetectorConfig config,
  })  : _gps = gpsStream,
        _fetchStations = fetchStations,
        _config = config {
    _start();
  }

  /// Stream of state transitions. Hot-broadcast — subscribers may
  /// join late and will receive only future transitions, not a replay.
  Stream<ApproachState> get state => _out.stream;

  /// Compute the speed-adaptive poll interval for [speedMps].
  ///
  /// `clamp(safetyFactor × radius_m / speed_mps, minPoll, maxPoll)`.
  /// Public so tests can verify the formula without spinning up a
  /// full detector + timers.
  static Duration computePollInterval({
    required double speedMps,
    required int radiusMeters,
    required int minPollSeconds,
    int maxPollSecondsOverride = maxPollSeconds,
  }) {
    if (speedMps <= 0) {
      return Duration(seconds: maxPollSecondsOverride);
    }
    final raw = safetyFactor * radiusMeters / speedMps;
    final clamped = raw.clamp(
      minPollSeconds.toDouble(),
      maxPollSecondsOverride.toDouble(),
    );
    return Duration(milliseconds: (clamped * 1000).round());
  }

  /// Great-circle distance in metres. Delegates to the shared
  /// [geo.distanceMeters] so the haversine lives in one place (#2169).
  static double distanceMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) =>
      geo.distanceMeters(lat1, lng1, lat2, lng2);

  void _start() {
    // Drop any prior subscription before re-subscribing so the error-
    // recovery restart (below) never leaks a second listener.
    unawaited(_gpsSub?.cancel());
    // #2297 — a mid-trip permission revoke or OS location kill emits an
    // error on the position stream; without an onError the subscription
    // terminates silently, the poll timer keeps firing against a frozen
    // `_lastGps`, and the overlay shows stale state with no transition.
    // Log it, reset to Idle, and re-subscribe so a later re-grant of the
    // location permission recovers the overlay automatically.
    _gpsSub = _gps.listen(
      _onPosition,
      onError: (Object e, StackTrace st) {
        if (_disposed) return;
        unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {
          'where': 'ApproachDetector GPS stream error',
        }));
        _emit(const ApproachIdle());
        _start();
      },
      cancelOnError: false,
    );
  }

  void _onPosition(Position p) {
    if (_disposed) return;
    _lastGps = p;
    final speedMps = p.speed.isFinite && p.speed >= 0 ? p.speed : 0.0;
    _recentSpeeds.add(speedMps);
    if (_recentSpeeds.length > 3) _recentSpeeds.removeAt(0);
    final cur = _state;
    // First emit on first sample — fire a Polling state immediately
    // so the consumer doesn't sit on Idle through the first poll
    // window.
    if (cur is ApproachIdle) {
      _emit(ApproachPolling(
        gps: p,
        nextPollIn: computePollInterval(
          speedMps: _avgSpeed(),
          radiusMeters: _config.radiusMeters,
          minPollSeconds: _config.minPollSeconds,
        ),
      ));
      _schedulePoll();
    } else if (cur is ApproachInRadius) {
      // #3092 — LIVE, GPS-driven distance. While a station is in radius,
      // recompute the distance to the ALREADY-targeted station on every GPS
      // fix and re-emit, so the overlay's distance ticks down smoothly as the
      // driver approaches — WITHOUT a data-service poll. The poll keeps doing
      // enter/leave detection + cheapest re-evaluation at its own, slower
      // cadence; this only refreshes the distance of the locked target.
      _emit(ApproachInRadius(
        station: cur.station,
        distanceMeters: distanceMeters(
          p.latitude,
          p.longitude,
          cur.station.lat,
          cur.station.lng,
        ),
      ));
    }
  }

  double _avgSpeed() => _recentSpeeds.average;

  void _schedulePoll() {
    _pollTimer?.cancel();
    final interval = computePollInterval(
      speedMps: _avgSpeed(),
      radiusMeters: _config.radiusMeters,
      minPollSeconds: _config.minPollSeconds,
    );
    _pollTimer = Timer(interval, _poll);
  }

  Future<void> _poll() async {
    if (_disposed) return;
    final gps = _lastGps;
    if (gps == null) {
      _schedulePoll();
      return;
    }
    // #3257 — always-on radar health counters (#3146): make the silent
    // "radar never fired" causes answerable in a field export.
    healthCounters.increment('radar.polls');
    try {
      final stations = await _fetchStations(
        gps.latitude,
        gps.longitude,
        _config.radiusMeters / 1000.0,
        _config.fuelTypeApiValue,
        // #3256 — thread the live heading so the corridor cache prefetches the
        // tile ahead before the driver crosses into it (a standstill/first-fix
        // sentinel maps to null = no prefetch).
        headingDegrees: geo.sanitizedHeading(gps.heading),
      );
      final inRadius = stations
          .map((s) => (
                s,
                distanceMeters(gps.latitude, gps.longitude, s.lat, s.lng),
              ))
          .where((p) => p.$2 <= _config.radiusMeters)
          .toList();
      // #2601 — priced-only surface (same rule as the radar #2583): an
      // unpriced forecourt has no actionable price for the driver, so it
      // must never trigger ApproachInRadius/Leaving. Filter to stations
      // that quote a usable price for the effective fuel before ranking;
      // the cheapest-ranking (#2299) + nearest-lock logic then operate on
      // the priced subset only.
      final fuel = FuelType.fromString(_config.fuelTypeApiValue);
      final priced = inRadius.where((p) {
        final price = p.$1.priceFor(fuel);
        return price != null && price > 0;
      }).toList();
      if (inRadius.isNotEmpty) healthCounters.increment('radar.inRadiusEnters');
      if (priced.isEmpty) {
        // #3257 — distinguish "no station in radius" from "all in-radius
        // stations were dropped by the #2601 priced-only filter" — the latter
        // is a silent reason the radar never fires despite a forecourt ahead.
        if (inRadius.isNotEmpty) {
          healthCounters.increment('radar.unpricedFiltered');
        }
        _onNoStationInRadius(gps);
      } else {
        _onStationsInRadius(priced);
      }
    } on Object {
      // Network / chain failure — stay in Polling silently. The next
      // poll will retry.
    }
    _schedulePoll();
  }

  void _onNoStationInRadius(Position gps) {
    final cur = _state;
    if (cur is ApproachInRadius) {
      // Just exited — enter grace.
      _graceTimer?.cancel();
      _graceTimer = Timer(exitGrace, () {
        if (_disposed) return;
        _lockedStation = null;
        _emit(ApproachPolling(
          gps: gps,
          nextPollIn: computePollInterval(
            speedMps: _avgSpeed(),
            radiusMeters: _config.radiusMeters,
            minPollSeconds: _config.minPollSeconds,
          ),
        ));
      });
      _emit(ApproachLeaving(lastStation: cur.station));
      return;
    }
    // Already polling (or leaving — keep the grace running).
    if (cur is! ApproachLeaving) {
      _emit(ApproachPolling(
        gps: gps,
        nextPollIn: computePollInterval(
          speedMps: _avgSpeed(),
          radiusMeters: _config.radiusMeters,
          minPollSeconds: _config.minPollSeconds,
        ),
      ));
    }
  }

  void _onStationsInRadius(List<(Station, double)> inRadius) {
    // Cancel grace — we're back in.
    _graceTimer?.cancel();
    _graceTimer = null;
    final Station target;
    final double dist;
    if (_config.priceMode == ApproachPriceMode.nearest) {
      // Lock onto the first crossed station; if already locked, keep.
      final locked = _lockedStation;
      if (locked != null) {
        final match = inRadius.where((p) => p.$1.id == locked.id).firstOrNull;
        if (match != null) {
          target = match.$1;
          dist = match.$2;
        } else {
          // Locked station left the radius but others are inside —
          // fall back to nearest of the remaining.
          inRadius.sort((a, b) => a.$2.compareTo(b.$2));
          target = inRadius.first.$1;
          dist = inRadius.first.$2;
          _lockedStation = target;
        }
      } else {
        inRadius.sort((a, b) => a.$2.compareTo(b.$2));
        target = inRadius.first.$1;
        dist = inRadius.first.$2;
        _lockedStation = target;
      }
    } else {
      // cheapestInRadius — re-evaluate every poll. #2299 — rank by the
      // price for the REQUESTED fuel only. The Tankerkoenig list API
      // returns every fuel price per station regardless of the `type`
      // filter, so taking the min across all fuels would target a diesel
      // station by its (cheaper) e10 price — i.e. the cheapest-any-fuel
      // station, not the cheapest-for-the-driver's-fuel one.
      final fuel = FuelType.fromString(_config.fuelTypeApiValue);
      double priceOf(Station s) => s.priceFor(fuel) ?? double.infinity;

      inRadius.sort((a, b) => priceOf(a.$1).compareTo(priceOf(b.$1)));
      target = inRadius.first.$1;
      dist = inRadius.first.$2;
    }
    _emit(ApproachInRadius(station: target, distanceMeters: dist));
  }

  void _emit(ApproachState s) {
    _state = s;
    _out.add(s);
  }

  /// Stop the detector. Idempotent.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _pollTimer?.cancel();
    _graceTimer?.cancel();
    await _gpsSub?.cancel();
    await _out.close();
  }
}
