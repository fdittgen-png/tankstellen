// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/error_logger.dart';
import '../../core/telemetry/collectors/breadcrumb_collector.dart';
import '../../features/route_search/providers/route_search_provider.dart';
import '../../features/search/presentation/screens/search_criteria_screen.dart';
import '../../features/search/providers/search_provider.dart';
import '../routes/shell_branches.dart';

/// Centre-FAB tap routing for [ShellBottomBar], extracted to keep that widget
/// under the 400-line cap (#1680). The bar owns the look; this owns where a
/// tap goes (navigation + telemetry).

/// Push the search-criteria modal onto the **Search branch's** nested
/// Navigator (via [searchBranchNavigatorKey]) rather than the root one — the
/// root push covered the shell + bottom bar and hid the FAB mid-flow (#2131).
/// Switches to the Search branch first so the modal lands on the visible
/// branch.
/// Test seam (#3098) — the real criteria push, overridable in tests. The
/// production push builds [SearchCriteriaScreen], which needs Hive; a widget
/// test injects a no-op recorder to verify the post-frame retry wiring without
/// standing up Hive. Null in production.
@visibleForTesting
void Function(NavigatorState nav)? debugPushSearchCriteriaOverride;

void openSearchCriteriaOnBranch({
  required int slot,
  required int currentIndex,
  required ValueChanged<int> onTap,
}) {
  final switched = slot != currentIndex;
  if (switched) onTap(slot);
  final searchNav = searchBranchNavigatorKey.currentState;
  if (searchNav != null) {
    _pushSearchCriteria(searchNav, slot);
    return;
  }
  // #3098 — the Search branch's nested Navigator mounts LAZILY (go_router
  // `StatefulShellRoute.indexedStack`, preload off), so on the FIRST switch to
  // Search from another branch its key has no `currentState` THIS frame. The
  // old code degraded to a bare branch jump and the criteria modal never
  // opened. Instead: ensure we've switched, then push the modal once the
  // branch's navigator mounts on the NEXT frame. NEVER root-push from here —
  // `Navigator.of(the bar)` is the ROOT and a fullscreen route there covers
  // the whole shell incl. the bar (#2811).
  if (!switched) onTap(slot);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final nav = searchBranchNavigatorKey.currentState;
    if (nav == null) {
      // Still unmounted a frame after the switch — genuinely abnormal; trace
      // and bail (no root push).
      unawaited(errorLogger.log(
        ErrorLayer.ui,
        'search branch navigator still not mounted a frame after FAB switch '
            '— criteria not opened',
        StackTrace.current,
        context: {'source': 'openCriteriaOnSearchBranch', 'branch': slot},
      ));
      return;
    }
    _pushSearchCriteria(nav, slot);
  });
}

/// Push the criteria modal onto the (mounted) Search-branch [nav], guarding
/// against stacking a duplicate (#2810).
void _pushSearchCriteria(NavigatorState nav, int slot) {
  // #2810 — refuse to stack a duplicate criteria modal: the FAB stays visible
  // while it is open (branch-push keeps the shell mounted), so a repeat tap
  // would push a second copy ("search just re-opens the same form again and
  // again"). Bail if it is already current.
  if (searchCriteriaRouteIsCurrent(nav)) {
    // #2874 — re-tapping the FAB while the criteria sheet is already open is an
    // EXPECTED no-op, not a fault: a breadcrumb (not an ErrorLayer.ui trace)
    // so it attaches to any LATER genuine trace instead of standing alone.
    BreadcrumbCollector.add(
      'search criteria re-open suppressed (already current)',
      detail: 'openCriteriaOnSearchBranch branch=$slot',
    );
    return;
  }
  final override = debugPushSearchCriteriaOverride;
  if (override != null) {
    override(nav);
    return;
  }
  nav.push<void>(
    MaterialPageRoute<void>(
      builder: (_) => const SearchCriteriaScreen(),
      fullscreenDialog: true,
      settings: const RouteSettings(name: kSearchCriteriaRouteName),
    ),
  );
}

/// Default centre-FAB behaviour (#2113), the three-branch matrix:
///   1. On the Search branch → open the criteria modal to refine.
///   2. On another branch WITH live results → switch to Search.
///   3. On another branch with NO results → open criteria directly.
///
/// A registered [SearchFabAction] (resolved by the caller) wins over this; this
/// is only the fallback path.
void handleSearchFabDefaultTap({
  required WidgetRef ref,
  required int slot,
  required int currentIndex,
  required ValueChanged<int> onTap,
}) {
  // Defensive read: in widget tests without the search-state providers wired,
  // the reads can throw; fall back to the historical branch-switch so existing
  // tests keep passing and so the FAB never deadlocks on an unwired provider.
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
    onTap(slot);
    return;
  }
  final onSearchBranch = slot == currentIndex;
  if (onSearchBranch || !hasResults) {
    // Open criteria modal — refine (on Search) or start (no results).
    openSearchCriteriaOnBranch(
        slot: slot, currentIndex: currentIndex, onTap: onTap);
  } else {
    // Other tab, results exist → switch to Search branch.
    onTap(slot);
  }
}
