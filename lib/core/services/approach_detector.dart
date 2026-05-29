// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../features/search/domain/entities/fuel_type.dart';
import '../../features/search/domain/entities/station.dart';
import '../logging/error_logger.dart';
import '../utils/geo_utils.dart' as geo;
import '../utils/num_extensions.dart';
import '../utils/station_extensions.dart';

/// State emitted by [ApproachDetector] (#2085 / ADR 0011).
///
/// Sealed hierarchy — the consumer (the PiP overlay in #2084) picks
/// its UI on the runtime subtype:
///
/// - [ApproachIdle] — no GPS fix yet, or detector not running.
/// - [ApproachPolling] — GPS available, no station in radius. The
///   overlay shows the default "huge L/100 km" view from #2068.
/// - [ApproachInRadius] — driver is inside the configured radius of
///   a target station. The overlay flips to the huge-price view.
/// - [ApproachLeaving] — radius exit was detected, but the 5 s
///   grace window is still open. The overlay keeps showing the
///   price until the grace expires or the radius is re-entered.
sealed class ApproachState {
  const ApproachState();
}

/// No GPS fix / detector not yet receiving samples.
class ApproachIdle extends ApproachState {
  const ApproachIdle();
}

/// GPS is producing samples but no station is in the radius right now.
class ApproachPolling extends ApproachState {
  final Position gps;
  final Duration nextPollIn;
  const ApproachPolling({required this.gps, required this.nextPollIn});
}

/// A target station is in the configured radius.
class ApproachInRadius extends ApproachState {
  final Station station;
  final double distanceMeters;
  const ApproachInRadius({
    required this.station,
    required this.distanceMeters,
  });
}

/// Grace period after exit — the overlay keeps the price visible for
/// [ApproachDetector.exitGrace] before falling back to [ApproachPolling].
class ApproachLeaving extends ApproachState {
  final Station lastStation;
  const ApproachLeaving({required this.lastStation});
}

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
    String fuelType,
  ) _fetchStations;
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
      String fuelType,
    ) fetchStations,
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
    // First emit on first sample — fire a Polling state immediately
    // so the consumer doesn't sit on Idle through the first poll
    // window.
    if (_state is ApproachIdle) {
      _emit(ApproachPolling(
        gps: p,
        nextPollIn: computePollInterval(
          speedMps: _avgSpeed(),
          radiusMeters: _config.radiusMeters,
          minPollSeconds: _config.minPollSeconds,
        ),
      ));
      _schedulePoll();
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
    try {
      final stations = await _fetchStations(
        gps.latitude,
        gps.longitude,
        _config.radiusMeters / 1000.0,
        _config.fuelTypeApiValue,
      );
      final inRadius = stations
          .map((s) => (
                s,
                distanceMeters(gps.latitude, gps.longitude, s.lat, s.lng),
              ))
          .where((p) => p.$2 <= _config.radiusMeters)
          .toList();
      if (inRadius.isEmpty) {
        _onNoStationInRadius(gps);
      } else {
        _onStationsInRadius(inRadius);
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
