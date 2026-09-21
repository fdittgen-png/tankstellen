// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// #4217 — the join half of fleet onboarding. What is pinned here is
// the promise the UI is built on: the service NEVER throws, and every
// refusal the user can act on arrives as its own named value. A single
// `unavailable` catch-all would make "your code is wrong", "your
// administrator has not enabled fleets" and "you are offline" one
// indistinguishable dead end.
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/features/fleet/api.dart';

import '../../core/sync/fleet/fake_fleet_transport.dart';
import '../../fakes/fake_storage_repository.dart';

void main() {
  late FakeStorageRepository storage;

  setUp(() => storage = FakeStorageRepository());

  FleetJoinService serviceWith(FakeFleetTransport transport) =>
      FleetJoinService(transport: transport, storage: storage);

  group('joining with an invite code', () {
    test('a granted membership is persisted so the scope can find it',
        () async {
      final transport = FakeFleetTransport(rpcResults: {
        FleetJoinService.joinRpc: {'org_id': 'org-acme', 'role': 'manager'},
      });

      final outcome =
          await serviceWith(transport).joinWithInviteCode(' ACME-4K2P ');

      expect(outcome, isA<FleetJoined>());
      expect((outcome as FleetJoined).orgId, 'org-acme');
      expect(outcome.role, FleetRole.manager);
      expect(storage.getSetting(StorageKeys.fleetOrgId), 'org-acme');
      expect(storage.getSetting(StorageKeys.fleetRole), 'manager');
      expect(transport.rpcCalls.single.fn, FleetJoinService.joinRpc);
      expect(transport.rpcCalls.single.params['p_invite_code'], 'ACME-4K2P',
          reason: 'the code is trimmed before it reaches the wire');
    });

    test('a server that answers only an org id grants the employee role',
        () async {
      final transport = FakeFleetTransport(
        rpcResults: {FleetJoinService.joinRpc: 'org-acme'},
      );

      final outcome = await serviceWith(transport).joinWithInviteCode('X1');

      expect((outcome as FleetJoined).role, FleetRole.employee);
    });

    test('an empty code is refused without a wire call', () async {
      final transport = FakeFleetTransport();

      final outcome = await serviceWith(transport).joinWithInviteCode('   ');

      expect(outcome, isA<FleetJoinRefused>());
      expect((outcome as FleetJoinRefused).failure,
          FleetJoinFailure.invalidCode);
      expect(transport.rpcCalls, isEmpty);
      expect(storage.getSetting(StorageKeys.fleetOrgId), isNull);
    });

    test('a response that is not a membership leaves nothing behind',
        () async {
      final transport = FakeFleetTransport(
        rpcResults: {FleetJoinService.joinRpc: 42},
      );

      final outcome = await serviceWith(transport).joinWithInviteCode('X1');

      expect((outcome as FleetJoinRefused).failure,
          FleetJoinFailure.unavailable);
      expect(storage.getSetting(StorageKeys.fleetRole), isNull);
    });
  });

  group('creating an organisation (the administrator path)', () {
    test('uses F2\'s RPC and records the admin role', () async {
      final transport = FakeFleetTransport(
        rpcResults: {FleetJoinService.createRpc: 'org-new'},
      );

      final outcome =
          await serviceWith(transport).createOrganization('Acme GmbH');

      expect((outcome as FleetJoined).role, FleetRole.admin);
      expect(transport.rpcCalls.single.fn, FleetJoinService.createRpc);
      expect(transport.rpcCalls.single.params['p_name'], 'Acme GmbH');
      expect(storage.getSetting(StorageKeys.fleetOrgId), 'org-new');
    });

    test('the community backend refuses with fleet_disabled, which the '
        'user reads as "this database does not do fleets" (ADR 0025 D3)',
        () async {
      final transport = FakeFleetTransport(rpcErrors: {
        FleetJoinService.createRpc: Exception('fleet_disabled'),
      });

      final outcome =
          await serviceWith(transport).createOrganization('Acme GmbH');

      expect((outcome as FleetJoinRefused).failure,
          FleetJoinFailure.notSupported);
      expect(storage.getSetting(StorageKeys.fleetOrgId), isNull);
    });
  });

  group('fault injection — the service never throws', () {
    for (final (token, expected) in <(String, FleetJoinFailure)>[
      ('already_member', FleetJoinFailure.alreadyMember),
      ('identity_required', FleetJoinFailure.identityRequired),
      ('not_authenticated', FleetJoinFailure.identityRequired),
      ('fleet_disabled', FleetJoinFailure.notSupported),
      ('invalid_code', FleetJoinFailure.invalidCode),
      ('invite_not_found', FleetJoinFailure.invalidCode),
      ('connection closed', FleetJoinFailure.unavailable),
    ]) {
      test('"$token" becomes ${expected.name}, not an exception', () async {
        final transport = FakeFleetTransport(rpcErrors: {
          FleetJoinService.joinRpc: Exception(token),
        });

        final call = serviceWith(transport).joinWithInviteCode('X1');

        await expectLater(call, completes);
        expect((await call as FleetJoinRefused).failure, expected);
      });
    }

    test('a self-host whose schema predates the join RPC says so instead '
        'of "unavailable"', () async {
      final transport = FakeFleetTransport(rpcErrors: {
        FleetJoinService.joinRpc: Exception(
          'PGRST202: Could not find the function public.fleet_join',
        ),
      });

      final outcome = await serviceWith(transport).joinWithInviteCode('X1');

      expect((outcome as FleetJoinRefused).failure,
          FleetJoinFailure.notSupported);
    });

    test('a transport that throws a bare Error still returns normally',
        () async {
      final transport = FakeFleetTransport(rpcErrors: {
        FleetJoinService.joinRpc: StateError('client torn down'),
      });

      expect(
        () => serviceWith(transport).joinWithInviteCode('X1'),
        returnsNormally,
      );
      expect(
        (await serviceWith(transport).joinWithInviteCode('X1')
            as FleetJoinRefused)
            .failure,
        FleetJoinFailure.unavailable,
      );
    });
  });
}
