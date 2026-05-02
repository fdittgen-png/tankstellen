import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/features/consent/presentation/screens/gdpr_consent_screen.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../fakes/fake_hive_storage.dart';

void main() {
  late FakeHiveStorage fakeStorage;

  setUp(() {
    fakeStorage = FakeHiveStorage()..hasBundledDefaultKey = false;
  });

  Widget buildScreen() {
    final router = GoRouter(
      initialLocation: '/consent',
      routes: [
        GoRoute(
          path: '/consent',
          builder: (context, state) => const GdprConsentScreen(),
        ),
        GoRoute(
          path: '/setup',
          builder: (context, state) => const Scaffold(
            body: Text('Setup Screen'),
          ),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        hiveStorageProvider.overrideWithValue(fakeStorage),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        routerConfig: router,
      ),
    );
  }

  group('GdprConsentScreen', () {
    testWidgets('shows privacy title and subtitle', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Your Privacy'), findsOneWidget);
      expect(
        find.textContaining('This app respects your privacy'),
        findsOneWidget,
      );
    });

    testWidgets('shows four consent toggles', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Location Access'), findsOneWidget);
      expect(find.text('Error Reporting'), findsOneWidget);
      expect(find.text('Cloud Sync'), findsOneWidget);
      expect(find.text('Community Wait Times'), findsOneWidget);
    });

    testWidgets('shows Accept All and Accept Selected buttons',
        (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Accept All'), findsOneWidget);
      expect(find.text('Accept Selected'), findsOneWidget);
    });

    testWidgets('shows legal basis text', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.textContaining('Art. 6(1)(a) GDPR'), findsOneWidget);
    });

    testWidgets('all toggles start off by default', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final switches = tester.widgetList<Switch>(find.byType(Switch));
      for (final s in switches) {
        expect(s.value, isFalse);
      }
    });

    testWidgets('tapping a switch toggles its value', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Tap the first switch (location)
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
      expect(switches[0].value, isTrue);
      expect(switches[1].value, isFalse);
      expect(switches[2].value, isFalse);
      expect(switches[3].value, isFalse);
    });

    testWidgets('tapping community wait-time switch toggles only that value',
        (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // The 4th switch is the community wait-time toggle. Scroll first
      // because the first-launch screen body is taller than the test
      // surface.
      await tester.scrollUntilVisible(
        find.text('Community Wait Times'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byType(Switch).at(3));
      await tester.pumpAndSettle();

      final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
      expect(switches[0].value, isFalse);
      expect(switches[1].value, isFalse);
      expect(switches[2].value, isFalse);
      expect(switches[3].value, isTrue);
    });

    testWidgets('Accept Selected saves only selected consents',
        (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Turn on location only
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      // Tap Accept Selected
      await tester.tap(find.text('Accept Selected'));
      await tester.pumpAndSettle();

      expect(fakeStorage.getSetting(StorageKeys.gdprConsentGiven), true);
      expect(fakeStorage.getSetting(StorageKeys.consentLocation), true);
      expect(fakeStorage.getSetting(StorageKeys.consentErrorReporting), false);
      expect(fakeStorage.getSetting(StorageKeys.consentCloudSync), false);
      expect(
          fakeStorage.getSetting(StorageKeys.consentCommunityWaitTime), false);
    });

    testWidgets('Accept All saves all consents as true', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Tap Accept All
      await tester.tap(find.text('Accept All'));
      await tester.pumpAndSettle();

      expect(fakeStorage.getSetting(StorageKeys.gdprConsentGiven), true);
      expect(fakeStorage.getSetting(StorageKeys.consentLocation), true);
      expect(fakeStorage.getSetting(StorageKeys.consentErrorReporting), true);
      expect(fakeStorage.getSetting(StorageKeys.consentCloudSync), true);
      expect(
          fakeStorage.getSetting(StorageKeys.consentCommunityWaitTime), true);
    });

    testWidgets('shows privacy icon', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.privacy_tip_outlined), findsOneWidget);
    });

    testWidgets('shows location, error reporting, sync, and timer icons',
        (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.my_location), findsOneWidget);
      expect(find.byIcon(Icons.bug_report_outlined), findsOneWidget);
      expect(find.byIcon(Icons.cloud_outlined), findsOneWidget);
      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
    });
  });
}
