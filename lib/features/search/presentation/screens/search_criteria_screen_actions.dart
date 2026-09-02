// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'search_criteria_screen.dart';

/// The imperative half of [SearchCriteriaScreen] (#3927): the four search
/// dispatchers, the save-as-defaults writer and the reset.
///
/// Split into a `part` mixin — not a separate widget — because every one
/// of these needs the screen's `ref`, `context` and `mounted`, and because
/// the screen file is at the 400-line cap. A mixin (not an extension) so
/// it can own the `GlobalKey`s and the re-entry flag as real fields.
mixin _SearchCriteriaActions on ConsumerState<SearchCriteriaScreen> {
  // #2131 / #2137 — GlobalKeys drive the inline inputs' submit from the
  // action bar (and from the shell FAB, which mirrors it).
  final GlobalKey<RouteInputWidgetState> routeInputKey =
      GlobalKey<RouteInputWidgetState>();
  final GlobalKey<LocationInputWidgetState> locationInputKey =
      GlobalKey<LocationInputWidgetState>();

  // #2136 — re-entry guard: double-tap pop races crash with "No element".
  bool searchFired = false;

  /// Runs the route search through [RouteInput]'s own resolve step.
  void onRouteSubmit() {
    unawaited(routeInputKey.currentState?.resolveAndSearch());
  }

  /// Runs the nearby search through [LocationInput], which decides between
  /// GPS / ZIP / city from what the field holds.
  void onNearbySubmit() {
    final loc = locationInputKey.currentState;
    if (loc != null) {
      loc.submit();
    } else {
      unawaited(performGpsSearch());
    }
  }

  Future<void> performGpsSearch() async {
    if (searchFired) return;
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
            AppLocalizations.of(context).locationDenied,
          );
        }
        return;
      }
      await LocationConsentDialog.recordConsent(settings);
    }
    if (searchFired || !mounted) return;
    searchFired = true;
    // SearchState dispatches to EV or fuel service based on fuelType.
    unawaited(
      ref
          .read(searchStateProvider.notifier)
          .searchByGps(fuelType: fuelType, radiusKm: radius),
    );
    Navigator.of(context).pop();
  }

  void performZipSearch(String zip) {
    if (searchFired || !mounted) return;
    searchFired = true;
    final fuelType = ref.read(selectedFuelTypeProvider);
    final radius = ref.read(searchRadiusProvider);
    unawaited(
      ref
          .read(searchStateProvider.notifier)
          .searchByZipCode(zipCode: zip, fuelType: fuelType, radiusKm: radius),
    );
    Navigator.of(context).pop();
  }

  void performCitySearch(ResolvedLocation city) {
    if (searchFired || !mounted) return;
    searchFired = true;
    final fuelType = ref.read(selectedFuelTypeProvider);
    final radius = ref.read(searchRadiusProvider);
    unawaited(
      ref
          .read(searchStateProvider.notifier)
          .searchByCoordinates(
            lat: city.lat,
            lng: city.lng,
            postalCode: city.postcode,
            locationName: city.name,
            fuelType: fuelType,
            radiusKm: radius,
          ),
    );
    Navigator.of(context).pop();
  }

  void performRouteSearch(List<RouteWaypoint> waypoints) {
    if (searchFired || !mounted) return;
    searchFired = true;
    final fuelType = ref.read(selectedFuelTypeProvider);
    // #2592 — the route-planning params come from the criteria screen's
    // per-search overrides (defaulted from the profile). #1602 — the
    // corridor radius is the detour budget.
    final detourBudgetKm = ref.read(routeDetourSearchParamProvider);
    final segmentKm = ref.read(routeSegmentSearchParamProvider);
    final minSaving = ref.read(minRouteSavingSearchParamProvider);
    ref.read(activeSearchModeProvider.notifier).set(SearchMode.route);
    unawaited(
      ref
          .read(routeSearchStateProvider.notifier)
          .searchAlongRoute(
            waypoints: waypoints,
            fuelType: fuelType,
            searchRadiusKm: detourBudgetKm,
            segmentKm: segmentKm,
            minSavingPerLiter: minSaving,
          ),
    );
    Navigator.of(context).pop();
  }

  /// #3927 — restore every criteria provider to the SAVED defaults, or to
  /// the factory ones when nothing was saved.
  ///
  /// Each of these notifiers already reads its saved default in `build()`
  /// (#1792 for the device-local ones, the profile for fuel / radius /
  /// route params), so invalidating them re-runs exactly the same
  /// restore path the app takes on a cold start — no second copy of the
  /// default logic to drift.
  void resetCriteria() {
    ref.invalidate(selectedFuelTypeProvider);
    ref.invalidate(searchRadiusProvider);
    ref.invalidate(openOnlyFilterProvider);
    ref.invalidate(selectedAmenitiesProvider);
    ref.invalidate(selectedBrandsProvider);
    ref.invalidate(excludeHighwayStationsProvider);
    ref.invalidate(routeSegmentSearchParamProvider);
    ref.invalidate(routeDetourSearchParamProvider);
    ref.invalidate(minRouteSavingSearchParamProvider);
    if (!mounted) return;
    SnackBarHelper.show(context, AppLocalizations.of(context).criteriaResetDone);
  }

  Future<void> saveAsDefaults() async {
    final l10n = AppLocalizations.of(context);
    final fuelType = ref.read(selectedFuelTypeProvider);
    final radius = ref.read(searchRadiusProvider);
    final amenities = ref.read(selectedAmenitiesProvider);
    final openOnly = ref.read(openOnlyFilterProvider);
    final brands = ref.read(selectedBrandsProvider);
    final excludeHighway = ref.read(excludeHighwayStationsProvider);

    // #3159 — read everything BEFORE the storage awaits below: a
    // post-await ref.read throws a StateError if the screen unmounted
    // while the settings were persisting. The captured notifier still
    // finishes the profile write on the unmounted path.
    final storage = ref.read(storageRepositoryProvider);
    final profile = ref.read(activeProfileProvider);
    final profileNotifier = ref.read(activeProfileProvider.notifier);
    final inRoute = ref.read(activeSearchModeProvider) == SearchMode.route;
    final routeSegmentKm = ref.read(routeSegmentSearchParamProvider);
    final routeDetourBudgetKm = ref.read(routeDetourSearchParamProvider);
    final minRouteSavingPerLiter = ref.read(minRouteSavingSearchParamProvider);

    // #1792 — the criteria with no UserProfile field of their own
    // (open-only, amenity set, brand filter) persist device-locally so
    // the *whole* default set round-trips, not just the profile
    // subset. This runs regardless of whether a profile is active.
    await storage.putSetting(StorageKeys.defaultOpenOnly, openOnly);
    await storage.putSetting(StorageKeys.defaultExcludeHighway, excludeHighway);
    await storage.putSetting(
      StorageKeys.defaultAmenities,
      amenities.map((a) => a.name).toList(),
    );
    await storage.putSetting(StorageKeys.defaultBrands, brands.toList());

    // Fuel type + radius are profile fields — mirror them into the
    // active profile so existing profile consumers keep seeing them.
    // #2592 — in route mode also persist the route-planning params so the
    // per-search overrides become the new profile defaults.
    if (profile != null) {
      await profileNotifier.updateProfile(
        profile.copyWith(
          preferredFuelType: fuelType,
          defaultSearchRadius: radius,
          routeSegmentKm: inRoute ? routeSegmentKm : profile.routeSegmentKm,
          routeDetourBudgetKm: inRoute
              ? routeDetourBudgetKm
              : profile.routeDetourBudgetKm,
          minRouteSavingPerLiter: inRoute
              ? minRouteSavingPerLiter
              : profile.minRouteSavingPerLiter,
        ),
      );
    }

    if (!mounted) return;
    SnackBarHelper.show(context, l10n.criteriaSavedToProfile);
  }
}
