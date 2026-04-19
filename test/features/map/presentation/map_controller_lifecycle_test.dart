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
      // MapScreen REASSIGNS the controller on tab-flip (#709 rebuild
      // fix), so the field is `late MapController` (non-final) and the
      // assertion now checks for the non-final declaration.
      expect(
        source.contains('late MapController _mapController'),
        isTrue,
        reason: 'MapController should be late (non-final), created in initState '
            'and replaced on tab-flip rebuild',
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
      'MapScreen rebuilds the FlutterMap subtree on every Carte tab-flip '
      '(regression #709 — zoom-nudge alone left blank tiles on first visit)',
      () {
        final source = File(
          'lib/features/map/presentation/screens/map_screen.dart',
        ).readAsStringSync();

        // The fix must (a) listen to currentShellBranchProvider, and
        // (b) use a ValueKey on a KeyedSubtree wrapping the body so
        // tab-flip destroys + rebuilds the TileLayer with fresh
        // constraints, and (c) dispose + recreate the MapController
        // so the old one isn't bound to the torn-down widget.
        expect(
          source.contains('currentShellBranchProvider'),
          isTrue,
          reason: 'MapScreen must observe tab flips via '
              'currentShellBranchProvider to rebuild on Carte visits (#709)',
        );
        expect(
          source.contains('KeyedSubtree'),
          isTrue,
          reason: 'MapScreen must wrap the map body in a KeyedSubtree so '
              'the tab-flip ValueKey forces a TileLayer rebuild (#709)',
        );
        expect(
          source.contains('_mapIncarnation'),
          isTrue,
          reason: 'Rebuild counter must exist so each tab-flip produces a '
              'distinct key (#709)',
        );
      },
    );
  });
}
