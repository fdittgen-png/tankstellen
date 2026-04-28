import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/app/routes/sync_routes.dart';

void main() {
  group('syncRoutes', () {
    test('returns exactly 4 routes', () {
      // Guards against accidental insert/delete — TankSync's four
      // optional screens must all stay registered.
      expect(syncRoutes.length, 4);
    });

    test('route 0 path is "/sync-setup"', () {
      final route = syncRoutes[0] as GoRoute;
      expect(route.path, '/sync-setup');
    });

    test('route 1 path is "/link-device"', () {
      final route = syncRoutes[1] as GoRoute;
      expect(route.path, '/link-device');
    });

    test('route 2 path is "/data-transparency"', () {
      final route = syncRoutes[2] as GoRoute;
      expect(route.path, '/data-transparency');
    });

    test('route 3 path is "/auth"', () {
      final route = syncRoutes[3] as GoRoute;
      expect(route.path, '/auth');
    });

    test('every entry is a GoRoute', () {
      for (var i = 0; i < syncRoutes.length; i++) {
        expect(
          syncRoutes[i],
          isA<GoRoute>(),
          reason: 'route $i should be a GoRoute',
        );
      }
    });

    test('every GoRoute has a non-null builder', () {
      for (var i = 0; i < syncRoutes.length; i++) {
        final route = syncRoutes[i] as GoRoute;
        expect(
          route.builder,
          isNotNull,
          reason: 'route $i (${route.path}) should have a non-null builder',
        );
      }
    });
  });
}
