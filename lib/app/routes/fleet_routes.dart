// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:go_router/go_router.dart';

import '../../core/navigation/app_routes.dart';
import '../../features/fleet/presentation/screens/expense_list_screen.dart';
import '../../features/fleet/presentation/screens/expense_review_screen.dart';

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
/// review screen it pushes. F9's manager surfaces append to this list.
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
    ];
