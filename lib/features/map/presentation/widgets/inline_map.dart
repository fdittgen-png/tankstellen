import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../search/providers/search_provider.dart';
import 'station_map_layers.dart';

/// A reusable map widget that displays station markers from current search results.
/// Designed to be embedded inline (e.g. in a split-screen layout).
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
    final searchState = ref.watch(searchStateProvider);
    final selectedFuel = ref.watch(selectedFuelTypeProvider);
    final searchRadius = ref.watch(searchRadiusProvider);

    return searchState.when(
      data: (result) {
        final stations = result.data;

        if (stations.isEmpty) {
          return const EmptyState(
            icon: Icons.map_outlined,
            title: 'Search to see stations on the map',
          );
        }

        final center = StationMapLayers.centerOf(stations);
        final zoom = StationMapLayers.zoomForRadius(searchRadius);

        return StationMapLayers(
          mapController: _mapController,
          stations: stations,
          center: center,
          zoom: zoom,
          searchRadiusKm: searchRadius,
          selectedFuel: selectedFuel,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text(
          'Map unavailable',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }
}
