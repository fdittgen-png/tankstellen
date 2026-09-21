// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// The "best stops" curation rule for a route search: the cheapest
/// station in each route segment.
///
/// #4125 — one definition, because there were two. The route LIST
/// (`route_results_view`) and the route MAP (`route_map_view`) each
/// carried a private copy of this function, byte-for-byte identical down
/// to the `take(5)` fallback, and each surface then labelled its own
/// count "best stops". A rule duplicated across two features is a rule
/// that will diverge, and the counts the user was comparing already
/// looked like it had.
///
/// It takes the two fields it reads rather than the `RouteSearchResult`
/// they live on, so this stays in `core/` with no import into any
/// feature — the same primitives-not-models shape the boundary lint
/// wants.
///
/// [idOf] adapts the element type: the list holds search-result items,
/// the map holds bare stations.
List<T> bestStopsAmong<T>({
  required List<T> stations,
  required String Function(T) idOf,
  required Map<int, String>? cheapestPerSegment,
  required String? cheapestId,
}) {
  if (cheapestPerSegment == null || cheapestPerSegment.isEmpty) {
    // No per-segment ranking was computed (a short route, or a search
    // that produced one price band). The single cheapest station is
    // still a defensible "best stop"…
    if (cheapestId != null) {
      return stations.where((s) => idOf(s) == cheapestId).toList();
    }
    // …and with no ranking at all, the first few in drive order are the
    // honest answer: the caller sorts by position along the route, so
    // these are the next stops coming up, not an arbitrary five.
    return stations.take(5).toList();
  }
  final bestIds = cheapestPerSegment.values.toSet();
  return stations.where((s) => bestIds.contains(idOf(s))).toList();
}
