import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/profile/presentation/screens/profile_screen.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../mocks/mocks.dart';

void main() {
  group('ProfileScreen', () {
    late MockHiveStorage mockStorage;
    late List<Object> overrides;

    setUp(() {
      mockStorage = MockHiveStorage();
      when(() => mockStorage.hasApiKey()).thenReturn(false);
      when(() => mockStorage.getApiKey()).thenReturn(null);
      when(() => mockStorage.getActiveProfileId()).thenReturn(null);
      when(() => mockStorage.getAllProfiles()).thenReturn([]);
      when(() => mockStorage.getRatings()).thenReturn({});
      when(() => mockStorage.getIgnoredIds()).thenReturn([]);
      when(() => mockStorage.getSetting(any())).thenReturn(null);
      when(() => mockStorage.storageStats).thenReturn((
        settings: 0,
        profiles: 0,
        favorites: 0,
        cache: 0,
        priceHistory: 0,
        alerts: 0,
        total: 0,
      ));
      when(() => mockStorage.profileCount).thenReturn(0);
      when(() => mockStorage.favoriteCount).thenReturn(0);
      when(() => mockStorage.cacheEntryCount).thenReturn(0);
      when(() => mockStorage.priceHistoryEntryCount).thenReturn(0);
      when(() => mockStorage.alertCount).thenReturn(0);
      when(() => mockStorage.getFavoriteIds()).thenReturn([]);
      when(() => mockStorage.getAlerts()).thenReturn([]);
      when(() => mockStorage.getEvApiKey()).thenReturn(null);
      when(() => mockStorage.hasCustomEvApiKey()).thenReturn(false);

      final test = standardTestOverrides();
      overrides = test.overrides;
      // Replace the mockStorage used in standardTestOverrides
      overrides = [
        hiveStorageProvider.overrideWithValue(mockStorage),
        ...test.overrides.skip(1), // Skip the default storage override
      ];
    });

    testWidgets('renders Scaffold with Settings title', (tester) async {
      await pumpApp(
        tester,
        const ProfileScreen(),
        overrides: overrides,
      );

      expect(find.byType(Scaffold), findsAtLeast(1));
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('renders section headers', (tester) async {
      await pumpApp(
        tester,
        const ProfileScreen(),
        overrides: overrides,
      );

      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Location'), findsOneWidget);
    });

    testWidgets('does not render Data Transparency section', (tester) async {
      await pumpApp(
        tester,
        const ProfileScreen(),
        overrides: overrides,
      );

      // Data Transparency was removed in favor of the Privacy Dashboard
      expect(find.text('Data transparency'), findsNothing);
    });

    testWidgets('does not render Data & Privacy section title', (tester) async {
      await pumpApp(
        tester,
        const ProfileScreen(),
        overrides: overrides,
      );

      // #519 — Data & Privacy was removed from the Settings screen
      // entirely; the ConfigVerificationWidget and its "Configuration
      // & Privacy" header moved into the Privacy Dashboard. The
      // Settings screen must contain neither.
      expect(find.text('Data & Privacy'), findsNothing);
      expect(find.text('Configuration & Privacy'), findsNothing);
    });

    testWidgets(
        '#530: no vertical SizedBox spacer taller than 16 dp on the '
        'Settings screen body', (tester) async {
      // Regression guard for #530 — the previous layout had four
      // `SizedBox(height: 32)` spacers between major sections,
      // eating ~100 dp of whitespace. A *vertical spacer* is a
      // `SizedBox` whose width is null / infinite and whose height
      // exceeds 16 dp. Square boxes (icons) and fixed-width sized
      // boxes (avatar wrappers) are excluded by the width-is-null
      // filter.
      await pumpApp(
        tester,
        const ProfileScreen(),
        overrides: overrides,
      );

      final verticalSpacers = tester
          .widgetList<SizedBox>(find.byType(SizedBox))
          .where((s) => s.width == null)
          .where((s) => (s.height ?? 0) > 16)
          .toList();

      expect(
        verticalSpacers,
        isEmpty,
        reason: '#530: no vertical spacer should exceed 16 dp — found '
            '${verticalSpacers.map((s) => s.height).toList()}',
      );
    });

    testWidgets('does not render the ConfigVerificationWidget (#519)',
        (tester) async {
      await pumpApp(
        tester,
        const ProfileScreen(),
        overrides: overrides,
      );

      // The whole ConfigVerificationWidget now lives inside the
      // Privacy Dashboard. No hardcoded profile/API key/cloud sync
      // labels should appear on the Settings screen any more.
      expect(find.text('Active profile'), findsNothing);
      expect(find.text('Preferred fuel'), findsNothing);
      expect(find.text('API keys'), findsNothing);
      expect(find.text('Cloud Sync'), findsNothing);
      expect(find.text('Privacy summary'), findsNothing);
      expect(find.text('Profil actif'), findsNothing);
      expect(find.text('Résumé de confidentialité'), findsNothing);
      expect(find.text('0 stations'), findsNothing);
      expect(find.text('0 configured'), findsNothing);
      expect(find.text('0 hidden'), findsNothing);
      expect(find.text('0 rated'), findsNothing);
    });

    testWidgets('renders Privacy Dashboard navigation link', (tester) async {
      await pumpApp(
        tester,
        const ProfileScreen(),
        overrides: overrides,
      );

      // Scroll down to find the Privacy Dashboard link
      await tester.scrollUntilVisible(
        find.text('Privacy Dashboard'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Privacy Dashboard'), findsOneWidget);
      expect(find.text('View, export, or delete your data'), findsOneWidget);
    });

    testWidgets('renders body as a scrollable ListView', (tester) async {
      await pumpApp(
        tester,
        const ProfileScreen(),
        overrides: overrides,
      );

      // ProfileScreen body is a ListView
      expect(find.byType(ListView), findsAtLeast(1));
    });

    testWidgets(
        '#520: AppBar title sits directly under the status bar '
        '(no doubled top inset, single Scaffold)', (tester) async {
      // Baseline — a bare Scaffold with an AppBar should place the
      // title within [statusBarHeight, statusBarHeight + kToolbarHeight].
      const statusBarHeight = 48.0;
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            padding: EdgeInsets.only(top: statusBarHeight),
            viewPadding: EdgeInsets.only(top: statusBarHeight),
            size: Size(412, 915),
            devicePixelRatio: 1,
          ),
          child: MaterialApp(
            home: Scaffold(
              appBar: AppBar(title: const Text('BARE_TITLE')),
              body: const SizedBox.shrink(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final bareTitleOffset = tester.getTopLeft(find.text('BARE_TITLE')).dy;
      expect(bareTitleOffset, greaterThanOrEqualTo(statusBarHeight - 4));
      expect(bareTitleOffset, lessThanOrEqualTo(statusBarHeight + kToolbarHeight));
    });

    testWidgets(
        '#528: Scaffold.bottomNavigationBar wrapped in SafeArea(top: false) '
        'does not double the gesture-bar inset', (tester) async {
      // Baseline for the #528 fix pattern. A bare bottomNavigationBar
      // built with SafeArea(top: false) inside it must have its bottom
      // edge sitting at screenHeight - viewPadding.bottom, not
      // screenHeight - 2 * viewPadding.bottom (the doubled-inset bug).
      const gestureBarHeight = 24.0;
      const barContentHeight = 64.0;
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(
            padding: EdgeInsets.only(bottom: gestureBarHeight),
            viewPadding: EdgeInsets.only(bottom: gestureBarHeight),
            size: Size(412, 915),
            devicePixelRatio: 1,
          ),
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox.shrink(),
              bottomNavigationBar: SafeArea(
                top: false,
                child: SizedBox(
                  key: ValueKey('nav-bar-test'),
                  height: barContentHeight,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final navBarRect = tester.getRect(find.byKey(const ValueKey('nav-bar-test')));
      // The SizedBox contents should sit ABOVE the gesture bar, with
      // its bottom edge at screenHeight - gestureBarHeight. The SafeArea
      // absorbs the inset so we never get a doubled gap below.
      expect(
        navBarRect.bottom,
        closeTo(915 - gestureBarHeight, 0.5),
        reason: 'bottom nav content must sit directly above the gesture '
            'bar — doubled-inset regression (#528)',
      );
      expect(
        navBarRect.height,
        closeTo(barContentHeight, 0.5),
        reason: 'SafeArea must not grow the bar height — it should '
            'only consume the inset from the surrounding space',
      );
    });

    testWidgets(
        '#520: nested Scaffold (shell pattern) with primary: false on '
        'the outer keeps the inner AppBar title in the correct band',
        (tester) async {
      // Reproduces the shell's structure: an outer Scaffold with no
      // AppBar (primary: false per #520) wrapping an inner Scaffold
      // that does have an AppBar. Before #520 the inner AppBar was
      // pushed down by a duplicated top inset; the primary: false
      // annotation on the outer Scaffold restores the expected band.
      const statusBarHeight = 48.0;
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            padding: EdgeInsets.only(top: statusBarHeight),
            viewPadding: EdgeInsets.only(top: statusBarHeight),
            size: Size(412, 915),
            devicePixelRatio: 1,
          ),
          child: MaterialApp(
            home: Scaffold(
              primary: false, // the #520 fix on ShellScreen
              body: Scaffold(
                appBar: AppBar(title: const Text('SHELL_TITLE')),
                body: const SizedBox.shrink(),
              ),
              bottomNavigationBar: const SizedBox(height: 56),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final shellTitleOffset =
          tester.getTopLeft(find.text('SHELL_TITLE')).dy;
      expect(
        shellTitleOffset,
        greaterThanOrEqualTo(statusBarHeight - 4),
        reason: 'title must not hide under the status bar',
      );
      expect(
        shellTitleOffset,
        lessThanOrEqualTo(statusBarHeight + kToolbarHeight),
        reason: 'nested inner AppBar must not be pushed below the '
            'first toolbar-sized band — doubled inset regression (#520)',
      );
    });
  });
}
