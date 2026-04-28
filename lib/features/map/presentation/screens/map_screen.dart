import 'dart:async';

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
///
/// ## First-open zero-size guard ([LayoutBuilder])
///
/// The [_mapIncarnation] listener handles repeat visits but cannot
/// fully cover the cold-start case (#1164): when the user taps Carte
/// for the first time, the listener fires AFTER the IndexedStack has
/// already promoted the offstage-mounted MapScreen to onstage, leaving
/// a one-frame window in which TileLayer has already captured its
/// zero-sized viewport. Wrapping the body in a [LayoutBuilder] that
/// suppresses the FlutterMap subtree until constraints are non-zero
/// guarantees the TileLayer NEVER sees degenerate constraints — its
/// first layout pass always uses the real post-mount size.
///
/// ## App-resume refresh (#1268)
///
/// Backgrounding the app and returning after >10 s leaves both tiles
/// and price chips frozen in their pre-pause state — none of the
/// existing defenses ([_mapIncarnation] tab-flip listener,
/// [LayoutBuilder] gate, first-paint reset stream) fire on lifecycle
/// resume because no tab-flip happens. The user reports the visible
/// viewport never recovers and price chips stay on `--` indefinitely.
///
/// We hook [WidgetsBindingObserver.didChangeAppLifecycleState] to:
///   1. Bump [_mapIncarnation] when the app resumes AND Carte is
///      currently visible — this rebuilds the FlutterMap subtree the
///      same way a tab-flip does, restoring the tile-fetch loop.
///   2. Call `searchStateProvider.notifier.repeatLastSearch()` so the
///      station data (and any prices that the API now reports) is
///      refreshed. Stations whose previous fetch returned no price for
///      the selected fuel get a second chance to populate; chips that
///      legitimately have no upstream data continue to render `--` (the
///      `priceColor(null,…)` grey signals "no data" — already distinct
///      from the loading state).
///
/// ## App-bar title color (#1164 bug 2)
///
/// `PageScaffold(titleTextStyle: const TextStyle(fontSize: 16))` would
/// strip the inherited foreground color: AppBar's title text-style
/// resolution does NOT merge with `defaults.titleTextStyle` when the
/// caller supplies a non-null `titleTextStyle`, so the title would
/// render in the DefaultTextStyle fallback (near-invisible against the
/// FlexColorScheme app bar surface). We resolve the theme's
/// foreground color explicitly so the compact 16pt size still inherits
/// the proper on-surface contrast.
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
  late MapController _mapController;

  /// Bumped every time the Carte tab becomes visible. Used as a
  /// [ValueKey] on the map subtree so the FlutterMap + TileLayer is
  /// destroyed and rebuilt with real post-layout constraints (#709).
  int _mapIncarnation = 0;

  /// Index of the Map branch in the bottom-nav stack. Kept as a named
  /// constant so the lifecycle handler stays readable.
  static const int _mapBranchIndex = 1;

  /// Minimum pause-to-resume gap that triggers a refresh on resume
  /// (#1268). A short blip (notification shade swipe, lock-screen
  /// peek) does not need to pay the rebuild + search-refresh cost, so
  /// brief lifecycle bounces are ignored. Ten seconds matches the
  /// acceptance criterion in the issue.
  static const Duration _resumeRefreshThreshold = Duration(seconds: 10);

  /// When the app last entered a non-resumed state. Compared against
  /// the resume timestamp to decide whether to refresh — see
  /// [_resumeRefreshThreshold].
  DateTime? _pausedAt;

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
      // Track the first transition into a non-resumed state. Don't
      // reset on every flip — repeated `inactive`+`paused` callbacks
      // during a single backgrounding would otherwise overwrite the
      // genuine pause moment.
      _pausedAt ??= _now();
    }
  }

  /// Refresh the map when the user returns to the app after >10 s
  /// AND the Carte tab is currently visible (#1268). Bumping the
  /// incarnation rebuilds the FlutterMap subtree (the same fix as the
  /// tab-flip listener); calling `repeatLastSearch` re-fetches station
  /// data so price chips pick up any newly-available prices.
  void _onAppResumed() {
    final pausedAt = _pausedAt;
    _pausedAt = null;
    if (!mounted) return;
    if (pausedAt == null) return;
    if (_now().difference(pausedAt) < _resumeRefreshThreshold) {
      return;
    }
    final currentBranch = ref.read(currentShellBranchProvider);
    if (currentBranch != _mapBranchIndex) return;

    final old = _mapController;
    try {
      setState(() {
        _mapController = MapController();
        _mapIncarnation++;
      });
    } catch (e, st) {
      debugPrint('MapScreen rebuild on app-resume: $e\n$st');
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        old.dispose();
      } catch (e, st) {
        debugPrint('MapScreen old controller dispose on resume: $e\n$st');
      }
    });

    // Fire-and-forget: re-issue the most recent search so the station
    // data underlying the price chips is refreshed. Failures (no last
    // search, network error) are surfaced via `searchStateProvider`'s
    // existing error path.
    unawaited(
      ref.read(searchStateProvider.notifier).repeatLastSearch(),
    );
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
        } catch (e, st) {
          debugPrint('MapScreen rebuild on tab-flip: $e\n$st');
        }
        // Dispose the previous controller after the next frame so the
        // old FlutterMap has fully detached from it.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            old.dispose();
          } catch (e, st) {
            debugPrint('MapScreen old controller dispose: $e\n$st');
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
    final theme = Theme.of(context);
    final appBarTheme = theme.appBarTheme;

    final hasRouteResults = routeState.hasValue && routeState.value != null;

    // #1164 — gate the FlutterMap subtree on real (non-zero) constraints
    // so its TileLayer never captures the offstage IndexedStack's
    // degenerate viewport. Combined with the [_mapIncarnation] rebuild
    // on tab-flip, this fully covers cold-start (first tap) and repeat
    // visits.
    final body = LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
          return const SizedBox.shrink();
        }
        return KeyedSubtree(
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
      },
    );

    // #1164 — restore the inherited foreground color when overriding
    // `titleTextStyle`. AppBar does NOT merge with the default title
    // style when the caller supplies a non-null `titleTextStyle`, so a
    // bare `TextStyle(fontSize: 16)` strips the color and the title
    // renders near-invisible. Resolve the foreground color from the
    // app-bar theme (FlexColorScheme) and preserve it explicitly.
    final foregroundColor = appBarTheme.foregroundColor ??
        theme.colorScheme.onSurface;
    // Inline title text-theme refs are banned in feature screens by
    // the `no_inline_title_theme_test` lint (#923) — including in
    // comments, since the static scan greps for the literal string.
    // The explicit `copyWith` below sets fontSize/color directly, and
    // any unset family/weight is inherited from the AppBar default
    // via DefaultTextStyle when `appBarTheme.titleTextStyle` is null.
    final baseTitleStyle = appBarTheme.titleTextStyle ?? const TextStyle();
    final compactTitleStyle = baseTitleStyle.copyWith(
      fontSize: 16,
      color: foregroundColor,
    );

    return PageScaffold(
      title: l10n?.map ?? 'Map',
      toolbarHeight: 36,
      titleSpacing: 12,
      titleTextStyle: compactTitleStyle,
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
