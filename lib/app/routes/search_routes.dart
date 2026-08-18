// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:go_router/go_router.dart';

import '../../core/navigation/app_routes.dart';
import '../../features/alerts/presentation/screens/alerts_screen.dart';
import '../../features/calculator/presentation/screens/calculator_screen.dart';
import '../../features/driving/presentation/screens/driving_mode_screen.dart';
import '../../features/feature_management/domain/feature.dart';
import 'feature_gated_screen.dart';

/// Search-adjacent routes that push on top of the bottom-nav shell:
/// driving mode, alerts list, and the fuel-cost calculator. These all
/// live under the search/results flow even though they are not part of
/// any shell branch.
List<RouteBase> get searchRoutes => [
      GoRoute(
        path: RoutePaths.driving,
        builder: (context, state) => const DrivingModeScreen(),
      ),
      GoRoute(
        path: RoutePaths.alerts,
        // Feature.priceAlerts finally gates its surface (2026-08-17
        // review, dead-code finding 6): route-guarded like the #1613
        // carbonDashboard precedent so a deep link cannot reach the
        // alerts list when the toggle is off. Default-on — behavior
        // unchanged unless the user disables it.
        builder: (context, state) => const FeatureGatedScreen(
          feature: Feature.priceAlerts,
          fallbackPath: RoutePaths.favorites,
          child: AlertsScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.calculator,
        builder: (context, state) {
          // #2543 — the search-results launch passes the price the
          // user was looking at as `extra` so the calculator opens
          // pre-filled. A cold open (no arg) leaves it null.
          final extra = state.extra;
          final initialPrice = extra is double ? extra : null;
          return CalculatorScreen(initialPrice: initialPrice);
        },
      ),
    ];
