import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../app/current_shell_branch_provider.dart';
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
  late MapController _mapController;

  /// Increments every time the Carte tab becomes visible. Used as a
  /// ValueKey on the map subtree so a tab-flip DESTROYS the old
  /// FlutterMap + TileLayer and builds a fresh one with real
  /// constraints. This is the only reliable cure for the blank-tile
  /// bug in flutter_map's TileLayer which caches an empty viewport
  /// when first mounted offstage inside `StatefulShellRoute.indexedStack`
  /// (#709 — zoom-jiggle was too small, only pan/zoom buttons fixed it).
  int _mapIncarnation = 0;

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
    // #529 — nudge the FlutterMap controller whenever a fresh search
    // result arrives, so the TileLayer re-computes its viewport and
    // fetches tiles for the new bounds. Without this, switching to
    // the Carte tab after a search briefly shows blank OSM tiles:
    // the map widget is pre-built offstage inside the shell's
    // indexedStack, the `initState` nudge and the one-shot
    // `onMapReady` (#498) have already fired, and nothing retriggers
    // a viewport recompute when the search state changes.
    // #709 — force a full TileLayer rebuild on every Carte tab-flip
    // AND on every fresh search result. `_rebuildMapSubtree()` bumps
    // `_mapIncarnation` (ValueKey below) so the whole FlutterMap +
    // TileLayer is torn down and built anew with real constraints.
    // Same fix applies to #529 (search-result-change).
    void rebuildMap() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        try {
          final old = _mapController;
          setState(() {
            _mapController = MapController();
            _mapIncarnation++;
          });
          // Dispose the old controller AFTER the rebuild so the old
          // FlutterMap has already detached from it.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              old.dispose();
            } catch (e) {
              debugPrint('MapScreen: old controller dispose: $e');
            }
          });
        } catch (e) {
          debugPrint('MapScreen rebuild: $e');
        }
      });
    }
    ref.listen<int>(currentShellBranchProvider, (prev, next) {
      const mapBranchIndex = 1;
      if (next != mapBranchIndex) return;
      rebuildMap();
    });
    ref.listen(searchStateProvider, (_, next) {
      if (next.hasValue && next.value!.data.isNotEmpty) rebuildMap();
    });

    final searchState = ref.watch(searchStateProvider);
    final selectedFuel = ref.watch(selectedFuelTypeProvider);
    final searchRadius = ref.watch(searchRadiusProvider);
    final routeState = ref.watch(routeSearchStateProvider);
    final showEv = ref.watch(evShowOnMapProvider);
    final l10n = AppLocalizations.of(context);

    final hasRouteResults = routeState.hasValue && routeState.value != null;

    // Key on `_mapIncarnation` so every Carte tab-flip rebuilds the
    // FlutterMap + TileLayer from scratch with the real post-layout
    // constraints (#709). Without this, TileLayer keeps the empty
    // viewport it captured while offstage.
    final body = KeyedSubtree(
      key: ValueKey<int>(_mapIncarnation),
      child: hasRouteResults
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
