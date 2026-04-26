import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/utils/frame_callbacks.dart';
import '../features/vehicle/providers/vehicle_providers.dart';
import '../l10n/app_localizations.dart';
import 'current_shell_branch_provider.dart';
import 'responsive_search_layout.dart';
import 'shell/shell_bottom_bar.dart';
import 'shell/shell_destinations.dart';
import 'shell/shell_nav_rail.dart';

/// The main app shell with adaptive navigation.
///
/// ## Architecture:
/// go_router uses `StatefulShellRoute.indexedStack` which preserves each
/// tab's widget tree in memory (so scroll position, form data, etc. persist
/// when switching tabs). This widget wraps the shell with:
/// - NavigationRail on medium/expanded screens (>= 600dp)
/// - Bottom navigation bar on compact screens (< 600dp)
/// - Smooth slide+fade transition animations between tabs
/// - Horizontal swipe gesture for tab switching (compact only)
/// - Bouncing icon animation on selection
/// - System navigation bar padding to avoid overlap with Android buttons
///
/// ## Navigation flow:
/// User taps tab → `_goToPage()` → plays animation → calls `goBranch()`
/// → go_router switches the visible branch → `navigationShell` renders new page
class ShellScreen extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  const ShellScreen({super.key, required this.navigationShell});

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen>
    with TickerProviderStateMixin {
  late final List<AnimationController> _iconControllers;
  late AnimationController _transitionController;
  late Animation<Offset> _slideInAnim;
  late Animation<double> _fadeAnim;

  int _currentIndex = 0;
  bool _isTransitioning = false;

  /// Router-branch indices for the currently visible nav slots. Refreshed
  /// on every `build()` so the swipe handler can walk to the adjacent
  /// visible tab rather than blindly `_currentIndex ± 1` (which would
  /// otherwise stop on the hidden Conso branch, #893).
  List<int> _branchForSlot = const [0, 1, 2, 3, 4];

  /// Upper bound on destination count — the router always registers 5
  /// branches (see StatefulShellRoute in router.dart), the UI decides
  /// how many are visible.
  static const _pageCount = 5;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.navigationShell.currentIndex;

    // Publish the INITIAL branch index so MapScreen's visibility listener
    // fires even on first-run landing where the user never taps a tab
    // (e.g. landingScreen == cheapest/nearest routes straight to Carte).
    // Without this the listener only caught later tab flips, leaving
    // the first visit blank (#709).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(currentShellBranchProvider.notifier).set(_currentIndex);
    });

    _iconControllers = List.generate(
      _pageCount,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 350),
      ),
    );

    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _setupAnimations(goingRight: true);
    _transitionController.value = 1.0;
  }

  void _setupAnimations({required bool goingRight}) {
    final direction = goingRight ? 1.0 : -1.0;
    _slideInAnim = Tween<Offset>(
      begin: Offset(0.3 * direction, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _transitionController, curve: Curves.easeOutCubic));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _transitionController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    for (final c in _iconControllers) {
      c.dispose();
    }
    _transitionController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    if (_isTransitioning || index == _currentIndex) return;

    final oldIndex = _currentIndex;
    _isTransitioning = true;

    _setupAnimations(goingRight: index > oldIndex);
    _transitionController.value = 0.0;

    // Play icon bounce
    _iconControllers[index]
      ..reset()
      ..forward();

    _transitionController.forward().then((_) {
      _isTransitioning = false;
    });

    setState(() => _currentIndex = index);
    // Publish the new branch index so observers (e.g. MapScreen for its
    // tile-viewport nudge, #696) can react without reaching into this
    // widget's private state.
    ref.read(currentShellBranchProvider.notifier).set(index);

    // Navigate via go_router — this preserves each branch's state
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 300) return;

    // Walk through the visible slots, not the branch indices — when
    // Conso is hidden (#893) the branch list has a gap between 2 and
    // 4 that the user shouldn't be able to swipe through.
    final slot = _branchForSlot.indexOf(_currentIndex);
    if (slot < 0) return;
    if (velocity < 0 && slot < _branchForSlot.length - 1) {
      _goToPage(_branchForSlot[slot + 1]);
    } else if (velocity > 0 && slot > 0) {
      _goToPage(_branchForSlot[slot - 1]);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep in sync with go_router's actual index (e.g. deep link or redirect)
    final routerIndex = widget.navigationShell.currentIndex;
    if (routerIndex != _currentIndex && !_isTransitioning) {
      safePostFrame(() {
        if (routerIndex != _currentIndex) {
          setState(() => _currentIndex = routerIndex);
          ref.read(currentShellBranchProvider.notifier).set(routerIndex);
        }
      });
    }

    final l10n = AppLocalizations.of(context);
    final screenSize = screenSizeOf(context);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    // #893 — Conso tab is only visible once the user has configured at
    // least one vehicle. A fresh install (no vehicles) shows the 4
    // canonical destinations (Search, Map, Favorites, Settings); the
    // Conso branch still exists in the router (deep links to
    // `/consumption-tab` and `/consumption/...` remain functional),
    // only the bottom-nav item is conditional. `ref.watch` makes this
    // reactive — removing the last vehicle from Settings instantly
    // collapses the tab to 4, and adding the first vehicle grows it
    // back to 5.
    final hasVehicle = ref.watch(vehicleProfileListProvider).isNotEmpty;

    final destinations =
        resolveShellDestinations(l10n: l10n, hasVehicle: hasVehicle);
    final visibleDestinations = destinations.items;
    final branchForSlot = destinations.branchForSlot;
    _branchForSlot = branchForSlot;

    // If the user was on the Conso tab and just deleted their last
    // vehicle, snap the selection to Search (branch 0) — the Conso
    // slot has disappeared from the nav bar and leaving
    // `_currentIndex` pointing at it would leave no item highlighted.
    if (!hasVehicle && _currentIndex == kConsumptionBranchIndex) {
      safePostFrame(() {
        if (!mounted) return;
        if (_currentIndex != kConsumptionBranchIndex) return;
        _goToPage(0);
      });
    }

    // Display-slot the animated nav bar should highlight. `-1` when
    // the active branch has no visible slot (transient, resolved by
    // the snap above on the next frame).
    final selectedSlot = branchForSlot.indexOf(_currentIndex);

    final body = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd:
          screenSize == ScreenSize.compact ? _onHorizontalDragEnd : null,
      child: AnimatedBuilder(
        animation: _transitionController,
        builder: (context, _) {
          return SlideTransition(
            position: _slideInAnim,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: widget.navigationShell,
            ),
          );
        },
      ),
    );

    // Translate a tap on a visible slot into the underlying branch
    // index before calling `_goToPage`. Keeps the animation + router
    // state machine unchanged when Conso is hidden (Settings at
    // display-slot 3 still targets branch 4).
    void onSlotTap(int slot) {
      if (slot < 0 || slot >= branchForSlot.length) return;
      _goToPage(branchForSlot[slot]);
    }

    // Wide screens: use NavigationRail instead of bottom nav
    if (screenSize != ScreenSize.compact) {
      return Scaffold(
        // #520 — the shell Scaffold has no AppBar of its own, so it must
        // not claim to be the primary Scaffold. Otherwise Flutter routes
        // the status-bar inset through the outer Scaffold *and* through
        // the inner screen's AppBar, producing the doubled gap the user
        // sees between the Android status bar and the title on every
        // top-level destination. Setting primary: false tells Flutter
        // "this Scaffold does not own the top inset — pass it through to
        // the child verbatim".
        primary: false,
        body: Row(
          children: [
            ShellNavRail(
              items: visibleDestinations,
              branchForSlot: branchForSlot,
              currentIndex: selectedSlot < 0 ? 0 : selectedSlot,
              iconControllers: _iconControllers,
              extended: screenSize == ScreenSize.expanded,
              onTap: onSlotTap,
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: body),
          ],
        ),
      );
    }

    // Compact screens: bottom navigation bar
    return Scaffold(
      // #520 — see comment in the wide-screen branch above. Same fix,
      // applied to the compact Scaffold that hosts the bottom nav.
      primary: false,
      body: body,
      bottomNavigationBar: ShellBottomBar(
        items: visibleDestinations,
        branchForSlot: branchForSlot,
        currentIndex: selectedSlot < 0 ? 0 : selectedSlot,
        iconControllers: _iconControllers,
        isLandscape: isLandscape,
        onTap: onSlotTap,
      ),
    );
  }
}
