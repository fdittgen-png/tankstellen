// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// The OSRM `/table` request and response for station travel estimates
/// (#4359) — pure, so the query shape and the decoding are testable
/// against recorded responses without Dio.
///
/// ## One request per context, both directions, both quantities
///
/// The coordinate list is `origin` (and, for a journey, `destination`)
/// followed by every station, and the FULL matrix is asked for with
/// `annotations=distance,duration`. One request therefore answers, for
/// every station at once:
///
///  * origin → station (row 0),
///  * station → origin, or station → destination (the return / rejoin
///    column) — a genuinely different leg on one-way streets and split
///    carriageways, never assumed equal to the outbound one,
///  * the baseline origin → destination (row 0, column 1), computed in
///    the SAME request under the SAME exclusions as the itineraries it is
///    compared with.
///
/// Distances (metres) and durations (seconds) are decoded from their own
/// matrices. A missing distance stays missing; it is never replaced by a
/// duration or by crow-flies.
library;

import '../../../../core/domain/travel_estimate.dart';

/// Bearing snap tolerance for the heading-constrained origin (°).
const int kTravelBearingToleranceDegrees = 25;

/// Index of the first station in the coordinate list.
int _firstStationIndex(TravelContext context) =>
    context.purpose == TravelPurpose.stopOnJourney ? 2 : 1;

/// The `lon,lat;lon,lat…` path segment.
String osrmTravelCoordinates(TravelContext context, List<TravelStop> stops) {
  final b = StringBuffer('${context.origin.lng},${context.origin.lat}');
  if (context.purpose == TravelPurpose.stopOnJourney) {
    final d = context.destination!;
    b.write(';${d.lng},${d.lat}');
  }
  for (final s in stops) {
    b.write(';${s.lng},${s.lat}');
  }
  return b.toString();
}

/// Query parameters: both annotations, the origin bearing when the
/// driver's heading is known, and every requested exclusion.
Map<String, String> osrmTravelParams(
  TravelContext context,
  int stationCount,
) {
  final params = <String, String>{'annotations': 'distance,duration'};
  final heading = context.headingDegrees;
  if (heading != null && heading.isFinite) {
    final coordinateCount = _firstStationIndex(context) + stationCount;
    // One entry per coordinate; only the origin is constrained.
    params['bearings'] =
        '${heading.round() % 360},$kTravelBearingToleranceDegrees'
        '${';' * (coordinateCount - 1)}';
  }
  if (context.constraints.isNotEmpty) {
    final names = [
      for (final c in context.constraints)
        switch (c) {
          TravelConstraint.avoidFerries => 'ferry',
          TravelConstraint.avoidTolls => 'toll',
          TravelConstraint.avoidMotorways => 'motorway',
        },
    ]..sort();
    params['exclude'] = names.join(',');
  }
  return params;
}

double? _cell(Object? matrix, int row, int column, double scale) {
  if (matrix is! List || row >= matrix.length) return null;
  final r = matrix[row];
  if (r is! List || column >= r.length) return null;
  final v = r[column];
  return v is num ? v.toDouble() / scale : null;
}

/// Decode an OSRM `/table` answer into one estimate per [stops] entry,
/// in order.
///
/// * `code != Ok` with exclusions requested →
///   [TravelEstimateStatus.constraintsUnsupported] for every station
///   (the public server answers `InvalidValue` for `exclude`): the
///   request is NOT retried without the exclusion.
/// * any other `code != Ok` → [TravelEstimateStatus.unreachable].
/// * per station, a null cell in either leg or the baseline →
///   unreachable; a negative extra beyond tolerance →
///   inconsistentBaseline (see [StationTravelEstimate.routed]).
List<StationTravelEstimate> parseOsrmTravelMatrix(
  Map<String, dynamic> json, {
  required TravelContext context,
  required List<TravelStop> stops,
  required DateTime calculatedAt,
}) {
  if (json['code'] != 'Ok') {
    final status = context.constraints.isNotEmpty
        ? TravelEstimateStatus.constraintsUnsupported
        : TravelEstimateStatus.unreachable;
    return [
      for (final s in stops)
        StationTravelEstimate.withoutRoute(
          stationId: s.id,
          context: context,
          status: status,
          calculatedAt: calculatedAt,
        ),
    ];
  }
  final distances = json['distances'];
  final durations = json['durations'];
  final first = _firstStationIndex(context);
  final journey = context.purpose == TravelPurpose.stopOnJourney;
  // The leg back: to the origin (column 0) or on to the destination (1).
  final backColumn = journey ? 1 : 0;

  TravelLeg leg(int row, int column) => TravelLeg(
        distanceKm: _cell(distances, row, column, 1000),
        durationMinutes: _cell(durations, row, column, 60),
      );

  final baseline = journey ? leg(0, 1) : TravelLeg.zero;
  return [
    for (var i = 0; i < stops.length; i++)
      StationTravelEstimate.routed(
        stationId: stops[i].id,
        context: context,
        toStation: leg(0, first + i),
        fromStation: leg(first + i, backColumn),
        baseline: baseline,
        calculatedAt: calculatedAt,
      ),
  ];
}

/// Decode the per-leg figures of an OSRM `/route` answer for an ORDERED
/// itinerary (origin → stop … → end), so a sequence of stops is routed
/// as one drive instead of summing independent detours that may overlap.
///
/// Null when the router answered no route; a leg whose distance or
/// duration is absent keeps that figure null on its own.
List<TravelLeg>? parseOsrmRouteLegs(Map<String, dynamic> json) {
  if (json['code'] != 'Ok') return null;
  final routes = json['routes'];
  if (routes is! List || routes.isEmpty) return null;
  final legs = (routes.first as Map<String, dynamic>)['legs'];
  if (legs is! List) return null;
  return [
    for (final l in legs.cast<Map<String, dynamic>>())
      TravelLeg(
        distanceKm: l['distance'] is num
            ? (l['distance'] as num).toDouble() / 1000
            : null,
        durationMinutes: l['duration'] is num
            ? (l['duration'] as num).toDouble() / 60
            : null,
      ),
  ];
}
