// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/app/shell/search_fab_action_provider.dart';

/// Unit tests for [SearchFabActionController] (#2553).
///
/// The owner-token API (`setFor` / `clearFor`) is the third defence
/// layer against the central-FAB-dead-no-op bug: a screen registers its
/// action under itself as owner, so even when its dispose clearer never
/// fires (it was left mounted-but-offstage on a branch the user tabbed
/// away from), a LATER owner's registration supersedes the token and a
/// stale `clearFor` can never blank out the live FAB.
void main() {
  SearchFabAction action(String tooltip) => SearchFabAction(
        icon: Icons.search,
        tooltip: tooltip,
        onTap: () {},
      );

  group('SearchFabActionController owner-token API (#2553)', () {
    test('clearFor with a different owner leaves the action unchanged', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(searchFabActionControllerProvider.notifier);

      final ownerA = Object();
      final ownerB = Object();
      final a1 = action('A');

      notifier.setFor(ownerA, a1);
      expect(container.read(searchFabActionControllerProvider), same(a1));

      // A foreign owner cannot clear A's registration.
      notifier.clearFor(ownerB);
      expect(container.read(searchFabActionControllerProvider), same(a1),
          reason: 'a non-owner clearFor must be a no-op.');
    });

    test('clearFor with the owning token clears the action', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(searchFabActionControllerProvider.notifier);

      final ownerA = Object();
      notifier.setFor(ownerA, action('A'));
      notifier.clearFor(ownerA);
      expect(container.read(searchFabActionControllerProvider), isNull);
    });

    test('a stale owner cannot stomp the live one (the core invariant)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(searchFabActionControllerProvider.notifier);

      final ownerA = Object();
      final ownerB = Object();
      final a1 = action('A');
      final a2 = action('B');

      notifier.setFor(ownerA, a1);
      // B supersedes A as the live registrant.
      notifier.setFor(ownerB, a2);
      expect(container.read(searchFabActionControllerProvider), same(a2));

      // A late clearFor from the now-stale owner A must NOT blank the FAB.
      notifier.clearFor(ownerA);
      expect(container.read(searchFabActionControllerProvider), same(a2),
          reason: '#2553 — a stale owner can never clear the live action.');
    });

    test('clearFor when no owner is set is a harmless no-op', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(searchFabActionControllerProvider.notifier);

      notifier.clearFor(Object());
      expect(container.read(searchFabActionControllerProvider), isNull);
    });
  });

  group('SearchFabActionController legacy set / clearIf still work', () {
    test('set replaces the action; set(null) clears it', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(searchFabActionControllerProvider.notifier);

      final a1 = action('A');
      notifier.set(a1);
      expect(container.read(searchFabActionControllerProvider), same(a1));

      notifier.set(null);
      expect(container.read(searchFabActionControllerProvider), isNull);
    });

    test('clearIf only clears when the held action matches by identity', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(searchFabActionControllerProvider.notifier);

      final a1 = action('A');
      final a2 = action('B');
      notifier.set(a1);

      // A non-matching action does not clear.
      notifier.clearIf(a2);
      expect(container.read(searchFabActionControllerProvider), same(a1));

      // The matching instance clears.
      notifier.clearIf(a1);
      expect(container.read(searchFabActionControllerProvider), isNull);
    });

    test('set(null) drops a prior owner token so clearFor cannot resurrect',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(searchFabActionControllerProvider.notifier);

      final ownerA = Object();
      notifier.setFor(ownerA, action('A'));
      // A branch-change reset goes through set(null) — it must drop the
      // owner so the prior owner's clearFor is a no-op (#2553 layer 2+3).
      notifier.set(null);
      expect(container.read(searchFabActionControllerProvider), isNull);

      // ownerA is no longer the owner; a fresh registration is safe.
      final ownerB = Object();
      final b = action('B');
      notifier.setFor(ownerB, b);
      notifier.clearFor(ownerA);
      expect(container.read(searchFabActionControllerProvider), same(b),
          reason: 'set(null) must have cleared the stale owner token.');
    });
  });
}
