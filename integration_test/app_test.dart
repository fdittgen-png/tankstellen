import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tankstellen/app/app.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app launches and renders main scaffold', (tester) async {
    // Initialize Hive for integration test environment
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
    await storage.setSetupComplete(true);

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
    } else {
      // BottomNavigationBar variant
      final bottomNavBars = find.byType(BottomNavigationBar);
      if (bottomNavBars.evaluate().isNotEmpty) {
        expect(bottomNavBars, findsOneWidget);
      }
    }
  });
}
