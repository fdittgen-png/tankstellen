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

  @override
  Size get preferredSize => const Size.fromHeight(kTextTabBarHeight);

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
              icon: entry.icon != null ? Icon(entry.icon) : null,
              text: entry.label,
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
