// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../core/data/storage_repository.dart';
import '../core/navigation/app_routes.dart';
import '../core/navigation/root_navigator_key.dart';
import '../l10n/app_localizations.dart';
import '../core/telemetry/integrations/navigation_trace_observer.dart';
import '../core/storage/storage_keys.dart';
import '../core/storage/storage_providers.dart';
import '../features/consumption/providers/pending_shared_receipt_provider.dart';
import '../features/widget/presentation/widget_uri_parser.dart';
import '../features/widget/providers/pending_widget_uri_provider.dart';
import 'routes/consumption_routes.dart';
import 'routes/onboarding_routes.dart';
import 'routes/profile_routes.dart';
import 'routes/search_routes.dart';
import 'routes/shell_branches.dart';
import 'routes/station_routes.dart';
import 'routes/sync_routes.dart';
import 'shell_screen.dart';

part 'router.g.dart';

/// Consumes the pending home-widget cold-launch URI (set by
/// `AppInitializer._stashWidgetLaunchUri`) and converts it to a router
/// path. Returns `null` when no URI is pending or the URI doesn't
/// resolve to a known route — callers fall back to their default
/// landing behaviour.
///
/// `consume()` clears the stash so the redirect only re-routes the
/// first time the router evaluates after a widget tap.
String? _consumePendingWidgetPath(Ref ref) {
  // `consumeDeferred` schedules the state clear via `Future.microtask`
  // so the mutation lands AFTER the router redirect / widget build
  // returns — Riverpod asserts against state writes during the build
  // phase. The URI itself is returned synchronously so the redirect
  // can act on it in the same tick.
  final pending = ref.read(pendingWidgetUriProvider.notifier).consumeDeferred();
  if (pending == null) return null;
  return widgetUriToPath(pending);
}

/// Resolves the route for a pending inbound-share receipt (stashed by
/// `ShareReceiptHandler` from an OS share intent, #2735). Returns
/// `/consumption/add` when an image path is pending AND we are not
/// already on that route; otherwise `null` so callers fall back to their
/// default landing behaviour.
///
/// Unlike [_consumePendingWidgetPath], this PEEKS rather than consumes:
/// the home-widget URI is self-contained, but here `AddFillUpScreen`
/// must still read the same stashed path on open to OCR the receipt
/// (`runSharedReceiptScan`, #2734). The screen owns clearing the stash;
/// the `state.matchedLocation` guard stops the redirect re-firing once
/// the user has landed on the form (the stash is cleared a frame later
/// by the screen, so without the guard the redirect would route to
/// `/consumption/add` again on the very next evaluation).
String? _resolvePendingSharedReceiptPath(Ref ref, GoRouterState state) {
  if (state.matchedLocation == RoutePaths.addFillUp) return null;
  final pending = ref.read(pendingSharedReceiptProvider);
  return pending != null ? RoutePaths.addFillUp : null;
}

/// Resolves the route to land on based on the active profile's
/// `landingScreen` preference. `cheapest` and `nearest` both open the Search
/// screen ('/') — the sort order is derived separately by `SelectedSortMode`.
/// Exposed for unit tests.
String resolveLandingLocation(StorageRepository storage) {
  final profileId = storage.getActiveProfileId();
  if (profileId == null) return RoutePaths.search;
  final landing = storage.getProfile(profileId)?['landingScreen']?.toString();
  switch (landing) {
    case 'favorites':
    case 'LandingScreen.favorites':
      return RoutePaths.favorites;
    case 'map':
    case 'LandingScreen.map':
      return RoutePaths.map;
    case 'cheapest':
    case 'LandingScreen.cheapest':
    case 'nearest':
    case 'LandingScreen.nearest':
    default:
      return RoutePaths.search;
  }
}

