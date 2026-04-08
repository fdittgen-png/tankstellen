import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/responsive_search_layout.dart';
import '../../../../core/country/country_provider.dart';
import '../../../../core/location/location_consent.dart';
import '../../../../core/location/user_position_provider.dart';
import '../../../../core/services/location_search_service.dart';
import '../../../../core/services/widgets/service_status_banner.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/utils/frame_callbacks.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/shimmer_placeholder.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../map/presentation/widgets/inline_map.dart';
import '../../providers/search_provider.dart';
import '../widgets/demo_mode_banner.dart';
import '../widgets/search_results_list.dart';
import '../widgets/user_position_bar.dart';
import '../../../route_search/domain/entities/route_info.dart';
import '../../../route_search/providers/route_search_provider.dart';
import '../../providers/search_mode_provider.dart';
import '../../providers/search_screen_ui_provider.dart';
import '../../providers/ev_search_provider.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/services/service_result.dart';
import '../../domain/entities/fuel_type.dart';
import '../../domain/entities/search_mode.dart';
import '../../domain/entities/search_result_item.dart';
import '../../domain/entities/station.dart';
import '../widgets/ev_station_card.dart';
import '../../../profile/data/models/user_profile.dart';
import '../../../profile/providers/profile_provider.dart';
import '../widgets/mode_chip.dart';
import '../widgets/nearby_search_controls.dart';
import '../widgets/route_search_controls.dart';
import '../widgets/route_results_view.dart';

