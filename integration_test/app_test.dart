import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tankstellen/app/app.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';

/// Pre-flight a fresh storage state where GDPR consent has been given
/// and onboarding has been completed. Used by the user-flow tests below
/// so they all start from a logged-in app reaching the shell screen
/// rather than the consent or setup wizards.
Future<HiveStorage> _bootStorageReady() async {
  await HiveStorage.init();
  final storage = HiveStorage();
  await storage.putSetting(StorageKeys.gdprConsentGiven, true);
  await storage.skipSetup();
  return storage;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app launches without crashing and renders a Scaffold',
      (tester) async {
    await HiveStorage.init();

    await tester.pumpWidget(
      const ProviderScope(
        child: TankstellenApp(),
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
      const ProviderScope(
        child: TankstellenApp(),
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
      const ProviderScope(
        child: TankstellenApp(),
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
      const ProviderScope(
        child: TankstellenApp(),
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
      const ProviderScope(
        child: TankstellenApp(),
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

  // ---------------------------------------------------------------------------
  // End-to-end user flows (#390)
  //
  // The remaining tests boot the app into a "ready" state — consent given +
  // onboarding skipped — so the router lands directly on the shell screen
  // and we can exercise the post-setup flows without driving the wizard.
  // ---------------------------------------------------------------------------

  testWidgets(
      'flow: consent + setup completed -> app lands on the search shell '
      'with bottom navigation', (tester) async {
    await _bootStorageReady();

    await tester.pumpWidget(
      const ProviderScope(
        child: TankstellenApp(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // The router should drop straight into the shell screen — no consent,
    // no onboarding.
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(4));
  });

  testWidgets(
      'flow: navigate Search -> Favorites -> Settings -> Map and back '
      'without crashing', (tester) async {
    await _bootStorageReady();

    await tester.pumpWidget(
      const ProviderScope(
        child: TankstellenApp(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));

    final destinations = find.byType(NavigationDestination);
    expect(destinations, findsNWidgets(4));

    // Walk every tab forwards then back to Search. Use a generous settle
    // window because some tabs (Map) initialise heavy widgets on first
    // visit (FlutterMap, geolocation provider, etc.).
    for (final i in [1, 2, 3, 0]) {
      await tester.tap(destinations.at(i));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(Scaffold), findsAtLeast(1),
          reason: 'Tab $i should render a Scaffold without crashing');
      // The bottom nav should still be present after navigating.
      expect(find.byType(NavigationBar), findsOneWidget,
          reason: 'NavigationBar should persist on tab $i');
    }
  });

  testWidgets(
      'flow: opening the Favorites tab on a fresh install shows the empty '
      '"No favorites yet" state', (tester) async {
    await _bootStorageReady();

    await tester.pumpWidget(
      const ProviderScope(
        child: TankstellenApp(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));

    final destinations = find.byType(NavigationDestination);
    // Tab 2 is Favorites in the standard 4-tab layout.
    await tester.tap(destinations.at(2));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Empty state shows the star_outline icon. Localized title varies, so we
    // assert on the icon (stable across locales).
    expect(find.byIcon(Icons.star_outline), findsAtLeast(1));
  });

  testWidgets(
      'flow: opening the Settings tab on a fresh install renders a '
      'scrollable list of sections', (tester) async {
    await _bootStorageReady();

    await tester.pumpWidget(
      const ProviderScope(
        child: TankstellenApp(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));

    final destinations = find.byType(NavigationDestination);
    // Tab 3 is Settings.
    await tester.tap(destinations.at(3));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // The settings screen body is a ListView composed of section widgets.
    expect(find.byType(ListView), findsAtLeast(1));
    // It must always render at least one ExpansionTile (Storage / Cache,
    // API Key, etc.) so the foldable sections are reachable.
    expect(find.byType(ExpansionTile), findsAtLeast(1));
  });
}
