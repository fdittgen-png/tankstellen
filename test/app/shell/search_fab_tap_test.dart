// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/app/routes/shell_branches.dart';
import 'package:tankstellen/app/shell/search_fab_tap.dart';

import '../../helpers/silence_error_logger.dart';

/// #3098 — tapping the centre search FAB from another branch must OPEN the
/// search-criteria modal, not degrade to a bare branch jump. The Search
/// branch's nested Navigator mounts LAZILY (go_router indexedStack), so the
/// push has to wait until the branch navigator appears on the next frame.
void main() {
  silenceErrorLoggerSpool();

  tearDown(() => debugPushSearchCriteriaOverride = null);

  testWidgets(
      'pushes the criteria once the lazily-mounted Search-branch nav appears '
      'on the next frame (no degrade)', (tester) async {
    NavigatorState? pushedOn;
    // The real push builds SearchCriteriaScreen (needs Hive) — record instead.
    debugPushSearchCriteriaOverride = (nav) => pushedOn = nav;

    // Frame 1: the Search-branch Navigator is NOT mounted yet (its key has no
    // currentState) — exactly the lazy-branch state before its first visit.
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    expect(searchBranchNavigatorKey.currentState, isNull);

    // Tap the FAB from another branch (slot 0 = Search; currentIndex 2 = e.g.
    // Favorites). The nav is null THIS frame → the push must be DEFERRED.
    openSearchCriteriaOnBranch(slot: 0, currentIndex: 2, onTap: (_) {});
    expect(pushedOn, isNull, reason: 'push is deferred to post-frame, not sync');

    // The branch navigator mounts on the next frame (the switch took effect).
    await tester.pumpWidget(
      MaterialApp(
        home: Navigator(
          key: searchBranchNavigatorKey,
          onGenerateRoute: (_) =>
              MaterialPageRoute<void>(builder: (_) => const SizedBox.shrink()),
        ),
      ),
    );
    await tester.pump();

    expect(pushedOn, isNotNull,
        reason: 'criteria must push once the branch nav mounts — the old code '
            'degraded to a branch jump and never opened it');
    expect(pushedOn, same(searchBranchNavigatorKey.currentState));
  });

  testWidgets('pushes synchronously when the Search-branch nav is already '
      'mounted', (tester) async {
    NavigatorState? pushedOn;
    debugPushSearchCriteriaOverride = (nav) => pushedOn = nav;

    await tester.pumpWidget(
      MaterialApp(
        home: Navigator(
          key: searchBranchNavigatorKey,
          onGenerateRoute: (_) =>
              MaterialPageRoute<void>(builder: (_) => const SizedBox.shrink()),
        ),
      ),
    );

    openSearchCriteriaOnBranch(slot: 0, currentIndex: 2, onTap: (_) {});
    // Mounted nav → no post-frame wait needed.
    expect(pushedOn, isNotNull);
    expect(pushedOn, same(searchBranchNavigatorKey.currentState));
  });
}
