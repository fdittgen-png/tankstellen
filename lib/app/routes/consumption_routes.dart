// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/app_routes.dart';
import '../../features/carbon/presentation/screens/carbon_dashboard_screen.dart';
import '../../features/consumption/presentation/screens/add_fill_up_screen.dart';
import '../../features/consumption/presentation/screens/consumption_statistics_screen.dart';
import '../../features/consumption/presentation/screens/consumption_screen.dart';
import '../../features/consumption/presentation/screens/pick_station_for_fill_up_screen.dart';
import '../../features/consumption/presentation/screens/trip_detail_screen.dart';
import '../../features/consumption/presentation/screens/trip_recording_screen.dart';
import '../../features/feature_management/application/feature_flags_provider.dart';
import '../../features/feature_management/domain/feature.dart';
import 'invalid_id_screen.dart';

/// Routes that drive the "behind-the-wheel" savings lens: consumption logging,
/// trip recording/history/detail, the carbon dashboard, and the deep-linkable
/// fill-up flow. The `/consumption-tab` path lives in [shellBranches]; this
/// file owns every consumption route that pushes on top of the shell.
List<RouteBase> get consumptionRoutes => [
  GoRoute(
    path: RoutePaths.consumption,
    builder: (context, state) => const ConsumptionScreen(),
  ),
  GoRoute(
    path: RoutePaths.carbon,
    // #1613 — the Carbon dashboard is gated on Feature.carbonDashboard.
    // Guarding the route (not just the entry-point button) means a
    // deep link or restored navigation stack cannot reach the
    // dashboard when the feature is disabled.
    builder: (context, state) => Consumer(
      builder: (context, ref, _) {
        final enabled = ref
            .watch(enabledFeaturesProvider)
            .contains(Feature.carbonDashboard);
        if (!enabled) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go(RoutePaths.consumptionTab);
          });
          return const SizedBox.shrink();
        }
        return const CarbonDashboardScreen();
      },
    ),
  ),
  // #2698 — full consumption-statistics detail page (month-over-month
  // comparison + evolution charts). No feature gate: it re-presents
  // fill-up data the user already sees on the summary card.
  GoRoute(
    path: RoutePaths.consumptionStats,
    builder: (_, _) => const ConsumptionStatisticsPage(),
  ),
  GoRoute(
    path: RoutePaths.pickStationForFillUp,
    builder: (_, _) => const PickStationForFillUpScreen(),
  ),
  // #726 — global trip recording view. The recording session
  // itself lives in `tripRecordingProvider` (keepAlive), so this
  // screen is a thin viewer that can come and go without losing
  // state. Opened from AddFillUpScreen after OBD2 connect, and
  // re-entered by tapping the banner shown on every screen
  // while a trip is active.
  GoRoute(
    path: RoutePaths.tripRecording,
    builder: (_, _) => const TripRecordingScreen(),
  ),
  // #889 — placeholder trip-detail route wired up alongside the
  // new Trajets tab on the Consumption screen. Full detail UI
  // (timeline / per-minute consumption / map) lands in #890.
  GoRoute(
    path: RoutePaths.tripPattern,
    builder: (context, state) {
      final id = state.pathParameters['id'];
      if (id == null || id.isEmpty) {
        return invalidIdScreen(context, state.matchedLocation);
      }
      return TripDetailScreen(tripId: id);
    },
  ),
  GoRoute(
    path: RoutePaths.addFillUp,
    builder: (context, state) {
      // #3135 — the pre-fill payload crosses as the typed [AddFillUpRoute]
      // itself (it used to be a stringly-keyed Map). A redirect-driven
      // entry (shared receipt, #2735) carries no extra → bare form.
      final extra = state.extra;
      final args = extra is AddFillUpRoute ? extra : null;
      return AddFillUpScreen(
        stationId: args?.stationId,
        stationName: args?.stationName,
        preFilledFuelType: args?.fuelType,
        preFilledPricePerLiter: args?.pricePerLiter,
      );
    },
  ),
];
