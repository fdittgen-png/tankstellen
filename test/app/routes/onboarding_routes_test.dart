import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/app/routes/onboarding_routes.dart';

void main() {
  group('onboardingRoutes', () {
    test('returns exactly 2 routes', () {
      // Guards against accidental insert/delete — the redirect logic
      // in the router relies on /consent and /setup being top-level.
      expect(onboardingRoutes.length, 2);
    });

    test('route 0 path is "/consent"', () {
      final route = onboardingRoutes[0] as GoRoute;
      expect(route.path, '/consent');
    });

    test('route 1 path is "/setup"', () {
      final route = onboardingRoutes[1] as GoRoute;
      expect(route.path, '/setup');
    });

    test('every entry is a GoRoute', () {
      for (var i = 0; i < onboardingRoutes.length; i++) {
        expect(
          onboardingRoutes[i],
          isA<GoRoute>(),
          reason: 'route $i should be a GoRoute',
        );
      }
    });

    test('every GoRoute has a non-null builder', () {
      for (var i = 0; i < onboardingRoutes.length; i++) {
        final route = onboardingRoutes[i] as GoRoute;
        expect(
          route.builder,
          isNotNull,
          reason: 'route $i (${route.path}) should have a non-null builder',
        );
      }
    });
  });
}
