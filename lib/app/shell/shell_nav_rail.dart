import 'package:flutter/material.dart';

import 'shell_nav_item.dart';

/// NavigationRail for medium and expanded screen sizes.
///
/// Shows labels and a wider rail on expanded screens (>= 840dp).
/// Shows an icons-only rail on medium screens (600-840dp).
///
/// Companion to [ShellBottomBar] — both consume the same
/// `(items, branchForSlot, currentIndex, iconControllers)` quad so the
/// parent shell can flip surfaces on resize without re-deriving any
/// state.
class ShellNavRail extends StatelessWidget {
  final List<ShellNavItem> items;

  /// Router-branch index for each visible slot. Used to index into the
  /// 5-wide [iconControllers] list when the Conso branch is hidden
  /// (#893) — the controllers stay aligned with the router branches,
  /// not the visible-slot positions.
  final List<int> branchForSlot;
  final int currentIndex;
  final List<AnimationController> iconControllers;
  final bool extended;
  final ValueChanged<int> onTap;

  const ShellNavRail({
    super.key,
    required this.items,
    required this.branchForSlot,
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
        final controller = iconControllers[branchForSlot[i]];
        return NavigationRailDestination(
          icon: ShellBounceIcon(
            controller: controller,
            selected: false,
            icon: item.outlinedIcon,
            iconSize: 24,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          selectedIcon: ShellBounceIcon(
            controller: controller,
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
