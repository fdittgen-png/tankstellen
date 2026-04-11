import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/location/location_consent.dart';
import '../../../../core/services/location_search_service.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/fuel_type.dart';
import '../../domain/entities/station.dart';
import '../../providers/ev_search_provider.dart';
import '../../providers/search_provider.dart';
import '../widgets/brand_filter_chips.dart';
import '../widgets/fuel_type_selector.dart';
import '../widgets/location_input.dart';

/// Full-screen modal for editing search criteria (location, fuel, radius, brands).
///
/// Pops on submission and delegates the new search to [SearchState]. The caller
/// (the results screen) automatically rebuilds when the state updates.
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
      // Ensure the EV provider is initialized so the results screen picks it up.
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final radius = ref.watch(searchRadiusProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.searchCriteriaTitle ?? 'Search criteria'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Close',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              const SizedBox(height: 12),
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
              const SizedBox(height: 24),
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
