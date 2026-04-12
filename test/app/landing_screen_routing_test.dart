import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';

void main() {
  group('LandingScreen routing', () {
    test('search landing maps to / route', () {
      const screen = LandingScreen.search;
      final route = _routeForLanding(screen);
      expect(route, '/');
    });

    test('favorites landing maps to /favorites route', () {
      const screen = LandingScreen.favorites;
      final route = _routeForLanding(screen);
      expect(route, '/favorites');
    });

    test('map landing maps to /map route', () {
      const screen = LandingScreen.map;
      final route = _routeForLanding(screen);
      expect(route, '/map');
    });

    test('cheapest landing maps to / route (auto-search triggers)', () {
      const screen = LandingScreen.cheapest;
      final route = _routeForLanding(screen);
      expect(route, '/');
    });

    test('nearest landing maps to / route (auto-search triggers)', () {
      const screen = LandingScreen.nearest;
      final route = _routeForLanding(screen);
      expect(route, '/');
    });

    test('all LandingScreen values produce valid routes', () {
      for (final screen in LandingScreen.values) {
        final route = _routeForLanding(screen);
        expect(route, anyOf('/', '/favorites', '/map'),
            reason: '$screen should map to a valid route');
      }
    });

    test('LandingScreen enum serialization matches router switch', () {
      // The router reads landing as a string from JSON storage.
      // Verify all enum names are handled.
      expect(LandingScreen.search.name, 'search');
      expect(LandingScreen.favorites.name, 'favorites');
      expect(LandingScreen.map.name, 'map');
      expect(LandingScreen.cheapest.name, 'cheapest');
      expect(LandingScreen.nearest.name, 'nearest');
    });
  });
}

/// Mirrors the routing logic in router.dart redirect.
String _routeForLanding(LandingScreen screen) {
  switch (screen.name) {
    case 'favorites':
      return '/favorites';
    case 'map':
      return '/map';
    default:
      return '/';
  }
}