/// Main search screen — a thin shell that composes NearbySearchControls,
/// RouteSearchControls, and RouteResultsView widgets.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  @override
  void initState() {
    super.initState();
    safePostFrame(() {
      final profile = ref.read(activeProfileProvider);
      if (profile?.landingScreen == LandingScreen.cheapest) {
        final zip = profile?.homeZipCode;
        if (zip != null && zip.isNotEmpty) {
          _performZipSearch(zip);
        } else {
          _performGpsSearch();
        }
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Search actions
  // ---------------------------------------------------------------------------

  void _performRouteSearch(List<RouteWaypoint> waypoints) {
    final fuelType = ref.read(selectedFuelTypeProvider);
    final radius = ref.read(searchRadiusProvider);
    ref.read(filtersExpandedProvider.notifier).collapse();
    ref.read(routeSearchStateProvider.notifier).searchAlongRoute(
      waypoints: waypoints,
      fuelType: fuelType,
      searchRadiusKm: radius.clamp(1, 10),
      strategyType: ref.read(selectedRouteStrategyProvider),
    );
  }

  Future<void> _performGpsSearch() async {
    final fuelType = ref.read(selectedFuelTypeProvider);
    final radius = ref.read(searchRadiusProvider);
    final settings = ref.read(settingsStorageProvider);
    if (!LocationConsentDialog.hasConsent(settings)) {
      if (!mounted) return;
      final consented = await LocationConsentDialog.show(context);
      if (!consented) {
        if (mounted) {
          SnackBarHelper.show(context, AppLocalizations.of(context)?.locationDenied ??
              'Location permission denied. You can search by postal code.');
        }
        return;
      }
      await LocationConsentDialog.recordConsent(settings);
    }
    ref.read(filtersExpandedProvider.notifier).collapse();

    if (fuelType == FuelType.electric) {
      try {
        final locationService = ref.read(locationServiceProvider);
        final position = await locationService.getCurrentPosition();
        ref.read(eVSearchStateProvider.notifier).searchNearby(
          lat: position.latitude,
          lng: position.longitude,
          radiusKm: radius,
        );
      } catch (e) {
        if (mounted) {
          SnackBarHelper.showError(context, '${AppLocalizations.of(context)?.gpsError ?? "GPS error"}: $e');
        }
      }
    } else {
      ref.read(searchStateProvider.notifier).searchByGps(
        fuelType: fuelType,
        radiusKm: radius,
      );
    }
  }

  void _performZipSearch(String zip) {
    final fuelType = ref.read(selectedFuelTypeProvider);
    final radius = ref.read(searchRadiusProvider);
    ref.read(filtersExpandedProvider.notifier).collapse();
    ref.read(searchStateProvider.notifier).searchByZipCode(
      zipCode: zip,
      fuelType: fuelType,
      radiusKm: radius,
    );
  }

  void _performCitySearch(ResolvedLocation city) {
    final fuelType = ref.read(selectedFuelTypeProvider);
    final radius = ref.read(searchRadiusProvider);
    ref.read(filtersExpandedProvider.notifier).collapse();
    ref.read(searchStateProvider.notifier).searchByCoordinates(
      lat: city.lat,
      lng: city.lng,
      postalCode: city.postcode,
      locationName: city.name,
      fuelType: fuelType,
      radiusKm: radius,
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isWide = isWideScreen(context);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final filtersExpanded = ref.watch(filtersExpandedProvider);
    if (isLandscape && filtersExpanded) {
      safePostFrame(() {
        ref.read(filtersExpandedProvider.notifier).collapse();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: Text(l10n?.appTitle ?? 'Fuel Prices'),
        ),
        toolbarHeight: isLandscape ? 40 : null,
      ),
      body: isWide
          ? Row(
              children: [
                Expanded(child: _buildSearchContent(context, isLandscape)),
                const VerticalDivider(width: 1),
                const Expanded(child: InlineMap()),
              ],
            )
          : _buildSearchContent(context, isLandscape),
    );
  }

  Widget _buildSearchContent(BuildContext context, bool isLandscape) {
    final searchState = ref.watch(searchStateProvider);
    final country = ref.watch(activeCountryProvider);
    final l10n = AppLocalizations.of(context);
    final searchMode = ref.watch(activeSearchModeProvider);

    return Column(
      children: [
        // --- Sticky header: search controls stay visible ---
        DemoModeBanner(country: country),
        Padding(
          padding: EdgeInsets.fromLTRB(16, isLandscape ? 4 : 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search mode toggle
              Semantics(
                label: 'Search mode',
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: ModeChip(
                          label: l10n?.searchNearby ?? 'Nearby',
                          icon: Icons.near_me,
                          selected: searchMode == SearchMode.nearby,
                          onTap: () => ref.read(activeSearchModeProvider.notifier).set(SearchMode.nearby),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ModeChip(
                          label: l10n?.searchAlongRouteLabel ?? 'Along route',
                          icon: Icons.route,
                          selected: searchMode == SearchMode.route,
                          onTap: () => ref.read(activeSearchModeProvider.notifier).set(SearchMode.route),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (searchMode == SearchMode.nearby)
                NearbySearchControls(
                  onGpsSearch: _performGpsSearch,
                  onZipSearch: _performZipSearch,
                  onCitySearch: _performCitySearch,
                  isLandscape: isLandscape,
                )
              else
                RouteSearchControls(
                  onSearch: _performRouteSearch,
                ),
            ],
          ),
        ),
        UserPositionBar(
          onUpdatePosition: () async {
            final settings = ref.read(settingsStorageProvider);
            if (!LocationConsentDialog.hasConsent(settings)) {
              if (!mounted) return;
              final consented = await LocationConsentDialog.show(context);
              if (!consented) return;
              await LocationConsentDialog.recordConsent(settings);
            }
            try {
              await ref.read(userPositionProvider.notifier).updateFromGps();
              final state = ref.read(searchStateProvider);
              if (state.hasValue && state.value!.data.isNotEmpty) {
                _performGpsSearch();
              }
            } catch (e) {
              if (mounted) {
                SnackBarHelper.showError(context, e.toString());
              }
            }
          },
        ),

        // --- Scrollable results ---
        Expanded(
          child: Semantics(
            label: 'Search results',
            child: _buildResults(context, l10n, searchState),
          ),
        ),
      ],
    );
  }

  Widget _buildResults(
    BuildContext context,
    AppLocalizations? l10n,
    AsyncValue<ServiceResult<List<Station>>> searchState,
  ) {
    final searchMode = ref.watch(activeSearchModeProvider);
    final fuelType = ref.watch(selectedFuelTypeProvider);

    // Route mode — RouteResultsView returns slivers, wrap in CustomScrollView
    if (searchMode == SearchMode.route) {
      return const CustomScrollView(
        slivers: [RouteResultsView()],
      );
    }

    // EV mode
    if (fuelType == FuelType.electric) {
      final evState = ref.watch(eVSearchStateProvider);
      return evState.when(
        data: (result) {
          if (result.data.isEmpty) {
            return EmptyState(
              icon: Icons.ev_station,
              title: l10n?.searchEvStations ?? 'Search to find EV charging stations',
              actionLabel: l10n?.searchNearby ?? 'Search nearby',
              onAction: _performGpsSearch,
            );
          }
          return ListView.builder(
            itemCount: result.data.length,
            itemBuilder: (context, index) {
              final station = result.data[index];
              return EVStationCard(
                key: ValueKey('ev-${station.id}'),
                result: EVStationResult(station),
                onTap: () => context.push('/ev-station', extra: station),
              );
            },
          );
        },
        loading: () => const ShimmerStationList(),
        error: (error, _) => ServiceChainErrorWidget(error: error, onRetry: _performGpsSearch),
      );
    }

    // Default: fuel station results
    return searchState.when(
      data: (result) {
        if (result.data.isEmpty) {
          return Center(
            child: Text(
              l10n?.startSearch ?? 'Search to find fuel stations.',
              style: const TextStyle(fontSize: 16),
            ),
          );
        }
        return SearchResultsList(result: result, onRefresh: _performGpsSearch);
      },
      loading: () => const ShimmerStationList(),
      error: (error, _) => ServiceChainErrorWidget(error: error, onRetry: _performGpsSearch),
    );
  }
}
