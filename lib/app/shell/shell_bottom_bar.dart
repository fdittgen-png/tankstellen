import 'package:flutter/material.dart';

import 'shell_nav_item.dart';

/// Compact-screen bottom navigation bar.
///
/// Sibling to [ShellNavRail]; the parent shell picks one based on
/// screen size. Shrinks the icon and drops the label row in landscape
/// to keep the bar from eating the body height on phones held
/// sideways.
class ShellBottomBar extends StatelessWidget {
  final List<ShellNavItem> items;

  /// Router-branch index for each visible slot (see rail comment, #893).
  final List<int> branchForSlot;
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
            final controller = iconControllers[branchForSlot[i]];

            return Expanded(
              child: Semantics(
                label: item.label,
                button: true,
                selected: selected,
                excludeSemantics: true,
                child: InkWell(
                  onTap: () => onTap(i),
                  splashColor:
                      theme.colorScheme.primary.withValues(alpha: 0.1),
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
                          style: TextStyle(
                            fontSize: selected ? 11 : 10,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
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
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
