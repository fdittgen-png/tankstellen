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
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/shimmer_placeholder.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../map/presentation/widgets/inline_map.dart';
import '../../providers/search_provider.dart';
import '../widgets/demo_mode_banner.dart';
import '../widgets/search_results_list.dart';
import '../widgets/user_position_bar.dart';
import '../../../route_search/domain/entities/route_info.dart';
import '../../../route_search/domain/route_search_strategy.dart';
import '../../../route_search/providers/route_search_provider.dart';
import '../../providers/search_mode_provider.dart';
import '../../providers/ev_search_provider.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/services/service_result.dart';
import '../../data/models/search_params.dart';
import '../../domain/entities/fuel_type.dart';
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
  bool _filtersExpanded = true;
  bool _searchBarExpanded = true;
  RouteSearchStrategyType _selectedStrategy = RouteSearchStrategyType.uniform;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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
    setState(() { _filtersExpanded = false; _searchBarExpanded = false; });
    ref.read(routeSearchStateProvider.notifier).searchAlongRoute(
      waypoints: waypoints,
      fuelType: fuelType,
      searchRadiusKm: radius.clamp(1, 10),
      strategyType: _selectedStrategy,
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)?.locationDenied ??
                  'Location permission denied. You can search by postal code.'),
            ),
          );
        }
        return;
      }
      await LocationConsentDialog.recordConsent(settings);
    }
    setState(() { _filtersExpanded = false; _searchBarExpanded = false; });

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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('GPS error: $e')),
          );
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
    setState(() { _filtersExpanded = false; _searchBarExpanded = false; });
    ref.read(searchStateProvider.notifier).searchByZipCode(
      zipCode: zip,
      fuelType: fuelType,
      radiusKm: radius,
    );
  }

  void _performCitySearch(ResolvedLocation city) {
    final fuelType = ref.read(selectedFuelTypeProvider);
    final radius = ref.read(searchRadiusProvider);
    setState(() { _filtersExpanded = false; _searchBarExpanded = false; });
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

    if (isLandscape && !_searchBarExpanded && _filtersExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _filtersExpanded = false);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.appTitle ?? 'Fuel Prices'),
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

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: DemoModeBanner(country: country)),

        // Search controls
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, isLandscape ? 4 : 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Search mode toggle
                Padding(
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
                if (searchMode == SearchMode.nearby)
                  NearbySearchControls(
                    onGpsSearch: _performGpsSearch,
                    onZipSearch: _performZipSearch,
                    onCitySearch: _performCitySearch,
                    filtersExpanded: _filtersExpanded,
                    searchBarExpanded: _searchBarExpanded,
                    onToggleFilters: (v) => setState(() => _filtersExpanded = v),
                    onToggleSearchBar: (v) => setState(() => _searchBarExpanded = v),
                    isLandscape: isLandscape,
                  )
                else
                  RouteSearchControls(
                    onSearch: _performRouteSearch,
                    selectedStrategy: _selectedStrategy,
                    onStrategyChanged: (s) => setState(() => _selectedStrategy = s),
                  ),
              ],
            ),
          ),
        ),

        // User position bar
        SliverToBoxAdapter(
          child: UserPositionBar(
            onUpdatePosition: () async {
              final settings = ref.read(settingsStorageProvider);
              final messenger = ScaffoldMessenger.of(context);
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
                  messenger.showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
          ),
        ),

        // Results
        _buildResultsSliver(context, l10n, searchState),
      ],
    );
  }

  Widget _buildResultsSliver(
    BuildContext context,
    AppLocalizations? l10n,
    AsyncValue<ServiceResult<List<Station>>> searchState,
  ) {
    final searchMode = ref.watch(activeSearchModeProvider);
    final fuelType = ref.watch(selectedFuelTypeProvider);

    // Route mode
    if (searchMode == SearchMode.route) {
      return const RouteResultsView();
    }

    // EV mode
    if (fuelType == FuelType.electric) {
      final evState = ref.watch(eVSearchStateProvider);
      return evState.when(
        data: (result) {
          if (result.data.isEmpty) {
            return SliverFillRemaining(
              child: EmptyState(
                icon: Icons.ev_station,
                title: l10n?.searchEvStations ?? 'Search to find EV charging stations',
                actionLabel: l10n?.searchNearby ?? 'Search nearby',
                onAction: _performGpsSearch,
              ),
            );
          }
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final station = result.data[index];
                return EVStationCard(
                  result: EVStationResult(station),
                  onTap: () => context.push('/ev-station', extra: station),
                );
              },
              childCount: result.data.length,
            ),
          );
        },
        loading: () => const SliverFillRemaining(child: ShimmerStationList()),
        error: (error, _) => SliverFillRemaining(
          child: ServiceChainErrorWidget(error: error, onRetry: _performGpsSearch),
        ),
      );
    }

    // Default: fuel station results
    return searchState.when(
      data: (result) {
        if (result.data.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Text(
                l10n?.startSearch ?? 'Search to find fuel stations.',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          );
        }
        return SliverFillRemaining(
          child: SearchResultsList(result: result, onRefresh: _performGpsSearch),
        );
      },
      loading: () => const SliverFillRemaining(child: ShimmerStationList()),
      error: (error, _) => SliverFillRemaining(
        child: ServiceChainErrorWidget(error: error, onRetry: _performGpsSearch),
      ),
    );
  }
}
