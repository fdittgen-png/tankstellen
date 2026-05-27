// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/consumption/presentation/screens/consumption_screen.dart';
import '../../features/favorites/presentation/screens/favorites_screen.dart';
import '../../features/map/presentation/screens/map_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';

/// Navigator key for the Search branch (#2131). Lets the shell-level
/// FAB push the criteria modal onto the *branch's* nested Navigator
/// instead of the root one — without it, MaterialPageRoute covers the
/// shell + bottom bar and the FAB disappears mid-flow.
final GlobalKey<NavigatorState> searchBranchNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'searchBranch');

/// Branches of the bottom-nav `StatefulShellRoute.indexedStack`. Each branch
/// owns the top-level route for one tab — Search, Map, Favorites, Carburant
/// (#778), Profile, Trajets (#1901).
///
/// #1901 — Carburant and Trajets are separate destinations. Carburant
/// keeps branch index 3 / path `/consumption-tab`; Trajets is appended
/// as branch 5 so Profile stays at branch 4 (deep links + the Settings
/// app-bar action depend on that index). Branch order is therefore not
/// the visual order — `ShellDestinations.branchForSlot` maps visible
/// slots back to branch indices.
List<StatefulShellBranch> get shellBranches => [
      StatefulShellBranch(
        navigatorKey: searchBranchNavigatorKey,
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const SearchScreen(),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/map',
            builder: (context, state) => const MapScreen(),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/favorites',
            builder: (context, state) => const FavoritesScreen(),
          ),
        ],
      ),
      // Carburant — branch 3 (#778). Path stays `/consumption-tab` to
      // avoid colliding with the `/consumption` deep link (which still
      // pushes on top of the current branch from station detail etc.).
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/consumption-tab',
            builder: (_, _) => const ConsumptionScreen(
              section: ConsumptionSection.fuel,
            ),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      // Trajets — branch 5 (#1901). Appended after Profile so Profile
      // keeps branch index 4. Renders the same [ConsumptionScreen] in
      // its Trajets section.
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/trajets-tab',
            builder: (_, _) => const ConsumptionScreen(
              section: ConsumptionSection.trajets,
            ),
          ),
        ],
      ),
    ];
