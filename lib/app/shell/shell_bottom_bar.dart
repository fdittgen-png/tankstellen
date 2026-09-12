// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notched_bar_border.dart';
import '../../core/navigation/search_fab_action_provider.dart';
import 'shell_nav_item.dart';
import 'dart:async';
import 'shell_bar_visibility.dart';
import 'shell_center_button.dart';

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
class ShellBottomBar extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final barHeight = isLandscape ? 48.0 : 64.0;
    // #4097 — swiped away: the tab surface slides out and the round
    // button stays put, revealing the strip of content the bar covered.
    // Landscape keeps its bar; the nav rail owns that case.
    final hidden = !isLandscape && ref.watch(shellBarHiddenProvider);
    final boxHeight = hidden ? (isLandscape ? 40.0 : 56.0) : barHeight;
    // #2113 — context-aware override registered by criteria / results
    // screens. Null means "default branch-switch behaviour".
    final fabAction = ref.watch(searchFabActionControllerProvider);
    // Portrait: the centre button docks into a concave notch carved into
    // the bar's top edge (see _centerButton, #2552). Landscape keeps the
    // bar flat — no head-room.

    final primaryIndex = items.indexWhere((i) => i.isPrimary);

    // #2552 — the FAB docks into a true concave notch (a
    // CircularNotchedRectangle scallop) cut into the bar's top edge. The
    // guest circle's radius is the FAB radius plus a small margin so the
    // bar surface curves up and embraces the button. Landscape stays flat:
    // notchRadius 0 → the border degenerates to a plain rectangle.
    const notchMargin = 6.0;
    final diameter = isLandscape ? 40.0 : 56.0;
    final notchRadius = isLandscape ? 0.0 : diameter / 2 + notchMargin;

    // Material both CLIPS the notch and casts a shadow that follows the
    // notched silhouette automatically (it derives its elevation shadow
    // from the ShapeBorder path), so no separate upward shadow painter is
    // needed.
    final bar = Material(
      color: theme.colorScheme.surfaceContainerHighest,
      elevation: theme.brightness == Brightness.dark ? 3 : 1,
      shadowColor: theme.brightness == Brightness.dark
          ? Colors.black.withValues(alpha: 0.3)
          : Colors.black.withValues(alpha: 0.12),
      shape: NotchedBarBorder(
        notchRadius: notchRadius,
        notchMargin: notchMargin,
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: barHeight,
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
            // Reserved gap the docked button straddles (≥ 2·notchRadius so
            // the tabs clear the notch walls).
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
      ),
    );

    // #1697 — clamp text scaling so labels grow with the OS setting but
    // never past what the fixed-height bar can show.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: SafeArea(
        top: false,
        // #4080 — the widget is exactly the coloured bar. It used to reserve
        // an extra `rise` strip above it for the protruding centre button,
        // which every tab body then stopped ABOVE: on the Map that was a
        // pale band between the map and the bar with the button sitting
        // half on nothing. The button's protrusion comes from the notch
        // geometry and the docked FAB location, not from reserved height —
        // bodies now run to the bar and the button floats over them.
        child: GestureDetector(
          // #4097 — a DRAG toggles; tap keeps its current meaning, so
          // nothing the user does today changes. Down hides, up shows,
          // and the target is the bar's full width, not a 56 dp circle.
          onVerticalDragEnd: (details) {
            final v = details.primaryVelocity ?? 0;
            if (v.abs() < 200) return;
            unawaited(
              ref.read(shellBarHiddenProvider.notifier).set(v > 0),
            );
          },
          child: AnimatedSize(
            duration: kShellBarHideDuration,
            curve: Curves.easeOutCubic,
            alignment: Alignment.bottomCenter,
        child: SizedBox(
          height: boxHeight,
            unawaited(
              ref.read(shellSwipeCoachSeenProvider.notifier).markSeen(),
            );
          child: Stack(
            children: [
              // Coloured bar pinned to the bottom; the docked centre button
              // protrudes `rise` above the notch carved into its top edge
              // (#2552).
              // The tab surface: slid fully below the fold when hidden and
              // made inert, so no tab can be tapped or read through it.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AnimatedSlide(
                  offset: Offset(0, hidden ? 1 : 0),
                  duration: kShellBarHideDuration,
                  curve: Curves.easeOutCubic,
                  child: IgnorePointer(
                    key: const Key('shell_bar_surface'),
                    ignoring: hidden,
                    child: ExcludeSemantics(
                      key: const Key('shell_bar_surface_semantics'),
                      excluding: hidden,
                      child: bar,
                    ),
                  ),
                ),
              ),
              // Raised primary action, horizontally centred.
              if (primaryIndex >= 0)
                Align(
                  alignment:
                      hidden ? Alignment.bottomCenter : Alignment.topCenter,
                  child: ShellCenterButton(
                    items: items,
                    slot: primaryIndex,
                    currentIndex: currentIndex,
                    iconControllers: iconControllers,
                    branchForSlot: branchForSlot,
                    isLandscape: isLandscape,
                    onTap: onTap,
                    action: fabAction,
                  ),
                ),
            ],
          ),
            ),
          ),
              // #4106 — introduce the gesture once, over the bar it acts
              // on. Never while the bar is already hidden: the user has
              // plainly found it.
              if (!hidden && !ref.watch(shellSwipeCoachSeenProvider))
                ShellSwipeCoachMark(
                  barHeight: barHeight,
                  onDismiss: () => unawaited(
                    ref.read(shellSwipeCoachSeenProvider.notifier).markSeen(),
                  ),
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

    // #2117 — M3 hides inactive-tab labels at narrow widths so the
    // active tab gets the breathing room. The shell can show up to 5
    // labels flanking a 76-dp centre gap; below ~360 dp each label
    // gets <50 dp and starts truncating. Hide on inactive only — the
    // active tab keeps its label so the user always sees what's
    // selected.
    final width = MediaQuery.sizeOf(context).width;
    final showLabel = !isLandscape && (selected || width >= 360);

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
          if (showLabel) ...[
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
}