@riverpod
GoRouter router(Ref ref) {
  final storage = ref.watch(storageRepositoryProvider);

  return GoRouter(
    // #1971 — an explicit root navigator key so widgets above the
    // navigator (e.g. `CountrySwitchListener` in the MaterialApp
    // builder) can reach a navigator-bearing context for `showDialog`.
    navigatorKey: rootNavigatorKey,
    initialLocation: RoutePaths.consent,
    observers: [NavigationTraceObserver()],
    errorBuilder: (context, state) {
      // #1690 — the 404 / page-not-found screen is localized so it
      // doesn't render in English for non-English users.
      final l = AppLocalizations.of(context);
      return Scaffold(
        appBar: AppBar(title: Text(l.notFoundTitle)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                l.notFoundBody(state.matchedLocation),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go(RoutePaths.search),
                child: Text(l.notFoundHomeButton),
              ),
            ],
          ),
        ),
      );
    },
    redirect: (context, state) {
      // Read live from storage each redirect — not cached at provider creation
      final hasConsent = storage.getSetting(StorageKeys.gdprConsentGiven) == true;
      final isConsent = state.matchedLocation == RoutePaths.consent;
      final isReady = storage.isSetupComplete;
      final isSetup = state.matchedLocation == RoutePaths.setup;
      // Routes the user can visit FROM inside /setup without the redirect
      // kicking them back to the wizard (#695). Without this whitelist,
      // pushing /vehicles/edit during the wizard's Vehicles step rounded
      // straight back to /setup, making "Add vehicle" appear broken.
      final isSetupAllowedChild = state.matchedLocation == RoutePaths.vehicles ||
          state.matchedLocation == RoutePaths.editVehicle;

      // Cold-start widget tap on an existing fully-setup user lands the
      // router at the configured `landingScreen` (typically '/'). The
      // stashed widget URI must be consumed BEFORE the consent/setup
      // gates run their default behaviour, otherwise an existing user
      // whose redirect never falls into the consent/setup branches
      // never gets the URI applied (the original 2026-05-24 report).
      // Consuming up-front is safe: the consent/setup gates below
      // return their own override paths if the user actually needs to
      // be sent to onboarding, and the pending URI is then re-honoured
      // by the consent/setup branches once the user lands past those
      // walls.
      if (hasConsent && isReady && !isConsent && !isSetup) {
        // #2735 — an inbound shared receipt routes the user to the
        // Add-fill-up form before the landing flow, same precedence /
        // safety rationale as the widget-URI consume above. Checked
        // first: a deliberate "share this receipt" gesture outranks a
        // pending widget deep-link.
        final sharePath = _resolvePendingSharedReceiptPath(ref, state);
        if (sharePath != null) return sharePath;
        final widgetPath = _consumePendingWidgetPath(ref);
        if (widgetPath != null) return widgetPath;
      }

      // Step 1: GDPR consent must be given before anything else
      if (!hasConsent && !isConsent) return RoutePaths.consent;
      if (hasConsent && isConsent) {
        if (!isReady) return RoutePaths.setup;
        // Past consent + past setup: prefer a pending widget cold-launch
        // URI over the user's configured landing screen so a home-widget
        // tap lands directly on the station detail. `consumeDeferred`
        // clears the stash via a microtask (Riverpod forbids state
        // writes during a widget-tree build) so a subsequent redirect
        // — e.g. the user backing out of the detail — falls through to
        // the normal landing flow.
        final sharePath = _resolvePendingSharedReceiptPath(ref, state);
        if (sharePath != null) return sharePath;
        final widgetPath = _consumePendingWidgetPath(ref);
        if (widgetPath != null) return widgetPath;
        return resolveLandingLocation(storage);
      }

      // Step 2: Setup (onboarding) must be complete before main app
      if (!isReady && !isSetup && !isConsent && !isSetupAllowedChild) {
        return RoutePaths.setup;
      }
      // Landing preference is only applied when leaving the setup flow — not
      // on every subsequent navigation back to '/', which would trap the
      // user on their landing tab.
      if (isReady && isSetup) {
        // Same widget-URI precedence as the consent->landing step above:
        // a fresh-install user who completes setup AND has a pending
        // widget URI should also land on the station detail.
        final sharePath = _resolvePendingSharedReceiptPath(ref, state);
        if (sharePath != null) return sharePath;
        final widgetPath = _consumePendingWidgetPath(ref);
        if (widgetPath != null) return widgetPath;
        return resolveLandingLocation(storage);
      }
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
