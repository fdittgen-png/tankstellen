import 'package:flutter/material.dart';

import 'shell_nav_item.dart';

/// Compact-screen bottom navigation bar (#1874).
///
/// The app's core action — Search — is rendered as a raised,
/// primary-tinted circular button in the centre; the other
/// destinations are flat tabs flanking it. Sibling to [ShellNavRail];
/// the parent shell picks one based on screen size.
///
/// In landscape the raised treatment is dropped (the bar is too short
/// to give the button head-room) and the label row is hidden, keeping
/// the bar from eating the body height on phones held sideways.
class ShellBottomBar extends StatelessWidget {
  final List<ShellNavItem> items;

  /// Router-branch index for each visible slot (see rail comment, #893).
  final List<int> branchForSlot;

  /// Selected visible slot, or `-1` when the active branch has no slot
  /// (e.g. the Settings/profile branch, reached from the app bar) — in
  /// which case no tab is highlighted.
  final int currentIndex;
  final List<AnimationController> iconControllers;
  final bool isLandscape;
  final ValueChanged<int> onTap;

  const ShellBottomBar({
    super.key,
    required this.items,
    required this.branchForSlot,
    required this.currentIndex,
    required this.iconControllers,
    required this.isLandscape,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final barHeight = isLandscape ? 48.0 : 64.0;
    // Portrait: the centre button rises into a transparent strip above
    // the coloured bar. Landscape keeps the bar flat — no head-room.
    final rise = isLandscape ? 0.0 : 20.0;

    final primaryIndex = items.indexWhere((i) => i.isPrimary);

    final bar = Container(
      height: barHeight,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Flat tabs left of the centre button.
          Expanded(
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  if (i < primaryIndex)
                    Expanded(child: _flatTab(context, i)),
              ],
            ),
          ),
          // Reserved gap the raised button straddles.
          const SizedBox(width: 76),
          // Flat tabs right of the centre button.
          Expanded(
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  if (i > primaryIndex)
                    Expanded(child: _flatTab(context, i)),
              ],
            ),
          ),
        ],
      ),
    );

    // #1697 — clamp text scaling so labels grow with the OS setting but
    // never past what the fixed-height bar can show.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: barHeight + rise,
          child: Stack(
            children: [
              // Coloured bar pinned to the bottom; the top `rise` strip
              // stays transparent so the button appears to float.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: bar,
              ),
              // Raised primary action, horizontally centred.
              if (primaryIndex >= 0)
                Align(
                  alignment: Alignment.topCenter,
                  child: _centerButton(context, primaryIndex),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// A flat side tab — bounce icon + (portrait only) label.
  Widget _flatTab(BuildContext context, int i) {
    final theme = Theme.of(context);
    final iconSize = isLandscape ? 20.0 : 24.0;
    final selected = i == currentIndex;
    final item = items[i];
    final controller = iconControllers[branchForSlot[i]];

    final inkWell = InkWell(
      onTap: () => onTap(i),
      splashColor: theme.colorScheme.primary.withValues(alpha: 0.1),
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShellBounceIcon(
            controller: controller,
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
              style: (theme.textTheme.labelMedium ?? const TextStyle())
                  .copyWith(
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );

    return Semantics(
      label: item.label,
      button: true,
      selected: selected,
      excludeSemantics: true,
      child: isLandscape
          ? Tooltip(message: item.label, child: inkWell)
          : inkWell,
    );
  }

  /// The raised, primary-tinted centre button for the core action.
  Widget _centerButton(BuildContext context, int i) {
    final theme = Theme.of(context);
    final selected = i == currentIndex;
    final item = items[i];
    final controller = iconControllers[branchForSlot[i]];
    final diameter = isLandscape ? 40.0 : 56.0;

    return Semantics(
      label: item.label,
      button: true,
      selected: selected,
      excludeSemantics: true,
      child: Tooltip(
        message: item.label,
        child: Material(
          color: theme.colorScheme.primary,
          shape: const CircleBorder(),
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.4),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => onTap(i),
            child: SizedBox(
              width: diameter,
              height: diameter,
              child: Center(
                child: ShellBounceIcon(
                  controller: controller,
                  selected: selected,
                  icon: selected ? item.filledIcon : item.outlinedIcon,
                  iconSize: isLandscape ? 22.0 : 28.0,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
