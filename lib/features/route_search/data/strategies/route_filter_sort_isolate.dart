// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/error/guarded.dart';
import '../../../../core/logging/error_logger.dart';
import '../../../../core/utils/route_projection.dart';
import '../../../../core/domain/search_result_item.dart';

/// Shared off-isolate along-route eligibility + itinerary sort for every
/// route-search strategy (#2303, #4432).
///
/// All four strategies — Uniform, Cheapest, Balanced, Eco — run their
/// corridor filter and itinerary sort through this one helper, and the
/// helper runs [RouteProjection.itineraryOccurrence]: the same segment
/// projection the planner, the off-route badge and the comparison use.
/// Until #4432 Uniform carried a private nearest-VERTEX copy and this
/// helper a second one, so on a loop, a U-shaped route or a crossing the
/// "globally nearest vertex" could pick the wrong pass, and a station
/// just behind the start clamped to progress zero and passed as ahead.
///
/// ### Non-fuel results
/// Cheapest / Balanced / Eco pass **non-fuel** results (EV charging
/// stations) through unconditionally when [keepNonFuel] is set — they
/// are only sorted, never dropped. [_PointLite.alwaysKeep] carries that
/// exemption across the isolate boundary. Uniform filters everything.
///
/// The isolate entry + payload ship only primitives; survivors are
/// returned as ids and re-hydrated on the UI side.

/// Filter [results] to those the route actually meets within
/// [detourLimitKm] and ahead of its start, then sort them by the
/// progress at which the route meets them — in a background isolate.
///
/// The returned list preserves the caller's original [SearchResultItem]
/// instances, re-hydrated by id in itinerary order. Empty results or
/// polyline short-circuit on the UI isolate (no `compute` hop).
Future<List<SearchResultItem>> filterAndSortAlongRoute({
  required List<SearchResultItem> results,
  required List<LatLng> polyline,
  required double detourLimitKm,
  bool keepNonFuel = true,
}) async {
  if (results.isEmpty || polyline.isEmpty) return results;
  final survivors = await compute(
    _filterAndSortIsolate,
    _payload(results, polyline, detourLimitKm, keepNonFuel),
  );
  return _rehydrate(results, survivors);
}

/// Run a corridor sweep and return its eligible, itinerary-ordered
/// results — with every streamed partial held to the same eligibility
/// (#4432).
///
/// [query] is the strategy's sweep; it receives the gated partial sink
/// (or null when the caller streams nothing). The gate is closed BEFORE
/// the final filter runs, so no partial can land after the final list.
Future<List<SearchResultItem>> queryEligibleAlongRoute({
  required Future<List<SearchResultItem>> Function(
          void Function(List<SearchResultItem> partial)? onPartial)
      query,
  required List<LatLng> polyline,
  required double detourLimitKm,
  bool keepNonFuel = true,
  void Function(List<SearchResultItem> partial)? onPartial,
}) async {
  final partials = onPartial == null
      ? null
      : EligiblePartials(
          downstream: onPartial,
          polyline: polyline,
          detourLimitKm: detourLimitKm,
          keepNonFuel: keepNonFuel,
        );
  try {
    final results = await query(partials?.add);
    partials?.close();
    return await filterAndSortAlongRoute(
      results: results,
      polyline: polyline,
      detourLimitKm: detourLimitKm,
      keepNonFuel: keepNonFuel,
    );
  } finally {
    partials?.close();
  }
}

/// Runs the eligibility filter + itinerary sort on the UI isolate.
/// Exposed for unit tests; production code reaches it via
/// [filterAndSortAlongRoute].
@visibleForTesting
List<SearchResultItem> filterAndSortAlongRouteSyncForTest({
  required List<SearchResultItem> results,
  required List<LatLng> polyline,
  required double detourLimitKm,
  bool keepNonFuel = true,
}) {
  if (results.isEmpty || polyline.isEmpty) return results;
  return _rehydrate(
    results,
    _filterAndSortIsolate(
        _payload(results, polyline, detourLimitKm, keepNonFuel)),
  );
}

/// Streams partial results through the SAME eligibility as the final
/// list (#4432).
///
/// The corridor sweep used to publish its raw accumulator while batches
/// were in flight, so a station behind the driver or outside the corridor
/// could appear on the list, the map and the counts for seconds and then
/// vanish when the final filtered set replaced it. Partials are
/// cumulative, so only the latest pending one needs filtering: at most
/// one isolate hop is in flight and intermediate snapshots are skipped.
/// [close] (called before the final result is returned) drops anything
/// still in flight, so a late partial can never overwrite the final list.
class EligiblePartials {
  EligiblePartials({
    required this.downstream,
    required this.polyline,
    required this.detourLimitKm,
    this.keepNonFuel = true,
  });

