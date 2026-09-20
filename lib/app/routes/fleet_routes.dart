// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:go_router/go_router.dart';

import '../../core/navigation/app_routes.dart';
import '../../features/fleet/presentation/screens/expense_list_screen.dart';
import '../../features/fleet/presentation/screens/expense_review_screen.dart';
import '../../features/fleet/presentation/screens/fleet_expense_queue_screen.dart';
import '../../features/fleet/presentation/screens/fleet_overview_screen.dart';
import '../../features/fleet/presentation/screens/fleet_reports_screen.dart';
import '../../features/fleet/presentation/screens/fleet_vehicle_detail_screen.dart';

/// The `/fleet/…` push family (Epic #4211).
///
/// A table of its own rather than two more entries on
/// `profile_routes.dart`: that list is pinned at 25 by
/// `profile_routes_test.dart` and every index below the insertion
/// point is asserted individually, so appending there makes every
/// later fleet slice a merge conflict with whatever else touched
/// Settings. Fleet routes now grow here, and `fleet_routes_test.dart`
/// pins this list the same way.
///
/// F7 (#4215) ships the employee's two: the expense list and the
/// review screen it pushes. F9 (#4216) appends the manager's four —
/// overview, vehicle detail, the org-wide expense queue and the period
/// report — LAST, so the employee indices above are untouched and the
/// next slice inherits the same promise.
List<RouteBase> get fleetRoutes => [
      GoRoute(
        path: RoutePaths.fleetExpenses,
        builder: (context, state) => const ExpenseListScreen(),
      ),
      // The payload is the expense ID, not the record: the screen looks
      // it up on every build, so a correction made elsewhere cannot be
      // rendered stale here. A deep link with no payload lands on the
      // screen's "not on this device" state rather than crashing, which
      // is why the cast is defensive and the id is allowed to be empty.
      GoRoute(
        path: RoutePaths.fleetExpenseReview,
        builder: (context, state) {
          final extra = state.extra;
          return ExpenseReviewScreen(
            expenseId: extra is String ? extra : '',
          );
        },
      ),
      // ── Manager surfaces (#4216) ──────────────────────────────────
      // Appended LAST so every index above keeps its number, exactly
      // as F7 promised the next slice it would.
      GoRoute(
        path: RoutePaths.fleetOverview,
        builder: (context, state) => const FleetOverviewScreen(),
      ),
      // Same payload rule as the review route: the id, never the
      // record. A deep link with nothing attached lands on the
      // "reported nothing in this period" state.
      GoRoute(
        path: RoutePaths.fleetVehicle,
        builder: (context, state) {
          final extra = state.extra;
          return FleetVehicleDetailScreen(
            fleetVehicleId: extra is String ? extra : '',
          );
        },
      ),
      GoRoute(
        path: RoutePaths.fleetQueue,
        builder: (context, state) => const FleetExpenseQueueScreen(),
      ),
      GoRoute(
        path: RoutePaths.fleetReports,
        builder: (context, state) => const FleetReportsScreen(),
      ),
    ];
