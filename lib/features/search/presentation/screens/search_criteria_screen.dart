// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/shell/search_fab_action_provider.dart';
import '../../../../core/location/location_consent.dart';
import '../../../../core/services/location_search_service.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../feature_management/application/feature_flags_provider.dart';
import '../../../feature_management/domain/feature.dart';
import '../../../feature_management/domain/feature_dependency_graph.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../../route_search/domain/entities/route_info.dart';
import '../../../route_search/presentation/widgets/route_input.dart'
    show RouteInputWidgetState;
import '../../../route_search/providers/route_input_provider.dart';
import '../../../route_search/providers/route_search_params_provider.dart';
import '../../../route_search/providers/route_search_provider.dart';
import '../../domain/entities/search_mode.dart';
import '../../providers/brand_filter_provider.dart';
import '../../providers/search_mode_provider.dart';
import '../../providers/search_provider.dart';
import '../../providers/search_screen_ui_provider.dart';
import '../widgets/location_input.dart' show LocationInputWidgetState;
import '../widgets/search_criteria_form.dart';

/// Full-screen modal for editing search criteria (mode, location, fuel, radius,
/// filters, equipment). Pops on submission and delegates to the relevant
/// state providers.
class SearchCriteriaScreen extends ConsumerStatefulWidget {
  const SearchCriteriaScreen({super.key});

  @override
  ConsumerState<SearchCriteriaScreen> createState() =>
      _SearchCriteriaScreenState();
}

class _SearchCriteriaScreenState extends ConsumerState<SearchCriteriaScreen> {
  // #2131 / #2137 — GlobalKeys drive the inline inputs' submit from the FAB.
  final GlobalKey<RouteInputWidgetState> _routeInputKey =
      GlobalKey<RouteInputWidgetState>();
  final GlobalKey<LocationInputWidgetState> _locationInputKey =
      GlobalKey<LocationInputWidgetState>();

  SearchFabAction? _registeredFabAction;
  SearchFabActionController? _fabNotifier;

  // #2136 — re-entry guard: double-tap pop races crash with "No element".
  bool _searchFired = false;

