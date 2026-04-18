import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../core/data/storage_repository.dart';
import '../core/error_tracing/integrations/navigation_trace_observer.dart';
import '../core/storage/storage_keys.dart';
import '../core/storage/storage_providers.dart';
import '../features/consent/presentation/screens/gdpr_consent_screen.dart';
import '../features/favorites/presentation/screens/favorites_screen.dart';
import '../features/map/presentation/screens/map_screen.dart';
import '../features/profile/presentation/screens/privacy_dashboard_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/search/presentation/screens/search_criteria_screen.dart';
import '../features/search/presentation/screens/search_screen.dart';
import '../features/setup/presentation/screens/onboarding_wizard_screen.dart';
import '../features/alerts/presentation/screens/alerts_screen.dart';
import '../features/calculator/presentation/screens/calculator_screen.dart';
import '../features/carbon/presentation/screens/carbon_dashboard_screen.dart';
import '../features/report/presentation/screens/report_screen.dart';
import '../features/consumption/presentation/screens/add_fill_up_screen.dart';
import '../features/consumption/presentation/screens/consumption_screen.dart';
import '../features/search/domain/entities/fuel_type.dart';
import '../features/price_history/presentation/screens/price_history_screen.dart';
import '../features/search/presentation/screens/ev_station_detail_screen.dart';
import '../features/search/domain/entities/charging_station.dart';
import '../features/station_detail/presentation/screens/station_detail_screen.dart';
import '../features/driving/presentation/screens/driving_mode_screen.dart';
import '../features/itinerary/presentation/screens/itineraries_screen.dart';
import '../features/sync/presentation/screens/auth_screen.dart';
import '../features/sync/presentation/screens/data_transparency_screen.dart';
import '../features/sync/presentation/screens/link_device_screen.dart';
import '../features/sync/presentation/screens/sync_setup_screen.dart';
import '../features/vehicle/presentation/screens/edit_vehicle_screen.dart';
import '../features/vehicle/presentation/screens/vehicle_list_screen.dart';
import 'shell_screen.dart';
import 'station_id_validator.dart';

part 'router.g.dart';

/// Resolves the route to land on based on the active profile's
/// `landingScreen` preference. `cheapest` and `nearest` both open the Search
/// screen ('/') — the sort order is derived separately by `SelectedSortMode`.
/// Exposed for unit tests.
String resolveLandingLocation(StorageRepository storage) {
  final profileId = storage.getActiveProfileId();
  if (profileId == null) return '/';
  final landing = storage.getProfile(profileId)?['landingScreen']?.toString();
  switch (landing) {
    case 'favorites':
    case 'LandingScreen.favorites':
      return '/favorites';
    case 'map':
    case 'LandingScreen.map':
      return '/map';
    case 'cheapest':
    case 'LandingScreen.cheapest':
    case 'nearest':
    case 'LandingScreen.nearest':
    default:
      return '/';
  }
}

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
  final storage = ref.watch(storageRepositoryProvider);

  return GoRouter(
    initialLocation: '/consent',
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
      final hasConsent = storage.getSetting(StorageKeys.gdprConsentGiven) == true;
      final isConsent = state.matchedLocation == '/consent';
      final isReady = storage.isSetupComplete;
      final isSetup = state.matchedLocation == '/setup';
      // Routes the user can visit FROM inside /setup without the redirect
      // kicking them back to the wizard (#695). Without this whitelist,
      // pushing /vehicles/edit during the wizard's Vehicles step rounded
      // straight back to /setup, making "Add vehicle" appear broken.
      final isSetupAllowedChild = state.matchedLocation == '/vehicles' ||
          state.matchedLocation == '/vehicles/edit';

      // Step 1: GDPR consent must be given before anything else
      if (!hasConsent && !isConsent) return '/consent';
      if (hasConsent && isConsent) {
        return isReady ? resolveLandingLocation(storage) : '/setup';
      }

      // Step 2: Setup (onboarding) must be complete before main app
      if (!isReady && !isSetup && !isConsent && !isSetupAllowedChild) {
        return '/setup';
      }
      // Landing preference is only applied when leaving the setup flow — not
      // on every subsequent navigation back to '/', which would trap the
      // user on their landing tab.
      if (isReady && isSetup) return resolveLandingLocation(storage);
      return null;
    },
    routes: [
      GoRoute(
        path: '/consent',
        builder: (context, state) => const GdprConsentScreen(),
      ),
      GoRoute(
        path: '/setup',
        builder: (context, state) => const OnboardingWizardScreen(),
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
        path: '/search/criteria',
        builder: (context, state) => const SearchCriteriaScreen(),
      ),
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
      GoRoute(
        path: '/consumption',
        builder: (context, state) => const ConsumptionScreen(),
      ),
      GoRoute(
        path: '/carbon',
        builder: (context, state) => const CarbonDashboardScreen(),
      ),
      GoRoute(
        path: '/vehicles',
        builder: (context, state) => const VehicleListScreen(),
      ),
      GoRoute(
        path: '/vehicles/edit',
        builder: (context, state) {
          final extra = state.extra;
          final vehicleId = extra is String ? extra : null;
          return EditVehicleScreen(vehicleId: vehicleId);
        },
      ),
      GoRoute(
        path: '/consumption/add',
        builder: (context, state) {
          final extra = state.extra;
          String? stationId;
          String? stationName;
          FuelType? fuelType;
          double? pricePerLiter;
          if (extra is Map) {
            stationId = extra['stationId']?.toString();
            stationName = extra['stationName']?.toString();
            final ft = extra['fuelType'];
            if (ft is FuelType) fuelType = ft;
            final price = extra['pricePerLiter'];
            if (price is num) pricePerLiter = price.toDouble();
          }
          return AddFillUpScreen(
            stationId: stationId,
            stationName: stationName,
            preFilledFuelType: fuelType,
            preFilledPricePerLiter: pricePerLiter,
          );
        },
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
      GoRoute(
        path: '/privacy-dashboard',
        builder: (context, state) => const PrivacyDashboardScreen(),
      ),
    ],
  );
}
