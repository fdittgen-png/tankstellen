// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/domain/ev/charging_station.dart';
import '../../core/logging/app_log.dart';
import '../../core/logging/error_logger.dart';
import '../../core/navigation/app_routes.dart';
import '../../core/storage/storage_providers.dart';
import '../../features/ev/data/repositories/ev_station_repository.dart';
import '../../features/ev/providers/ev_providers.dart';
import '../../features/feature_management/domain/feature.dart';
import '../../features/report/presentation/screens/report_screen.dart';
import '../../features/search/presentation/screens/ev_station_detail_screen.dart';
import '../../features/station_detail/presentation/screens/station_detail_screen.dart';
import '../station_id_validator.dart';
import 'detail_transition_page.dart';
import 'feature_gated_screen.dart';
import 'invalid_id_screen.dart';

/// Detail-level routes anchored on a single station id: fuel and EV
/// detail screens, price history, and the user report flow. The EV
/// deep-link variant (`/ev-station/:id`) needs storage access to hydrate
/// the [ChargingStation] payload from the cached widget JSON, so the
/// list is parameterised with the router's [Ref].
List<RouteBase> stationRoutes(Ref ref) => [
      GoRoute(
        path: RoutePaths.stationPattern,
        // #3615 — shared detail transition (fade + settle).
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'];
          return detailTransitionPage(
            key: state.pageKey,
            child: !isValidStationId(id)
                ? invalidIdScreen(context, state.matchedLocation)
                : StationDetailScreen(stationId: id!),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.evStation,
        // #3615 — same detail transition as the fuel screen.
        // Feature.evCharging finally gates the EV surfaces (2026-08-17
        // review, dead-code finding 6). Default-on.
        pageBuilder: (context, state) {
          // #4052 — was `state.extra as ChargingStation`, an unchecked
          // cast that red-screened whenever the payload arrived as
          // anything else. Field log 2026-09-11: `_Map<String, dynamic>
          // is not a subtype of ChargingStation`, thrown inside
          // `pageBuilder` where no error boundary catches it. The same
          // export carries 34 low-memory process kills in three days,
          // and a restored route stack hands the payload back as JSON —
          // so this is downstream of ordinary Android behaviour, not of
          // anything the user did. Recover the station when the payload
          // still describes one; fall back to the graceful screen the
          // id-only sibling route below already uses. Never throw.
          final station = evStationFromExtra(state.extra);
          return detailTransitionPage(
            key: state.pageKey,
            child: station == null
                ? invalidIdScreen(context, state.matchedLocation)
                : FeatureGatedScreen(
                    feature: Feature.evCharging,
                    fallbackPath: RoutePaths.search,
                    child: EVStationDetailScreen(station: station),
                  ),
          );
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
          // Feature.evCharging gate — same guard as the extra-payload
          // EV route above, covering the widget/URL deep-link path.
          return FeatureGatedScreen(
            feature: Feature.evCharging,
            fallbackPath: RoutePaths.search,
            child: EVStationDetailScreen(station: station),
          );
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

/// Recover the [ChargingStation] a `/ev-station` navigation carried in
/// `extra`, or `null` when the payload no longer describes one (#4052).
///
/// The route exists for callers that already hold the object — the map
/// overlay, search results, favorites — so the live instance is the hot
/// path. It is not the only path. `extra` is an untyped `Object?` that
/// survives a route stack being rebuilt, and a payload that has been
/// through serialisation comes back as a plain `Map`, not as the class.
/// The field log of 2026-09-11 caught exactly that, as an unhandled cast
/// inside `pageBuilder` — a red screen in answer to "show me this
/// charger", on a device the OS had killed 34 times in three days.
///
/// Decoding the map back into a station means those users still land on
/// the charger they asked for. A payload that is neither a station nor a
/// station-shaped map is genuinely unusable, and the caller shows the
/// same graceful screen the id-only route uses for an unknown id.
///
/// Never throws: a malformed map is a `null`, not an exception.
@visibleForTesting
ChargingStation? evStationFromExtra(Object? extra) {
  if (extra is ChargingStation) return extra;
  if (extra is Map) {
    try {
      return ChargingStation.fromJson(Map<String, dynamic>.from(extra));
    } catch (e, st) {
      log.warn(
          'station_routes: /ev-station payload was a Map but did not decode '
          'into a ChargingStation — showing the unknown-station screen',
          tag: 'navigation',
          error: e,
          stack: st,
          layer: ErrorLayer.ui);
      return null;
    }
  }
  return null;
}
