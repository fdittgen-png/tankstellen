// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../../search/domain/entities/search_result_item.dart';
import '../../../search/domain/entities/station.dart';
import '../../../search/presentation/widgets/sort_selector.dart';
import '../../../search/providers/radar_search_provider.dart';
import '../../../search/providers/search_provider.dart';
import '../../../search/providers/search_screen_ui_provider.dart';
import '../../../search/providers/selected_station_provider.dart';
import 'station_map_layers.dart';

/// A reusable map widget that displays station markers in the split-screen
/// landscape pane.
///
/// #2939 — "Clustered + cheapest-labelled". When the on-search Fuel Station
/// Radar owns the results (`radarSearchProvider.active`), the map renders the
/// RADAR stations — proximity-clustered with cheapest-price badges so the
/// narrow pane never overlaps — fits the camera to the actual result bounds,
/// and two-way-syncs selection with the list via `selectedStationProvider`
/// (tap a marker -> select the row; the selected row's marker is emphasised).
/// When the radar is idle it falls back to the regular `searchStateProvider`
/// results — also clustered now, so the split pane never overlaps either.
class InlineMap extends ConsumerStatefulWidget {
  const InlineMap({super.key});

  @override
  ConsumerState<InlineMap> createState() => _InlineMapState();
}

class _InlineMapState extends ConsumerState<InlineMap> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedFuel = ref.watch(selectedFuelTypeProvider);
    final searchRadius = ref.watch(searchRadiusProvider);
    final sortMode = ref.watch(selectedSortModeProvider);

    // #2939 — the on-search radar OWNS the split map when active (mirrors the
    // results-list early-return in SearchResultsContent). Its stations are
    // clustered + fit-to-bounds and list<->map selection is two-way synced.
    // Idle -> regular search results.
    final radar = ref.watch(radarSearchProvider);
    if (radar.active) {
      return radar.stations.when(
        data: (stations) =>
            _buildMap(context, stations, selectedFuel, searchRadius, sortMode),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _mapUnavailable(context),
      );
    }

    final searchState = ref.watch(searchStateProvider);
    return searchState.when(
      data: (result) {
        final stations = result.data
            .whereType<FuelStationResult>()
            .map((r) => r.station)
            .toList();
        return _buildMap(
            context, stations, selectedFuel, searchRadius, sortMode);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => _mapUnavailable(context),
    );
  }

  /// Render [stations] on the clustered split map, fitting the camera to the
  /// actual result bounds and wiring two-way list<->map selection.
  Widget _buildMap(
    BuildContext context,
    List<Station> stations,
    FuelType selectedFuel,
    double searchRadius,
    SortMode sortMode,
  ) {
    if (stations.isEmpty) {
      return EmptyState(
        icon: Icons.map_outlined,
        title: AppLocalizations.of(context)?.searchToSeeMap ??
            'Search to see stations on the map',
      );
    }

    // #2939 — fit the camera to the ACTUAL result bounds within the pane, not
    // the search-radius circle: a dense radar set is far smaller than the
    // radius (and a sparse one larger), so the radius zoom framed the wrong
    // viewport in the narrow split pane.
    final bounds = _boundsOf(stations);
    final center = StationMapLayers.centerOf(stations);

    // #2939 — two-way sync: emphasise the selected row's marker, and a marker
    // tap selects its row (keeping the map visible) instead of navigating.
    final selectedId = ref.watch(selectedStationProvider);

    return StationMapLayers(
      mapController: _mapController,
      stations: stations,
      center: center,
      zoom: StationMapLayers.zoomForRadius(searchRadius),
      searchRadiusKm: searchRadius,
      selectedFuel: selectedFuel,
      sortMode: sortMode,
      clusterAlways: true,
      cameraFitBounds: bounds,
      showSearchRadius: false,
      selectedStationIds: selectedId != null ? {selectedId} : null,
      onStationTap: (id) =>
          ref.read(selectedStationProvider.notifier).select(id),
    );
  }

  Widget _mapUnavailable(BuildContext context) => Center(
        child: Text(
          AppLocalizations.of(context)?.mapUnavailable ?? 'Map unavailable',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );

  /// The [LatLngBounds] of the result [stations], with a tiny epsilon box for
  /// a single result so `CameraFit.bounds` cannot divide-by-zero (mirrors
  /// `RouteMapView._computeRouteBounds`).
  static LatLngBounds _boundsOf(List<Station> stations) {
    final points = [for (final s in stations) LatLng(s.lat, s.lng)];
    if (points.length == 1) {
      final p = points.first;
      const eps = 0.0005; // ~50 m; fine for any latitude.
      return LatLngBounds(
        LatLng(p.latitude - eps, p.longitude - eps),
        LatLng(p.latitude + eps, p.longitude + eps),
      );
    }
    return LatLngBounds.fromPoints(points);
  }
}
