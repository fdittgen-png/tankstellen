// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #4213 — the current-vehicle contract: explicit selection only, the
// latest VALID assignment as the default, an expired assignment out of
// the selectable set, and no auto-switch anywhere.
import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/core/sync/sync_config.dart';
import 'package:tankstellen/core/time/app_clock.dart';
import 'package:tankstellen/features/fleet/api.dart';

import 'fleet_vehicle_test_support.dart';

void main() {
  late FleetHarness harness;

  setUp(() => harness = FleetHarness());

  CurrentVehicleContext read() =>
      harness.container().read(currentFleetVehicleProvider);

  group('the default is the latest VALID open assignment', () {
    test('the newest open assignment is current on a first run', () {
      harness.seedTwoAssignedVehicles();

      final state = read();

      expect(state.vehicle?.fleetVehicleId, vanRow.id,
          reason: 'the van was assigned 3 days ago, the estate 90');
      expect(state.absence, CurrentVehicleAbsence.none);
      expect(state.switchingEnabled, isTrue);
      expect(
        state.selectable.map((v) => v.fleetVehicleId),
        [vanRow.id, estateRow.id],
      );
    });

    test('a vehicle in the directory with no assignment is NOT selectable '
        '— the org roster is not a menu', () {
      harness.seedTwoAssignedVehicles();

      expect(
        read().selectable.map((v) => v.fleetVehicleId),
        isNot(contains(poolRow.id)),
      );
    });

    test('an ENDED assignment is not selectable, and the vehicle the '
        'driver handed back is gone from the control', () {
      harness.seedMembership();
      harness.seedDirectory(directoryOf(
        vehicles: const [vanRow, estateRow],
        assignments: [
          // Handed back an hour ago.
          assignment(vanRow.id,
              startedAgo: const Duration(days: 30),
              endedAgo: const Duration(hours: 1)),
          assignment(estateRow.id, startedAgo: const Duration(days: 2)),
        ],
      ));

      final state = read();

      expect(state.selectable.map((v) => v.fleetVehicleId), [estateRow.id]);
      expect(state.vehicle?.fleetVehicleId, estateRow.id);
    });

    test('an assignment that starts tomorrow is not selectable yet — the '
        'new vehicle becomes the default only once it is valid', () {
      harness.seedMembership();
      harness.seedDirectory(directoryOf(
        vehicles: const [vanRow, estateRow],
        assignments: [
          assignment(estateRow.id, startedAgo: const Duration(days: 2)),
          assignment(vanRow.id, startedAgo: const Duration(days: -1)),
        ],
      ));

      final state = read();

      expect(state.selectable.map((v) => v.fleetVehicleId), [estateRow.id]);
      expect(state.vehicle?.fleetVehicleId, estateRow.id,
          reason: 'a future assignment must never pre-empt the current one');
    });

    test('no valid assignment is its own state, not "not in a fleet"', () {
      harness.seedMembership();
      harness.seedDirectory(directoryOf(
        vehicles: const [vanRow],
        assignments: [
          assignment(vanRow.id,
              startedAgo: const Duration(days: 30),
              endedAgo: const Duration(days: 1)),
        ],
      ));

      final state = read();

      expect(state.vehicle, isNull);
      expect(state.absence, CurrentVehicleAbsence.noValidAssignment);
      expect(state.isVisible, isTrue,
          reason: 'the control stays on screen and says there is no '
              'vehicle — it never silently disappears mid-handover');
    });

    test('an assignment naming a vehicle the directory does not hold is '
        'skipped, not rendered as a blank car', () {
      harness.seedMembership();
      harness.seedDirectory(directoryOf(
        vehicles: const [estateRow],
        assignments: [
          assignment('veh-ghost', startedAgo: const Duration(days: 1)),
          assignment(estateRow.id, startedAgo: const Duration(days: 40)),
        ],
      ));

      expect(read().vehicle?.fleetVehicleId, estateRow.id);
    });

    test('another employee\'s assignment is never selectable', () {
      harness.seedMembership();
      harness.seedDirectory(directoryOf(
        vehicles: const [vanRow, estateRow],
        assignments: [
          assignment(vanRow.id,
              startedAgo: const Duration(days: 1), userId: 'user-2'),
          assignment(estateRow.id, startedAgo: const Duration(days: 40)),
        ],
      ));

      expect(read().selectable.map((v) => v.fleetVehicleId), [estateRow.id]);
    });
  });

  group('a personal user gets no control at all', () {
    test('no membership → not in a fleet, nothing to render', () {
      harness.seedDirectory(directoryOf(vehicles: const [vanRow],
          assignments: [assignment(vanRow.id, startedAgo: Duration.zero)]));

      final state = read();

      expect(state.absence, CurrentVehicleAbsence.notInFleet);
      expect(state.isVisible, isFalse);
      expect(state.vehicle, isNull);
      expect(state.selectable, isEmpty);
    });

    test('a membership with no cached directory grants no vehicle — an '
        'offline device never invents an assignment', () {
      harness.seedMembership();

      expect(read().absence, CurrentVehicleAbsence.notInFleet);
    });

    test('a directory cached for another org is never served here', () {
      harness.seedTwoAssignedVehicles();
      harness.seedMembership(orgId: 'org-other');

      expect(read().vehicle, isNull);
    });
  });

  group('freshness: stale is badged, expired disables the switch', () {
    test('a 3-day-old directory still switches, and says it is a copy',
        () {
      harness.seedTwoAssignedVehicles(age: const Duration(days: 3));

      final state = read();

      expect(state.scopeState, FleetScopeState.stale);
      expect(state.isStale, isTrue);
      expect(state.switchingEnabled, isTrue);
      expect(state.selectable, isNotEmpty);
    });

    test('an EXPIRED directory keeps showing the vehicle but withholds '
        'the list and disables switching (ADR 0025 D4)', () {
      harness.seedTwoAssignedVehicles(age: const Duration(days: 8));

      final state = read();

      expect(state.scopeState, FleetScopeState.expired);
      expect(state.vehicle?.fleetVehicleId, vanRow.id,
          reason: 'expiry must not fall back to a different car');
      expect(state.switchingEnabled, isFalse);
      expect(state.selectable, isEmpty,
          reason: 'a list too old to trust is not offered');
      expect(state.isStale, isTrue);
    });

    test('select() refuses while the directory is expired', () async {
      harness.seedTwoAssignedVehicles(age: const Duration(days: 8));
      final container = harness.container();

      final switched = await container
          .read(currentFleetVehicleProvider.notifier)
          .select(estateRow.id);

      expect(switched, isFalse);
      expect(
        container.read(currentFleetVehicleProvider).vehicle?.fleetVehicleId,
        vanRow.id,
      );
      expect(
        harness.storage.getSetting(StorageKeys.fleetCurrentVehicleId),
        isNull,
        reason: 'a refused switch writes nothing at all',
      );
    });
  });

  group('switching is explicit, and only explicit', () {
    test('select() changes the current vehicle immediately and persists '
        'the choice', () async {
      harness.seedTwoAssignedVehicles();
      final container = harness.container();

      final switched = await container
          .read(currentFleetVehicleProvider.notifier)
          .select(estateRow.id);

      expect(switched, isTrue);
      expect(
        container.read(currentFleetVehicleProvider).vehicle?.fleetVehicleId,
        estateRow.id,
      );
      expect(harness.storage.getSetting(StorageKeys.fleetCurrentVehicleId),
          estateRow.id);
    });

    test('select() refuses a vehicle that is not assigned — a code path '
        'cannot put the driver in the pool car', () async {
      harness.seedTwoAssignedVehicles();
      final container = harness.container();

      final switched = await container
          .read(currentFleetVehicleProvider.notifier)
          .select(poolRow.id);

      expect(switched, isFalse);
      expect(
        container.read(currentFleetVehicleProvider).vehicle?.fleetVehicleId,
        vanRow.id,
      );
    });

    test('a stored selection survives a restart', () {
      harness.seedTwoAssignedVehicles();
      harness.seedSelection(estateRow.id);

      expect(read().vehicle?.fleetVehicleId, estateRow.id);
    });

    test('a stored selection the driver no longer has is DROPPED, not '
        'repaired into a neighbouring car', () {
      harness.seedSelection(vanRow.id);
      harness.seedMembership();
      harness.seedDirectory(directoryOf(
        vehicles: const [vanRow, estateRow],
        assignments: [
          assignment(vanRow.id,
              startedAgo: const Duration(days: 30),
              endedAgo: const Duration(hours: 2)),
          assignment(estateRow.id, startedAgo: const Duration(days: 1)),
        ],
      ));

      final state = read();

      expect(state.vehicle?.fleetVehicleId, estateRow.id);
      expect(state.selectable.map((v) => v.fleetVehicleId), [estateRow.id]);
    });

    test('recent picks come first in the selectable list', () async {
      harness.seedTwoAssignedVehicles();
      final container = harness.container();

      await container
          .read(currentFleetVehicleProvider.notifier)
          .select(estateRow.id);

      expect(
        container
            .read(currentFleetVehicleProvider)
            .selectable
            .map((v) => v.fleetVehicleId),
        [estateRow.id, vanRow.id],
        reason: 'the sheet opens on what the driver actually drives',
      );
    });

    test('the recents list is capped and never duplicates', () async {
      harness.seedTwoAssignedVehicles();
      final container = harness.container();
      final notifier = container.read(currentFleetVehicleProvider.notifier);

      await notifier.select(estateRow.id);
      await notifier.select(vanRow.id);
      await notifier.select(estateRow.id);

      final stored = jsonDecode(harness.storage
          .getSetting(StorageKeys.fleetRecentVehicleIds) as String) as List;
      expect(stored, [estateRow.id, vanRow.id]);
      expect(stored.length, lessThanOrEqualTo(kFleetRecentVehicleLimit));
    });

    test('an unreadable recents list costs an ordering, not the list', () {
      harness.seedTwoAssignedVehicles();
      unawaited(harness.storage
          .putSetting(StorageKeys.fleetRecentVehicleIds, '{not json'));

      final state = read();

      expect(state.selectable.map((v) => v.fleetVehicleId),
          [vanRow.id, estateRow.id]);
    });
  });

  group('no auto-switch: nothing but a tap moves the current vehicle', () {
    test('a CONFIRMED adapter attribution pointing at the other car does '
        'not change the current vehicle', () async {
      harness.seedTwoAssignedVehicles();
      final container = harness.container();
      await container
          .read(currentFleetVehicleProvider.notifier)
          .select(vanRow.id);

      // The adapter is verified, confident and unambiguous — exactly
      // the situation a naive implementation would "helpfully" act on.
      final resolution = VehicleAttributionResolver.resolve(
        [
          VehicleSignal(
            source: VehicleAttributionSource.adapterIdentity,
            fleetVehicleId: estateRow.id,
            confidence: 1,
            evidence: const ['adapter:AA:BB:CC'],
          ),
        ],
        clock: const _NoopClock(),
      );

      expect(resolution.verdict, VehicleAttributionVerdict.confirmed);
      expect(resolution.attribution!.fleetVehicleId, estateRow.id);
      expect(
        container.read(currentFleetVehicleProvider).vehicle?.fleetVehicleId,
        vanRow.id,
        reason: '#4213: never silently switch because GPS, OBD2 or VIN '
            'happens to suggest another car',
      );
      expect(harness.storage.getSetting(StorageKeys.fleetCurrentVehicleId),
          vanRow.id);
    });

    test('rebuilding after the directory changes keeps the explicit pick '
        'as long as it is still assigned', () async {
      harness.seedTwoAssignedVehicles();
      final container = harness.container();
      await container
          .read(currentFleetVehicleProvider.notifier)
          .select(estateRow.id);

      // A later pull adds a third, newer assignment.
      harness.seedDirectory(directoryOf(
        vehicles: const [vanRow, estateRow, poolRow],
        assignments: [
          assignment(estateRow.id, startedAgo: const Duration(days: 90)),
          assignment(vanRow.id, startedAgo: const Duration(days: 3)),
          assignment(poolRow.id, startedAgo: const Duration(minutes: 5)),
        ],
      ));
      container.invalidate(currentFleetVehicleProvider);

      final state = container.read(currentFleetVehicleProvider);
      expect(state.vehicle?.fleetVehicleId, estateRow.id,
          reason: 'a brand-new assignment is offered, never imposed');
      expect(state.selectable.map((v) => v.fleetVehicleId),
          contains(poolRow.id));
    });
  });

  group('the scope gates everything', () {
    test('the community backend yields no fleet vehicle at all — a fleet '
        'never lives on the shared database (ADR 0025 D3)', () {
      harness.seedTwoAssignedVehicles();
      expect(harness.container().read(currentFleetVehicleProvider).isVisible,
          isTrue);

      final community = harness.container(
          sync: const SyncConfig(
        enabled: true,
        supabaseUrl: fleetBackend,
        supabaseAnonKey: 'key',
        userId: fleetUser,
        userEmail: 'driver@acme.example',
        mode: SyncMode.community,
      ));

      expect(community.read(currentFleetVehicleProvider).isVisible, isFalse);
    });

    test('an anonymous identity yields no fleet vehicle (ADR 0025 D2)', () {
      harness.seedTwoAssignedVehicles();

      final anonymous = harness.container(
          sync: const SyncConfig(
        enabled: true,
        supabaseUrl: fleetBackend,
        supabaseAnonKey: 'key',
        userId: fleetUser,
        mode: SyncMode.private,
      ));

      expect(anonymous.read(currentFleetVehicleProvider).isVisible, isFalse);
    });
  });
}

/// A clock for the one resolver call in this file; the attribution's
/// timestamp is irrelevant to what that test asserts.
class _NoopClock implements AppClock {
  const _NoopClock();

  @override
  DateTime now() => DateTime.utc(2026, 3, 11, 14, 30);
}
