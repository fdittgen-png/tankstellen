import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/app/routes/search_routes.dart';

void main() {
  group('searchRoutes', () {
    test('returns exactly 3 routes', () {
      // Guards against accidental insert/delete — the search-adjacent
      // flow expects all three push-on-shell screens to be registered.
      // (#1706 removed the unused `/search/criteria` route — the
      // SearchCriteriaScreen is reached via a MaterialPageRoute.)
      expect(searchRoutes.length, 3);
    });

    test('route 0 path is "/driving"', () {
      final route = searchRoutes[0] as GoRoute;
      expect(route.path, '/driving');
    });

    test('route 1 path is "/alerts"', () {
      final route = searchRoutes[1] as GoRoute;
      expect(route.path, '/alerts');
    });

    test('route 2 path is "/calculator"', () {
      final route = searchRoutes[2] as GoRoute;
      expect(route.path, '/calculator');
    });

    test('every entry is a GoRoute', () {
      for (var i = 0; i < searchRoutes.length; i++) {
        expect(
          searchRoutes[i],
          isA<GoRoute>(),
          reason: 'route $i should be a GoRoute',
        );
      }
    });

    test('every GoRoute has a non-null builder', () {
      for (var i = 0; i < searchRoutes.length; i++) {
        final route = searchRoutes[i] as GoRoute;
        expect(
          route.builder,
          isNotNull,
          reason: 'route $i (${route.path}) should have a non-null builder',
        );
      }
    });
  });
}
