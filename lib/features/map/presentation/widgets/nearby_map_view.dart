import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/location/user_position_provider.dart';
import '../../../../core/services/widgets/service_status_banner.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../ev/presentation/widgets/ev_map_overlay.dart';
import '../../../ev/providers/ev_providers.dart';
import '../../../search/domain/entities/search_result_item.dart';
import 'station_map_layers.dart';

/// Displays a map of nearby stations from the current search results.
///
/// Shows the service status banner, station markers on the map,
/// and a bottom info bar with station count and search radius.
class NearbyMapView extends ConsumerWidget {
  final AsyncValue searchState;
  final dynamic selectedFuel;
  final double searchRadiusKm;
  final MapController mapController;

  const NearbyMapView({
    super.key,
    required this.searchState,
    required this.selectedFuel,
    required this.searchRadiusKm,
    required this.mapController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return searchState.when(
      data: (result) {
        // Extract fuel stations for map markers; EV stations are
        // handled by the separate EvMapLayer overlay.
        final allItems = result.data as List<SearchResultItem>;
        final stations = allItems
            .whereType<FuelStationResult>()
            .map((r) => r.station)
            .toList();

        if (allItems.isEmpty) {
          return EmptyState(
            icon: Icons.map_outlined,
            title: l10n?.startSearch ??
                'Search for stations to see them on the map',
            actionLabel: l10n?.search ?? 'Search now',
            onAction: () => context.go('/'),
            iconSize: 80,
          );
        }

        final showEv = ref.watch(evShowOnMapProvider);
        final userPos = ref.read(userPositionProvider);
        // Prefer the user's actual position as the radius origin so the
        // viewport-fit matches the search circle drawn on the map.
        final center = userPos != null
            ? LatLng(userPos.lat, userPos.lng)
            : StationMapLayers.centerOf(stations);
        final zoom = StationMapLayers.zoomForRadius(searchRadiusKm);

        final evLat = userPos?.lat ?? center.latitude;
        final evLng = userPos?.lng ?? center.longitude;
        final extraLayers = <Widget>[];
        if (showEv) {
          extraLayers.add(
            EvMapLayer(
              viewport: EvViewport(
                latitude: evLat,
                longitude: evLng,
                radiusKm: searchRadiusKm,
              ),
            ),
          );
        }

        // Fit map viewport to the search radius when results change so the
        // user immediately sees the entire searched area instead of having
        // to zoom out manually.
        final bounds =
            StationMapLayers.boundsForRadius(center, searchRadiusKm);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            mapController.fitCamera(
              CameraFit.bounds(
                bounds: bounds,
                padding: const EdgeInsets.all(32),
              ),
            );
          } catch (e) {
            debugPrint('Map fitCamera failed: $e');
          }
        });

        return Column(
          children: [
            ServiceStatusBanner(result: result),
            Expanded(
              child: StationMapLayers(
                mapController: mapController,
                stations: stations,
                center: center,
                zoom: zoom,
                searchRadiusKm: searchRadiusKm,
                selectedFuel: selectedFuel,
                showRecenterButton: true,
                onRecenter: () => mapController.fitCamera(
                  CameraFit.bounds(
                    bounds: bounds,
                    padding: const EdgeInsets.all(32),
                  ),
                ),
                extraLayers: extraLayers,
              ),
            ),
            _buildInfoBar(context, l10n, stations, result),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ServiceChainErrorWidget(
        error: error,
        onRetry: () => context.go('/'),
      ),
    );
  }

  Widget _buildInfoBar(
    BuildContext context,
    AppLocalizations? l10n,
    List stations,
    dynamic result,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Icon(Icons.local_gas_station,
              size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            l10n?.nStations(stations.length) ?? '${stations.length} stations',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 16),
          Icon(Icons.circle,
              size: 8,
              color: theme.colorScheme.primary.withValues(alpha: 0.3)),
          const SizedBox(width: 4),
          Text(
            '${searchRadiusKm.round()} km ${l10n?.searchRadius ?? "radius"}',
            style: theme.textTheme.bodySmall,
          ),
          const Spacer(),
          Text(
            result.freshnessLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
