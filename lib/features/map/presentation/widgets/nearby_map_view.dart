// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

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
import '../../../search/providers/search_screen_ui_provider.dart';
import 'station_map_layers.dart';

/// Displays a map of nearby stations from the current search results.
///
/// Layout: station markers fill the body, the bottom info bar pins to
/// the bottom, and any [ServiceStatusBanner] (cache / fallback /
/// offline) floats as a Positioned overlay at the top so it never
/// pushes the map down. Pre-#1428 the banner was the first child of a
/// Column and produced a visible grey strip between the AppBar and
/// the map whenever a fallback fired — a permanent ~32 dp tax on
/// every "stations were fetched via the secondary API" session.
class NearbyMapView extends ConsumerStatefulWidget {
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
  ConsumerState<NearbyMapView> createState() => _NearbyMapViewState();

  /// Decides whether a post-frame `fitCamera` should be scheduled for a
  /// freshly-computed [next] fit target, given the [last] target we
  /// already fitted to (null on first build). Extracted as a pure
  /// predicate so the guard can be unit-tested without driving a real
  /// [MapController] (#2177).
  ///
  /// The first fit (`last == null`) and any genuine change to the search
  /// bounds return `true`; an identical re-fit returns `false`. flutter_map's
  /// [LatLngBounds] implements value-based `==`/`hashCode`, so the
  /// comparison is a cheap structural check on south/north/east/west.
  @visibleForTesting
  static bool shouldFit(LatLngBounds? last, LatLngBounds next) => last != next;
}

class _NearbyMapViewState extends ConsumerState<NearbyMapView> {
  @override
  Widget build(BuildContext context) {
    final searchState = widget.searchState;
    final selectedFuel = widget.selectedFuel;
    final searchRadiusKm = widget.searchRadiusKm;
    final mapController = widget.mapController;
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
        // #2510 — the active list sort drives which stations the map
        // emphasizes (full price bubble) vs renders as compact dots.
        final sortMode = ref.watch(selectedSortModeProvider);
        final userPos = ref.read(userPositionProvider);
        // Center the viewport on the SEARCHED area, not the user's GPS.
        // Otherwise a ZIP/city search from a distant location (e.g. user
        // in Castelnau-de-Guers searching "Paris") pans the map to the
        // user's position while the stations sit 700 km away, leaving
        // the screen empty (#692). Fall back to userPos only when the
        // result set is empty (no station centroid to compute).
        final center = stations.isNotEmpty
            ? StationMapLayers.centerOf(stations)
            : (userPos != null
                ? LatLng(userPos.lat, userPos.lng)
                : const LatLng(0, 0));
        final zoom = StationMapLayers.zoomForRadius(searchRadiusKm);

        final evLat = center.latitude;
        final evLng = center.longitude;
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

        // #2399 — the viewport is framed by `StationMapLayers` itself:
        // `MapOptions.initialCameraFit` positions the first paint during
        // layout, and a single guarded `didUpdateWidget` re-fit handles a
        // changed search centre. The old per-build post-frame `fitCamera`
        // here raced the (now-deleted) cold-start reset window and is
        // gone. `bounds` is still computed for the recenter button.
        final bounds =
            StationMapLayers.boundsForRadius(center, searchRadiusKm);

        return Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: StationMapLayers(
                    mapController: mapController,
                    stations: stations,
                    center: center,
                    zoom: zoom,
                    searchRadiusKm: searchRadiusKm,
                    selectedFuel: selectedFuel,
                    sortMode: sortMode,
                    // #2998 — adopt the maintainer-loved radar grammar
                    // (#2939): proximity-cluster EVERY result set with the
                    // cheapest-price badge, identical to the landscape
                    // split-screen radar map (InlineMap), instead of the
                    // legacy emphasis(top-4 pills)+compact-dots scheme. No
                    // `onStationTap` is passed, so a marker tap keeps its
                    // default GoRouter push to /station/{id} (the full-screen
                    // map has no co-visible list to select into); the radius
                    // circle (`showSearchRadius`, default true) stays drawn.
                    clusterAlways: true,
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
            ),
            // Stale / fallback banner as a floating overlay so it
            // never steals vertical space from the map. Self-hides
            // (returns SizedBox.shrink) when the result has neither
            // staleness nor fallbacks, so the overlay is invisible
            // on the happy path.
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: _OverlayBanner(result: result),
            ),
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
            '${widget.searchRadiusKm.round()} km ${l10n?.searchRadius ?? "radius"}',
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

/// Floating wrapper for [ServiceStatusBanner] used by the map view.
///
/// [ServiceStatusBanner] returns [SizedBox.shrink] when the result is
/// neither stale nor used a fallback, so this widget is invisible on
/// the happy path. When a banner IS rendered, the [Material] envelope
/// gives it elevation + rounded corners so it reads as a floating
/// chip overlaying the map rather than a full-bleed strip cutting the
/// screen in half. [SafeArea] keeps the chip clear of the AppBar's
/// shadow without inflating its size when the AppBar already provides
/// its own SafeArea padding (the bottom side is disabled — the bottom
/// info bar already pins to the safe area).
class _OverlayBanner extends StatelessWidget {
  final dynamic result;

  const _OverlayBanner({required this.result});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: ServiceStatusBanner(result: result),
      ),
    );
  }
}
