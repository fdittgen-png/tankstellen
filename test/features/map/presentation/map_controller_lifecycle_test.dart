// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MapController lifecycle regression', () {
    test('MapScreen disposes MapController', () {
      final source = File(
        'lib/features/map/presentation/screens/map_screen.dart',
      ).readAsStringSync();

      expect(
        source.contains('_mapController.dispose()'),
        isTrue,
        reason:
            'MapScreen must dispose MapController to prevent stale references',
      );
      // #1605 — the structural viewport gate replaced the per-tab-flip
      // controller swap. There is now exactly one controller for the
      // lifetime of the State, so it is `late final` (created in
      // initState, never reassigned).
      expect(
        source.contains('late final MapController _mapController'),
        isTrue,
        reason: 'MapController should be `late final` — created once in '
            'initState, never reassigned (the incarnation controller-swap '
            'was removed by the #1605 structural gate)',
      );
    });

    test('InlineMap disposes MapController', () {
      final source = File(
        'lib/features/map/presentation/widgets/inline_map.dart',
      ).readAsStringSync();

      expect(
        source.contains('_mapController.dispose()'),
        isTrue,
        reason:
            'InlineMap must dispose MapController to prevent stale references',
      );
      expect(
        source.contains('late final MapController _mapController'),
        isTrue,
        reason: 'MapController should be late final, created in initState',
      );
    });

    test('no MapController created as field initializer (must use initState)',
        () {
      final mapScreen = File(
        'lib/features/map/presentation/screens/map_screen.dart',
      ).readAsStringSync();
      final inlineMap = File(
        'lib/features/map/presentation/widgets/inline_map.dart',
      ).readAsStringSync();

      // Should NOT have `final _mapController = MapController()` as a field
      // initializer — must be created in initState.
      expect(
        mapScreen.contains('final _mapController = MapController()'),
        isFalse,
        reason:
            'MapController should be created in initState, not as field initializer',
      );
      expect(
        inlineMap.contains('final _mapController = MapController()'),
        isFalse,
        reason:
            'MapController should be created in initState, not as field initializer',
      );
    });

    test(
      '#1605: MapScreen gates the map subtree on currentShellBranchProvider '
      '— the structural cure for the #473-#1316 grey-tile patch-pile',
      () {
        final source = File(
          'lib/features/map/presentation/screens/map_screen.dart',
        ).readAsStringSync();

        // The IndexedStack offstage-mount bug is a tile fetch that is
        // never *issued* — TileLayer captures a zero-sized viewport on
        // its first layout pass while the Carte branch is offstage. The
        // structural fix is to never build the FlutterMap subtree until
        // Carte is the visible shell branch, so the first layout pass
        // always runs against real onstage constraints. This replaces
        // the incarnation controller-swap, the cold-start one-shot bump,
        // the delayed retry-bump and the `< 100`px LayoutBuilder gate.
        expect(
          source.contains('currentShellBranchProvider'),
          isTrue,
          reason: 'the map subtree must be gated on the visible shell '
              'branch — the producer is in ShellScreen',
        );
        expect(
          source.contains('_mapIncarnation'),
          isFalse,
          reason: 'the incarnation controller-swap was removed by #1605 — '
              'the structural gate makes it redundant',
        );
        expect(
          source.contains('_retryBumpTimer') ||
              source.contains('_scheduleDelayedRetryBump'),
          isFalse,
          reason: 'the defensive retry-bump timer was removed by #1605',
        );
      },
    );
  });
}
