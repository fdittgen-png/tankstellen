// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../domain/station.dart';
import '../../utils/geo_utils.dart' as geo;
import 'highway_mode.dart';

/// One OSM `highway=motorway_junction` node (#3633) — an exit's
/// position plus its signposted number (`ref`, e.g. "36") and optional
/// name. Parsed from the compact per-country asset the
/// `motorway-exits-publish.yml` pipeline publishes.
@immutable
class MotorwayExit {
  final double lat;
  final double lng;

  /// The signposted exit number ("36", "34a"), or null when OSM has no
  /// `ref` for the node — the annotation then falls back to [name].
  final String? ref;

  /// The exit's destination name ("Saint-Thibéry"), when tagged.
  final String? name;

  const MotorwayExit({
    required this.lat,
    required this.lng,
    this.ref,
    this.name,
  });

  /// Parse the pipeline's compact shape `{"la":…,"lo":…,"r":…,"n":…}`.
  /// Returns null on a malformed entry (skip, never throw — the asset
  /// is machine-written but the cache layer's contract is lenient).
  static MotorwayExit? fromCompactJson(Map<String, dynamic> json) {
    final la = json['la'];
    final lo = json['lo'];
    if (la is! num || lo is! num) return null;
    return MotorwayExit(
      lat: la.toDouble(),
      lng: lo.toDouble(),
      ref: json['r'] as String?,
      name: json['n'] as String?,
    );
  }

  /// A display label for the annotation: the signposted number when
  /// tagged, else the exit name, else null (no annotation).
  String? get label => ref ?? name;
}

/// Parse a whole per-country asset (`{"v":1,"exits":[…]}`) into exits.
/// Lenient: unknown versions and malformed entries yield what parses.
List<MotorwayExit> parseMotorwayExits(Map<String, dynamic> json) {
  final raw = json['exits'];
  if (raw is! List) return const [];
  return [
    for (final e in raw)
      if (e is Map)
        ?MotorwayExit.fromCompactJson(Map<String, dynamic>.from(e)),
  ];
}

/// Per-station exit annotation (#3633): which exit serves the station
/// and what the straight-line detour from that exit is.
@immutable
class HighwayExitInfo {
  /// The exit's display label ([MotorwayExit.label]) — never null here;
  /// unlabeled exits produce no annotation.
  final String exitLabel;

  /// Straight-line km from the exit to the station (the issue's scope:
  /// no routing — an honest lower bound the UI prefixes with "+").
  final double detourKm;

  /// Along-track km from the driver to the STATION's projection on the
  /// travel bearing — the v2 sort key ("what can I reach next").
  final double alongKm;

  const HighwayExitInfo({
    required this.exitLabel,
    required this.detourKm,
    required this.alongKm,
  });
}

/// Result of [annotateStationsViaExits]: the input stations re-sorted
/// by along-track distance, plus per-station exit annotations.
@immutable
class HighwayExitAnnotation {
  final List<Station> stations;
  final Map<String, HighwayExitInfo> infoByStationId;

  const HighwayExitAnnotation({
    required this.stations,
    required this.infoByStationId,
  });
}

/// #3633 v2 — make the ahead-filtered station list exit-aware.
///
/// Projects [exits] and [stations] onto the travel bearing (the same
/// along/lateral math as the #3631 cone):
///
///  * exits behind the driver or outside the ahead cone are ignored;
///  * a station essentially ON the road (|lateral| <
///    [kHighwayOnRoadLateralKm]) is a service area — no exit needed,
///    no annotation, but its along-track distance still drives the
///    sort;
///  * an off-axis station is associated with the nearest exit AHEAD of
///    the driver at-or-before the station's along-track position (the
///    exit you would take), annotated "via exit {label} · +{detour} km"
///    with the straight-line exit→station distance;
///  * the returned list is sorted by along-track distance — "what can
///    I reach next" — replacing the crow-flies order (a station 2 km
///    away laterally across fields sorts after the services 5 km
///    straight ahead).
///
/// Pure and total: with no usable exits or a non-finite heading the
/// input order is preserved and the annotation map is empty, so the
/// caller degrades to exit-less v1 behaviour with zero branching.
HighwayExitAnnotation annotateStationsViaExits({
  required List<Station> stations,
  required List<MotorwayExit> exits,
  required double lat,
  required double lng,
  required double headingDegrees,
}) {
  if (stations.isEmpty || exits.isEmpty || !headingDegrees.isFinite) {
    return HighwayExitAnnotation(stations: stations, infoByStationId: const {});
  }

  double relOf(double toLat, double toLng) {
    var rel = geo.bearingDegrees(lat, lng, toLat, toLng) - headingDegrees;
    while (rel > 180) {
      rel -= 360;
    }
    while (rel <= -180) {
      rel += 360;
    }
    return rel;
  }

  // Exits ahead, projected onto the bearing, sorted by along-track km.
  final aheadExits = <({MotorwayExit exit, double alongKm})>[];
  for (final e in exits) {
    final rel = relOf(e.lat, e.lng);
    if (rel.abs() > kHighwayAheadConeDeg) continue;
    final distKm = geo.distanceMeters(lat, lng, e.lat, e.lng) / 1000.0;
    final alongKm = distKm * math.cos(rel * math.pi / 180.0);
    if (alongKm <= 0) continue;
    aheadExits.add((exit: e, alongKm: alongKm));
  }
  aheadExits.sort((a, b) => a.alongKm.compareTo(b.alongKm));

  final info = <String, HighwayExitInfo>{};
  final alongByStationId = <String, double>{};
  for (final s in stations) {
    final rel = relOf(s.lat, s.lng);
    final distKm = geo.distanceMeters(lat, lng, s.lat, s.lng) / 1000.0;
    final alongKm = distKm * math.cos(rel * math.pi / 180.0);
    final lateralKm = distKm * math.sin(rel * math.pi / 180.0);
    alongByStationId[s.id] = alongKm;
    // On-road service area: reachable without exiting — no annotation.
    if (lateralKm.abs() < kHighwayOnRoadLateralKm) continue;
    // The exit you would take: the LAST exit at-or-before the station's
    // along-track position (small tolerance — an exit level with the
    // station still serves it). Ignore unlabeled exits.
    ({MotorwayExit exit, double alongKm})? via;
    for (final e in aheadExits) {
      if (e.alongKm > alongKm + 0.5) break;
      if (e.exit.label == null) continue;
      via = e;
    }
    if (via == null) continue;
    info[s.id] = HighwayExitInfo(
      exitLabel: via.exit.label!,
      detourKm:
          geo.distanceMeters(via.exit.lat, via.exit.lng, s.lat, s.lng) /
              1000.0,
      alongKm: alongKm,
    );
  }

  final sorted = [...stations]..sort((a, b) =>
      (alongByStationId[a.id] ?? a.dist)
          .compareTo(alongByStationId[b.id] ?? b.dist));
  return HighwayExitAnnotation(stations: sorted, infoByStationId: info);
}
