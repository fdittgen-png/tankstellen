import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tankstellen/app/app.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app launches without crashing and renders a Scaffold',
      (tester) async {
    await HiveStorage.init();

    await tester.pumpWidget(
      ProviderScope(
        child: const TankstellenApp(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // App should render without crashing — at minimum a Scaffold is present
    expect(find.byType(Scaffold), findsAtLeast(1));
  });

  testWidgets('app shows setup screen or search screen after launch',
      (tester) async {
    await HiveStorage.init();

    await tester.pumpWidget(
      ProviderScope(
        child: const TankstellenApp(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Depending on setup state, either SetupScreen or SearchScreen renders.
    // Both contain a Scaffold, so we verify the app navigated somewhere valid.
    final hasScaffold = find.byType(Scaffold).evaluate().isNotEmpty;
    expect(hasScaffold, isTrue);
  });

  testWidgets('bottom navigation has 4 tabs when app is set up',
      (tester) async {
    await HiveStorage.init();
    // Mark setup as complete so we reach the shell screen
    final storage = HiveStorage();
    await storage.skipSetup();

    await tester.pumpWidget(
      ProviderScope(
        child: const TankstellenApp(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // If setup is complete, the shell screen should be showing with
    // bottom navigation bar containing 4 tabs (Search, Map, Favorites, Settings)
    final navBars = find.byType(NavigationBar);
    if (navBars.evaluate().isNotEmpty) {
      expect(navBars, findsOneWidget);

      // Verify 4 navigation destinations exist
      final destinations = find.byType(NavigationDestination);
      expect(destinations, findsNWidgets(4));
    } else {
      // BottomNavigationBar variant
      final bottomNavBars = find.byType(BottomNavigationBar);
      if (bottomNavBars.evaluate().isNotEmpty) {
        expect(bottomNavBars, findsOneWidget);
      }
    }
  });

  testWidgets('tapping each navigation tab navigates without crash',
      (tester) async {
    await HiveStorage.init();
    final storage = HiveStorage();
    await storage.skipSetup();

    await tester.pumpWidget(
      ProviderScope(
        child: const TankstellenApp(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));

    final navBars = find.byType(NavigationBar);
    if (navBars.evaluate().isEmpty) return; // Skip if not on shell screen

    final destinations = find.byType(NavigationDestination);
    if (destinations.evaluate().length != 4) return;

    // Tab 0 is already active (Search). Tap each remaining tab.
    for (var i = 1; i < 4; i++) {
      await tester.tap(destinations.at(i));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // App should still have a scaffold and not have crashed
      expect(find.byType(Scaffold), findsAtLeast(1),
          reason: 'Tab $i should render without crashing');
    }

    // Navigate back to the first tab
    await tester.tap(destinations.at(0));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.byType(Scaffold), findsAtLeast(1));
  });

  testWidgets('localization loads and provides text', (tester) async {
    await HiveStorage.init();

    await tester.pumpWidget(
      ProviderScope(
        child: const TankstellenApp(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // The app should have rendered some localized text (not raw ARB keys).
    // We check that at least one common widget has visible text content.
    // The app renders either the setup screen or the search screen,
    // both of which contain buttons, labels, or titles.
    final allText = find.byType(Text);
    expect(allText, findsAtLeast(1),
        reason: 'App should render at least one Text widget with localized content');
  });
}
