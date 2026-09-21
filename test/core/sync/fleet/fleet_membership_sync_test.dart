// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/fleet/fleet_membership_sync.dart';
import 'package:tankstellen/core/sync/fleet/fleet_transport.dart';

import 'fake_fleet_transport.dart';

/// #4212 — the caller's own membership row, read through the transport;
/// a wire fault is reported as "no membership", never thrown.
void main() {
  group('FleetRole', () {
    test('is the explicit three of ADR 0025 D1 and nothing else', () {
      expect(FleetRole.values.map((r) => r.wireName),
          ['employee', 'manager', 'admin']);
      expect(FleetRole.fromWireName('manager'), FleetRole.manager);
      expect(FleetRole.fromWireName('owner'), isNull,
          reason: 'a role this build does not know must not decode');
      expect(FleetRole.fromWireName(null), isNull);
      expect(FleetRole.employee.isManager, isFalse);
      expect(FleetRole.manager.isManager, isTrue);
      expect(FleetRole.admin.isManager, isTrue);
    });
  });

  group('fetchOwn', () {
    test('returns the caller\'s row', () async {
      final t = FakeFleetTransport(userId: 'u1', tables: {
        FleetTables.members: [
          {'org_id': 'org-a', 'user_id': 'u1', 'role': 'employee',
            'status': 'active'},
          {'org_id': 'org-b', 'user_id': 'u2', 'role': 'admin',
            'status': 'active'},
        ],
      });
      final m = await FleetMembershipSync.fetchOwn(transport: t);
      expect(m, const FleetMembership(
          orgId: 'org-a', role: FleetRole.employee, active: true));
      expect(t.selects, ['fleet_members@own']);
    });

    test('an active row wins over a left one; a left one still reports',
        () async {
      final t = FakeFleetTransport(userId: 'u1', tables: {
        FleetTables.members: [
          {'org_id': 'org-old', 'user_id': 'u1', 'role': 'employee',
            'status': 'left'},
          {'org_id': 'org-a', 'user_id': 'u1', 'role': 'manager',
            'status': 'active'},
        ],
      });
      expect((await FleetMembershipSync.fetchOwn(transport: t))!.orgId,
          'org-a');
      t.tables[FleetTables.members]!.removeLast();
      final left = await FleetMembershipSync.fetchOwn(transport: t);
      expect(left!.active, isFalse);
      expect(left.toJson()['status'], 'left');
    });

    test('no row, an unknown role, or a malformed row → null', () async {
      expect(await FleetMembershipSync.fetchOwn(
          transport: FakeFleetTransport(userId: 'u1')), isNull);
      final t = FakeFleetTransport(userId: 'u1', tables: {
        FleetTables.members: [
          {'org_id': 'org-a', 'user_id': 'u1', 'role': 'owner'},
          {'user_id': 'u1', 'role': 'admin'},
        ],
      });
      expect(await FleetMembershipSync.fetchOwn(transport: t), isNull);
    });

    test('a wire fault completes with null instead of throwing', () async {
      final t = FakeFleetTransport(userId: 'u1')..failSelects = true;
      final future = FleetMembershipSync.fetchOwn(transport: t);
      await expectLater(future, completes);
      expect(await future, isNull);
    });

    test('unauthenticated (no transport) → null', () async {
      expect(await FleetMembershipSync.fetchOwn(), isNull);
    });
  });
}
