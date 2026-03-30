import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/responsive_search_layout.dart';
import '../../../../core/country/country_provider.dart';
import '../../../../core/location/location_consent.dart';
import '../../../../core/location/user_position_provider.dart';
import '../../../../core/services/location_search_service.dart';
import '../../../../core/services/widgets/service_status_banner.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/shimmer_placeholder.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../map/presentation/widgets/inline_map.dart';
import '../../providers/search_provider.dart';
import '../widgets/demo_mode_banner.dart';
import '../widgets/fuel_type_selector.dart';
import '../widgets/location_input.dart';
import '../widgets/search_results_list.dart';
import '../widgets/user_position_bar.dart';
import '../../../route_search/presentation/widgets/route_input.dart';
import '../../../route_search/providers/route_search_provider.dart';
import '../../../route_search/domain/entities/route_info.dart';
import '../../../route_search/domain/route_search_strategy.dart';
import '../../providers/search_mode_provider.dart';
import '../../providers/ev_search_provider.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/services/service_result.dart';
import '../../../favorites/providers/favorites_provider.dart';
import '../../data/models/search_params.dart';
import '../../domain/entities/fuel_type.dart';
import '../../domain/entities/search_result_item.dart';
import '../../domain/entities/station.dart';
import '../widgets/ev_station_card.dart';
import '../widgets/station_card.dart';
import '../../../profile/data/models/user_profile.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../providers/ignored_stations_provider.dart';
import '../../../../core/utils/navigation_utils.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

/// Route result view mode for search screen.
enum _RouteResultMode { allStations, bestStops }

class _SearchScreenState extends ConsumerState<SearchScreen> {
  bool _filtersExpanded = true;
  bool _searchBarExpanded = true;
  _RouteResultMode _routeResultMode = _RouteResultMode.allStations;
  bool _autoSearchTriggered = false;
  RouteSearchStrategyType _selectedStrategy = RouteSearchStrategyType.uniform;

  void _performRouteSearch(List<RouteWaypoint> waypoints) {
    final fuelType = ref.read(selectedFuelTypeProvider);
    final radius = ref.read(searchRadiusProvider);
    setState(() {
      _filtersExpanded = false;
      _searchBarExpanded = false;
    });
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
    final storage = ref.read(hiveStorageProvider);
    if (!LocationConsentDialog.hasConsent(storage)) {
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
      await LocationConsentDialog.recordConsent(storage);
    }
    setState(() {
      _filtersExpanded = false;
      _searchBarExpanded = false;
    });

    if (fuelType == FuelType.electric) {
      // EV charging search — get GPS, then query OpenChargeMap
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
    setState(() {
      _filtersExpanded = false;
      _searchBarExpanded = false;
    });
    ref.read(searchStateProvider.notifier).searchByZipCode(
          zipCode: zip,
          fuelType: fuelType,
          radiusKm: radius,
        );
  }

  void _performCitySearch(ResolvedLocation city) {
    final fuelType = ref.read(selectedFuelTypeProvider);
    final radius = ref.read(searchRadiusProvider);
    setState(() {
      _filtersExpanded = false;
      _searchBarExpanded = false;
    });
    ref.read(searchStateProvider.notifier).searchByCoordinates(
          lat: city.lat,
          lng: city.lng,
          postalCode: city.postcode,
          locationName: city.name,
          fuelType: fuelType,
          radiusKm: radius,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isWide = isWideScreen(context);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    // Auto-search for "cheapest nearby" landing screen
    if (!_autoSearchTriggered) {
      _autoSearchTriggered = true;
      final profile = ref.read(activeProfileProvider);
      if (profile?.landingScreen == LandingScreen.cheapest) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          // Use zip code from profile if available, otherwise GPS
          final zip = profile?.homeZipCode;
          if (zip != null && zip.isNotEmpty) {
            _performZipSearch(zip);
          } else {
            _performGpsSearch();
          }
        });
      }
    }

