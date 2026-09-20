// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #4212 / #4218 — the fleet scope contract. The rules under test are
// ADR 0025 D2 (the e-mail identity), D3 (never the community backend)
// and D4 (explicit stale/expired, no auto-switch, no fallback).
import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/core/sync/fleet/fleet_directory.dart';
import 'package:tankstellen/core/sync/fleet/fleet_directory_cache.dart';
import 'package:tankstellen/core/sync/sync_config.dart';
import 'package:tankstellen/core/time/app_clock.dart';
import 'package:tankstellen/features/fleet/api.dart';

import '../../fakes/fake_hive_storage.dart';

/// A mid-month Wednesday — never a weekend, month boundary or DST edge.
final _now = DateTime.utc(2026, 3, 11, 14, 30);

const _backend = 'https://acme.supabase.co';
const _user = 'user-1';
const _org = 'org-acme';

FleetDirectory _directory({
  required DateTime fetchedAt,
  String orgId = _org,
  String orgName = 'Acme GmbH',
}) =>
    FleetDirectory(
      orgId: orgId,
      orgName: orgName,
      vehicles: const [],
      assignments: const [],
      policy: const {},
      fetchedAt: fetchedAt,
    );

/// An in-memory [FleetDirectoryCache] over a plain map.
({FleetDirectoryCache cache, Map<String, String> store}) _memoryCache() {
  final store = <String, String>{};
  return (
    cache: FleetDirectoryCache(
      load: (key) => store[key],
      persist: (key, json) async => store[key] = json,
      remove: (key) async => store.remove(key),
    ),
    store: store,
  );
}