  final void Function(List<SearchResultItem> partial) downstream;
  final List<LatLng> polyline;
  final double detourLimitKm;
  final bool keepNonFuel;

  List<SearchResultItem>? _pending;
  bool _running = false;
  bool _closed = false;

  /// Queue [partial] for filtering; replaces any not-yet-started one.
  void add(List<SearchResultItem> partial) {
    if (_closed) return;
    _pending = partial;
    if (!_running) unawaited(_pump());
  }

  /// Stop forwarding. Idempotent.
  void close() => _closed = true;

  Future<void> _pump() async {
    _running = true;
    try {
      while (!_closed && _pending != null) {
        final next = _pending!;
        _pending = null;
        final filtered = await filterAndSortAlongRoute(
          results: next,
          polyline: polyline,
          detourLimitKm: detourLimitKm,
          keepNonFuel: keepNonFuel,
        );
        if (_closed) break;
        downstream(filtered);
      }
    } catch (e, st) {
      // A failed partial is cosmetic — the final result still arrives
      // through the strategy's own path — but it must be visible.
      logFailure(e, st,
          where: 'EligiblePartials: partial filter failed',
          layer: ErrorLayer.providers);
    } finally {
      _running = false;
    }
  }
}

_RouteFilterSortPayload _payload(
  List<SearchResultItem> results,
  List<LatLng> polyline,
  double detourLimitKm,
  bool keepNonFuel,
) =>
    _RouteFilterSortPayload(
      points: [
        for (final item in results)
          _PointLite(
            id: item.id,
            lat: item.lat,
            lng: item.lng,
            alwaysKeep: keepNonFuel && item is! FuelStationResult,
          ),
      ],
      polyLats: List<double>.unmodifiable(polyline.map((p) => p.latitude)),
      polyLngs: List<double>.unmodifiable(polyline.map((p) => p.longitude)),
      detourLimitKm: detourLimitKm,
    );

List<SearchResultItem> _rehydrate(
  List<SearchResultItem> results,
  List<String> survivors,
) {
  final byId = {for (final r in results) r.id: r};
  return [
    for (final id in survivors)
      if (byId[id] != null) byId[id]!,
  ];
}

// ---------------------------------------------------------------------------
// Isolate entry + payload — top level so `compute()` can ship the function
// pointer across the boundary.

class _RouteFilterSortPayload {
  final List<_PointLite> points;
  final List<double> polyLats;
  final List<double> polyLngs;
  final double detourLimitKm;

  const _RouteFilterSortPayload({
    required this.points,
    required this.polyLats,
    required this.polyLngs,
    required this.detourLimitKm,
  });
}

class _PointLite {
  final String id;
  final double lat;
  final double lng;

  /// Exempt from the corridor filter (non-fuel results pass through).
  final bool alwaysKeep;

  const _PointLite({
    required this.id,
    required this.lat,
    required this.lng,
    required this.alwaysKeep,
  });
}

/// Keep what the route meets within the corridor and ahead of its start
/// (unless [_PointLite.alwaysKeep]), then order by the progress of that
/// pass. Returns survivor ids in itinerary order; ties keep input order.
List<String> _filterAndSortIsolate(_RouteFilterSortPayload payload) {
  final projection = RouteProjection([
    for (var i = 0; i < payload.polyLats.length; i++)
      LatLng(payload.polyLats[i], payload.polyLngs[i]),
  ]);

  final survivors = <(_PointLite, double)>[];
  for (final p in payload.points) {
    if (p.alwaysKeep) {
      survivors.add((p, projection.project(p.lat, p.lng).alongKm));
      continue;
    }
    final pass = projection.itineraryOccurrence(
      p.lat,
      p.lng,
      corridorKm: payload.detourLimitKm,
    );
    if (pass == null) continue;
    survivors.add((p, pass.alongKm));
  }

  // List.sort is not stable; the index tiebreak keeps equal-progress
  // stations in the order the sweep produced them.
  final indexed = [for (var i = 0; i < survivors.length; i++) (i, survivors[i])];
  indexed.sort((a, b) {
    final byAlong = a.$2.$2.compareTo(b.$2.$2);
    return byAlong != 0 ? byAlong : a.$1.compareTo(b.$1);
  });
  return [for (final entry in indexed) entry.$2.$1.id];
}