    // Auto-collapse search controls in landscape after first search
    if (isLandscape && !_searchBarExpanded && _filtersExpanded) {
      _filtersExpanded = false;
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
    final radius = ref.watch(searchRadiusProvider);
    final country = ref.watch(activeCountryProvider);
    final l10n = AppLocalizations.of(context);

    return CustomScrollView(
      slivers: [
        // Demo banner
        SliverToBoxAdapter(child: DemoModeBanner(country: country)),

        // Search controls — collapsible in landscape
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                16, isLandscape ? 4 : 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Search mode toggle — compact chips
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ModeChip(
                          label: l10n?.searchNearby ?? 'Nearby',
                          icon: Icons.near_me,
                          selected: ref.watch(activeSearchModeProvider) == SearchMode.nearby,
                          onTap: () => ref.read(activeSearchModeProvider.notifier).set(SearchMode.nearby),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ModeChip(
                          label: l10n?.searchAlongRouteLabel ?? 'Along route',
                          icon: Icons.route,
                          selected: ref.watch(activeSearchModeProvider) == SearchMode.route,
                          onTap: () => ref.read(activeSearchModeProvider.notifier).set(SearchMode.route),
                        ),
                      ),
                    ],
                  ),
                ),
                if (ref.watch(activeSearchModeProvider) == SearchMode.nearby) ...[
                  // Search bar — foldable after search
                  AnimatedCrossFade(
                    firstChild: LocationInput(
                      onGpsSearch: () => _performGpsSearch(),
                      onZipSearch: (zip) => _performZipSearch(zip),
                      onCitySearch: (city) => _performCitySearch(city),
                    ),
                    secondChild: GestureDetector(
                      onTap: () => setState(() => _searchBarExpanded = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Theme.of(context).colorScheme.outline),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, size: 18,
                                color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                ref.watch(searchLocationProvider).isNotEmpty
                                    ? ref.watch(searchLocationProvider)
                                    : l10n?.search ?? 'Search...',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(Icons.expand_more, size: 18,
                                color: Theme.of(context).colorScheme.primary),
                          ],
                        ),
                      ),
                    ),
                    crossFadeState: _searchBarExpanded
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    duration: const Duration(milliseconds: 200),
                  ),
                  // Collapsible filters: fuel type + radius
                  AnimatedCrossFade(
                    firstChild: Padding(
                      padding: EdgeInsets.only(top: isLandscape ? 4 : 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const FuelTypeSelector(),
                          SizedBox(height: isLandscape ? 0 : 4),
                          Row(
                            children: [
                              Text('${l10n?.searchRadius ?? "Radius"}:',
                                  style:
                                      Theme.of(context).textTheme.bodySmall),
                              Expanded(
                                child: Slider(
                                  value: radius,
                                  min: 1,
                                  max: 25,
                                  divisions: 24,
                                  label: '${radius.round()} km',
                                  onChanged: (value) {
                                    ref
                                        .read(searchRadiusProvider.notifier)
                                        .set(value);
                                  },
                                ),
                              ),
                              Text('${radius.round()} km',
                                  style:
                                      Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                          if (!isLandscape)
                            FilledButton.icon(
                              onPressed: () {
                                setState(() => _filtersExpanded = false);
                                _performGpsSearch();
                              },
                              icon: const Icon(Icons.search),
                              label: Text(
                                  l10n?.searchNearby ?? 'Nearby stations'),
                            ),
                        ],
                      ),
                    ),
                    secondChild: GestureDetector(
                      onTap: () => setState(() => _filtersExpanded = true),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(Icons.tune, size: 16,
                                color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              '${ref.watch(selectedFuelTypeProvider).displayName}'
                              ' · ${radius.round()} km',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                            const Spacer(),
                            Icon(Icons.expand_more, size: 18,
                                color: Theme.of(context).colorScheme.primary),
                          ],
                        ),
                      ),
                    ),
                    crossFadeState: _filtersExpanded
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    duration: const Duration(milliseconds: 200),
                  ),
                ] else ...[
                  // Route input
                  RouteInput(
                    onSearch: (waypoints) => _performRouteSearch(waypoints),
                  ),
                  const SizedBox(height: 4),
                  // Still show fuel type selector in route mode
                  const FuelTypeSelector(),
                  const SizedBox(height: 4),
                  // Strategy selector
                  Row(
                    children: [
                      Text('Strategy:',
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(width: 8),
                      for (final strategy in RouteSearchStrategyType.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: ChoiceChip(
                            label: Text(_strategyLabel(strategy, l10n),
                                style: const TextStyle(fontSize: 11)),
                            selected: _selectedStrategy == strategy,
                            onSelected: (_) => setState(() => _selectedStrategy = strategy),
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => context.push('/itineraries'),
                      icon: const Icon(Icons.bookmark, size: 16),
                      label: Text(l10n?.savedRoutes ?? 'Saved routes',
                          style: Theme.of(context).textTheme.bodySmall),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // User position bar
        SliverToBoxAdapter(
          child: UserPositionBar(
            onUpdatePosition: () async {
              final storage = ref.read(hiveStorageProvider);
              final messenger = ScaffoldMessenger.of(context);
              if (!LocationConsentDialog.hasConsent(storage)) {
                if (!mounted) return;
                final consented =
                    await LocationConsentDialog.show(context);
                if (!consented) return;
                await LocationConsentDialog.recordConsent(storage);
              }
              try {
                await ref
                    .read(userPositionProvider.notifier)
                    .updateFromGps();
                final searchState = ref.read(searchStateProvider);
                if (searchState.hasValue &&
                    searchState.value!.data.isNotEmpty) {
                  _performGpsSearch();
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
          ),
        ),

        // Results — show fuel, EV, or route results based on active mode
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

    // Route mode — show route search results
    if (searchMode == SearchMode.route) {
      final routeState = ref.watch(routeSearchStateProvider);
      return routeState.when(
        data: (result) {
          if (result == null) {
            return SliverFillRemaining(
              child: Center(
                child: Text(
                  l10n?.startSearch ?? 'Enter start and destination to search along route.',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (result.stations.isEmpty) {
            return SliverFillRemaining(
              child: Center(
                child: Text(
                  'No stations found along this route.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // Filter ignored stations, then apply view mode
          final ignoredIds = ref.watch(ignoredStationsProvider);
          final visibleStations = result.stations
              .where((s) => !ignoredIds.contains(s.id))
              .toList();
          final allFuelStations = visibleStations.whereType<FuelStationResult>().toList();
          final displayItems = _routeResultMode == _RouteResultMode.bestStops
              ? _filterBestStops(allFuelStations, result)
              : visibleStations;

          // Show route results with view mode toggle
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index == 0) {
                  // Route info header + view mode toggle
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.route, size: 16, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${result.route.distanceKm.round()} km · ${result.route.durationMinutes.round()} min · ${result.stations.length} stations',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // All / Best stops toggle
                        Row(
                          children: [
                            _ModeChip(
                              label: l10n?.allStations ?? 'All stations',
                              icon: Icons.local_gas_station,
                              selected: _routeResultMode == _RouteResultMode.allStations,
                              onTap: () => setState(() => _routeResultMode = _RouteResultMode.allStations),
                            ),
                            const SizedBox(width: 8),
                            _ModeChip(
                              label: l10n?.bestStops ?? 'Best stops',
                              icon: Icons.star,
                              selected: _routeResultMode == _RouteResultMode.bestStops,
                              onTap: () => setState(() => _routeResultMode = _RouteResultMode.bestStops),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }
                final item = displayItems[index - 1];
                if (item is FuelStationResult) {
                  // Bidirectional swipe: right=navigate, left=ignore
                  return Dismissible(
                    key: ValueKey('swipe-${item.id}'),
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.startToEnd) {
                        _openStationInMaps(item.station);
                        return false;
                      } else {
                        ref.read(ignoredStationsProvider.notifier).add(item.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${item.station.brand.isNotEmpty ? item.station.brand : item.station.name} hidden'),
                            action: SnackBarAction(
                              label: 'Undo',
                              onPressed: () => ref.read(ignoredStationsProvider.notifier).remove(item.id),
                            ),
                            duration: const Duration(seconds: 4),
                          ),
                        );
                        return true;
                      }
                    },
                    background: Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 24),
                      color: Theme.of(context).colorScheme.primary,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.navigation, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(l10n?.navigate ?? 'Navigate',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    secondaryBackground: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      color: Colors.orange.shade700,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Hide',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          const Icon(Icons.visibility_off, color: Colors.white, size: 20),
                        ],
                      ),
                    ),
                    child: StationCard(
                      station: item.station,
                      selectedFuelType: fuelType,
                      isFavorite: ref.watch(isFavoriteProvider(item.id)),
                      onTap: () => context.push('/station/${item.id}'),
                      onFavoriteTap: () => ref.read(favoritesProvider.notifier)
                          .toggle(item.id, stationData: item.station),
                      isCheapest: item.id == result.cheapestId,
                    ),
                  );
                } else if (item is EVStationResult) {
                  return EVStationCard(
                    result: item,
                    onTap: () => context.push('/ev-station', extra: item.station),
                  );
                }
                return const SizedBox.shrink();
              },
              childCount: displayItems.length + 1,
            ),
          );
        },
        loading: () => const SliverFillRemaining(child: ShimmerStationList()),
        error: (error, _) => SliverFillRemaining(
          child: ServiceChainErrorWidget(
            error: error,
            onRetry: () => ref.read(routeSearchStateProvider.notifier).clear(),
          ),
        ),
      );
    }

    // EV mode — show EV charging results
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
          child: ServiceChainErrorWidget(
            error: error,
            onRetry: _performGpsSearch,
          ),
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
          child: SearchResultsList(
            result: result,
            onRefresh: _performGpsSearch,
          ),
        );
      },
      loading: () => const SliverFillRemaining(child: ShimmerStationList()),
      error: (error, _) => SliverFillRemaining(
        child: ServiceChainErrorWidget(
          error: error,
          onRetry: _performGpsSearch,
        ),
      ),
    );
  }

  /// Filter to only the cheapest station per route segment.
  List<SearchResultItem> _filterBestStops(
    List<FuelStationResult> allStations,
    RouteSearchResult result,
  ) {
    final segmentMap = result.cheapestPerSegment;
    if (segmentMap == null || segmentMap.isEmpty) {
      if (result.cheapestId != null) {
        return allStations.where((s) => s.id == result.cheapestId).cast<SearchResultItem>().toList();
      }
      return allStations.take(5).cast<SearchResultItem>().toList();
    }
    final bestIds = segmentMap.values.toSet();
    return allStations.where((s) => bestIds.contains(s.id)).cast<SearchResultItem>().toList();
  }

  /// Open a station in the default maps app via geo: URI.
  void _openStationInMaps(Station station) {
    NavigationUtils.openInMaps(
      station.lat, station.lng,
      label: station.brand.isNotEmpty ? station.brand : station.street,
    );
  }

  String _strategyLabel(RouteSearchStrategyType type, AppLocalizations? l10n) {
    switch (type) {
      case RouteSearchStrategyType.uniform:
        return 'Uniform';
      case RouteSearchStrategyType.cheapest:
        return l10n?.cheapest ?? 'Cheapest';
      case RouteSearchStrategyType.balanced:
        return 'Balanced';
    }
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
