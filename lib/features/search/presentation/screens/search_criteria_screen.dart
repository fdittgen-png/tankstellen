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
import '../../domain/entities/station_amenity.dart';
import '../../providers/ev_search_provider.dart';
import '../../providers/search_mode_provider.dart';
import '../../providers/search_provider.dart';
import '../../providers/search_screen_ui_provider.dart';
import '../widgets/brand_filter_chips.dart';
import '../widgets/fuel_type_selector.dart';
import '../widgets/location_input.dart';

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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // First-time help banner
              HelpBanner(
                storageKey: StorageKeys.helpBannerCriteria,
                icon: Icons.lightbulb_outline,
                message: l10n?.helpBannerCriteria ??
                    'Your profile defaults are pre-filled. Adjust criteria below to refine your search.',
              ),
              // Itinerary mode toggle.
              SegmentedButton<SearchMode>(
                key: const ValueKey('criteria-mode-toggle'),
                segments: [
                  ButtonSegment(
                    value: SearchMode.nearby,
                    label: Text(l10n?.searchNearby ?? 'Nearby'),
                    icon: const Icon(Icons.near_me),
                  ),
                  ButtonSegment(
                    value: SearchMode.route,
                    label: Text(l10n?.searchAlongRoute ?? 'Along route'),
                    icon: const Icon(Icons.route),
                  ),
                ],
                selected: {mode},
                onSelectionChanged: (selected) {
                  ref
                      .read(activeSearchModeProvider.notifier)
                      .set(selected.first);
                },
              ),
              const SizedBox(height: 20),
              if (mode == SearchMode.nearby) ...[
                Text(
                  l10n?.gpsLocation ?? 'Location',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
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
                const SizedBox(height: 8),
                RouteInput(onSearch: _performRouteSearch),
              ],
              const SizedBox(height: 20),
              Text(
                l10n?.fuelType ?? 'Fuel type',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              const FuelTypeSelector(),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    '${l10n?.searchRadius ?? "Radius"}:',
                    style: theme.textTheme.titleSmall,
                  ),
                  const Spacer(),
                  Text('${radius.round()} km',
                      style: theme.textTheme.titleSmall),
                ],
              ),
              Slider(
                value: radius,
                min: 1,
                max: 25,
                divisions: 24,
                label: '${radius.round()} km',
                onChanged: (value) {
                  ref.read(searchRadiusProvider.notifier).set(value);
                },
              ),
              const SizedBox(height: 4),
              // "Open only" filter.
              SwitchListTile(
                key: const ValueKey('criteria-open-only-toggle'),
                contentPadding: EdgeInsets.zero,
                value: openOnly,
                onChanged: (value) {
                  ref.read(openOnlyFilterProvider.notifier).set(value);
                },
                title: Text(l10n?.openOnlyFilter ?? 'Open only'),
                secondary: const Icon(Icons.schedule),
              ),
              const SizedBox(height: 8),
              // Equipment filter chips.
              Text(
                l10n?.amenities ?? 'Amenities',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              _AmenityFilterWrap(
                selected: amenities,
                onToggle: (a) => ref
                    .read(selectedAmenitiesProvider.notifier)
                    .toggle(a),
              ),
              const SizedBox(height: 16),
              // Brand filter operates on the currently loaded result set.
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
              const SizedBox(height: 16),
              // Save as defaults.
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
              const SizedBox(height: 12),
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

/// Wrap of FilterChips, one per [StationAmenity].
class _AmenityFilterWrap extends StatelessWidget {
  final Set<StationAmenity> selected;
  final ValueChanged<StationAmenity> onToggle;

  const _AmenityFilterWrap({
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final amenity in StationAmenity.values)
          FilterChip(
            key: ValueKey('criteria-amenity-${amenity.name}'),
            avatar: Icon(amenityIcon(amenity), size: 18),
            label: Text(_label(amenity, l10n)),
            selected: selected.contains(amenity),
            onSelected: (_) => onToggle(amenity),
          ),
      ],
    );
  }

  String _label(StationAmenity a, AppLocalizations? l10n) {
    return switch (a) {
      StationAmenity.shop => l10n?.amenityShop ?? 'Shop',
      StationAmenity.carWash => l10n?.amenityCarWash ?? 'Car Wash',
      StationAmenity.airPump => l10n?.amenityAirPump ?? 'Air',
      StationAmenity.toilet => l10n?.amenityToilet ?? 'WC',
      StationAmenity.restaurant => l10n?.amenityRestaurant ?? 'Food',
      StationAmenity.atm => l10n?.amenityAtm ?? 'ATM',
      StationAmenity.wifi => l10n?.amenityWifi ?? 'WiFi',
      StationAmenity.ev => l10n?.amenityEv ?? 'EV',
    };
  }
}
