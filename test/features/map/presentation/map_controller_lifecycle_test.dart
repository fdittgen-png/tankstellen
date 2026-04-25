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
      // The controller is reassigned on every Carte tab-flip rebuild
      // (see _mapIncarnation in the screen), so it cannot be `late
      // final` — it's `late MapController _mapController` and the
      // previous instance is disposed in the post-frame callback that
      // bumps the incarnation.
      expect(
        source.contains('late MapController _mapController'),
        isTrue,
        reason: 'MapController should be `late MapController` (mutable), '
            'created in initState and reassigned on tab-flip rebuild',
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
      '#473 / #498 / #709: MapScreen keeps the `_mapIncarnation` + '
      '`KeyedSubtree` tab-flip teardown — RetryNetworkTileProvider does '
      'NOT subsume it',
      () {
        final source = File(
          'lib/features/map/presentation/screens/map_screen.dart',
        ).readAsStringSync();

        // Earlier reasoning (in the ddeace4 commit message) was that
        // RetryNetworkTileProvider + evictErrorTileStrategy at the HTTP
        // layer would make this workaround redundant. They don't:
        //
        //   * Retry handles failed HTTP fetches.
        //   * The IndexedStack offstage-mount bug is a fetch that's
        //     never *issued* — TileLayer captures a zero-sized
        //     viewport on its first layout pass and settles into a
        //     "no tiles to fetch" state.
        //
        // The only reliable fix is to tear down + rebuild the
        // FlutterMap subtree when the Carte tab becomes visible so it
        // lays out against real constraints. Removing this guard
        // ships a gray map on first open (#473, #498, #709).
        expect(
          source.contains('_mapIncarnation'),
          isTrue,
          reason: 'subtree-rebuild counter is required to defeat the '
              'IndexedStack offstage zero-viewport bug — see screen '
              'docstring',
        );
        expect(
          source.contains('KeyedSubtree'),
          isTrue,
          reason: 'KeyedSubtree(ValueKey<int>(_mapIncarnation)) is what '
              'forces flutter_map teardown on tab-flip',
        );
        expect(
          source.contains('currentShellBranchProvider'),
          isTrue,
          reason: 'tab-flip rebuild is driven by listening to '
              'currentShellBranchProvider — the producer is in '
              'ShellScreen and must have a consumer here',
        );
      },
    );
  });
}
