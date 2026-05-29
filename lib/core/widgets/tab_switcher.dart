// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

/// One canonical tab row for the app.
///
/// Replaces the three hand-rolled `TabBar` implementations flagged in
/// the #923 audit (`ConsumptionScreen`, `FavoritesScreen`,
/// `CarbonDashboardScreen`). The visual contract is locked:
///
///   * underline indicator = `colorScheme.primary`, weight 3,
///   * selected label color = `colorScheme.primary`,
///   * unselected label color = `colorScheme.onSurfaceVariant`,
///   * label style = `textTheme.titleSmall` with `FontWeight.w600`,
///   * transparent `Material` host so the tab row adopts whatever
///     surface the caller provides (app bar, card header, …).
///
/// See `docs/design/DESIGN_SYSTEM.md` §"TabSwitcher".
class TabSwitcher extends StatelessWidget implements PreferredSizeWidget {
  /// Tabs to render. Each entry becomes one `Tab` widget with an
  /// optional leading icon + label.
  final List<TabSwitcherEntry> tabs;

  /// Optional explicit controller. When null the widget falls back
  /// to [DefaultTabController.of] — mirroring the standard [TabBar]
  /// behaviour.
  final TabController? controller;

  /// Whether the tab row scrolls horizontally instead of dividing
  /// the width equally. Default: false.
  final bool isScrollable;

  /// Mirrors [TabBar.onTap] so callers can respond to taps without
  /// owning a controller.
  final ValueChanged<int>? onTap;

  const TabSwitcher({
    super.key,
    required this.tabs,
    this.controller,
    this.isScrollable = false,
    this.onTap,
  });

  /// Compact single-row tab height. The default Material layout stacks
  /// the icon above the label (`Tab(icon:, text:)`) which renders ~72 dp
  /// tall (75 dp incl. the bottom divider). We lay icon + label out
  /// side-by-side instead (see [build]): each [Tab] is the text-only
  /// `kTextTabBarHeight` (46 dp) — still ≥ the 48 dp touch target once
  /// the indicator/divider is included — and the whole [TabBar] renders
  /// 49 dp. `preferredSize` is set to that measured 49 dp so an
  /// `AppBar.bottom:` host reserves exactly the right amount.
  static const double _compactHeight = kTextTabBarHeight + 1;

  @override
  Size get preferredSize => const Size.fromHeight(_compactHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
    );
    return Material(
      color: Colors.transparent,
      child: TabBar(
        controller: controller,
        isScrollable: isScrollable,
        onTap: onTap,
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
        indicatorColor: theme.colorScheme.primary,
        indicatorWeight: 3,
        labelStyle: labelStyle,
        unselectedLabelStyle: labelStyle,
        tabs: [
          for (final entry in tabs)
            Tab(
              // Compact single-row layout: icon beside the label rather
              // than Material's default stacked `icon:`/`text:` (which
              // renders ~72 dp tall). Colours/weight are intentionally
              // left unset so the surrounding `TabBar` theme drives the
              // selected ↔ unselected animation for both the Icon (via
              // IconTheme) and the Text (via DefaultTextStyle).
              child: Semantics(
                label: entry.semanticLabel ?? entry.label,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (entry.icon != null) ...[
                      Icon(entry.icon, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        entry.label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One entry in a [TabSwitcher].
class TabSwitcherEntry {
  /// Tab label. Rendered next to / below the optional [icon].
  final String label;

  /// Optional leading icon.
  final IconData? icon;

  /// Optional semantic label override for screen readers.
  final String? semanticLabel;

  const TabSwitcherEntry({
    required this.label,
    this.icon,
    this.semanticLabel,
  });
}