  @override
  void initState() {
    super.initState();
    _fabNotifier = ref.read(searchFabActionControllerProvider.notifier);
    // Defer to post-frame: the input widgets' state (and their text
    // controllers) only stabilises after the first build.
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateFabAction());
  }

  @override
  void dispose() {
    final action = _registeredFabAction;
    final notifier = _fabNotifier;
    if (action != null && notifier != null) {
      // #2139 — microtask fires before any frame; addPostFrameCallback
      // can be skipped if no frame is scheduled, leaving a stale
      // action that makes the FAB look enabled but no-op.
      Future.microtask(() {
        try {
          notifier.clearFor(this); // #2553 — clear by owner, not action.
        } catch (_) {
          // ProviderContainer torn down (e.g. test teardown) — no-op.
        }
      });
    }
    super.dispose();
  }

  void _updateFabAction() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final mode = ref.read(activeSearchModeProvider);
    final manifest = ref.read(featureManifestProvider);
    final enabledFlags = ref.read(enabledFeaturesProvider);
    final routePlanningOn = isEffectivelyEnabled(
      Feature.routePlanning,
      manifest,
      enabledFlags,
    );
    final effectiveMode = routePlanningOn ? mode : SearchMode.nearby;

    final bool enabled;
    final VoidCallback onTap;
    if (effectiveMode == SearchMode.route) {
      enabled = ref.read(routeInputControllerProvider).canSearch;
      onTap = _onFabRouteTap;
    } else {
      enabled = true;
      onTap = _onFabNearbyTap;
    }

    final action = SearchFabAction(
      icon: Icons.search,
      tooltip: l10n?.fabRunSearch ?? 'Run search',
      enabled: enabled,
      onTap: onTap,
    );
    // #2553 — register under this State as owner (self-clears by owner).
    ref.read(searchFabActionControllerProvider.notifier).setFor(this, action);
    _registeredFabAction = action;
  }

  // #2139 — defensively clear if invoked after dispose (covers the
  // window before the dispose-microtask fires).
  bool _bailIfStale() {
    if (mounted) return false;
    // #2553 — clear by owner identity (see SearchFabActionController).
    if (_registeredFabAction != null) _fabNotifier?.clearFor(this);
    return true;
  }

  void _onFabRouteTap() {
    if (_bailIfStale()) return;
    _routeInputKey.currentState?.resolveAndSearch();
  }

  void _onFabNearbyTap() {
    if (_bailIfStale()) return;
    final loc = _locationInputKey.currentState;
    if (loc != null) {
      loc.submit();
    } else {
      unawaited(_performGpsSearch());
    }
  }

  Future<void> _performGpsSearch() async {
    if (_searchFired) return;
    final fuelType = ref.read(selectedFuelTypeProvider);
    final radius = ref.read(searchRadiusProvider);
    final settings = ref.read(settingsStorageProvider);
    if (!LocationConsentDialog.hasConsent(settings)) {
      if (!mounted) return;
      final consented = await LocationConsentDialog.show(context);
      if (!consented) {
        if (mounted) {
          SnackBarHelper.show(
            context,
            AppLocalizations.of(context)?.locationDenied ??
                'Location permission denied.',
          );
        }
        return;
      }
      await LocationConsentDialog.recordConsent(settings);
    }
    if (_searchFired || !mounted) return;
    _searchFired = true;
    // SearchState dispatches to EV or fuel service based on fuelType.
    unawaited(ref.read(searchStateProvider.notifier).searchByGps(
        fuelType: fuelType, radiusKm: radius));
    Navigator.of(context).pop();
  }

  void _performZipSearch(String zip) {
    if (_searchFired || !mounted) return;
    _searchFired = true;
    final fuelType = ref.read(selectedFuelTypeProvider);
    final radius = ref.read(searchRadiusProvider);
    ref.read(searchStateProvider.notifier).searchByZipCode(
          zipCode: zip,
          fuelType: fuelType,
          radiusKm: radius,
        );
    Navigator.of(context).pop();
  }

  void _performCitySearch(ResolvedLocation city) {
    if (_searchFired || !mounted) return;
    _searchFired = true;
    final fuelType = ref.read(selectedFuelTypeProvider);
    final radius = ref.read(searchRadiusProvider);
    ref.read(searchStateProvider.notifier).searchByCoordinates(
          lat: city.lat,
          lng: city.lng,
          postalCode: city.postcode,
          locationName: city.name,
          fuelType: fuelType,
          radiusKm: radius,
        );
    Navigator.of(context).pop();
  }

  void _performRouteSearch(List<RouteWaypoint> waypoints) {
    if (_searchFired || !mounted) return;
    _searchFired = true;
    final fuelType = ref.read(selectedFuelTypeProvider);
    // #2592 — the route-planning params come from the criteria screen's
    // per-search overrides (defaulted from the profile). #1602 — the
    // corridor radius is the detour budget.
    final detourBudgetKm = ref.read(routeDetourSearchParamProvider);
    final segmentKm = ref.read(routeSegmentSearchParamProvider);
    final minSaving = ref.read(minRouteSavingSearchParamProvider);
    ref.read(activeSearchModeProvider.notifier).set(SearchMode.route);
    ref.read(routeSearchStateProvider.notifier).searchAlongRoute(
          waypoints: waypoints,
          fuelType: fuelType,
          searchRadiusKm: detourBudgetKm,
          segmentKm: segmentKm,
          minSavingPerLiter: minSaving,
        );
    Navigator.of(context).pop();
  }

  Future<void> _saveAsDefaults() async {
    final l10n = AppLocalizations.of(context);
    final fuelType = ref.read(selectedFuelTypeProvider);
    final radius = ref.read(searchRadiusProvider);
    final amenities = ref.read(selectedAmenitiesProvider);
    final openOnly = ref.read(openOnlyFilterProvider);
    final brands = ref.read(selectedBrandsProvider);
    final excludeHighway = ref.read(excludeHighwayStationsProvider);

    // #1792 — the criteria with no UserProfile field of their own
    // (open-only, amenity set, brand filter) persist device-locally so
    // the *whole* default set round-trips, not just the profile
    // subset. This runs regardless of whether a profile is active.
    final storage = ref.read(storageRepositoryProvider);
    await storage.putSetting(StorageKeys.defaultOpenOnly, openOnly);
    await storage.putSetting(
        StorageKeys.defaultExcludeHighway, excludeHighway);
    await storage.putSetting(
      StorageKeys.defaultAmenities,
      amenities.map((a) => a.name).toList(),
    );
    await storage.putSetting(StorageKeys.defaultBrands, brands.toList());

    // Fuel type + radius are profile fields — mirror them into the
    // active profile so existing profile consumers keep seeing them.
    // #2592 — in route mode also persist the route-planning params so the
    // per-search overrides become the new profile defaults.
    final profile = ref.read(activeProfileProvider);
    if (profile != null) {
      final inRoute = ref.read(activeSearchModeProvider) == SearchMode.route;
      await ref.read(activeProfileProvider.notifier).updateProfile(
            profile.copyWith(
              preferredFuelType: fuelType,
              defaultSearchRadius: radius,
              routeSegmentKm: inRoute
                  ? ref.read(routeSegmentSearchParamProvider)
                  : profile.routeSegmentKm,
              routeDetourBudgetKm: inRoute
                  ? ref.read(routeDetourSearchParamProvider)
                  : profile.routeDetourBudgetKm,
              minRouteSavingPerLiter: inRoute
                  ? ref.read(minRouteSavingSearchParamProvider)
                  : profile.minRouteSavingPerLiter,
            ),
          );
    }

    if (!mounted) return;
    SnackBarHelper.show(
      context,
      l10n?.criteriaSavedToProfile ?? 'Saved as defaults',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final storedMode = ref.watch(activeSearchModeProvider);

    // #2131 — re-register the FAB when mode or canSearch flip.
    ref.listen<SearchMode>(activeSearchModeProvider, (_, _) => _updateFabAction());
    ref.listen<RouteInputState>(routeInputControllerProvider, (p, n) {
      if (p?.canSearch != n.canSearch) _updateFabAction();
    });

    // #1447 phase 4 — when routePlanning is gated off, hide the toggle
    // and treat the stored mode as Nearby (the stored value is preserved).
    final manifest = ref.watch(featureManifestProvider);
    final enabledFlags = ref.watch(enabledFeaturesProvider);
    final routePlanningOn = isEffectivelyEnabled(
      Feature.routePlanning,
      manifest,
      enabledFlags,
    );
    final mode = routePlanningOn ? storedMode : SearchMode.nearby;

    return PageScaffold(
      title: l10n?.searchCriteriaTitle ?? 'Search criteria',
      leading: IconButton(
        icon: const Icon(Icons.close),
        tooltip: AppLocalizations.of(context)?.tooltipClose ?? 'Close',
        onPressed: () => Navigator.of(context).pop(),
      ),
      bodyPadding: EdgeInsets.zero,
      // #2592 — the form body lives in SearchCriteriaForm so this screen
      // stays under the file-length cap; the State retains the search /
      // save actions and the FAB wiring and passes them down.
      body: SafeArea(
        child: SearchCriteriaForm(
          routeInputKey: _routeInputKey,
          locationInputKey: _locationInputKey,
          routePlanningOn: routePlanningOn,
          mode: mode,
          onGpsSearch: _performGpsSearch,
          onZipSearch: _performZipSearch,
          onCitySearch: _performCitySearch,
          onRouteSearch: _performRouteSearch,
          onSaveDefaults: _saveAsDefaults,
        ),
      ),
    );
  }
}

