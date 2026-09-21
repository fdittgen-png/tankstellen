// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/core/navigation/app_routes.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/core/sync/sync_provider.dart';
import 'package:tankstellen/features/profile/presentation/widgets/tank_sync_section.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../fakes/fake_hive_storage.dart';
import '../../../../helpers/silence_error_logger.dart';

void main() {
  silenceErrorLoggerSpool();

  group('TankSyncSection', () {
    test('has a const constructor', () {
      const widget = TankSyncSection();
      expect(widget, isA<TankSyncSection>());
    });
  });

  /// #4337 — "Set up cloud sync" asks for the Cloud Sync consent first
  /// when it is not given, instead of opening a setup that would mint and
  /// upload without it.
  group('setup requests the Cloud Sync consent (#4337)', () {
    late FakeHiveStorage storage;

    setUp(() {
      storage = FakeHiveStorage();
    });

    Future<void> pump(WidgetTester tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) =>
                const Scaffold(body: SingleChildScrollView(child: TankSyncSection())),
          ),
          GoRoute(
            path: RoutePaths.syncSetup,
            builder: (_, _) => const Scaffold(body: Text('setup-route')),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [hiveStorageProvider.overrideWithValue(storage)],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('without consent, setup shows the consent request; Cancel '
        'leaves everything as it was', (tester) async {
      await pump(tester);
      await tester.tap(find.text('Set up cloud sync'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('cloudSyncConsentRequest')), findsOneWidget);
      expect(find.text('setup-route'), findsNothing);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('cloudSyncConsentRequest')), findsNothing);
      expect(find.text('setup-route'), findsNothing);
      expect(storage.getSetting(StorageKeys.consentCloudSync), isNot(true));
    });

    testWidgets('granting the consent records it and opens the setup',
        (tester) async {
      await pump(tester);
      await tester.tap(find.text('Set up cloud sync'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(storage.getSetting(StorageKeys.consentCloudSync), isTrue);
      expect(find.text('setup-route'), findsOneWidget);
    });

    testWidgets('granting the consent back to a kept configuration resumes it '
        'in place — no second setup', (tester) async {
      await storage.putSetting('sync_enabled', true);
      await storage.putSetting('supabase_url', 'https://a.supabase.co');
      await storage.setSupabaseAnonKey('key');
      await storage.putSetting('sync_user_id', 'u1');
      await pump(tester);
      await tester.tap(find.text('Set up cloud sync'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(storage.getSetting(StorageKeys.consentCloudSync), isTrue);
      expect(find.text('setup-route'), findsNothing);
      expect(find.text('Set up cloud sync'), findsNothing,
          reason: 'the section shows the resumed configuration');
    });

    testWidgets('with consent given, setup opens directly', (tester) async {
      await storage.putSetting(StorageKeys.consentCloudSync, true);
      await pump(tester);
      await tester.tap(find.text('Set up cloud sync'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('cloudSyncConsentRequest')), findsNothing);
      expect(find.text('setup-route'), findsOneWidget);
    });
  });

  /// #4338 — the relink guidance a lost session raises is surfaced in the
  /// section, and a provider rebuild no longer drops it.
  testWidgets('relink guidance shows in the section and survives a '
      'SyncState rebuild (#4338)', (tester) async {
    final storage = FakeHiveStorage();
    await storage.putSetting('sync_enabled', true);
    await storage.putSetting(StorageKeys.consentCloudSync, true);
    await storage.putSetting('supabase_url', 'https://a.supabase.co');
    await storage.setSupabaseAnonKey('key');
    await storage.putSetting('sync_user_id', 'u1');
    final container = ProviderContainer(
      overrides: [hiveStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: Scaffold(
            body: SingleChildScrollView(child: TankSyncSection()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tankSyncRelinkTile')), findsNothing);

    container.read(syncStateProvider.notifier).markRelinkRequired();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tankSyncRelinkTile')), findsOneWidget);

    container.invalidate(syncStateProvider);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tankSyncRelinkTile')), findsOneWidget);
  });
}
