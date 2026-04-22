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
      // After #757 retired the `_mapIncarnation` subtree-rebuild hack,
      // the controller is created once in initState and reused for the
      // lifetime of the widget. The declaration is `late final` again.
      expect(
        source.contains('late final MapController _mapController'),
        isTrue,
        reason: 'MapController should be late final, created in initState',
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
      '#757: MapScreen no longer relies on `_mapIncarnation` subtree-rebuild '
      'hack — retry+evict provider handles transient tile failures',
      () {
        final source = File(
          'lib/features/map/presentation/screens/map_screen.dart',
        ).readAsStringSync();

        // The `_mapIncarnation` counter + `ValueKey` KeyedSubtree wrapper
        // from #709 were symptom-level workarounds for `TileLayer`
        // caching failed fetches. They cancelled in-flight HTTP
        // requests on every tab-flip, which itself caused the gray
        // viewport some users reported (see #709 rollback history).
        // Root cause is addressed by `RetryNetworkTileProvider` +
        // `evictErrorTileStrategy` (#757), so these workarounds must
        // be gone.
        expect(
          source.contains('_mapIncarnation'),
          isFalse,
          reason: '#757 — subtree-rebuild counter should have been '
              'removed now that tile retries happen at the HTTP layer',
        );
        expect(
          source.contains('KeyedSubtree'),
          isFalse,
          reason: '#757 — KeyedSubtree wrapper no longer needed',
        );
      },
    );
  });
}
