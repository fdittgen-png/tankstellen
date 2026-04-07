import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/features/consent/presentation/screens/gdpr_consent_screen.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../mocks/mocks.dart';

void main() {
  late MockHiveStorage mockStorage;

  setUp(() {
    mockStorage = MockHiveStorage();
    when(() => mockStorage.getSetting(any())).thenReturn(null);
    when(() => mockStorage.putSetting(any(), any())).thenAnswer((_) async {});
    when(() => mockStorage.hasApiKey()).thenReturn(false);
    when(() => mockStorage.isSetupComplete).thenReturn(false);
    when(() => mockStorage.isSetupSkipped).thenReturn(false);
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
        hiveStorageProvider.overrideWithValue(mockStorage),
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

    testWidgets('shows three consent toggles', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Location Access'), findsOneWidget);
      expect(find.text('Error Reporting'), findsOneWidget);
      expect(find.text('Cloud Sync'), findsOneWidget);
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

      verify(() => mockStorage.putSetting(StorageKeys.gdprConsentGiven, true))
          .called(1);
      verify(() => mockStorage.putSetting(StorageKeys.consentLocation, true))
          .called(1);
      verify(() =>
              mockStorage.putSetting(StorageKeys.consentErrorReporting, false))
          .called(1);
      verify(() =>
              mockStorage.putSetting(StorageKeys.consentCloudSync, false))
          .called(1);
    });

    testWidgets('Accept All saves all consents as true', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Tap Accept All
      await tester.tap(find.text('Accept All'));
      await tester.pumpAndSettle();

      verify(() => mockStorage.putSetting(StorageKeys.gdprConsentGiven, true))
          .called(1);
      verify(() => mockStorage.putSetting(StorageKeys.consentLocation, true))
          .called(1);
      verify(() =>
              mockStorage.putSetting(StorageKeys.consentErrorReporting, true))
          .called(1);
      verify(() => mockStorage.putSetting(StorageKeys.consentCloudSync, true))
          .called(1);
    });

    testWidgets('shows privacy icon', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.privacy_tip_outlined), findsOneWidget);
    });

    testWidgets('shows location, error reporting, and sync icons',
        (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.my_location), findsOneWidget);
      expect(find.byIcon(Icons.bug_report_outlined), findsOneWidget);
      expect(find.byIcon(Icons.cloud_outlined), findsOneWidget);
    });
  });
}
