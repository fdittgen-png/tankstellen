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
import '../../../../core/widgets/help_banner.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../feature_management/application/feature_flags_provider.dart';
import '../../../feature_management/domain/feature.dart';
import '../../../feature_management/domain/feature_dependency_graph.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../../route_search/domain/entities/route_info.dart';
import '../../../route_search/presentation/widgets/route_input.dart';
import '../../../route_search/providers/route_input_provider.dart';
import '../../../route_search/providers/route_search_provider.dart';
import '../../domain/entities/search_mode.dart';
import '../../providers/brand_filter_provider.dart';
import '../../providers/search_mode_provider.dart';
import '../../providers/search_provider.dart';
import '../../providers/search_screen_ui_provider.dart';
import '../widgets/amenity_filter_wrap.dart';
import '../widgets/brand_filter_chips.dart';
import '../widgets/fuel_type_selector.dart';
import '../widgets/location_input.dart' show LocationInput, LocationInputWidgetState;
import '../widgets/search_mode_toggle.dart';
import '../widgets/search_radius_slider.dart';

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
    // #1602 — the route search corridor is the user's detour budget.
    final detourBudgetKm =
        ref.read(activeProfileProvider)?.routeDetourBudgetKm ?? 5.0;
    ref.read(activeSearchModeProvider.notifier).set(SearchMode.route);
    ref.read(routeSearchStateProvider.notifier).searchAlongRoute(
          waypoints: waypoints,
          fuelType: fuelType,
          searchRadiusKm: detourBudgetKm,
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
    final profile = ref.read(activeProfileProvider);
    if (profile != null) {
      await ref.read(activeProfileProvider.notifier).updateProfile(
            profile.copyWith(
              preferredFuelType: fuelType,
              defaultSearchRadius: radius,
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
    final theme = Theme.of(context);
    final radius = ref.watch(searchRadiusProvider);
    final storedMode = ref.watch(activeSearchModeProvider);
    final openOnly = ref.watch(openOnlyFilterProvider);
    final amenities = ref.watch(selectedAmenitiesProvider);

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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          // #522 / #1962 — compact the form so every filter fits above
          // the fold on an S23 Ultra at 1x text scale. Section gaps are
          // 8 dp, label-to-control gaps 4 dp, and the surrounding
          // padding is 8 dp at the top. #1962 took the section gaps
          // from 12 dp → 8 dp and shrank the radius-slider overlay.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HelpBanner(
                storageKey: StorageKeys.helpBannerCriteria,
                icon: Icons.lightbulb_outline,
                message: l10n?.helpBannerCriteria ??
                    'Your profile defaults are pre-filled. Adjust criteria below to refine your search.',
              ),
              if (routePlanningOn) ...[
                SearchModeToggle(
                  mode: mode,
                  onChanged: (m) =>
                      ref.read(activeSearchModeProvider.notifier).set(m),
                ),
                const SizedBox(height: 8),
              ],
              // #2111 — segmented control labels the active mode.
              if (mode == SearchMode.nearby) ...[
                LocationInput(
                  key: _locationInputKey,
                  onGpsSearch: _performGpsSearch,
                  onZipSearch: _performZipSearch,
                  onCitySearch: _performCitySearch,
                ),
              ] else ...[
                RouteInput(
                  key: _routeInputKey,
                  onSearch: _performRouteSearch,
                ),
              ],
              const SizedBox(height: 8),
              Text(
                l10n?.fuelType ?? 'Fuel type',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              const FuelTypeSelector(),
              const SizedBox(height: 8),
              SearchRadiusSlider(
                radiusKm: radius,
                onChanged: (value) =>
                    ref.read(searchRadiusProvider.notifier).set(value),
              ),
              SwitchListTile(
                key: const ValueKey('criteria-open-only-toggle'),
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: openOnly,
                onChanged: (value) {
                  ref.read(openOnlyFilterProvider.notifier).set(value);
                },
                title: Text(l10n?.openOnlyFilter ?? 'Open only'),
                secondary: const Icon(Icons.schedule),
              ),
              const SizedBox(height: 4),
              Text(
                l10n?.amenities ?? 'Amenities',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              AmenityFilterWrap(
                selected: amenities,
                onToggle: (a) => ref
                    .read(selectedAmenitiesProvider.notifier)
                    .toggle(a),
              ),
              const SizedBox(height: 8),
              Consumer(
                builder: (context, ref, _) {
                  final stations = ref.watch(fuelStationsProvider);
                  if (stations.isEmpty) return const SizedBox.shrink();
                  return BrandFilterChips(stations: stations);
                },
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const ValueKey('criteria-save-defaults-button'),
                onPressed: _saveAsDefaults,
                icon: const Icon(Icons.bookmark_add),
                label: Text(
                  l10n?.saveAsDefaults ?? 'Save as my defaults',
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                ),
              ),
              // #2131 — the inline Search CTA moved to the central
              // FAB. Registration is set up in initState; see
              // [_updateFabAction] for the mode-driven enabled state.
            ],
          ),
        ),
      ),
    );
  }
}

