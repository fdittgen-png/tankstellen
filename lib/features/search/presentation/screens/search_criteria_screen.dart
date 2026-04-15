import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/location/location_consent.dart';
import '../../../../core/services/location_search_service.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/widgets/help_banner.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../../route_search/domain/entities/route_info.dart';
import '../../../route_search/presentation/widgets/route_input.dart';
import '../../../route_search/providers/route_search_provider.dart';
import '../../domain/entities/fuel_type.dart';
import '../../domain/entities/search_mode.dart';
import '../../domain/entities/station.dart';
import '../../providers/ev_search_provider.dart';
import '../../providers/search_mode_provider.dart';
import '../../providers/search_provider.dart';
import '../../providers/search_screen_ui_provider.dart';
import '../widgets/amenity_filter_wrap.dart';
import '../widgets/brand_filter_chips.dart';
import '../widgets/fuel_type_selector.dart';
import '../widgets/location_input.dart';
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
  Future<void> _performGpsSearch() async {
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

    if (fuelType == FuelType.electric) {
      ref.read(eVSearchStateProvider);
    }
    unawaited(ref.read(searchStateProvider.notifier).searchByGps(
          fuelType: fuelType,
          radiusKm: radius,
        ));
    if (mounted) Navigator.of(context).pop();
  }

  void _performZipSearch(String zip) {
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
    final fuelType = ref.read(selectedFuelTypeProvider);
    ref.read(activeSearchModeProvider.notifier).set(SearchMode.route);
    ref.read(routeSearchStateProvider.notifier).searchAlongRoute(
          waypoints: waypoints,
          fuelType: fuelType,
        );
    Navigator.of(context).pop();
  }

  Future<void> _saveAsDefaults() async {
    final profile = ref.read(activeProfileProvider);
    final l10n = AppLocalizations.of(context);
    if (profile == null) {
      SnackBarHelper.show(
        context,
        l10n?.profileNotFound ?? 'No active profile',
      );
      return;
    }
    final fuelType = ref.read(selectedFuelTypeProvider);
    final radius = ref.read(searchRadiusProvider);
    final amenities = ref.read(selectedAmenitiesProvider);
    final updated = profile.copyWith(
      preferredFuelType: fuelType,
      defaultSearchRadius: radius,
      preferredAmenities: amenities.toList(),
    );
    await ref.read(activeProfileProvider.notifier).updateProfile(updated);
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
    final mode = ref.watch(activeSearchModeProvider);
    final openOnly = ref.watch(openOnlyFilterProvider);
    final amenities = ref.watch(selectedAmenitiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.searchCriteriaTitle ?? 'Search criteria'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: AppLocalizations.of(context)?.tooltipClose ?? 'Close',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          // #522 — compact the form so every filter fits above the
          // fold on an S23 Ultra at 1x text scale. Section gaps went
          // from 20 dp → 12 dp, label-to-control gaps from 8 dp →
          // 4 dp, and surrounding padding from 16 dp top → 8 dp.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HelpBanner(
                storageKey: StorageKeys.helpBannerCriteria,
                icon: Icons.lightbulb_outline,
                message: l10n?.helpBannerCriteria ??
                    'Your profile defaults are pre-filled. Adjust criteria below to refine your search.',
              ),
              SearchModeToggle(
                mode: mode,
                onChanged: (m) =>
                    ref.read(activeSearchModeProvider.notifier).set(m),
              ),
              const SizedBox(height: 12),
              if (mode == SearchMode.nearby) ...[
                Text(
                  l10n?.gpsLocation ?? 'Location',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                LocationInput(
                  onGpsSearch: _performGpsSearch,
                  onZipSearch: _performZipSearch,
                  onCitySearch: _performCitySearch,
                ),
              ] else ...[
                Text(
                  l10n?.searchAlongRoute ?? 'Along route',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                RouteInput(onSearch: _performRouteSearch),
              ],
              const SizedBox(height: 12),
              Text(
                l10n?.fuelType ?? 'Fuel type',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              const FuelTypeSelector(),
              const SizedBox(height: 12),
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
                  final state = ref.watch(searchStateProvider);
                  final stations = state.hasValue
                      ? state.value!.data
                      : const <Station>[];
                  if (stations.isEmpty) return const SizedBox.shrink();
                  return BrandFilterChips(stations: stations);
                },
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 8),
              if (mode == SearchMode.nearby)
                FilledButton.icon(
                  key: const ValueKey('criteria-search-button'),
                  onPressed: _performGpsSearch,
                  icon: const Icon(Icons.search),
                  label: Text(l10n?.searchButton ?? 'Search'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

