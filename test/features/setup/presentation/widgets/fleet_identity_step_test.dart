// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// #4217 / ADR 0025 D2–D4 — the step's three faces and, above all, the
// rule that a blocked fleet is *explained*: an anonymous identity or
// the community backend must never reach a join button that silently
// fails on the server. The accessibility rungs (360 dp, 2x text, a
// non-English locale) are here too, because this is the page a driver
// meets on day one on whatever phone the employer handed them.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/core/sync/fleet/fleet_directory.dart';
import 'package:tankstellen/core/sync/fleet/fleet_directory_cache.dart';
import 'package:tankstellen/core/sync/sync_config.dart';
import 'package:tankstellen/core/time/app_clock.dart';
import 'package:tankstellen/features/fleet/api.dart';
import 'package:tankstellen/features/setup/presentation/widgets/fleet_identity_step.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../core/sync/fleet/fake_fleet_transport.dart';
import '../../../../fakes/fake_storage_repository.dart';
import '../../../../helpers/mock_providers.dart';

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
        fetchedAt: _now,
      ).toJson(),
    );
  }

  Future<FakeStorageRepository> pumpStep(
    WidgetTester tester, {
    SyncConfig sync = _capable,
    FakeFleetTransport? transport,
    Locale locale = const Locale('en'),
    double textScale = 1.0,
    Size surface = const Size(800, 600),
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
          if (transport != null)
            fleetTransportProvider.overrideWithValue(transport),
        ].cast(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
              child: const FleetIdentityStep(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return std.fakeStorage;
  }

  group('blocked, with the reason (ADR 0025 D2/D3)', () {
    testWidgets('an anonymous identity cannot proceed and is told why',
        (tester) async {
      await pumpStep(
        tester,
        sync: const SyncConfig(
          enabled: true,
          supabaseUrl: _backend,
          supabaseAnonKey: 'key',
          userId: _user,
          mode: SyncMode.private,
        ),
      );

      expect(find.byKey(const Key('fleetIdentityBlocked')), findsOneWidget);
      expect(find.byKey(const Key('fleetJoinButton')), findsNothing);
      expect(find.byKey(const Key('fleetInviteCodeField')), findsNothing);
      expect(
        find.textContaining('e-mail address'),
        findsOneWidget,
        reason: 'the block names the fix, not just the refusal',
      );
    });

    testWidgets('the community backend gets its OWN reason, not the '
        'identity one', (tester) async {
      await pumpStep(
        tester,
        sync: const SyncConfig(
          enabled: true,
          supabaseUrl: _backend,
          supabaseAnonKey: 'key',
          userId: _user,
          userEmail: 'driver@acme.example',
          mode: SyncMode.community,
        ),
      );

      expect(find.byKey(const Key('fleetIdentityBlocked')), findsOneWidget);
      expect(find.textContaining('community database'), findsOneWidget);
      expect(find.byKey(const Key('fleetJoinButton')), findsNothing);
    });

    testWidgets('sync switched off is a third, distinct reason',
        (tester) async {
      await pumpStep(tester, sync: const SyncConfig());

      expect(find.byKey(const Key('fleetIdentityBlocked')), findsOneWidget);
      expect(find.textContaining('Cloud sync is switched off'),
          findsOneWidget);
    });
  });

  group('joining', () {
    testWidgets('Join is disabled with a reason until a code is typed',
        (tester) async {
      await pumpStep(tester);

      final button = tester.widget<FilledButton>(
        find.byKey(const Key('fleetJoinButton')),
      );
      expect(button.onPressed, isNull);
      expect(find.textContaining('invite code your fleet administrator'),
          findsWidgets);
    });

    testWidgets('a granted join replaces the form with the membership',
        (tester) async {
      final transport = FakeFleetTransport(
        userId: _user,
        backendUrl: _backend,
        tables: {
          'fleet_organizations': [
            {'id': _org, 'name': 'Acme GmbH'},
          ],
        },
        rpcResults: {
          'fleet_join': {'org_id': _org, 'role': 'employee'},
        },
      );
      final storage = await pumpStep(tester, transport: transport);

      await tester.enterText(
          find.byKey(const Key('fleetInviteCodeField')), 'ACME-4K2P');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('fleetJoinButton')));
      await tester.pumpAndSettle();

      expect(storage.getSetting(StorageKeys.fleetOrgId), _org);
      expect(find.byKey(const Key('fleetIdentityMember')), findsOneWidget);
      expect(find.textContaining('Acme GmbH'), findsOneWidget);
      expect(find.byKey(const Key('fleetInviteCodeField')), findsNothing);
    });

    testWidgets('a refused join keeps the form and shows the server\'s own '
        'reason — never a generic failure', (tester) async {
      final transport = FakeFleetTransport(
        userId: _user,
        backendUrl: _backend,
        rpcErrors: {'fleet_join': Exception('already_member')},
      );
      await pumpStep(tester, transport: transport);

      await tester.enterText(
          find.byKey(const Key('fleetInviteCodeField')), 'ACME-4K2P');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('fleetJoinButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fleetJoinFailure')), findsOneWidget);
      expect(find.textContaining('already belongs to a fleet'),
          findsOneWidget);
      expect(find.byKey(const Key('fleetInviteCodeField')), findsOneWidget);
    });
  });

  testWidgets('an existing member sees the org and role instead of a form',
      (tester) async {
    await pumpStep(tester, seed: (s) => seedMembership(s, role: 'manager'));

    expect(find.byKey(const Key('fleetIdentityMember')), findsOneWidget);
    expect(find.textContaining('Acme GmbH'), findsOneWidget);
    expect(find.textContaining('Fleet manager'), findsOneWidget);
    expect(find.byKey(const Key('fleetJoinButton')), findsNothing);
  });

  group('accessibility', () {
    testWidgets('renders at 360 dp without overflow', (tester) async {
      await pumpStep(tester, surface: const Size(360, 690));

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('fleetInviteCodeField')), findsOneWidget);
    });

    testWidgets('renders at 2.0x text scale without overflow',
        (tester) async {
      await pumpStep(
        tester,
        surface: const Size(360, 690),
        textScale: 2.0,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders in French — the wizard is a French user\'s first '
        'impression (#495)', (tester) async {
      await pumpStep(tester, locale: const Locale('fr'));

      expect(tester.takeException(), isNull);
      expect(find.text('Rejoindre la flotte'), findsOneWidget);
      expect(find.text('Scanner le code QR'), findsOneWidget);
    });
  });
}
