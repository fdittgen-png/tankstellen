// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/deletions_sync.dart';
import 'package:tankstellen/core/sync/fill_ups_sync.dart';
import 'package:tankstellen/core/sync/pending_deletions_journal.dart';
import 'package:tankstellen/core/sync/schema_sql.dart';
import 'package:tankstellen/core/sync/schema_verifier.dart';
import 'package:tankstellen/core/sync/sync_device_identity.dart';
import 'package:tankstellen/core/sync/sync_transport.dart';
import 'package:tankstellen/core/sync/vehicles_sync.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';

import 'fake_sync_transport.dart';

/// A pre-v4 self-host schema: the `deletions` table doesn't know the
/// #3125 forensic columns, so PostgREST rejects payloads carrying them
/// with `PGRST204` — exactly what an outdated wizard SQL produces.
class _PreV4SchemaTransport extends FakeSyncTransport {
  int rejectedUpserts = 0;

  @override
  Future<void> upsert(
    String table,
    List<JsonRow> rows, {
    required String onConflict,
  }) {
    if (table == 'deletions' &&
        rows.any((r) => r.containsKey('device_id'))) {
      rejectedUpserts++;
      throw Exception(
        "PGRST204: Could not find the 'device_id' column of 'deletions' "
        'in the schema cache',
      );
    }
    return super.upsert(table, rows, onConflict: onConflict);
  }
}

/// #3125 — device_id + app_version stamps on synced rows and tombstones.
void main() {
  String? journalStore;

  setUp(() {
    SyncDeviceIdentity.resetForTest('device-under-test');
    journalStore = null;
    PendingDeletionsJournal.load = () => journalStore;
    PendingDeletionsJournal.persist = (json) async => journalStore = json;
  });

  tearDown(() {
    SyncDeviceIdentity.resetForTest();
    PendingDeletionsJournal.resetForTest();
  });

  group('tombstone forensic stamps (#3125)', () {
    test('every tombstone row carries device_id + app_version', () async {
      final fake = FakeSyncTransport();
      await DeletionsSync.recordAll(
        'vehicles',
        const ['veh-1'],
        transport: fake,
      );

      final row = fake.upsertedRows('deletions').single;
      expect(row['device_id'], 'device-under-test');
      expect(row['app_version'], SyncDeviceIdentity.appVersion);
      expect(row['table_name'], 'vehicles');
      expect(row['record_id'], 'veh-1');
    });

    test(
        'a pre-v4 self-host schema (no forensic columns) falls back to a '
        'stamp-less tombstone write instead of breaking deletes', () async {
      final fake = _PreV4SchemaTransport();
      final ok = await DeletionsSync.recordAll(
        'favorites',
        const ['st-1'],
        transport: fake,
      );

      expect(ok, isTrue,
          reason: 'an outdated schema must degrade, not fail the tombstone');
      expect(fake.rejectedUpserts, 1);
      final row = fake.upsertedRows('deletions').single;
      expect(row['record_id'], 'st-1');
      expect(row.containsKey('device_id'), isFalse);
      expect(row.containsKey('app_version'), isFalse);
    });
  });

  group('entity-row forensic stamps ride the JSONB data blob (#3125)', () {
    test('an uploaded fill-up data blob carries the stamps', () async {
      final fillUp = FillUp(
        id: 'f-1',
        vehicleId: 'veh-1',
        date: DateTime.utc(2026, 6, 1),
        liters: 40,
        totalCost: 72,
        odometerKm: 120000,
        fuelType: FuelType.e10,
      );
      final fake = FakeSyncTransport();

      await FillUpsSync.merge([fillUp], transport: fake);

      final data =
          fake.upsertedRows('fill_ups').single['data'] as Map;
      expect(data['device_id'], 'device-under-test');
      expect(data['app_version'], SyncDeviceIdentity.appVersion);
      // The stamps are additive — the model payload is intact and a
      // decode of the same blob still round-trips (unknown keys ignored).
      expect(data['liters'], 40);
      expect(FillUp.fromJson(Map<String, dynamic>.from(data)).id, 'f-1');
    });

    test('an uploaded vehicle data blob carries the stamps', () async {
      const vehicle = VehicleProfile(id: 'v-1', name: 'Car');
      final fake = FakeSyncTransport();

      await VehiclesSync.merge([vehicle], transport: fake);

      final data = fake.upsertedRows('vehicles').single['data'] as Map;
      expect(data['device_id'], 'device-under-test');
      expect(data['app_version'], SyncDeviceIdentity.appVersion);
      expect(data['name'], 'Car');
    });
  });

  group('device identity contract', () {
    test('deviceId is session-stable without persistent storage', () {
      SyncDeviceIdentity.resetForTest();
      final first = SyncDeviceIdentity.deviceId;
      expect(SyncDeviceIdentity.deviceId, first);
      expect(first, isNotEmpty);
    });
  });

  group('self-host schema parity (HARD RULE #5)', () {
    test('the wizard SQL creates AND retrofits the forensic columns', () {
      // Fresh install: CREATE TABLE carries the columns.
      expect(tableSql['deletions'], contains('device_id TEXT'));
      expect(tableSql['deletions'], contains('app_version TEXT'));
      // Existing install: the CREATE block is skipped for a present table,
      // so the unconditional upgrade section must retrofit the columns.
      final sqlForExisting =
          SchemaVerifier.getMigrationSql(const {'deletions': true});
      expect(sqlForExisting,
          contains('ADD COLUMN IF NOT EXISTS device_id TEXT'));
      expect(sqlForExisting,
          contains('ADD COLUMN IF NOT EXISTS app_version TEXT'));
    });

    test('the schema version was bumped for the new explicit columns', () {
      expect(kSupabaseSchemaVersion, greaterThanOrEqualTo(4));
    });
  });
}
