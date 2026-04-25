import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/current_shell_branch_provider.dart';
import '../../../../core/widgets/page_scaffold.dart';
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
/// ## Tab-flip teardown ([_mapIncarnation])
///
/// `StatefulShellRoute.indexedStack` pre-mounts every tab with degenerate
/// (zero-sized) constraints. `flutter_map`'s [TileLayer] captures its
/// tile viewport on the first layout pass; when that pass happens
/// offstage, the layer settles into a "no tiles to fetch" state and
/// never re-issues requests when real constraints arrive. Result: gray
/// background until the user manually pans or zooms (#473, #498, #709).
///
/// [RetryNetworkTileProvider] + `evictErrorTileStrategy` (#757) handle
/// transient HTTP failures but cannot recover this state — the bug
/// isn't a failed fetch, it's a fetch that's never issued. The only
/// reliable cure is to tear down and rebuild the entire FlutterMap
/// subtree when the Carte tab becomes visible, so it lays out against
/// real post-mount constraints. That's what the [currentShellBranchProvider]
/// listener + [_mapIncarnation] [ValueKey] do below.
///
/// We deliberately do NOT also listen to `searchStateProvider` —
/// rebuilding on search-result change cancelled in-flight tile fetches
/// when price-refreshes landed (#709 regression). Camera moves on
/// search results are nudged inside [NearbyMapView] / [RouteMapView]
/// instead.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  late MapController _mapController;

  /// Bumped every time the Carte tab becomes visible. Used as a
  /// [ValueKey] on the map subtree so the FlutterMap + TileLayer is
  /// destroyed and rebuilt with real post-layout constraints (#709).
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
    ref.listen<int>(currentShellBranchProvider, (_, next) {
      const mapBranchIndex = 1;
      if (next != mapBranchIndex) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final old = _mapController;
        try {
          setState(() {
            _mapController = MapController();
            _mapIncarnation++;
          });
        } catch (e) {
          debugPrint('MapScreen rebuild on tab-flip: $e');
        }
        // Dispose the previous controller after the next frame so the
        // old FlutterMap has fully detached from it.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            old.dispose();
          } catch (e) {
            debugPrint('MapScreen old controller dispose: $e');
          }
        });
      });
    });

    final searchState = ref.watch(searchStateProvider);
    final selectedFuel = ref.watch(selectedFuelTypeProvider);
    final searchRadius = ref.watch(searchRadiusProvider);
    final routeState = ref.watch(routeSearchStateProvider);
    final showEv = ref.watch(evShowOnMapProvider);
    final l10n = AppLocalizations.of(context);

    final hasRouteResults = routeState.hasValue && routeState.value != null;

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

    return PageScaffold(
      title: l10n?.map ?? 'Map',
      toolbarHeight: 36,
      titleSpacing: 12,
      titleTextStyle: const TextStyle(fontSize: 16),
      bodyPadding: EdgeInsets.zero,
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