void main() {
  late FakeHiveStorage storage;
  late Map<String, String> cacheStore;
  late FleetDirectoryCache cache;

  setUp(() {
    storage = FakeHiveStorage();
    final memory = _memoryCache();
    cache = memory.cache;
    cacheStore = memory.store;
  });

  /// Seeds [directory] into the cache under the key for [orgId] as seen
  /// by [_user] on [_backend] — exactly what a successful pull writes.
  void seedCache(FleetDirectory directory, {String orgId = _org}) {
    cacheStore[FleetDirectoryCache.keyFor(
        backendUrl: _backend, userId: _user, orgId: orgId)] = jsonEncode(
      directory.toJson(),
    );
  }

  void seedMembership({String orgId = _org, String role = 'employee'}) {
    unawaited(storage.putSetting(StorageKeys.fleetOrgId, orgId));
    unawaited(storage.putSetting(StorageKeys.fleetRole, role));
  }

  ProviderContainer containerWith({
    SyncConfig sync = const SyncConfig(
      enabled: true,
      supabaseUrl: _backend,
      supabaseAnonKey: 'key',
      userId: _user,
      userEmail: 'driver@acme.example',
      mode: SyncMode.private,
    ),
  }) {
    final container = ProviderContainer(overrides: [
      hiveStorageProvider.overrideWithValue(storage),
      fleetSyncConfigProvider.overrideWithValue(sync),
      fleetDirectoryCacheProvider.overrideWithValue(cache),
      appClockProvider.overrideWithValue(FixedClock(_now)),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  group('the backend and the identity gate fleet mode (ADR 0025 D2/D3)', () {
    test('the community backend is unavailable — an organisation never '
        'lives there', () {
      seedMembership();
      seedCache(_directory(fetchedAt: _now));
      final scope = containerWith(
        sync: const SyncConfig(
          enabled: true,
          supabaseUrl: _backend,
          supabaseAnonKey: 'key',
          userId: _user,
          userEmail: 'driver@acme.example',
          mode: SyncMode.community,
        ),
      ).read(fleetScopeProvider);

      expect(scope.state, FleetScopeState.unavailable);
      expect(scope.reason, FleetScopeReason.communityBackend);
      expect(scope.orgId, isNull,
          reason: 'an unavailable scope names no org, even with a cache');
    });

    test('an anonymous identity is unavailable WITH the reason, so the '
        'join control can be disabled rather than hidden', () {
      seedMembership();
      seedCache(_directory(fetchedAt: _now));
      final scope = containerWith(
        sync: const SyncConfig(
          enabled: true,
          supabaseUrl: _backend,
          supabaseAnonKey: 'key',
          userId: _user,
          mode: SyncMode.private,
        ),
      ).read(fleetScopeProvider);

      expect(scope.state, FleetScopeState.unavailable);
      expect(scope.reason, FleetScopeReason.identityRequired);
    });

    test('joinExisting is a fleet-capable backend too', () {
      seedMembership();
      seedCache(_directory(fetchedAt: _now));
      final scope = containerWith(
        sync: const SyncConfig(
          enabled: true,
          supabaseUrl: _backend,
          supabaseAnonKey: 'key',
          userId: _user,
          userEmail: 'driver@acme.example',
          mode: SyncMode.joinExisting,
        ),
      ).read(fleetScopeProvider);

      expect(scope.state, FleetScopeState.active);
    });

    test('sync switched off is its own reason, not "no fleet"', () {
      seedMembership();
      seedCache(_directory(fetchedAt: _now));
      final scope = containerWith(
        sync: const SyncConfig(userId: _user),
      ).read(fleetScopeProvider);

      expect(scope.state, FleetScopeState.unavailable);
      expect(scope.reason, FleetScopeReason.syncDisabled);
    });
  });

  group('an offline cache never grants a fleet it was not given', () {
    test('no stored membership → none, even with a directory on disk', () {
      seedCache(_directory(fetchedAt: _now));
      final scope = containerWith().read(fleetScopeProvider);

      expect(scope.state, FleetScopeState.none);
      expect(scope.reason, FleetScopeReason.notInFleet);
      expect(scope.orgId, isNull);
    });

    test('a directory cached for ANOTHER org is not served for this one '
        '— the key carries backend, account AND org', () {
      seedMembership(orgId: 'org-other');
      seedCache(_directory(fetchedAt: _now), orgId: _org);
      final scope = containerWith().read(fleetScopeProvider);

      expect(scope.state, FleetScopeState.none,
          reason: 'org-other has no cache of its own; the neighbouring '
              'org-acme directory must never stand in for it');
      expect(scope.orgId, isNull);
    });

    test('a cache whose payload names a different org is refused even if '
        'it sits under this org\'s key', () {
      seedMembership();
      seedCache(_directory(fetchedAt: _now, orgId: 'org-smuggled'));
      final scope = containerWith().read(fleetScopeProvider);

      expect(scope.state, FleetScopeState.none);
    });

    test('an unknown role decodes as no fleet — a newer server must not '
        'read as *some* role', () {
      seedMembership(role: 'auditor-general');
      seedCache(_directory(fetchedAt: _now));
      final scope = containerWith().read(fleetScopeProvider);

      expect(scope.state, FleetScopeState.none);
    });
  });

  group('freshness is three-valued and explicit (ADR 0025 D4)', () {
    test('fresh under 24 h → active, selection enabled', () {
      seedMembership();
      seedCache(_directory(fetchedAt: _now.subtract(const Duration(hours: 23))));
      final scope = containerWith().read(fleetScopeProvider);

      expect(scope.state, FleetScopeState.active);
      expect(scope.orgId, _org);
      expect(scope.orgName, 'Acme GmbH');
      expect(scope.role, FleetRole.employee);
      expect(scope.selectionEnabled, isTrue);
      expect(scope.age, const Duration(hours: 23));
    });

    test('at 24 h it turns stale — still usable, and it says so', () {
      seedMembership();
      seedCache(_directory(fetchedAt: _now.subtract(const Duration(hours: 24))));
      final scope = containerWith().read(fleetScopeProvider);

      expect(scope.state, FleetScopeState.stale);
      expect(scope.isMember, isTrue);
      expect(scope.selectionEnabled, isTrue);
      expect(scope.orgId, _org,
          reason: 'stale is the SAME org, labelled — never a switch');
    });

    test('at 7 d it expires and selection is DISABLED', () {
      seedMembership();
      seedCache(_directory(fetchedAt: _now.subtract(const Duration(days: 7))));
      final scope = containerWith().read(fleetScopeProvider);

      expect(scope.state, FleetScopeState.expired);
      expect(scope.isMember, isTrue,
          reason: 'the user is still in the fleet; only picking is blocked');
      expect(scope.selectionEnabled, isFalse);
      expect(scope.orgId, _org,
          reason: 'expiry must not fall back to another org or to none');
    });

    test('a manager role is carried through, and an employee is not '
        'promoted by an old cache', () {
      seedMembership(role: 'manager');
      seedCache(_directory(fetchedAt: _now.subtract(const Duration(days: 30))));
      final scope = containerWith().read(fleetScopeProvider);

      expect(scope.state, FleetScopeState.expired);
      expect(scope.role, FleetRole.manager);
      expect(scope.isManager, isTrue);
    });
  });
}
