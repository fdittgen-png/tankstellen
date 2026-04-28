import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/app/routes/shell_branches.dart';

void main() {
  group('shellBranches', () {
    test('returns exactly 5 branches', () {
      // Guards against accidental reorder/insert — the bottom-nav
      // depends on this length matching the destinations list.
      expect(shellBranches.length, 5);
    });

    test('branch 0 route path is "/"', () {
      final route = shellBranches[0].routes.single as GoRoute;
      expect(route.path, '/');
    });

    test('branch 1 route path is "/map"', () {
      final route = shellBranches[1].routes.single as GoRoute;
      expect(route.path, '/map');
    });

    test('branch 2 route path is "/favorites"', () {
      final route = shellBranches[2].routes.single as GoRoute;
      expect(route.path, '/favorites');
    });

    test('branch 3 route path is "/consumption-tab" (#778)', () {
      // Explicit assertion: the consumption tab MUST live at
      // `/consumption-tab`. The bare `/consumption` path is reserved
      // for the deep link that pushes on top of the current branch
      // (e.g. from station detail). Collapsing them would break the
      // tab-preserving navigation behaviour described in #778.
      final route = shellBranches[3].routes.single as GoRoute;
      expect(route.path, '/consumption-tab');
      expect(route.path, isNot('/consumption'));
    });

    test('branch 4 route path is "/profile"', () {
      final route = shellBranches[4].routes.single as GoRoute;
      expect(route.path, '/profile');
    });

    test('every branch has exactly one route', () {
      for (var i = 0; i < shellBranches.length; i++) {
        expect(
          shellBranches[i].routes.length,
          1,
          reason: 'branch $i should have exactly one route',
        );
      }
    });

    test('every branch route is a GoRoute', () {
      for (var i = 0; i < shellBranches.length; i++) {
        expect(
          shellBranches[i].routes.single,
          isA<GoRoute>(),
          reason: 'branch $i route should be a GoRoute',
        );
      }
    });

    test('every branch route has a non-null builder', () {
      for (var i = 0; i < shellBranches.length; i++) {
        final route = shellBranches[i].routes.single as GoRoute;
        expect(
          route.builder,
          isNotNull,
          reason: 'branch $i GoRoute should have a non-null builder',
        );
      }
    });
  });
}
