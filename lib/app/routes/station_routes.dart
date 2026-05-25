// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/storage_repository.dart';
import '../../core/storage/storage_providers.dart';
import '../../features/ev/data/repositories/ev_station_repository.dart';
import '../../features/ev/domain/entities/charging_station.dart';
import '../../features/ev/providers/ev_providers.dart';
import '../../features/price_history/presentation/screens/price_history_screen.dart';
import '../../features/report/presentation/screens/report_screen.dart';
import '../../features/search/presentation/screens/ev_station_detail_screen.dart';
import '../../features/station_detail/presentation/screens/station_detail_screen.dart';
import '../station_id_validator.dart';
import 'invalid_id_screen.dart';

/// Detail-level routes anchored on a single station id: fuel and EV
/// detail screens, price history, and the user report flow. The EV
/// deep-link variant (`/ev-station/:id`) needs storage access to hydrate
/// the [ChargingStation] payload from the cached widget JSON, so the
/// list is parameterised with the router's [Ref].
List<RouteBase> stationRoutes(Ref ref) => [
      GoRoute(
        path: '/station/:id/history',
        builder: (context, state) {
          final id = state.pathParameters['id'];
          if (!isValidStationId(id)) {
            return invalidIdScreen(context, state.matchedLocation);
          }
          return PriceHistoryScreen(stationId: id!);
        },
      ),
      GoRoute(
        path: '/station/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'];
          if (!isValidStationId(id)) {
            return invalidIdScreen(context, state.matchedLocation);
          }
          return StationDetailScreen(stationId: id!);
        },
      ),
      GoRoute(
        path: '/ev-station',
        builder: (context, state) {
          final station = state.extra as ChargingStation;
          return EVStationDetailScreen(station: station);
        },
      ),
      // Deep-link friendly EV detail: takes the station id in the
      // path and hydrates the ChargingStation by id (#713 widget →
      // station detail flow). Used when the caller has only the id —
      // a home-screen widget tap or an external URL. Falls back to the
      // invalid-id screen only when the id is genuinely unknown.
      GoRoute(
        path: '/ev-station/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'];
          if (!isValidStationId(id)) {
            return invalidIdScreen(context, state.matchedLocation);
          }
          final station = hydrateEvStationById(
            id!,
            ref.watch(storageRepositoryProvider),
            ref.watch(evStationRepositoryProvider),
          );
          if (station == null) {
            return invalidIdScreen(context, state.matchedLocation);
          }
          return EVStationDetailScreen(station: station);
        },
      ),
      GoRoute(
        path: '/report/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'];
          if (!isValidStationId(id)) {
            return invalidIdScreen(context, state.matchedLocation);
          }
          return ReportScreen(stationId: id!);
        },
      ),
    ];

/// Hydrates the [ChargingStation] for an `/ev-station/:id` deep link.
///
/// #1804 — checks the EV favorites store first, then falls back to the
/// recently-fetched EV station cache ([EvStationRepository]), so a
/// station the user has seen on the map — or that a home-screen widget
/// surfaced — opens from a deep link even when it is **not** a saved
/// favorite. Returns `null` only when the id is genuinely unknown to
/// the device (the caller then shows the invalid-id screen).
@visibleForTesting
ChargingStation? hydrateEvStationById(
  String id,
  EvFavoriteStorage favorites,
  EvStationRepository cache,
) {
  final raw = favorites.getEvFavoriteStationData(id);
  if (raw != null) {
    try {
      return ChargingStation.fromJson(raw);
    } catch (e, st) { // ignore: unused_catch_stack
      // A corrupt favorites payload shouldn't block a valid cache hit.
    }
  }
  return cache.getById(id);
}
