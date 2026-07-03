// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/domain/ev/charging_station.dart';
import '../../core/navigation/app_routes.dart';
import '../../core/storage/storage_providers.dart';
import '../../features/ev/data/repositories/ev_station_repository.dart';
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
        path: RoutePaths.stationHistoryPattern,
        builder: (context, state) {
          final id = state.pathParameters['id'];
          if (!isValidStationId(id)) {
            return invalidIdScreen(context, state.matchedLocation);
          }
          return PriceHistoryScreen(stationId: id!);
        },
      ),
      GoRoute(
        path: RoutePaths.stationPattern,
        builder: (context, state) {
          final id = state.pathParameters['id'];
          if (!isValidStationId(id)) {
            return invalidIdScreen(context, state.matchedLocation);
          }
          return StationDetailScreen(stationId: id!);
        },
      ),
      GoRoute(
        path: RoutePaths.evStation,
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
        path: RoutePaths.evStationPattern,
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
        path: RoutePaths.reportPattern,
        builder: (context, state) {
          final id = state.pathParameters['id'];
          if (!isValidStationId(id)) {
            return invalidIdScreen(context, state.matchedLocation);
          }
          return ReportScreen(stationId: id!);
        },
      ),
    ];

// `hydrateEvStationById` moved to `ev_station_repository.dart` (#3455) so
// the stationDetail provider's ocm-id routing reuses the same cache-lookup
// path as this deep-link route. Imported above; behaviour unchanged.
