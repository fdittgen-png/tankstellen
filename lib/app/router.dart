import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../core/error_tracing/integrations/navigation_trace_observer.dart';
import '../core/storage/hive_storage.dart';
import '../features/favorites/presentation/screens/favorites_screen.dart';
import '../features/map/presentation/screens/map_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/search/presentation/screens/search_screen.dart';
import '../features/setup/presentation/screens/setup_screen.dart';
import '../features/alerts/presentation/screens/alerts_screen.dart';
import '../features/calculator/presentation/screens/calculator_screen.dart';
import '../features/report/presentation/screens/report_screen.dart';
import '../features/price_history/presentation/screens/price_history_screen.dart';
import '../features/search/presentation/screens/ev_station_detail_screen.dart';
import '../features/search/domain/entities/charging_station.dart';
import '../features/station_detail/presentation/screens/station_detail_screen.dart';
import '../features/itinerary/presentation/screens/itineraries_screen.dart';
import '../features/sync/presentation/screens/auth_screen.dart';
import '../features/sync/presentation/screens/data_transparency_screen.dart';
import '../features/sync/presentation/screens/link_device_screen.dart';
import '../features/sync/presentation/screens/sync_setup_screen.dart';
import 'shell_screen.dart';
import 'station_id_validator.dart';

part 'router.g.dart';

Widget _invalidIdScreen(BuildContext context, String path) {
  return Scaffold(
    appBar: AppBar(title: const Text('Invalid link')),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.link_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'The link "$path" is not valid.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.go('/'),
            child: const Text('Home'),
          ),
        ],
      ),
    ),
  );
}

@riverpod
GoRouter router(Ref ref) {
  final storage = ref.watch(hiveStorageProvider);

  return GoRouter(
    initialLocation: '/setup',
    observers: [NavigationTraceObserver()],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              '"${state.matchedLocation}" not found.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('Home'),
            ),
          ],
        ),
      ),
    ),
    redirect: (context, state) {
      // Read live from storage each redirect — not cached at provider creation
      final isReady = storage.isSetupComplete;
      final isSetup = state.matchedLocation == '/setup';
      if (!isReady && !isSetup) return '/setup';
      if (isReady && isSetup) {
        // Route to profile landing screen preference
        final profileId = storage.getActiveProfileId();
        if (profileId != null) {
          final profile = storage.getProfile(profileId);
          final landing = profile?['landingScreen']?.toString();
          // json_serializable stores enum as name: "map", "favorites", etc.
          // Also handle legacy format "LandingScreen.map"
          if (landing == 'favorites' || landing == 'LandingScreen.favorites') return '/favorites';
          // 'cheapest' and 'map' both go to search — cheapest triggers auto-search there
        }
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/setup',
        builder: (context, state) => const SetupScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ShellScreen(navigationShell: navigationShell),
        branches: [
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
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/alerts',
        builder: (context, state) => const AlertsScreen(),
      ),
      GoRoute(
        path: '/calculator',
        builder: (context, state) => const CalculatorScreen(),
      ),
      GoRoute(
        path: '/station/:id/history',
        builder: (context, state) {
          final id = state.pathParameters['id'];
          if (!isValidStationId(id)) {
            return _invalidIdScreen(context, state.matchedLocation);
          }
          return PriceHistoryScreen(stationId: id!);
        },
      ),
      GoRoute(
        path: '/station/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'];
          if (!isValidStationId(id)) {
            return _invalidIdScreen(context, state.matchedLocation);
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
      GoRoute(
        path: '/report/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'];
          if (!isValidStationId(id)) {
            return _invalidIdScreen(context, state.matchedLocation);
          }
          return ReportScreen(stationId: id!);
        },
      ),
      GoRoute(
        path: '/sync-setup',
        builder: (context, state) => const SyncSetupScreen(),
      ),
      GoRoute(
        path: '/link-device',
        builder: (context, state) => const LinkDeviceScreen(),
      ),
      GoRoute(
        path: '/data-transparency',
        builder: (context, state) => const DataTransparencyScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/itineraries',
        builder: (context, state) => const ItinerariesScreen(),
      ),
    ],
  );
}
