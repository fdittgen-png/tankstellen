// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// #4217 / #4218 — Settings → Fleet, plus the gate in front of it. Two
// things must hold together: a personal user sees no fleet tile at all,
// and the fleet user's screen answers "what does my employer know"
// without offering a control this slice has no policy bump for.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/navigation/app_routes.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/core/sync/fleet/fleet_directory.dart';
import 'package:tankstellen/core/sync/fleet/fleet_directory_cache.dart';
import 'package:tankstellen/core/sync/sync_config.dart';
import 'package:tankstellen/core/time/app_clock.dart';
import 'package:tankstellen/features/fleet/api.dart';
import 'package:tankstellen/features/profile/presentation/screens/settings/fleet_screen.dart';
import 'package:tankstellen/features/profile/presentation/screens/settings/settings_topics.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../../fakes/fake_storage_repository.dart';
import '../../../../../helpers/mock_providers.dart';

final _now = DateTime.utc(2026, 3, 11, 14, 30);

const _backend = 'https://acme.supabase.co';
const _user = 'user-1';
const _org = 'org-acme';

const _capable = SyncConfig(
  enabled: true,
  supabaseUrl: _backend,
  supabaseAnonKey: 'key',
  userId: _user,
  userEmail: 'driver@acme.example',
  mode: SyncMode.private,
);

void main() {
  late Map<String, String> cacheStore;
  late FleetDirectoryCache cache;

  setUp(() {
    cacheStore = <String, String>{};
    cache = FleetDirectoryCache(
      load: (key) => cacheStore[key],
      persist: (key, json) async => cacheStore[key] = json,
      remove: (key) async => cacheStore.remove(key),
    );
  });

  Future<void> seedMembership(
    FakeStorageRepository storage, {
    String role = 'employee',
    Duration age = Duration.zero,
  }) async {
    await storage.putSetting(StorageKeys.fleetOrgId, _org);
    await storage.putSetting(StorageKeys.fleetRole, role);
    cacheStore[FleetDirectoryCache.keyFor(
        backendUrl: _backend, userId: _user, orgId: _org)] = jsonEncode(
      FleetDirectory(
        orgId: _org,
        orgName: 'Acme GmbH',
        vehicles: const [],
        assignments: const [],
        policy: const {},
        fetchedAt: _now.subtract(age),
      ).toJson(),
    );
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    SyncConfig sync = _capable,
    Locale locale = const Locale('en'),
    Size surface = const Size(360, 690),
    double textScale = 1.0,
    Future<void> Function(FakeStorageRepository storage)? seed,
  }) async {
    final std = standardFakeTestOverrides();
    await seed?.call(std.fakeStorage);
    await tester.binding.setSurfaceSize(surface);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Object>[
          ...std.overrides,
          fleetSyncConfigProvider.overrideWithValue(sync),
          fleetDirectoryCacheProvider.overrideWithValue(cache),
          appClockProvider.overrideWithValue(FixedClock(_now)),
        ].cast(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: const FleetScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('the Settings tile is gated on the capability (#4218)', () {
    test('a personal user gets no Fleet topic at all', () {
      final topics = buildSettingsTopics(
        lookupAppLocalizations(const Locale('en')),
        tankSyncOn: true,
        advancedOn: false,
      );

      expect(topics.map((t) => t.id), isNot(contains(SettingsTopicId.fleet)));
    });

    test('a fleet user gets one, routed at the appended path', () {
      final topics = buildSettingsTopics(
        lookupAppLocalizations(const Locale('en')),
        tankSyncOn: true,
        advancedOn: false,
        fleetOn: true,
      );

      final fleet =
          topics.firstWhere((t) => t.id == SettingsTopicId.fleet);
      expect(fleet.route, RoutePaths.settingsFleet);
      expect(fleet.matches('company car'), isTrue,
          reason: 'the settings search has to find it by what users call it');
    });
  });

  testWidgets('a member sees the org, the role and the sharing state',
      (tester) async {
    await pumpScreen(tester, seed: (s) => seedMembership(s, role: 'manager'));

    expect(find.text('Acme GmbH'), findsOneWidget);
    expect(find.text('Fleet manager'), findsOneWidget);
    expect(find.textContaining('Nothing fleet-related leaves this device'),
        findsOneWidget,
        reason: 'sharing is opt-in and off by default');
  });

  testWidgets('a stale directory says so instead of pretending it is '
      'fresh (ADR 0025 D4)', (tester) async {
    await pumpScreen(
      tester,
      seed: (s) => seedMembership(s, age: const Duration(days: 3)),
    );

    expect(find.textContaining('could not be refreshed recently'),
        findsOneWidget);
  });

  testWidgets('an account in no fleet is told how to get into one',
      (tester) async {
    await pumpScreen(tester);

    expect(find.textContaining('not in a fleet yet'), findsOneWidget);
  });

  testWidgets('a blocked scope shows its reason here too', (tester) async {
    await pumpScreen(tester, sync: const SyncConfig());

    expect(find.textContaining('Cloud sync is switched off'), findsOneWidget);
  });

  testWidgets('the visibility list names both what a manager sees and '
      'what they never do', (tester) async {
    await pumpScreen(tester, seed: seedMembership);

    expect(find.textContaining('assigned to, and for which period'),
        findsOneWidget);
    expect(find.textContaining('Never your journeys'), findsOneWidget);
    expect(find.textContaining('Never a driving-style ranking'),
        findsOneWidget);
  });

  testWidgets('it offers no consent control — the switch lands with the '
      'manager surfaces (ADR 0025 D6)', (tester) async {
    await pumpScreen(tester, seed: seedMembership);

    expect(find.byType(Switch), findsNothing);
  });

  testWidgets('renders at 2.0x text and in French without overflow',
      (tester) async {
    await pumpScreen(
      tester,
      seed: seedMembership,
      locale: const Locale('fr'),
      textScale: 2.0,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Acme GmbH'), findsOneWidget);
  });
}
