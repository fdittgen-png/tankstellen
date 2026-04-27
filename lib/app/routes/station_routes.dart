import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/storage/storage_providers.dart';
import '../../features/ev/domain/entities/charging_station.dart';
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
      // path and hydrates the ChargingStation from storage (#713
      // widget → station detail flow). Used when the caller has
      // only the id — e.g. a home-screen widget tap or an external
      // URL. Falls back to the invalid-id screen when the id is
      // unknown or the cached JSON is missing.
      GoRoute(
        path: '/ev-station/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'];
          if (!isValidStationId(id)) {
            return invalidIdScreen(context, state.matchedLocation);
          }
          final storage = ref.watch(storageRepositoryProvider);
          final raw = storage.getEvFavoriteStationData(id!);
          if (raw == null) {
            return invalidIdScreen(context, state.matchedLocation);
          }
          try {
            final station = ChargingStation.fromJson(raw);
            return EVStationDetailScreen(station: station);
          } catch (e, st) { // ignore: unused_catch_stack
            return invalidIdScreen(context, state.matchedLocation);
          }
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
