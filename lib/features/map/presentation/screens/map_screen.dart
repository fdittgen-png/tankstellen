import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../driving/presentation/widgets/driving_mode_fab.dart';
import '../../../route_search/providers/route_search_provider.dart';
import '../../../search/providers/search_provider.dart';
import '../widgets/nearby_map_view.dart';
import '../widgets/route_map_view.dart';

/// Top-level map screen that delegates to [RouteMapView] when route search
/// results are available, or [NearbyMapView] for nearby station results.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
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
    final routeState = ref.watch(routeSearchStateProvider);
    final l10n = AppLocalizations.of(context);

    final hasRouteResults = routeState.hasValue && routeState.value != null;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(36),
        child: AppBar(
          title:
              Text(l10n?.map ?? 'Map', style: const TextStyle(fontSize: 16)),
          toolbarHeight: 36,
          titleSpacing: 12,
        ),
      ),
      floatingActionButton: const DrivingModeFab(),
      body: hasRouteResults
          ? RouteMapView(
              routeResult: routeState.value!,
              selectedFuel: selectedFuel,
              mapController: _mapController,
            )
          : NearbyMapView(
              searchState: searchState,
              selectedFuel: selectedFuel,
              searchRadiusKm: searchRadius,
              mapController: _mapController,
            ),
    );
  }
}
