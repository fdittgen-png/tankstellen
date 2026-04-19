import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/utils/frame_callbacks.dart';
import '../features/profile/providers/profile_provider.dart';
import '../features/vehicle/providers/vehicle_providers.dart';
import '../l10n/app_localizations.dart';
import 'current_shell_branch_provider.dart';
import 'responsive_search_layout.dart';

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

class _ShellScreenState extends ConsumerState<ShellScreen> with TickerProviderStateMixin {
  late final List<AnimationController> _iconControllers;
  late AnimationController _transitionController;
  late Animation<Offset> _slideInAnim;
  late Animation<double> _fadeAnim;

  int _currentIndex = 0;
  bool _isTransitioning = false;

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
    ).animate(CurvedAnimation(parent: _transitionController, curve: Curves.easeOutCubic));
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

    if (velocity < 0 && _currentIndex < _pageCount - 1) {
      _goToPage(_currentIndex + 1);
    } else if (velocity > 0 && _currentIndex > 0) {
      _goToPage(_currentIndex - 1);
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
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    // Profile flag + vehicle presence decide whether the 5th tab
    // (#701) renders. The tab ALWAYS exists as a router branch so
    // deep links keep working; the UI just hides the nav entry when
    // the user hasn't opted in or has no vehicle yet.
    bool showConsumptionTab = false;
    try {
      final profile = ref.watch(activeProfileProvider);
      final vehicles = ref.watch(vehicleProfileListProvider);
      showConsumptionTab =
          (profile?.showConsumptionTab ?? false) && vehicles.isNotEmpty;
    } catch (e) {
      // Widget tests without a real Hive storage — treat as hidden.
      debugPrint('ShellScreen: consumption-tab visibility probe: $e');
    }

    final destinations = <_NavItem>[
      _NavItem(Icons.search_outlined, Icons.search, l10n?.search ?? 'Search'),
      _NavItem(Icons.map_outlined, Icons.map, l10n?.map ?? 'Map'),
      _NavItem(Icons.star_outline, Icons.star, l10n?.favorites ?? 'Favorites'),
      _NavItem(
        Icons.settings_outlined,
        Icons.settings,
        l10n?.settings ?? 'Settings',
      ),
      if (showConsumptionTab)
        _NavItem(
          Icons.local_gas_station_outlined,
          Icons.local_gas_station,
          l10n?.consumptionLogTitle ?? 'Consumption',
        ),
    ];

    final body = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: screenSize == ScreenSize.compact
          ? _onHorizontalDragEnd
          : null,
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
            _AdaptiveNavigationRail(
              items: destinations,
              currentIndex: _currentIndex,
              iconControllers: _iconControllers,
              extended: screenSize == ScreenSize.expanded,
              onTap: _goToPage,
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
      bottomNavigationBar: _AnimatedNavBar(
        items: destinations,
        currentIndex: _currentIndex,
        iconControllers: _iconControllers,
        isLandscape: isLandscape,
        onTap: _goToPage,
      ),
    );
  }
}

class _NavItem {
  final IconData outlinedIcon;
  final IconData filledIcon;
  final String label;
  const _NavItem(this.outlinedIcon, this.filledIcon, this.label);
}

/// NavigationRail for medium and expanded screen sizes.
///
/// Shows labels and wider rail on expanded screens (> 840dp).
/// Shows icons-only rail on medium screens (600-840dp).
class _AdaptiveNavigationRail extends StatelessWidget {
  final List<_NavItem> items;
  final int currentIndex;
  final List<AnimationController> iconControllers;
  final bool extended;
  final ValueChanged<int> onTap;

  const _AdaptiveNavigationRail({
    required this.items,
    required this.currentIndex,
    required this.iconControllers,
    required this.extended,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      extended: extended,
      minWidth: 56,
      minExtendedWidth: 180,
      labelType: extended
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.selected,
      selectedIconTheme: IconThemeData(color: theme.colorScheme.primary),
      unselectedIconTheme: IconThemeData(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      destinations: List.generate(items.length, (i) {
        final item = items[i];
        final selected = i == currentIndex;
        return NavigationRailDestination(
          icon: _BounceIcon(
            controller: iconControllers[i],
            selected: false,
            icon: item.outlinedIcon,
            iconSize: 24,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          selectedIcon: _BounceIcon(
            controller: iconControllers[i],
            selected: true,
            icon: item.filledIcon,
            iconSize: 24,
            color: theme.colorScheme.primary,
          ),
          label: Text(item.label),
          padding: EdgeInsets.symmetric(vertical: selected ? 4 : 0),
        );
      }),
    );
  }
}

class _AnimatedNavBar extends StatelessWidget {
  final List<_NavItem> items;
  final int currentIndex;
  final List<AnimationController> iconControllers;
  final bool isLandscape;
  final ValueChanged<int> onTap;

  const _AnimatedNavBar({
    required this.items,
    required this.currentIndex,
    required this.iconControllers,
    required this.isLandscape,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconSize = isLandscape ? 20.0 : 24.0;
    // #528 — wrap the bar in `SafeArea(top: false)` rather than
    // reading `MediaQuery.viewPadding.bottom` manually. SafeArea
    // *consumes* the inset, so no ancestor or descendant can
    // accidentally apply it a second time. Fixes the visible band
    // of empty space between the bottom nav and the Android gesture
    // bar on edge-to-edge devices (same class of bug as #520).
    final barHeight = isLandscape ? 48.0 : 64.0;

    return SafeArea(
      top: false,
      child: Container(
      height: barHeight,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final selected = i == currentIndex;
          final item = items[i];

          return Expanded(
            child: Semantics(
              label: item.label,
              button: true,
              selected: selected,
              excludeSemantics: true,
              child: InkWell(
              onTap: () => onTap(i),
              splashColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              highlightColor: Colors.transparent,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _BounceIcon(
                    controller: iconControllers[i],
                    selected: selected,
                    icon: selected ? item.filledIcon : item.outlinedIcon,
                    iconSize: iconSize,
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  if (!isLandscape) ...[
                    const SizedBox(height: 2),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: selected ? 11 : 10,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        color: selected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      child: Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ],
              ),
            ),
            ),
          );
        }),
      ),
      ),
    );
  }
}

class _BounceIcon extends StatelessWidget {
  final AnimationController controller;
  final bool selected;
  final IconData icon;
  final double iconSize;
  final Color color;

  const _BounceIcon({
    required this.controller,
    required this.selected,
    required this.icon,
    required this.iconSize,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.25).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.25, end: 0.95).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.95, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(controller);

    return AnimatedBuilder(
      animation: scaleAnim,
      builder: (context, child) {
        return Transform.scale(
          scale: scaleAnim.value,
          child: child,
        );
      },
      child: Icon(icon, size: iconSize, color: color),
    );
  }
}
