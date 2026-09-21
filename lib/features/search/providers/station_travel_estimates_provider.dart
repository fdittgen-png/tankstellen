// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/travel_estimate.dart';
import '../../../core/services/station_offer.dart';
import '../../../core/time/app_clock.dart';
import '../../route_search/api.dart';

/// One `/table` round-trip: every stop's estimate in [context].
typedef TravelEstimateFetcher = Future<List<StationTravelEstimate>> Function(
  TravelContext context,
  List<TravelStop> stops,
);

/// The single travel-estimate seam (#4359), injectable so tests replay
/// recorded router answers through the REAL [RoutingService] (a fixed
/// Dio) or gate completion order — never a public endpoint.
final travelEstimateFetcherProvider = Provider<TravelEstimateFetcher>((ref) {
  final service = RoutingService();
  final clock = ref.watch(appClockProvider);
  return (context, stops) => service.stationTravelEstimates(
        context: context,
        stops: stops,
        now: clock.now(),
      );
});

/// What to quote: a context and the stations, already budgeted.
///
/// Value-equal on the context's cache key and the exact stop list, so it
/// is the family key — a changed origin, destination, heading, purpose,
/// constraint set, route revision or station selection is a DIFFERENT
/// request, and the previous one's answer can never land on it.
@immutable
class TravelQuoteRequest {
  const TravelQuoteRequest._(this.context, this.stops);

  /// Build a request under the documented budget (#4359):
  ///
  ///  * reference-price locations are dropped — #4348, a town-square
  ///    stand-in never initiates physical access routing;
  ///  * duplicates are dropped;
  ///  * at most [kTravelQuoteMaxStations] stops, in the caller's
  ///    priority order (picks and selections first), so ONE request
  ///    covers what a decision presents — not only the radar's top eight.
  factory TravelQuoteRequest.budgeted(
    TravelContext context,
    Iterable<TravelStop> prioritised,
  ) {
    final seen = <String>{};
    final stops = <TravelStop>[];
    for (final s in prioritised) {
      if (stops.length >= kTravelQuoteMaxStations) break;
      if (!StationOffer.forStation(stationId: s.id, lat: s.lat, lng: s.lng)
          .canRouteTo) {
        continue;
      }
      if (seen.add(s.id)) stops.add(s);
    }
    return TravelQuoteRequest._(context, List.unmodifiable(stops));
  }

  final TravelContext context;
  final List<TravelStop> stops;

  @override
  bool operator ==(Object other) =>
      other is TravelQuoteRequest &&
      other.context == context &&
      listEquals(other.stops, stops);

  @override
  int get hashCode => Object.hash(context, Object.hashAll(stops));
}

/// Road estimates for one [TravelQuoteRequest], by station id.
///
/// **Obsolete answers are ignored by construction.** Each request is its
/// own auto-disposed family instance; a consumer that moves to a new
/// request stops watching the old one, which is disposed, so a slow
/// response for a previous origin or selection completes into nothing.
/// Every estimate is additionally fenced on its own context key, so even
/// a caller holding two requests cannot read one's quote for the other.
/// A station removed from the selection is simply absent from the new
/// request's map; an unreachable answer REPLACES the quote rather than
/// leaving an old actionable one behind.
final stationTravelEstimatesProvider = FutureProvider.autoDispose
    .family<Map<String, StationTravelEstimate>, TravelQuoteRequest>(
        (ref, request) async {
  if (request.stops.isEmpty) return const {};
  final fetch = ref.watch(travelEstimateFetcherProvider);
  final estimates = await fetch(request.context, request.stops);
  final wanted = {for (final s in request.stops) s.id};
  return {
    for (final e in estimates)
      if (wanted.contains(e.stationId) &&
          e.context.cacheKey == request.context.cacheKey)
        e.stationId: e,
  };
});

/// The actionable road quote for [stationId] under [request] at [now],
/// or null — in which case the caller stays on its explicitly
/// approximate figure. A loading, failed, stale, unreachable or
/// constraint-refused quote is never promoted to a recommendation.
StationTravelEstimate? actionableTravelEstimate(
  AsyncValue<Map<String, StationTravelEstimate>> estimates,
  TravelQuoteRequest request,
  String stationId,
  DateTime now,
) {
  final e = estimates.value?[stationId];
  if (e == null || !e.isActionable) return null;
  return e.isCurrentFor(request.context, now) ? e : null;
}
