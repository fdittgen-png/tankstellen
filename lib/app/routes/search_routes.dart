// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:go_router/go_router.dart';

import '../../features/alerts/presentation/screens/alerts_screen.dart';
import '../../features/calculator/presentation/screens/calculator_screen.dart';
import '../../features/driving/presentation/screens/driving_mode_screen.dart';

/// Search-adjacent routes that push on top of the bottom-nav shell:
/// driving mode, alerts list, and the fuel-cost calculator. These all
/// live under the search/results flow even though they are not part of
/// any shell branch.
List<RouteBase> get searchRoutes => [
      GoRoute(
        path: '/driving',
        builder: (context, state) => const DrivingModeScreen(),
      ),
      GoRoute(
        path: '/alerts',
        builder: (context, state) => const AlertsScreen(),
      ),
      GoRoute(
        path: '/calculator',
        builder: (context, state) => const CalculatorScreen(),
      ),
    ];
