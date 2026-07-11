// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notched_bar_border.dart';
import '../../core/navigation/search_fab_action_provider.dart';
import 'search_fab_tap.dart';
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
    // #2113 — context-aware override registered by criteria / results
    // screens. Null means "default branch-switch behaviour".
    final fabAction = ref.watch(searchFabActionControllerProvider);
    // Portrait: the centre button docks into a concave notch carved into
    // the bar's top edge (see _centerButton, #2552). Landscape keeps the
    // bar flat — no head-room.
    final rise = isLandscape ? 0.0 : 24.0;

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
        child: SizedBox(
          height: barHeight + rise,
          child: Stack(
            children: [
              // Coloured bar pinned to the bottom. The top `rise` strip
              // is where the docked centre button protrudes above the
              // notch carved into the bar's top edge (#2552).
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
                  child: _centerButton(context, primaryIndex, fabAction, ref),
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

    // #2117 — M3 hides inactive-tab labels at narrow widths so the
    // active tab gets the breathing room. The shell can show up to 5
    // labels flanking a 76-dp centre gap; below ~360 dp each label
    // gets <50 dp and starts truncating. Hide on inactive only — the
    // active tab keeps its label so the user always sees what's
    // selected.
    final width = MediaQuery.of(context).size.width;
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

  /// The raised, primary-tinted centre button for the core action.
  ///
  /// Portrait (#2552): the button docks into a concave notch carved into
  /// the bar's top edge (a CircularNotchedRectangle scallop, painted by
  /// the bar's [NotchedBarBorder] shape). The notch IS the seat — the bar
  /// surface curves up and embraces the button instead of a flat disc
  /// sitting behind it. Landscape has no head-room, so the button stays
  /// flat in the bar.
  Widget _centerButton(
      BuildContext context, int i, SearchFabAction? action, WidgetRef ref) {
    final theme = Theme.of(context);
    final selected = i == currentIndex;
    final item = items[i];
    final controller = iconControllers[branchForSlot[i]];
    final diameter = isLandscape ? 40.0 : 56.0;

    // #2113 — context-aware FAB. Default reads stay safe (no `watch`
    // here so a results refresh doesn't re-paint the whole bar) —
    // the read happens lazily inside `onTap`, when it matters.
    //
    // Behaviour matrix:
    //   1. On the Search branch (results screen): tap → open the
    //      criteria modal so the user can refine the active search.
    //   2. On any other branch WITH live results: tap → switch to
    //      the Search branch and show the existing results.
    //   3. On any other branch with NO results: tap → open the
    //      criteria modal directly so the user can start a search
    //      from anywhere (no detour through an empty results screen).
    //
    // A registered [SearchFabAction] (e.g. from a future criteria-
    // screen "fire search" hook) wins over all three branches —
    // pluggable extension point.
    final defaultIcon = selected ? item.filledIcon : item.outlinedIcon;
    final iconData = action?.icon ?? defaultIcon;
    final tooltipLabel = action?.tooltip ?? item.label;
    // #2131 — disabled override: dim the icon when the current
    // registrant says the action isn't ready (e.g. route tab with no
    // destination). Null action ⇒ default branch behaviour, always
    // enabled.
    // #2553 — the dim is contextual *affordance only* now; a disabled
    // (or stale) action no longer swallows the tap — see [onTapHandler].
    final actionEnabled = action?.enabled ?? true;

    // #2553 — a registered-but-DISABLED (or stale) action must never
    // produce a dead `() {}` no-op. Only an enabled action overrides the
    // tap; anything else (null OR disabled OR stale) FALLS BACK to the
    // default branch behaviour (#2113 three-branch matrix, implemented in
    // search_fab_tap.dart). Worst case the FAB opens criteria / jumps to
    // Search — it can never become a permanent dead hit-target.
    final onTapHandler = (action != null && actionEnabled)
        ? action.onTap
        : () => handleSearchFabDefaultTap(
              ref: ref,
              slot: i,
              currentIndex: currentIndex,
              onTap: onTap,
            );

    // #2131 — surface + icon both dim when the registered action is
    // disabled, mirroring Material's standard disabled-button look.
    final buttonColor = actionEnabled
        ? theme.colorScheme.primary
        : theme.colorScheme.primary.withValues(alpha: 0.38);
    final iconColor = actionEnabled
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onPrimary.withValues(alpha: 0.6);

    // #3548 — the app's heart must not read as a flat disc. Three layers
    // of depth, all derived from the theme so light/dark/eco stay
    // coherent:
    //   * a hairline surface-coloured ring in the CircleBorder side —
    //     a crisp seat separating the button from whatever scrolls
    //     beneath the notch;
    //   * a top-light gradient over the primary fill (painted by an Ink
    //     so the ripple stays above it) — the dome that makes the disc
    //     read as raised;
    //   * a soft primary-tinted glow under the Material's own key
    //     shadow — the professional "lifted" halo.
    // Disabled keeps the flat dimmed fill (no dome on a dead control).
    final ringColor = theme.colorScheme.surface;
    final gradient = actionEnabled
        ? LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(buttonColor, Colors.white, 0.22)!,
              buttonColor,
              Color.lerp(buttonColor, Colors.black, 0.14)!,
            ],
            stops: const [0.0, 0.55, 1.0],
          )
        : null;

    final button = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: actionEnabled
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.30),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : const [],
      ),
      child: Material(
        color: buttonColor,
        shape: CircleBorder(
          side: BorderSide(color: ringColor, width: isLandscape ? 2 : 2.5),
        ),
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: gradient),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTapHandler,
            child: SizedBox(
              width: diameter,
              height: diameter,
              child: Center(
                child: action != null
                    ? Icon(
                        iconData,
                        size: isLandscape ? 22.0 : 28.0,
                        color: iconColor,
                      )
                    : ShellBounceIcon(
                        controller: controller,
                        selected: selected,
                        icon: iconData,
                        iconSize: isLandscape ? 22.0 : 28.0,
                        color: iconColor,
                      ),
              ),
            ),
          ),
        ),
      ),
    );

    return Semantics(
      label: tooltipLabel,
      button: true,
      selected: selected,
      excludeSemantics: true,
      // #2552 — the notch in the bar (the [NotchedBarBorder] shape) is
      // the seat now, for both orientations; no separate cradle disc.
      child: Tooltip(
        message: tooltipLabel,
        child: button,
      ),
    );
  }
}
