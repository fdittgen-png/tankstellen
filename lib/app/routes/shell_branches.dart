import 'package:go_router/go_router.dart';

import '../../features/consumption/presentation/screens/consumption_screen.dart';
import '../../features/favorites/presentation/screens/favorites_screen.dart';
import '../../features/map/presentation/screens/map_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';

/// Branches of the bottom-nav `StatefulShellRoute.indexedStack`. Each branch
/// owns the top-level route for one tab — Search, Map, Favorites, Consumption
/// (#778), Profile.
List<StatefulShellBranch> get shellBranches => [
      StatefulShellBranch(
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
      // Consumption is the 4th tab (#778) — sits between
      // Favorites and Settings so the "behind-the-wheel savings"
      // workflow has a first-class entry point. Path stays
      // `/consumption-tab` to avoid colliding with the existing
      // `/consumption` deep link (which still pushes on top of
      // the current branch from station detail etc.).
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/consumption-tab',
            builder: (_, _) => const ConsumptionScreen(),
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
    ];
