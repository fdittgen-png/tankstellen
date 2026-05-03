import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/current_shell_branch_provider.dart';
import '../../../../core/providers/app_state_provider.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../driving/presentation/widgets/driving_mode_fab.dart';
import '../../../ev/presentation/widgets/ev_filter_chips.dart';
import '../../../ev/presentation/widgets/ev_map_overlay.dart';
import '../../../ev/providers/ev_providers.dart';
import '../../../route_search/providers/route_search_provider.dart';
import '../../../search/providers/search_provider.dart';
import '../../providers/map_breadcrumb_provider.dart';
import '../widgets/map_debug_breadcrumb_overlay.dart';
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
/// ## Cold-start one-shot bump (#1316 phase 1)
///
/// The 5-fix stack above (#473/#498/#709/#1164/#1268) regressed
/// because none of the rebuild triggers fire when the user opens the
/// app DIRECTLY onto the Carte tab (e.g. `last_visited_tab = Carte`
/// restored from disk). The [currentShellBranchProvider] listener at
/// the top of [build] only fires on TRANSITIONS to branch 1 — the
/// initial render at branch 1 is not a transition, so it is silent.
/// The lifecycle observer only fires on resume from background, not
/// on first launch. The [LayoutBuilder] gate prevents degenerate
/// constraints from reaching TileLayer but cannot recover if a 1×1
/// Android placeholder pass slips through (see the gate threshold
/// below).
///
/// Phase 1 adds a one-shot incarnation bump on the first build that
/// observes `currentShellBranchProvider == _mapBranchIndex`. This
/// mirrors the tab-flip rebuild pattern (controller swap, dispose
/// after next frame) and is guarded by [_coldStartBumpFired] so it
/// fires exactly once per [_MapScreenState] instance. Phase 1 also
/// scatters [debugPrint] breadcrumbs across every cold-start path
/// (tagged `[map-cold-start]`, `[map-layout]`, `[map-incarn]`,
/// `[map-lifecycle]`, `[map-branch]`) so a `adb logcat | grep map-`
/// during a repro yields actionable evidence — the issue body
/// explicitly calls out "a diagnostic logging pass before any 'fix'
/// is the right move".
///
/// ## In-app breadcrumb overlay + delayed retry-bump (#1316 phase 2)
///
/// Phase 1 routed actionable diagnostics through `adb logcat`, but the
/// user has not been able to capture logcat across any prior repro,
/// leaving the diagnostic loop open. Phase 2 routes the same messages
/// through [MapBreadcrumbsNotifier] so an in-app overlay
/// ([MapDebugBreadcrumbOverlay]) can render them on-device. The user
/// flips the overlay on via a hidden 5-tap gesture on the AppBar title
/// (no-op until the gate threshold is reached, so accidental presses
/// during normal use are harmless).
///
/// Phase 2 also takes one defensive swing at the timing: 1.5 s after
/// the cold-start one-shot bump, if the user hasn't pan/zoomed the map,
/// the screen bumps the incarnation once more. The first bump might
/// have run against a still-laying-out viewport; the delayed bump
/// catches the post-stabilised constraints. If the user already
/// interacted with the map (latched via [_userInteractedWithMap], set
/// from [MapController.mapEventStream] for any user-source event) the
/// retry is skipped — the bug doesn't reproduce, or the user
/// already self-corrected.
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

  /// Delay before the defensive retry-bump fires after a cold-start
  /// (#1316 phase 2). 1.5 s is long enough that any first-frame layout
  /// thrash has settled (a typical cold-start finishes its layout in
  /// well under one second on mid-range hardware) and short enough
  /// that the user is still looking at the map if the bug reproduced
  /// — they have not yet given up and switched tabs.
  static const Duration _retryBumpDelay = Duration(milliseconds: 1500);

  /// Window for the hidden 5-tap gesture that toggles
  /// [mapDebugOverlayProvider]. Taps are reset to zero if the user
  /// pauses for more than this many milliseconds — a stray double-tap
  /// during normal use cannot accidentally enable the overlay.
  static const Duration _debugGestureWindow = Duration(seconds: 2);

  /// Tap threshold for the hidden gesture. Five taps within
  /// [_debugGestureWindow] flips [mapDebugOverlayProvider].
  static const int _debugGestureTapThreshold = 5;

  /// When the app last entered a non-resumed state. Compared against
  /// the resume timestamp to decide whether to refresh — see
  /// [_resumeRefreshThreshold].
  DateTime? _pausedAt;

  /// Guard for the cold-start one-shot incarnation bump (#1316 phase
  /// 1). Set to `true` the first time [build] observes
  /// `currentShellBranchProvider == _mapBranchIndex`, which schedules
  /// a single post-frame controller swap so TileLayer re-runs its
  /// first-layout pass against real constraints. Subsequent builds
  /// skip the bump — repeat tab visits are covered by the
  /// [currentShellBranchProvider] listener.
  bool _coldStartBumpFired = false;

  /// Pending defensive retry-bump timer (#1316 phase 2). Scheduled
  /// once after the cold-start bump. Cancelled in [dispose] and on
  /// tab-flip-away so a late firing cannot rebuild an offstage map.
  Timer? _retryBumpTimer;

  /// Latches `true` the first time [_mapController] emits a
  /// user-source map event. Once set, never resets — the retry-bump
  /// stays disarmed for the lifetime of the [State] (the user has
  /// proven the screen is interactive, so the bug did not reproduce).
  bool _userInteractedWithMap = false;

  /// Subscription on [_mapController.mapEventStream] that drives
  /// [_userInteractedWithMap]. Cancelled and re-subscribed on every
  /// controller swap so the latch tracks the LIVE controller, not a
  /// stale one that was disposed by a previous incarnation bump.
  StreamSubscription<MapEvent>? _mapEventSub;

  /// Number of consecutive AppBar-title taps the user has accumulated
  /// inside [_debugGestureWindow]. Reset on idle.
  int _debugTapCount = 0;

  /// Last AppBar-title tap timestamp, used to enforce
  /// [_debugGestureWindow] — taps separated by more than the window
  /// reset the counter.
  DateTime? _lastDebugTapAt;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _subscribeToMapEvents();
    WidgetsBinding.instance.addObserver(this);
    _crumb(
      'map-lifecycle',
      'initState — incarnation=$_mapIncarnation, observer attached',
    );
  }

  @override
  void dispose() {
    _retryBumpTimer?.cancel();
    _mapEventSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _mapController.dispose();
    super.dispose();
  }

  DateTime _now() => widget.clockOverride?.call() ?? DateTime.now();

  /// Pushes a `[tag] message` to the in-app breadcrumb collector AND
  /// to [debugPrint] so existing `adb logcat`-based workflows still
  /// work (#1316 phase 2). Safe to call from any State callback —
  /// guarded by [mounted] because Riverpod's [ref] is invalidated
  /// after [dispose]. The Riverpod state mutation is deferred via
  /// [WidgetsBinding.addPostFrameCallback] so callers can [_crumb]
  /// from inside [build], [initState], and [LayoutBuilder.builder]
  /// without tripping Riverpod's "modify-in-lifecycle" guard.
  void _crumb(String tag, String message) {
    debugPrint('[$tag] $message');
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(mapBreadcrumbsProvider.notifier).record(tag, message);
    });
  }

  /// Subscribes to [_mapController.mapEventStream] to latch
  /// [_userInteractedWithMap] on the first user-driven event. Called
  /// from [initState] and after every controller swap so the
  /// subscription always points at the LIVE controller.
  void _subscribeToMapEvents() {
    _mapEventSub?.cancel();
    _mapEventSub = _mapController.mapEventStream.listen((event) {
      if (_userInteractedWithMap) return;
      if (_isUserDrivenEvent(event)) {
        _userInteractedWithMap = true;
        _crumb(
          'map-cold-start',
          'user interaction detected (${event.source.name}); '
              'retry-bump disarmed',
        );
      }
    });
  }

  /// True if [event] was issued by the user (drag, pinch, scroll-wheel,
  /// double-tap, fling, keyboard rotate, …) rather than a programmatic
  /// move (`mapController.move(...)`, fitCamera, interactiveFlags
  /// change). Mirrors the source enum at flutter_map 8.3.x — keep in
  /// sync if upgrading.
  bool _isUserDrivenEvent(MapEvent event) {
    switch (event.source) {
      case MapEventSource.dragStart:
      case MapEventSource.onDrag:
      case MapEventSource.dragEnd:
      case MapEventSource.multiFingerGestureStart:
      case MapEventSource.onMultiFinger:
      case MapEventSource.multiFingerEnd:
      case MapEventSource.doubleTap:
      case MapEventSource.doubleTapHold:
      case MapEventSource.doubleTapZoomAnimationController:
      case MapEventSource.flingAnimationController:
      case MapEventSource.scrollWheel:
      case MapEventSource.tap:
      case MapEventSource.longPress:
      case MapEventSource.cursorKeyboardRotation:
      case MapEventSource.keyboard:
        return true;
      case MapEventSource.mapController:
      case MapEventSource.fitCamera:
      case MapEventSource.interactiveFlagsChanged:
      case MapEventSource.nonRotatedSizeChange:
      case MapEventSource.custom:
      case MapEventSource.secondaryTap:
        return false;
    }
  }

  /// Increments [_mapIncarnation], swaps [_mapController], and
  /// re-subscribes the event stream. Used by every rebuild trigger
  /// (tab-flip, lifecycle resume, cold-start, delayed retry) so the
  /// controller-swap + dispose sequence is identical across paths.
  void _swapControllerAndBump(String trigger) {
    final old = _mapController;
    try {
      setState(() {
        _mapController = MapController();
        _mapIncarnation++;
      });
      _subscribeToMapEvents();
      _crumb(
        'map-incarn',
        'bumped to $_mapIncarnation (trigger: $trigger)',
      );
    } catch (e, st) {
      debugPrint('MapScreen rebuild on $trigger: $e\n$st');
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        old.dispose();
      } catch (e, st) {
        debugPrint(
          'MapScreen old controller dispose on $trigger: $e\n$st',
        );
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _crumb('map-lifecycle', 'state=$state, pausedAt=$_pausedAt');
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
    if (pausedAt == null) {
      _crumb('map-lifecycle', 'resume skipped: no pausedAt timestamp');
      return;
    }
    final pauseDuration = _now().difference(pausedAt);
    if (pauseDuration < _resumeRefreshThreshold) {
      _crumb(
        'map-lifecycle',
        'resume skipped: pauseDuration=$pauseDuration '
            '< threshold=$_resumeRefreshThreshold',
      );
      return;
    }
    final currentBranch = ref.read(currentShellBranchProvider);
    if (currentBranch != _mapBranchIndex) {
      _crumb(
        'map-lifecycle',
        'resume skipped: currentBranch=$currentBranch '
            '(not on Carte=$_mapBranchIndex)',
      );
      return;
    }
    _crumb(
      'map-lifecycle',
      'resume firing refresh: pauseDuration=$pauseDuration, '
          'incarnation=$_mapIncarnation -> ${_mapIncarnation + 1}',
    );

    // App-resume rebuild also covers the cold-start case; mark the
    // one-shot as fired so the next [build] doesn't pile on.
    _coldStartBumpFired = true;
    _swapControllerAndBump('app-resume');

    // Fire-and-forget: re-issue the most recent search so the station
    // data underlying the price chips is refreshed. Failures (no last
    // search, network error) are surfaced via `searchStateProvider`'s
    // existing error path.
    unawaited(
      ref.read(searchStateProvider.notifier).repeatLastSearch(),
    );
  }

  /// Hidden gesture handler — counts AppBar-title taps inside
  /// [_debugGestureWindow] and toggles [mapDebugOverlayProvider] on
  /// reaching [_debugGestureTapThreshold] (#1316 phase 2).
  void _bumpDebugTapCount() {
    final now = _now();
    final last = _lastDebugTapAt;
    if (last == null || now.difference(last) > _debugGestureWindow) {
      _debugTapCount = 1;
    } else {
      _debugTapCount++;
    }
    _lastDebugTapAt = now;

    if (_debugTapCount >= _debugGestureTapThreshold) {
      _debugTapCount = 0;
      _lastDebugTapAt = null;
      final wasEnabled = ref.read(mapDebugOverlayProvider);
      unawaited(
        ref.read(mapDebugOverlayProvider.notifier).toggle().then((_) {
          if (!mounted) return;
          final l10n = AppLocalizations.of(context);
          final msg = wasEnabled
              ? (l10n?.mapDebugOverlayDisabledSnack ??
                  'Map debug overlay disabled')
              : (l10n?.mapDebugOverlayEnabledSnack ??
                  'Map debug overlay enabled');
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(msg)));
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(currentShellBranchProvider, (previous, next) {
      _crumb(
        'map-branch',
        'listener fired: $previous -> $next '
            '(mapBranch=$_mapBranchIndex, incarnation=$_mapIncarnation)',
      );
      if (next != _mapBranchIndex) {
        // Tab-flip away from Carte — cancel any pending retry-bump so
        // it can't rebuild an offstage map a second later (#1316
        // phase 2).
        if (_retryBumpTimer?.isActive ?? false) {
          _retryBumpTimer?.cancel();
          _crumb(
            'map-cold-start',
            'retry-bump timer cancelled (tab-flip away from Carte)',
          );
        }
        _crumb(
          'map-branch',
          'skipped rebuild: next=$next is not mapBranch',
        );
        return;
      }
      // A tab-flip rebuild already covers the cold-start case — mark
      // the one-shot as fired so the post-flip [build] doesn't pile a
      // second redundant rebuild on top.
      _coldStartBumpFired = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _swapControllerAndBump('tab-flip');
      });
    });

    // #1316 phase 1 — cold-start one-shot incarnation bump. Covers the
    // case where the user opens the app directly onto Carte (no tab
    // flip → the listener above stays silent → TileLayer keeps any
    // degenerate constraints captured during the IndexedStack
    // pre-mount). Mirrors the tab-flip rebuild pattern (controller
    // swap + dispose on next frame). Guarded by [_coldStartBumpFired]
    // so it fires exactly once per [_MapScreenState] instance.
    final currentBranch = ref.read(currentShellBranchProvider);
    if (!_coldStartBumpFired && currentBranch == _mapBranchIndex) {
      _coldStartBumpFired = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _crumb(
          'map-cold-start',
          'firing one-shot incarnation bump on first Carte build',
        );
        _swapControllerAndBump('cold-start');
        _scheduleDelayedRetryBump();
      });
    }

    final searchState = ref.watch(searchStateProvider);
    final selectedFuel = ref.watch(selectedFuelTypeProvider);
    final searchRadius = ref.watch(searchRadiusProvider);
    final routeState = ref.watch(routeSearchStateProvider);
    final showEv = ref.watch(evShowOnMapProvider);
    final l10n = AppLocalizations.of(context);

    final hasRouteResults = routeState.hasValue && routeState.value != null;

    // #1164 — gate the FlutterMap subtree on real (non-zero) constraints
    // so its TileLayer never captures the offstage IndexedStack's
    // degenerate viewport. Combined with the [_mapIncarnation] rebuild
    // on tab-flip, this fully covers cold-start (first tap) and repeat
    // visits.
    final body = LayoutBuilder(
      builder: (context, constraints) {
        // #1316: Some Android layout passes use a 1×1 placeholder before the
        // real constraints arrive — the prior `<= 0` gate let those through
        // and TileLayer captured a degenerate viewport. Require at least
        // 100px on each axis so the gate covers placeholder constraints too.
        final suppressed = constraints.maxWidth < 100 ||
            constraints.maxHeight < 100;
        _crumb(
          'map-layout',
          'LayoutBuilder constraints='
              '${constraints.maxWidth.toStringAsFixed(1)}x'
              '${constraints.maxHeight.toStringAsFixed(1)}, '
              'suppressed=$suppressed, incarnation=$_mapIncarnation',
        );
        if (suppressed) {
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

    final titleText = l10n?.map ?? 'Map';
    return PageScaffold(
      titleWidget: GestureDetector(
        // The 5-tap gesture is hidden — `behavior: opaque` ensures the
        // tap is captured even when the title's intrinsic size leaves
        // empty space inside the AppBar's title slot.
        behavior: HitTestBehavior.opaque,
        onTap: _bumpDebugTapCount,
        child: Semantics(
          header: true,
          child: Text(titleText),
        ),
      ),
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
      ],
      bodyPadding: EdgeInsets.zero,
      floatingActionButton: const DrivingModeFab(),
      body: Stack(
        children: [
          Column(
            children: [
              if (showEv) const EvFilterChips(),
              Expanded(child: body),
            ],
          ),
          const MapDebugBreadcrumbOverlay(),
        ],
      ),
    );
  }

  /// Schedules the defensive retry-bump (#1316 phase 2). Fires
  /// [_retryBumpDelay] after the cold-start bump if and only if the
  /// user still hasn't interacted with the map AND Carte is still the
  /// visible branch. The retry covers a hypothesised race where the
  /// cold-start bump runs against a still-laying-out viewport — the
  /// post-stabilised constraints catch up after a few hundred ms, so
  /// rebuilding once more after 1.5 s gives TileLayer a clean second
  /// chance.
  void _scheduleDelayedRetryBump() {
    _retryBumpTimer?.cancel();
    _retryBumpTimer = Timer(_retryBumpDelay, () {
      if (!mounted) return;
      if (_userInteractedWithMap) {
        _crumb(
          'map-cold-start',
          'delayed retry-bump skipped: user already interacted',
        );
        return;
      }
      final branch = ref.read(currentShellBranchProvider);
      if (branch != _mapBranchIndex) {
        _crumb(
          'map-cold-start',
          'delayed retry-bump skipped: branch=$branch '
              '(not on Carte=$_mapBranchIndex)',
        );
        return;
      }
      _crumb(
        'map-cold-start',
        'delayed retry-bump fired (no user interaction)',
      );
      _swapControllerAndBump('delayed-retry');
    });
  }
}
