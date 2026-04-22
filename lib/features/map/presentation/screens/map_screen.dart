import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../driving/presentation/widgets/driving_mode_fab.dart';
import '../../../ev/presentation/widgets/ev_filter_chips.dart';
import '../../../ev/presentation/widgets/ev_map_overlay.dart';
import '../../../ev/providers/ev_providers.dart';
import '../../../route_search/providers/route_search_provider.dart';
import '../../../search/providers/search_provider.dart';
import '../widgets/nearby_map_view.dart';
import '../widgets/route_map_view.dart';

/// Top-level map screen that delegates to [RouteMapView] when route search
/// results are available, or [NearbyMapView] for nearby station results.
///
/// Previously this screen hosted a complex subtree-rebuild counter plus
/// a `searchStateProvider` listener that nudged the controller on fresh
/// search results (#529, #709). Both were symptom-level workarounds for
/// `TileLayer` caching failed fetches — now addressed at the root by
/// [RetryNetworkTileProvider] and `evictErrorTileStrategy:
/// notVisibleRespectMargin` on every `TileLayer` in the app (#757).
/// Keeping the workarounds after the root-cause fix added complexity
/// and cancelled in-flight tile requests when price-refreshes landed.
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
    final showEv = ref.watch(evShowOnMapProvider);
    final l10n = AppLocalizations.of(context);

    final hasRouteResults = routeState.hasValue && routeState.value != null;

    final body = hasRouteResults
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
          );

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
      body: Column(
        children: [
          if (showEv) const EvFilterChips(),
          Expanded(
            child: Stack(
              children: [
                body,
                const Positioned(
                  left: 16,
                  top: 16,
                  child: EvToggleButton(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
