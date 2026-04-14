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
        reason: 'MapScreen must dispose MapController to prevent stale references',
      );
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
        reason: 'InlineMap must dispose MapController to prevent stale references',
      );
      expect(
        source.contains('late final MapController _mapController'),
        isTrue,
        reason: 'MapController should be late final, created in initState',
      );
    });

    test('no MapController created as field initializer (must use initState)', () {
      final mapScreen = File(
        'lib/features/map/presentation/screens/map_screen.dart',
      ).readAsStringSync();
      final inlineMap = File(
        'lib/features/map/presentation/widgets/inline_map.dart',
      ).readAsStringSync();

      // Should NOT have `final _mapController = MapController()` as a field initializer
      expect(
        mapScreen.contains('final _mapController = MapController()'),
        isFalse,
        reason: 'MapController should be created in initState, not as field initializer',
      );
      expect(
        inlineMap.contains('final _mapController = MapController()'),
        isFalse,
        reason: 'MapController should be created in initState, not as field initializer',
      );
    });

    test(
      'MapScreen.initState schedules a post-frame controller nudge so the '
      'TileLayer recomputes visible bounds on first paint (regression #473)',
      () {
        final source = File(
          'lib/features/map/presentation/screens/map_screen.dart',
        ).readAsStringSync();

        // The fix must (a) hook a post-frame callback in initState,
        // (b) call _mapController.move(...) inside it, and (c) wrap
        // the move in a try/catch so the controller-not-attached path
        // does not throw.
        expect(
          source.contains('addPostFrameCallback'),
          isTrue,
          reason: 'MapScreen.initState must schedule a post-frame callback to '
              'nudge the MapController on first paint (#473)',
        );
        expect(
          source.contains('_mapController.move'),
          isTrue,
          reason: 'The post-frame callback must call MapController.move(...) '
              'so the TileLayer recomputes its visible bounds (#473)',
        );
        expect(
          source.contains('try {'),
          isTrue,
          reason: 'The nudge must be wrapped in try/catch — on the first '
              'frame the controller may not yet be attached to a FlutterMap',
        );
      },
    );
  });
}
