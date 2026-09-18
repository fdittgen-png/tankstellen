// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/fleet/fleet_directory_sync.dart';
import 'package:tankstellen/core/sync/fleet/fleet_transport.dart';
import 'package:tankstellen/core/time/app_clock.dart';

import 'fake_fleet_transport.dart';

/// #4212 / ADR 0025 D4 — the org-scoped pull is pull-only, caches under
/// backend|account|org, and is explicit about age: fresh, stale (24 h),
/// expired (7 d, selection disabled). No auto-switch, no fallback to
/// another org; a server that says "not a member" forgets the cache.
void main() {
  // A mid-month Wednesday, pinned.
  final now = DateTime.utc(2026, 3, 11, 14, 30);
  const org = 'org-a';
  const user = 'user-1';

  Map<String, List<Map<String, dynamic>>> serverRows() => {
        FleetTables.organizations: [
          {'id': org, 'name': 'Acme Logistics'},
          {'id': 'org-b', 'name': 'Other GmbH'},
        ],
        FleetTables.vehicles: [
          {
            'id': 'veh-1',
            'org_id': org,
            'fleet_code': 'AC-01',
            'display_name': 'Transporter 1',
            'plate_masked': 'B-XX 1',
            'data': {'fuelKeys': ['diesel']},
          },
          {
            'id': 'veh-9',
            'org_id': 'org-b',
            'fleet_code': 'OT-09',
            'display_name': 'Not ours',
          },
        ],
        FleetTables.assignments: [
          {
            'id': 'as-1',
            'org_id': org,
            'fleet_vehicle_id': 'veh-1',
            'user_id': user,
            'effective_from': '2026-03-01T00:00:00Z',
            'effective_to': null,
          },
          {
            'id': 'as-0',
            'org_id': org,
            'fleet_vehicle_id': 'veh-1',
            'user_id': user,
            'effective_from': '2026-01-01T00:00:00Z',
            'effective_to': '2026-02-28T00:00:00Z',
          },
        ],
        FleetTables.policies: [
          {
            'org_id': org,
            'data': {'aggregationMinSamples': 5},
          },
        ],
      };

  /// An in-memory cache with the store exposed.
  (FleetDirectoryCache, Map<String, String>) memoryCache() {
    final store = <String, String>{};
    return (
      FleetDirectoryCache(
        load: (k) => store[k],
        persist: (k, json) async => store[k] = json,
        remove: (k) async => store.remove(k),
      ),
      store,
    );
  }

  group('pull from the server', () {
    test('returns the org directory and caches it under backend|user|org',
        () async {
      final transport = FakeFleetTransport(userId: user, tables: serverRows());
      final (cache, store) = memoryCache();
      final pull = await FleetDirectorySync.pull(
          orgId: org, transport: transport, cache: cache, clock: FixedClock(now));

      expect(pull.source, FleetDirectorySource.server);
      expect(pull.selectionEnabled, isTrue);
      final d = pull.directory!;
      expect(d.orgName, 'Acme Logistics');
      expect(d.vehicles.map((v) => v.id), ['veh-1'],
          reason: 'only this org\'s vehicles, never org-b\'s');
      expect(d.assignments.map((a) => a.id), ['as-1', 'as-0']);
      expect(d.openAssignmentsOf(user).map((a) => a.id), ['as-1']);
      expect(d.policy['aggregationMinSamples'], 5);
      expect(d.fetchedAt, now);

      final key = FleetDirectoryCache.keyFor(
          backendUrl: transport.backendUrl, userId: user, orgId: org);
      expect(key, 'fleet.example.supabase.co|user-1|org-a');
      expect(store.keys, [key]);
      expect(jsonDecode(store[key]!)['org_name'], 'Acme Logistics');
    });

    test('reads exactly the four directory tables, never a user table',
        () async {
      final transport = FakeFleetTransport(userId: user, tables: serverRows());
      final (cache, _) = memoryCache();
      await FleetDirectorySync.pull(
          orgId: org, transport: transport, cache: cache, clock: FixedClock(now));
      expect(transport.selects, [
        'fleet_organizations@org=org-a',
        'fleet_vehicles@org=org-a',
        'vehicle_assignments@org=org-a',
        'fleet_policies@org=org-a',
      ]);
      expect(FleetDirectorySync.tables, {
        'fleet_organizations', 'fleet_vehicles', 'vehicle_assignments',
        'fleet_policies',
      });
      expect(transport.rpcCalls, isEmpty, reason: 'pull-only');
    });

    test('an ended assignment keeps its history and is not active', () async {
      final transport = FakeFleetTransport(userId: user, tables: serverRows());
      final (cache, _) = memoryCache();
      final pull = await FleetDirectorySync.pull(
          orgId: org, transport: transport, cache: cache, clock: FixedClock(now));
      final ended = pull.directory!.assignments.firstWhere((a) => a.id == 'as-0');
      expect(ended.isOpen, isFalse);
      expect(ended.isActiveAt(DateTime.utc(2026, 2, 1)), isTrue);
      expect(ended.isActiveAt(DateTime.utc(2026, 3, 1)), isFalse);
      final open = pull.directory!.assignments.firstWhere((a) => a.id == 'as-1');
      expect(open.isActiveAt(now), isTrue);
      expect(open.isActiveAt(DateTime.utc(2026, 2, 1)), isFalse);
    });

    test('a user who is not a member gets nothing, and the cache is '
        'forgotten (D4: no fallback to an org the server no longer grants)',
        () async {
      final (cache, store) = memoryCache();
      final key = FleetDirectoryCache.keyFor(
          backendUrl: 'https://fleet.example.supabase.co',
          userId: user,
          orgId: org);
      store[key] = '{"stale": "copy"}';
      final rows = serverRows()..[FleetTables.organizations] = [];
      final transport = FakeFleetTransport(userId: user, tables: rows);
      final pull = await FleetDirectorySync.pull(
          orgId: org, transport: transport, cache: cache, clock: FixedClock(now));
      expect(pull.source, FleetDirectorySource.none);
      expect(pull.failure, FleetPullFailure.notAMember);
      expect(pull.selectionEnabled, isFalse);
      expect(store, isEmpty);
    });

    test('a malformed row is skipped, not fabricated', () async {
      final rows = serverRows();
      rows[FleetTables.vehicles]!.add({'id': 'broken', 'org_id': org});
      rows[FleetTables.assignments]!.add({
        'id': 'as-bad',
        'org_id': org,
        'fleet_vehicle_id': 'veh-1',
        'user_id': user,
        'effective_from': 'not a date',
      });
      final transport = FakeFleetTransport(userId: user, tables: rows);
      final (cache, _) = memoryCache();
      final pull = await FleetDirectorySync.pull(
          orgId: org, transport: transport, cache: cache, clock: FixedClock(now));
      expect(pull.directory!.vehicles.map((v) => v.id), ['veh-1']);
      expect(pull.directory!.assignments.map((a) => a.id), ['as-1', 'as-0']);
    });
  });

  group('offline — the cache with its age (D4)', () {
    Future<FleetDirectoryPull> pullAt(
      DateTime later, {
      required FleetDirectoryCache cache,
    }) async {
      final transport = FakeFleetTransport(userId: user, tables: serverRows());
      // First pull fills the cache at `now`.
      await FleetDirectorySync.pull(
          orgId: org, transport: transport, cache: cache, clock: FixedClock(now));
      // Then the wire fails.
      transport.failSelects = true;
      return FleetDirectorySync.pull(
          orgId: org, transport: transport, cache: cache, clock: FixedClock(later));
    }

    test('under 24 h: fresh, selection enabled', () async {
      final (cache, _) = memoryCache();
      final pull = await pullAt(now.add(const Duration(hours: 23)), cache: cache);
      expect(pull.source, FleetDirectorySource.cache);
      expect(pull.freshness, FleetDirectoryFreshness.fresh);
      expect(pull.age, const Duration(hours: 23));
      expect(pull.selectionEnabled, isTrue);
      expect(pull.directory!.orgName, 'Acme Logistics');
    });

    test('24 h to 7 d: stale, still selectable', () async {
      final (cache, _) = memoryCache();
      final pull = await pullAt(now.add(const Duration(hours: 25)), cache: cache);
      expect(pull.freshness, FleetDirectoryFreshness.stale);
      expect(pull.selectionEnabled, isTrue);
    });

    test('7 d and beyond: expired, selection disabled, nothing switched',
        () async {
      final (cache, _) = memoryCache();
      final pull = await pullAt(now.add(const Duration(days: 7)), cache: cache);
      expect(pull.source, FleetDirectorySource.cache);
      expect(pull.freshness, FleetDirectoryFreshness.expired);
      expect(pull.selectionEnabled, isFalse);
      expect(pull.directory, isNotNull,
          reason: 'the directory is still shown, labelled expired');
    });

    test('a failed pull never fabricates a fresher cache', () async {
      final (cache, store) = memoryCache();
      await pullAt(now.add(const Duration(days: 2)), cache: cache);
      final key = store.keys.single;
      expect(jsonDecode(store[key]!)['fetched_at'], now.toIso8601String());
    });

    test('wire failure with nothing cached completes with none(wireFailed)',
        () async {
      final transport = FakeFleetTransport(userId: user, tables: serverRows())
        ..failSelects = true;
      final (cache, _) = memoryCache();
      final future = FleetDirectorySync.pull(
          orgId: org, transport: transport, cache: cache, clock: FixedClock(now));
      await expectLater(future, completes);
      final pull = await future;
      expect(pull.source, FleetDirectorySource.none);
      expect(pull.failure, FleetPullFailure.wireFailed);
    });

    test('a cache that throws on read or write is a logged fault, not a '
        'crash', () async {
      final cache = FleetDirectoryCache(
        load: (_) => throw StateError('box closed'),
        persist: (_, _) async => throw StateError('box closed'),
        remove: (_) async => throw StateError('box closed'),
      );
      final transport = FakeFleetTransport(userId: user, tables: serverRows());
      await expectLater(
          FleetDirectorySync.pull(
              orgId: org, transport: transport, cache: cache, clock: FixedClock(now)),
          completes);
      transport.failSelects = true;
      final pull = await FleetDirectorySync.pull(
          orgId: org, transport: transport, cache: cache, clock: FixedClock(now));
      expect(pull.failure, FleetPullFailure.wireFailed);
    });
  });

  group('the cache key separates backend, account and org', () {
    test('another account, backend or org never reads this entry', () async {
      final (cache, store) = memoryCache();
      final transport = FakeFleetTransport(userId: user, tables: serverRows());
      await FleetDirectorySync.pull(
          orgId: org, transport: transport, cache: cache, clock: FixedClock(now));
      expect(store.length, 1);

      for (final (u, b, o) in [
        ('user-2', transport.backendUrl, org),
        (user, 'https://other.supabase.co', org),
        (user, transport.backendUrl, 'org-b'),
      ]) {
        expect(
            FleetDirectorySync.cached(
                orgId: o, userId: u, backendUrl: b, cache: cache,
                clock: FixedClock(now)),
            isNull,
            reason: '$u@$b/$o must not see $user\'s $org directory');
      }
      expect(
          FleetDirectorySync.cached(
              orgId: org, userId: user, backendUrl: transport.backendUrl,
              cache: cache, clock: FixedClock(now))!.directory.orgName,
          'Acme Logistics');
    });

    test('a bare host and a URL key the same context (#4058)', () {
      expect(
        FleetDirectoryCache.keyFor(
            backendUrl: 'abc.supabase.co', userId: 'u', orgId: 'o'),
        FleetDirectoryCache.keyFor(
            backendUrl: 'https://abc.supabase.co/', userId: 'u', orgId: 'o'),
      );
    });
  });

  group('no session', () {
    test('returns none(notAuthenticated) — nothing is read under a global '
        'key', () async {
      final (cache, store) = memoryCache();
      store['(default)|user-1|org-a'] = '{"anything": true}';
      final pull = await FleetDirectorySync.pull(
          orgId: org, transport: null, cache: cache, clock: FixedClock(now));
      expect(pull.source, FleetDirectorySource.none);
      expect(pull.failure, FleetPullFailure.notAuthenticated);
    });
  });

  group('directory JSON round-trip', () {
    test('every field survives, and an unreadable blob decodes to null',
        () async {
      final transport = FakeFleetTransport(userId: user, tables: serverRows());
      final (cache, _) = memoryCache();
      final pull = await FleetDirectorySync.pull(
          orgId: org, transport: transport, cache: cache, clock: FixedClock(now));
      final d = pull.directory!;
      final back = FleetDirectory.fromJson(
          jsonDecode(jsonEncode(d.toJson())) as Map<String, dynamic>)!;
      expect(back.orgId, d.orgId);
      expect(back.orgName, d.orgName);
      expect(back.fetchedAt, d.fetchedAt);
      expect(back.vehicles.single.data, {'fuelKeys': ['diesel']});
      expect(back.vehicles.single.plateMasked, 'B-XX 1');
      expect(back.assignments.map((a) => a.effectiveTo),
          [null, DateTime.utc(2026, 2, 28)]);
      expect(back.policy, {'aggregationMinSamples': 5});

      expect(FleetDirectory.fromJson({'org_id': org}), isNull);
      expect(
          cache.read('missing', clock: FixedClock(now)), isNull);
    });
  });
}
