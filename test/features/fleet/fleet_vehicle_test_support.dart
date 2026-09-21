// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// Shared harness for the #4213 current-vehicle tests: an in-memory
/// fleet directory cache, a fake settings store and a container whose
/// fleet scope is real (derived by `fleetScopeProvider`) rather than
/// stubbed — a fake that echoed the scope back would hide exactly the
/// expiry/handover bugs these tests exist to catch.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
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
final fleetNow = DateTime.utc(2026, 3, 11, 14, 30);

const fleetBackend = 'https://acme.supabase.co';
const fleetUser = 'user-1';
const fleetOrg = 'org-acme';

const fleetSyncOn = SyncConfig(
  enabled: true,
  supabaseUrl: fleetBackend,
  supabaseAnonKey: 'key',
  userId: fleetUser,
  userEmail: 'driver@acme.example',
  mode: SyncMode.private,
);

/// The van, the estate and the pool car — three assignable vehicles.
const vanRow = FleetVehicleRow(
  id: 'veh-van',
  orgId: fleetOrg,
  fleetCode: 'VAN-12',
  displayName: 'VW Caddy 2.0 TDI',
  plateMasked: 'B-XY 1234',
);
const estateRow = FleetVehicleRow(
  id: 'veh-estate',
  orgId: fleetOrg,
  fleetCode: 'CAR-07',
  displayName: 'Skoda Octavia Combi',
  plateMasked: 'B-AB 5678',
);
const poolRow = FleetVehicleRow(
  id: 'veh-pool',
  orgId: fleetOrg,
  fleetCode: 'POOL-01',
  displayName: 'Renault Zoe',
);

/// An assignment of [vehicleId] to [fleetUser], effective-dated.
FleetAssignmentRow assignment(
  String vehicleId, {
  required Duration startedAgo,
  Duration? endedAgo,
  String userId = fleetUser,
}) =>
    FleetAssignmentRow(
      id: 'asg-$vehicleId',
      orgId: fleetOrg,
      fleetVehicleId: vehicleId,
      userId: userId,
      effectiveFrom: fleetNow.subtract(startedAgo),
      effectiveTo: endedAgo == null ? null : fleetNow.subtract(endedAgo),
    );

FleetDirectory directoryOf({
  required List<FleetVehicleRow> vehicles,
  required List<FleetAssignmentRow> assignments,
  Duration age = Duration.zero,
  String orgId = fleetOrg,
}) =>
    FleetDirectory(
      orgId: orgId,
      orgName: 'Acme GmbH',
      vehicles: vehicles,
      assignments: assignments,
      policy: const {},
      fetchedAt: fleetNow.subtract(age),
    );

/// The whole seeded world of one test.
class FleetHarness {
  FleetHarness() {
    cache = FleetDirectoryCache(
      load: (key) => _store[key],
      persist: (key, json) async => _store[key] = json,
      remove: (key) async => _store.remove(key),
    );
  }

  final FakeHiveStorage storage = FakeHiveStorage();
  final Map<String, String> _store = <String, String>{};
  late final FleetDirectoryCache cache;

  /// Writes [directory] where a successful pull would have written it.
  void seedDirectory(FleetDirectory directory, {String orgId = fleetOrg}) {
    _store[FleetDirectoryCache.keyFor(
            backendUrl: fleetBackend, userId: fleetUser, orgId: orgId)] =
        jsonEncode(directory.toJson());
  }

  void seedMembership({String orgId = fleetOrg, String role = 'employee'}) {
    unawaited(storage.putSetting(StorageKeys.fleetOrgId, orgId));
    unawaited(storage.putSetting(StorageKeys.fleetRole, role));
  }

  /// Pre-existing explicit selection, as a previous session left it.
  void seedSelection(String fleetVehicleId, {List<String>? recents}) {
    unawaited(storage.putSetting(
        StorageKeys.fleetCurrentVehicleId, fleetVehicleId));
    unawaited(storage.putSetting(StorageKeys.fleetRecentVehicleIds,
        jsonEncode(recents ?? [fleetVehicleId])));
  }

  /// The provider overrides every fleet test shares. [sync] states a
  /// different backend/identity (the D2/D3 gates) without stacking a
  /// second override of the same provider.
  List<Override> overridesWith({SyncConfig sync = fleetSyncOn}) => [
        hiveStorageProvider.overrideWithValue(storage),
        fleetSyncConfigProvider.overrideWithValue(sync),
        fleetDirectoryCacheProvider.overrideWithValue(cache),
        appClockProvider.overrideWithValue(FixedClock(fleetNow)),
      ];

  List<Override> get overrides => overridesWith();

  ProviderContainer container({SyncConfig sync = fleetSyncOn}) {
    final container = ProviderContainer(overrides: overridesWith(sync: sync));
    addTearDown(container.dispose);
    return container;
  }

  /// The common case: a member of Acme with the van and the estate
  /// assigned, the van's assignment the newer one.
  void seedTwoAssignedVehicles({Duration age = Duration.zero}) {
    seedMembership();
    seedDirectory(directoryOf(
      vehicles: const [vanRow, estateRow, poolRow],
      assignments: [
        assignment(estateRow.id, startedAgo: const Duration(days: 90)),
        assignment(vanRow.id, startedAgo: const Duration(days: 3)),
      ],
      age: age,
    ));
  }
}
