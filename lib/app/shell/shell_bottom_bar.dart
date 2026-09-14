// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notched_bar_border.dart';
import '../../core/navigation/search_fab_action_provider.dart';
import 'shell_nav_item.dart';
import 'dart:async';
import 'shell_bar_collapse.dart';
import 'shell_bar_double_tap.dart';
import 'shell_bar_visibility.dart';
import 'shell_center_button.dart';
import 'shell_swipe_coach_mark.dart';

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
    // #4168 — both ENDS of the collapse, so every property below can be
    // a function of one progress value instead of a set of independent
    // implicit animations that were free to disagree with each other.
    final collapsedBoxHeight = isLandscape ? 40.0 : 56.0;
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
        child: ShellBarCollapse(
          // #4169 — the finger drives the progress directly, and the
          // bar's own height is the distance that covers the whole
          // travel: the control moves at roughly life size, which is
          // what makes it feel pulled rather than triggered.
          dragExtent: barHeight,
          enabled: !isLandscape,
          builder: (context, t) => _frame(
            context: context,
            ref: ref,
            t: t,
            hidden: hidden,
            bar: bar,
            barHeight: barHeight,
            collapsedBoxHeight: collapsedBoxHeight,
            diameter: diameter,
            primaryIndex: primaryIndex,
            fabAction: fabAction,
          ),
        ),
      ),
    );
  }

  /// One frame of the collapse, at progress [t] (0 expanded, 1 hidden).
  ///
  /// #4168 — what used to be here was an `AnimatedSize`, an
  /// `AnimatedSlide` and, fatally, a plain `Align` whose alignment
  /// flipped between `topCenter` and `bottomCenter`. `Align` is not
  /// `AnimatedAlign`, so the button JUMPED to its new seat on the first
  /// frame and then sat still while everything around it animated for
  /// the remaining 219 ms.
  ///
  /// #4169 — and the split that makes driving this from a finger
  /// affordable. `PageScaffold` watches the same preference and
  /// collapses the TOP app bar with it on 44 screens, so a box height
  /// that followed `t` would relayout map, lists and charts on every
  /// frame of every swipe. Chrome is continuous; LAYOUT is quantised:
  /// the reserved height takes the expanded value for the whole gesture
  /// and only drops at the far end, where the surface has already gone
  /// and nothing is drawn in the difference.
  Widget _frame({
    required BuildContext context,
    required WidgetRef ref,
    required double t,
    required bool hidden,
    required Widget bar,
    required double barHeight,
    required double collapsedBoxHeight,
    required double diameter,
    required int primaryIndex,
    required SearchFabAction? fabAction,
  }) {
    // Two values across a whole drag, and never a third. See the class
    // note above: this is the number every body in the app reads as
    // `MediaQuery.padding.bottom`.
    final boxHeight = t >= 1 ? collapsedBoxHeight : barHeight;
    // The button's seat, measured from the box's bottom edge — which is
    // pinned to the safe-area inset and does not move. Expanded it sits
    // in the notch at the bar's top edge; collapsed it rests on the
    // floor. Eight logical pixels, and the whole point is that they are
    // TRAVELLED rather than skipped.
    final buttonBottom = lerpDouble(barHeight - diameter, 0, t)!;
    // The surface CONTRACTS rather than sliding out from under the
    // button. Sliding is the cheap version and it reads as a drawer
    // leaving; contracting reads as the control changing shape around
    // the one part of it that stays.
    final surfaceFactor = (1 - t).clamp(0.0, 1.0);
    // Contents go before the surface does, so the bar never reaches its
    // last few pixels still carrying legible labels.
    final contentOpacity = (1 - t / 0.7).clamp(0.0, 1.0);
    return SizedBox(
      height: boxHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // The tab surface, made inert once hidden so no tab can be
          // tapped or read through it.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRect(
              child: Align(
                alignment: Alignment.bottomCenter,
                heightFactor: surfaceFactor,
                child: Opacity(
                  opacity: contentOpacity,
                  child: IgnorePointer(
                    key: const Key('shell_bar_surface'),
                    ignoring: hidden,
                    child: ExcludeSemantics(
                      key: const Key('shell_bar_surface_semantics'),
                      excluding: hidden,
                      // #4107 — a double-tap on the bar toggles it away.
                      // Scoped to the tab surface on purpose: the round
                      // button is NOT a descendant, so the primary
                      // search action keeps its zero-delay tap (see the
                      // class doc for the 300 ms arena hold this
                      // avoids).
                      child: ShellBarDoubleTap(
                        onDoubleTap: () => unawaited(
                          ref
                              .read(shellBarHiddenProvider.notifier)
                              .set(!hidden),
                        ),
                        child: bar,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // #4106 — introduce the gesture once, over the bar it acts on.
          // Never while the bar is already hidden: the user has plainly
          // found it.
          if (!hidden && !ref.watch(shellSwipeCoachSeenProvider))
            ShellSwipeCoachMark(
              barHeight: barHeight,
              onDismiss: () => unawaited(
                ref.read(shellSwipeCoachSeenProvider.notifier).markSeen(),
              ),
            ),
          // The raised primary action. Horizontally centred and
          // vertically CONTINUOUS — this is the anchor the eye follows
          // through the whole transition.
          if (primaryIndex >= 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: buttonBottom,
              child: Align(
                child: ShellCenterButton(
                  items: items,
                  slot: primaryIndex,
                  currentIndex: currentIndex,
                  iconControllers: iconControllers,
                  branchForSlot: branchForSlot,
                  isLandscape: isLandscape,
                  onTap: onTap,
                  action: fabAction,
                  collapseProgress: t,
                ),
              ),
            ),
        ],
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