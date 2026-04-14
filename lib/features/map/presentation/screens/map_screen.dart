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

    // Nudge the controller after the first paint so the TileLayer
    // recomputes its visible bounds and starts fetching tiles. Without
    // this, on the very first visit to the Carte tab (when the shell's
    // IndexedStack pre-mounts the map offstage with degenerate
    // constraints), the TileLayer's internal `_TileBoundsAtZoom` reads
    // the empty bounds, fetches nothing, and the map renders the
    // markers and the radius circle on a blank white background until
    // the user pans or pinches the map (#473). The 100 ms delay is
    // long enough to wait for the first real layout pass while still
    // being invisible to the user.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;
        try {
          final camera = _mapController.camera;
          _mapController.move(camera.center, camera.zoom);
        } catch (_) {
          // Controller not yet attached to a FlutterMap — the
          // post-frame callback inside NearbyMapView will pick up the
          // first real fit and tiles will load on that path instead.
        }
      });
    });
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
