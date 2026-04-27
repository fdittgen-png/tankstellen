import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../core/data/storage_repository.dart';
import '../core/telemetry/integrations/navigation_trace_observer.dart';
import '../core/storage/storage_keys.dart';
import '../core/storage/storage_providers.dart';
import 'routes/consumption_routes.dart';
import 'routes/onboarding_routes.dart';
import 'routes/profile_routes.dart';
import 'routes/search_routes.dart';
import 'routes/shell_branches.dart';
import 'routes/station_routes.dart';
import 'routes/sync_routes.dart';
import 'shell_screen.dart';

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
      ...onboardingRoutes,
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ShellScreen(navigationShell: navigationShell),
        branches: shellBranches,
      ),
      ...searchRoutes,
      ...profileRoutes,
      ...consumptionRoutes,
      ...stationRoutes(ref),
      ...syncRoutes,
    ],
  );
}
