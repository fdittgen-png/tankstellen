import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/utils/frame_callbacks.dart';
import '../l10n/app_localizations.dart';

/// The main app shell with bottom navigation bar and page transitions.
///
/// ## Architecture:
/// go_router uses `StatefulShellRoute.indexedStack` which preserves each
/// tab's widget tree in memory (so scroll position, form data, etc. persist
/// when switching tabs). This widget wraps the shell with:
/// - Smooth slide+fade transition animations between tabs
/// - Horizontal swipe gesture for tab switching
/// - Bouncing icon animation on selection
/// - System navigation bar padding to avoid overlap with Android buttons
///
/// ## Navigation flow:
/// User taps tab → `_goToPage()` → plays animation → calls `goBranch()`
/// → go_router switches the visible branch → `navigationShell` renders new page
class ShellScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const ShellScreen({super.key, required this.navigationShell});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> with TickerProviderStateMixin {
  late final List<AnimationController> _iconControllers;
  late AnimationController _transitionController;
  late Animation<Offset> _slideInAnim;
  late Animation<double> _fadeAnim;

  int _currentIndex = 0;
  bool _isTransitioning = false;

  static const _pageCount = 4;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.navigationShell.currentIndex;

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
        }
      });
    }

    final l10n = AppLocalizations.of(context);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    final destinations = [
      _NavItem(Icons.search_outlined, Icons.search, l10n?.search ?? 'Search'),
      _NavItem(Icons.map_outlined, Icons.map, l10n?.map ?? 'Map'),
      _NavItem(Icons.star_outline, Icons.star, l10n?.favorites ?? 'Favorites'),
      _NavItem(Icons.settings_outlined, Icons.settings, l10n?.settings ?? 'Settings'),
    ];

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: _onHorizontalDragEnd,
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
      ),
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
    // Respect system navigation bar
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    final barHeight = (isLandscape ? 48.0 : 64.0) + bottomPadding;

    return Container(
      height: barHeight,
      padding: EdgeInsets.only(bottom: bottomPadding),
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
