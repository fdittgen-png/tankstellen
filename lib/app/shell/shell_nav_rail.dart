// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import 'shell_nav_item.dart';

/// NavigationRail for medium and expanded screen sizes.
///
/// A compact rail with each label UNDER its icon ([NavigationRailLabelType.all])
/// at both sizes (#3056) — the old `extended` horizontal-label rail wasted
/// ~100px of width the results column + map needed on wide/tablet layouts.
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

  /// Selected visible slot, or `null` when the active branch has no
  /// slot (the Settings/profile branch, reached from the app bar).
  final int? currentIndex;
  final List<AnimationController> iconControllers;
  final ValueChanged<int> onTap;

  const ShellNavRail({
    super.key,
    required this.items,
    required this.branchForSlot,
    required this.currentIndex,
    required this.iconControllers,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      // #3056 — a COMPACT rail (every label UNDER its icon) on every wide
      // layout, instead of the old `extended` horizontal-label rail (~180px)
      // that wasted ~100px the results column + map needed. Keeps all labels
      // (discoverable) at roughly half the width.
      minWidth: 80,
      labelType: NavigationRailLabelType.all,
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
