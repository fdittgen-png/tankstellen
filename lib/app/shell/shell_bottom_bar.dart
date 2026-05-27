// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/route_search/providers/route_search_provider.dart';
import '../../features/search/presentation/screens/search_criteria_screen.dart';
import '../../features/search/providers/search_provider.dart';
import '../routes/shell_branches.dart';
import 'search_fab_action_provider.dart';
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
    // Portrait: the centre button rises into a bar-coloured cradle (see
    // _centerButton, #1885). Landscape keeps the bar flat — no head-room.
    final rise = isLandscape ? 0.0 : 24.0;

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
              // Coloured bar pinned to the bottom. The top `rise` strip
              // is where the centre button's cradle protrudes (#1885).
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
  /// Portrait (#1885): the button is seated in a circular *cradle* in
  /// the bar's own surface colour. The cradle's lower half overlaps the
  /// flat bar — same colour, so the seam vanishes — and its upper half
  /// protrudes into the `rise` strip, so the bar appears to rise up and
  /// embrace the button rather than the button floating on top of it.
  /// Landscape has no head-room, so the button stays flat in the bar.
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
    // #2131 — disabled override: dim the icon + swallow taps when the
    // current registrant says the action isn't ready (e.g. route tab
    // with no destination). Null action ⇒ default branch behaviour,
    // always enabled.
    final actionEnabled = action == null || action.enabled;

    // #2131 — push the criteria modal onto the **Search branch's**
    // nested Navigator (via [searchBranchNavigatorKey]) instead of the
    // root one. The root push covered the shell + bottom bar, hiding
    // the FAB mid-flow; the branch push keeps the shell visible.
    // Switching to the Search branch first ensures the criteria
    // modal appears on the currently-displayed branch.
    void openCriteriaOnSearchBranch() {
      if (i != currentIndex) onTap(i);
      final searchNav = searchBranchNavigatorKey.currentState;
      if (searchNav != null) {
        searchNav.push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const SearchCriteriaScreen(),
            fullscreenDialog: true,
          ),
        );
      } else {
        // Defensive fallback for environments where the branch nav
        // isn't mounted yet (very early frame, widget tests without
        // the shell wired). Use the local context's Navigator.
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const SearchCriteriaScreen(),
            fullscreenDialog: true,
          ),
        );
      }
    }

    void defaultOnTap() {
      // Defensive read: in widget tests without the search-state
      // providers wired, the reads can throw; fall back to the
      // historical branch-switch so existing tests keep passing
      // and so the FAB never deadlocks on an unwired provider.
      bool hasResults;
      try {
        final hasFuelResults = ref.read(searchStateProvider).when(
              data: (r) => r.data.isNotEmpty,
              loading: () => false,
              error: (_, _) => false,
            );
        final hasRouteResults = ref.read(routeSearchStateProvider).when(
              data: (r) => r != null,
              loading: () => false,
              error: (_, _) => false,
            );
        hasResults = hasFuelResults || hasRouteResults;
      } catch (_) {
        onTap(i);
        return;
      }
      final onSearchBranch = i == currentIndex;
      if (onSearchBranch || !hasResults) {
        // Open criteria modal — refine (on Search) or start (no results).
        openCriteriaOnSearchBranch();
      } else {
        // Other tab, results exist → switch to Search branch.
        onTap(i);
      }
    }

    final onTapHandler = action != null
        ? (actionEnabled ? action.onTap : () {})
        : defaultOnTap;

    // #2131 — surface + icon both dim when the registered action is
    // disabled, mirroring Material's standard disabled-button look.
    final buttonColor = actionEnabled
        ? theme.colorScheme.primary
        : theme.colorScheme.primary.withValues(alpha: 0.38);
    final iconColor = actionEnabled
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onPrimary.withValues(alpha: 0.6);

    final button = Material(
      color: buttonColor,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.4),
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
    );

    return Semantics(
      label: tooltipLabel,
      button: true,
      selected: selected,
      excludeSemantics: true,
      child: Tooltip(
        message: tooltipLabel,
        child: isLandscape
            ? button
            : Stack(
                alignment: Alignment.center,
                children: [
                  // Bar-coloured cradle — blends into the bar where it
                  // overlaps, protrudes as a soft bump above it.
                  Container(
                    width: diameter + 20,
                    height: diameter + 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.surfaceContainerHighest,
                      boxShadow: [
                        BoxShadow(
                          color: theme.brightness == Brightness.dark
                              ? Colors.black.withValues(alpha: 0.4)
                              : Colors.black.withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  button,
                ],
              ),
      ),
    );
  }
}
