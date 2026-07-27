// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import '../../domain/station.dart';
import '../../utils/geo_utils.dart' as geo;

/// Speed at/above which sustained driving reads as motorway (#3631).
const double kHighwayEnterSpeedKmh = 95.0;

/// Sustained time above [kHighwayEnterSpeedKmh] before the mode engages.
const Duration kHighwayEnterSustain = Duration(seconds: 60);

/// Below this speed the exit clock runs.
const double kHighwayExitSpeedKmh = 70.0;

/// Sustained time below [kHighwayExitSpeedKmh] before the mode releases —
/// long enough that a traffic jam or a brief exit-ramp slowdown doesn't
/// flap the filter off mid-highway.
const Duration kHighwayExitSustain = Duration(seconds: 180);

/// Relative bearing (°) beyond which a station counts as behind/beside —
/// outside the "ahead" cone.
const double kHighwayAheadConeDeg = 75.0;

/// Lateral distance (km) within which a station is "essentially ON the
/// road" — the band where an opposite-carriageway service area lives.
const double kHighwayOnRoadLateralKm = 0.15;

/// Countries the app serves that drive on the left — the
/// opposite-carriageway side inverts there.
const Set<String> kLeftHandTrafficCountries = {'UK', 'IE', 'MT', 'CY'};

/// Sustained-speed highway detection with hysteresis (#3631).
///
/// Fed the GPS speed the approach detector already polls with — no new
/// location subscription. Pure and clock-injected: `onFix` folds one fix,
/// [active] is the current verdict.
///
/// Deliberately a speed heuristic, not a map lookup: it needs no network,
/// no new dependency, and the failure modes are benign (a fast rural
/// N-road gains the ahead-filter too — which is still correct behavior
/// for a driver passing stations they cannot reach).
class HighwayModeDetector {
  DateTime? _fastSince;
  DateTime? _slowSince;
  bool _active = false;

  bool get active => _active;

  /// Fold one GPS fix. [speedKmh] non-finite/negative reads as 0.
  void onFix({required double speedKmh, required DateTime at}) {
    final v = speedKmh.isFinite && speedKmh > 0 ? speedKmh : 0.0;
    if (!_active) {
      if (v >= kHighwayEnterSpeedKmh) {
        _fastSince ??= at;
        if (at.difference(_fastSince!) >= kHighwayEnterSustain) {
          _active = true;
          _slowSince = null;
        }
      } else {
        _fastSince = null;
      }
      return;
    }
    if (v < kHighwayExitSpeedKmh) {
      _slowSince ??= at;
      if (at.difference(_slowSince!) >= kHighwayExitSustain) {
        _active = false;
        _fastSince = null;
        _slowSince = null;
      }
    } else {
      _slowSince = null;
    }
  }

  /// Drop this detector's history (fresh trip).
  void reset() {
    _fastSince = null;
    _slowSince = null;
    _active = false;
  }
}

/// The #3631 ahead-filter: keep only stations a highway driver can still
/// reach — ahead within the [kHighwayAheadConeDeg] cone, minus the
/// opposite-carriageway trap (essentially on the road but on the wrong
/// side). Stations further off-axis ahead (a town off the next exit)
/// stay.
///
/// SAFETY FALLBACK: when the filter would return an empty list, the
/// UNFILTERED input is returned — a driver low on fuel must never see
/// zero stations because of a heuristic. Callers can distinguish via
/// [HighwayAheadResult.filtered].
class HighwayAheadResult {
  const HighwayAheadResult({required this.stations, required this.filtered});

  final List<Station> stations;

  /// False when the safety fallback engaged (nothing survived the cone).
  final bool filtered;
}

HighwayAheadResult filterStationsAhead({
  required List<Station> stations,
  required double lat,
  required double lng,
  required double headingDegrees,
  required bool leftHandTraffic,
}) {
  if (!headingDegrees.isFinite || stations.isEmpty) {
    return HighwayAheadResult(stations: stations, filtered: false);
  }
  final kept = <Station>[];
  for (final s in stations) {
    final distKm = geo.distanceMeters(lat, lng, s.lat, s.lng) / 1000.0;
    final bearing = geo.bearingDegrees(lat, lng, s.lat, s.lng);
    // Signed relative bearing in (-180, 180]: positive = right of travel.
    var rel = bearing - headingDegrees;
    while (rel > 180) {
      rel -= 360;
    }
    while (rel <= -180) {
      rel += 360;
    }
    if (rel.abs() > kHighwayAheadConeDeg) continue; // behind / beside
    final lateralKm = distKm * math.sin(rel * math.pi / 180.0);
    final onRoad = lateralKm.abs() < kHighwayOnRoadLateralKm;
    // On the road but on the oncoming side = the opposite carriageway.
    final oncomingSide = leftHandTraffic ? lateralKm > 0 : lateralKm < 0;
    if (onRoad && oncomingSide && distKm > kHighwayOnRoadLateralKm) {
      continue;
    }
    kept.add(s);
  }
  if (kept.isEmpty) {
    return HighwayAheadResult(stations: stations, filtered: false);
  }
  return HighwayAheadResult(stations: kept, filtered: true);
}
