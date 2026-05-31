// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/current_shell_branch_provider.dart';
import '../../../../app/responsive_search_layout.dart';
import '../../../../app/shell/settings_app_bar_action.dart';
import '../../../../core/sharing/widget_share_renderer.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../ev/presentation/widgets/ev_filter_chips.dart';
import '../../../ev/presentation/widgets/ev_map_overlay.dart';
import '../../../ev/providers/ev_providers.dart';
import '../../../route_search/providers/route_search_provider.dart';
import '../../../search/providers/search_provider.dart';
import '../../../search/providers/selected_station_provider.dart';
import '../../../station_detail/presentation/widgets/station_detail_inline.dart';
import '../widgets/nearby_map_view.dart';
import '../widgets/price_legend.dart';
import '../widgets/route_map_view.dart';
import '../../../../core/logging/error_logger.dart';

/// Top-level map screen that delegates to [RouteMapView] when route search
/// results are available, or [NearbyMapView] for nearby station results.
///
/// ## Structural viewport gate (#1605)
///
/// `StatefulShellRoute.indexedStack` pre-mounts every tab with degenerate
/// (zero-sized) constraints. `flutter_map`'s [TileLayer] captures its tile
/// viewport on the first layout pass; when that pass happens offstage, the
/// layer settles into a "no tiles to fetch" state and never re-issues
/// requests when real constraints arrive — the map stays grey until the
/// user pans or zooms.
///
/// The cure is structural: the `FlutterMap` subtree is built **only when
/// the Carte tab is the visible shell branch** ([currentShellBranchProvider]
/// `== _mapBranchIndex`). The shell publishes the branch index before the
/// `IndexedStack` promotes the branch onstage, so by the time this screen
/// builds the map, it lays out against real post-mount constraints —
/// `TileLayer` never sees the degenerate offstage viewport. One gate at the
/// source replaces the cold-start / tab-flip / lifecycle rebuild triggers,
/// the incarnation controller-swap, the magic timing windows and the
/// `< 100`px [LayoutBuilder] gate that the bug accreted over #473–#1316.
///
/// ## App-resume price refresh (#1268)
///
/// Returning to the app after a long background gap can leave price chips
/// frozen on stale data. On resume after [_resumeRefreshThreshold], while
/// Carte is visible, the screen re-issues the last search so chips pick up
/// any newly-available prices. This is a data refresh only — the structural
/// gate above already keeps the tile layer healthy across a resume, so no
/// map rebuild is needed.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key, this.clockOverride});

  /// When non-null, overrides `DateTime.now()` for the resume-threshold
  /// comparison. Tests use this so they can simulate "paused 30 s ago"
  /// without sleeping wall-clock seconds. Production callers leave it
  /// `null`.
  @visibleForTesting
  final DateTime Function()? clockOverride;

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with WidgetsBindingObserver {
  late final MapController _mapController;

  /// Index of the Map branch in the bottom-nav stack.
  static const int _mapBranchIndex = 1;

  /// Minimum pause-to-resume gap that triggers a price refresh on resume
  /// (#1268). A short blip (notification-shade swipe, lock-screen peek)
  /// does not need the search-refresh cost.
  static const Duration _resumeRefreshThreshold = Duration(seconds: 10);

  /// When the app last entered a non-resumed state. Compared against the
  /// resume timestamp to decide whether to refresh.
  DateTime? _pausedAt;

  /// Boundary around the map body — `shareWidgetAsImage` renders the
  /// widget under this key to a PNG for the Share action (#1959).
  final GlobalKey _shareBoundaryKey =
      GlobalKey(debugLabel: 'map_share_boundary');

  /// Render the current map view to an image and hand it to the OS
  /// share sheet (#1959). Best-effort — a share failure is logged and
  /// swallowed so the action never crashes the map screen.
  Future<void> _onShare(AppLocalizations? l10n) async {
    try {
      await shareWidgetAsImage(
        boundaryKey: _shareBoundaryKey,
        subject: l10n?.map ?? 'Map',
        fileNameStem: 'tankstellen_map',
      );
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.ui, e, st, context: const {'where': 'MapScreen share image'}));
    }
  }

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mapController.dispose();
    super.dispose();
  }

  DateTime _now() => widget.clockOverride?.call() ?? DateTime.now();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _onAppResumed();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      // Track the first transition into a non-resumed state — don't
      // overwrite the genuine pause moment on repeated callbacks.
      _pausedAt ??= _now();
    }
  }

  /// Re-issue the last search when the user returns after a long gap and
  /// Carte is visible (#1268), so price chips pick up newer prices.
  void _onAppResumed() {
    final pausedAt = _pausedAt;
    _pausedAt = null;
    if (!mounted || pausedAt == null) return;
    if (_now().difference(pausedAt) < _resumeRefreshThreshold) return;
    if (ref.read(currentShellBranchProvider) != _mapBranchIndex) return;
    unawaited(ref.read(searchStateProvider.notifier).repeatLastSearch());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // #1605 — the structural viewport gate. The FlutterMap subtree is
    // built only while Carte is the visible shell branch, so TileLayer's
    // first layout pass always runs against real onstage constraints.
    final isVisibleBranch =
        ref.watch(currentShellBranchProvider) == _mapBranchIndex;
    final showEv = ref.watch(evShowOnMapProvider);

    // #2532 — on a wide screen a marker tap selects the station into the
    // side panel rather than pushing the full route; on compact the marker
    // keeps its default `/station/:id` push (passing null leaves the
    // StationMarkerBuilder default untouched). The detail then renders in a
    // sibling pane beside the still-full-bleed map (see body below).
    final isWide = screenSizeOf(context) != ScreenSize.compact;
    final void Function(String)? onStationTap = isWide
        ? (id) => ref.read(selectedStationProvider.notifier).select(id)
        : null;

    final Widget body;
    if (!isVisibleBranch) {
      // Offstage: render nothing heavy. When the branch becomes visible
      // this build re-runs and the map lays out against real constraints.
      body = const SizedBox.shrink();
    } else {
      final searchState = ref.watch(searchStateProvider);
      final selectedFuel = ref.watch(selectedFuelTypeProvider);
      final searchRadius = ref.watch(searchRadiusProvider);
      final routeState = ref.watch(routeSearchStateProvider);
      final hasRouteResults = routeState.hasValue && routeState.value != null;
      body = hasRouteResults
          ? RouteMapView(
              routeResult: routeState.value!,
              selectedFuel: selectedFuel,
              mapController: _mapController,
              onStationTap: onStationTap,
            )
          : NearbyMapView(
              searchState: searchState,
              selectedFuel: selectedFuel,
              searchRadiusKm: searchRadius,
              mapController: _mapController,
              onStationTap: onStationTap,
            );
    }

    // The master pane — the EV filter chips + the (gated) map body, wrapped
    // in the #1959 share boundary so the Share action still renders ONLY the
    // map to a PNG (the detail pane is a sibling, outside the boundary).
    final Widget mapPane = RepaintBoundary(
      key: _shareBoundaryKey,
      child: Column(
        children: [
          if (isVisibleBranch && showEv) const EvFilterChips(),
          Expanded(child: body),
        ],
      ),
    );

    // #2532 — on wide, the selected station (if any) shows its inline detail
    // in the side pane; otherwise the pane is the empty-state legend. On
    // compact `ResponsiveMasterDetail` hides the detail entirely, so the map
    // stays byte-for-byte full-bleed and the marker tap pushes the route.
    final selectedStationId = ref.watch(selectedStationProvider);
    final Widget detailPane = selectedStationId != null
        ? StationDetailInline(
            stationId: selectedStationId,
            onClose: () =>
                ref.read(selectedStationProvider.notifier).clear(),
          )
        : const _MapDetailPlaceholder();

    return PageScaffold(
      title: l10n?.map ?? 'Map',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            unawaited(
              ref.read(searchStateProvider.notifier).repeatLastSearch(),
            );
          },
          tooltip: l10n?.refreshPrices ?? 'Refresh prices',
        ),
        const EvToggleButton(),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () => _onShare(l10n),
          tooltip: l10n?.favoritesShareAction ?? 'Share',
        ),
        const SettingsAppBarAction(),
      ],
      bodyPadding: EdgeInsets.zero,
      body: ResponsiveMasterDetail(
        master: mapPane,
        detail: detailPane,
      ),
    );
  }
}

/// Empty-state side pane shown on a wide map screen when no station is
/// selected (#2532). A simple hint plus the [PriceLegend] so the colour
/// ramp is explained even before the user has tapped a marker. Uses only
/// existing ARB keys — no new strings.
class _MapDetailPlaceholder extends StatelessWidget {
  const _MapDetailPlaceholder();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: EmptyState(
            icon: Icons.touch_app_outlined,
            title: l10n?.startSearch ??
                'Search for stations to see them on the map',
            iconSize: 64,
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: PriceLegend(),
        ),
      ],
    );
  }
}
