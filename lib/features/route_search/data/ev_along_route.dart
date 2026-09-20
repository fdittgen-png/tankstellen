// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/domain/search_result_item.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/logging/error_logger.dart';
import '../../search/providers/ev_charging_service_provider.dart';
import '../domain/entities/route_info.dart';
import 'strategies/route_geometry.dart';

/// Charging points along [route], in itinerary order.
///
/// The EV leg keeps its own straight-line sweep rather than going
/// through a route-search strategy: OpenChargeMap answers per point and
/// there is no price to rank by, so the per-sample-point top-N reduce
/// the fuel path uses would have nothing to reduce on.
///
/// Sample failures are tolerated — other points still yield results —
/// but each is routed to the exportable log (#2146) so a recurring
/// blackout of EV results is recoverable from a field report.
Future<List<SearchResultItem>> searchEvAlongRoute(
  Ref ref,
  RouteInfo route,
  double radiusKm,
) async {
  final service = ref.read(evChargingServiceProvider);
  if (service == null) {
    throw const ApiException(message: 'OpenChargeMap API key required');
  }

  final seen = <String>{};
  final results = <SearchResultItem>[];

  for (final point in route.samplePoints) {
    try {
      // #697/#3742 — `countryCode` is no longer passed: OCM's
      // countrycode filter dropped legitimate results in border regions
      // and the service stopped sending it to the API; the lat/lng +
      // distance constraint is the geographic filter.
      final result = await service.searchStations(
        lat: point.latitude,
        lng: point.longitude,
        radiusKm: radiusKm,
        maxResults: 20,
      );
      for (final station in result.data) {
        if (seen.add(station.id)) results.add(EVStationResult(station));
      }
    } catch (e, st) {
      // #3145 — coords bucketed to 1 decimal: triage never needs more.
      unawaited(errorLogger.log(ErrorLayer.services, e, st, context: {
        'where': 'RouteSearch EV: sample point query',
        'lat': point.latitude.toStringAsFixed(1),
        'lng': point.longitude.toStringAsFixed(1),
      }));
    }
  }

  sortByItineraryOrder(results, route.geometry);
  return results;
}
