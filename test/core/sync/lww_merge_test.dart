// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/fill_ups_sync.dart';
import 'package:tankstellen/core/sync/sync_helper.dart';
import 'package:tankstellen/core/sync/sync_transport.dart';
import 'package:tankstellen/core/sync/vehicles_sync.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';

import 'fake_sync_transport.dart';

/// #3122 — last-write-wins edit propagation.
///
/// The id-union merges upload only local-only ids and download only
/// server-only ids, so a record present on BOTH sides never re-syncs and
/// an edit diverges between devices forever. These tests drive the real
/// merges through a [FakeSyncTransport] and pin the LWW fix:
/// local-newer re-uploads, server-newer overwrites, ties and missing
/// stamps skip, tombstoned ids stay excluded.
void main() {
  final tOld = DateTime.utc(2026, 1, 1, 12);
  final tNew = DateTime.utc(2026, 6, 1, 12);

  FillUp fill({
    required String id,
    double liters = 40,
    DateTime? updatedAt,
  }) =>
      FillUp(
        id: id,
        vehicleId: 'veh-1',
        date: DateTime.utc(2026, 1, 1),
        liters: liters,
        totalCost: liters * 1.8,
        odometerKm: 120000,
        fuelType: FuelType.e10,
        updatedAt: updatedAt,
      );

  JsonRow serverFillRow(FillUp f, {required DateTime updatedAt}) => {
        'id': f.id,
        'user_id': 'user-1',
        'data': f.toJson(),
        'updated_at': updatedAt.toIso8601String(),
      };

  group('FillUpsSync.merge — LWW (#3122)', () {
    test(
        'RED for #3122: a local edit to a both-sides record reaches '
        'the server', () async {
      // f-1 exists on BOTH sides; locally it was edited (50 L, fresher
      // stamp) — before #3122 the union merge never re-uploaded it.
      final serverCopy = fill(id: 'f-1', liters: 40, updatedAt: tOld);
      final localEdit = fill(id: 'f-1', liters: 50, updatedAt: tNew);
      final fake = FakeSyncTransport(tables: {
        'fill_ups': [serverFillRow(serverCopy, updatedAt: tOld)],
      });

      final result = await FillUpsSync.merge([localEdit], transport: fake);

      final uploaded = fake.upsertedRows('fill_ups');
      expect(uploaded, hasLength(1),
          reason: 'the local edit of a both-sides id must re-upload');
      expect(uploaded.single['id'], 'f-1');
      expect((uploaded.single['data'] as Map)['liters'], 50);
      // The upload carries the LOCAL edit stamp, not upload time, so the
      // next compare sees equal stamps and skips.
      expect(uploaded.single['updated_at'], tNew.toIso8601String());
      // The local copy stays the winner in the returned union.
      expect(result.single.liters, 50);
    });

    test('server-newer row overwrites the local copy in the returned union',
        () async {
      final serverEdit = fill(id: 'f-1', liters: 55, updatedAt: tNew);
      final localStale = fill(id: 'f-1', liters: 40, updatedAt: tOld);
      final fake = FakeSyncTransport(tables: {
        'fill_ups': [serverFillRow(serverEdit, updatedAt: tNew)],
      });

      final result = await FillUpsSync.merge([localStale], transport: fake);

      expect(fake.upsertCalls, isEmpty,
          reason: 'a stale local copy must not clobber the server edit');
      expect(result.single.liters, 55,
          reason: 'the fresher server edit must replace the local copy');
      expect(result.single.updatedAt, tNew,
          reason: 'the stamp travels inside the data blob');
    });

    test('equal stamps skip — no upload, local copy kept', () async {
      final record = fill(id: 'f-1', liters: 40, updatedAt: tNew);
      final fake = FakeSyncTransport(tables: {
        'fill_ups': [serverFillRow(record, updatedAt: tNew)],
      });

      final result = await FillUpsSync.merge([record], transport: fake);

      expect(fake.upsertCalls, isEmpty);
      expect(result.single, record);
    });

    test('missing local stamp skips — legacy record neither uploads nor '
        'is clobbered', () async {
      final serverCopy = fill(id: 'f-1', liters: 99, updatedAt: tNew);
      final legacyLocal = fill(id: 'f-1', liters: 40); // updatedAt: null
      final fake = FakeSyncTransport(tables: {
        'fill_ups': [serverFillRow(serverCopy, updatedAt: tNew)],
      });

      final result = await FillUpsSync.merge([legacyLocal], transport: fake);

      expect(fake.upsertCalls, isEmpty);
      expect(result.single.liters, 40,
          reason: 'missing-stamp policy is SKIP: the unstamped legacy '
              'record keeps the pre-LWW behaviour until its next edit');
    });

    test('tombstoned both-sides id is excluded from every LWW path',
        () async {
      final localEdit = fill(id: 'f-dead', liters: 50, updatedAt: tNew);
      final fake = FakeSyncTransport(tables: {
        'fill_ups': [
          serverFillRow(fill(id: 'f-dead', updatedAt: tOld), updatedAt: tOld),
        ],
        'deletions': [
          {'record_id': 'f-dead', 'table_name': 'fill_ups'},
        ],
      });

      final result = await FillUpsSync.merge([localEdit], transport: fake);

      expect(fake.upsertCalls, isEmpty,
          reason: 'a deleted record must never re-upload');
      expect(result, isEmpty,
          reason: 'a deleted record must never re-download');
    });

    test('local-only upload + server-only download still work', () async {
      final localOnly = fill(id: 'f-local', updatedAt: tNew);
      final serverOnly = fill(id: 'f-server', liters: 33, updatedAt: tOld);
      final fake = FakeSyncTransport(tables: {
        'fill_ups': [serverFillRow(serverOnly, updatedAt: tOld)],
      });

      final result = await FillUpsSync.merge([localOnly], transport: fake);

      expect(fake.upsertedRows('fill_ups').map((r) => r['id']),
          contains('f-local'));
      expect(result.map((f) => f.id), containsAll(['f-local', 'f-server']));
    });
  });

  group('VehiclesSync.merge — LWW (#3122)', () {
    VehicleProfile vehicle({
      required String id,
      String name = 'Car',
      DateTime? updatedAt,
    }) =>
        VehicleProfile(id: id, name: name, updatedAt: updatedAt);

    JsonRow serverVehicleRow(VehicleProfile v, {required DateTime updatedAt}) =>
        {
          'id': v.id,
          'user_id': 'user-1',
          'data': v.toJson(),
          'updated_at': updatedAt.toIso8601String(),
        };

    test('local-newer profile edit re-uploads', () async {
      final fake = FakeSyncTransport(tables: {
        'vehicles': [
          serverVehicleRow(vehicle(id: 'v-1', name: 'Old name'),
              updatedAt: tOld),
        ],
      });

      final localEdit = vehicle(id: 'v-1', name: 'New name', updatedAt: tNew);
      final result = await VehiclesSync.merge([localEdit], transport: fake);

      final uploaded = fake.upsertedRows('vehicles');
      expect(uploaded, hasLength(1));
      expect((uploaded.single['data'] as Map)['name'], 'New name');
      expect(uploaded.single['updated_at'], tNew.toIso8601String());
      expect(result.single.name, 'New name');
    });

    test('server-newer profile overwrites the local copy', () async {
      final fake = FakeSyncTransport(tables: {
        'vehicles': [
          serverVehicleRow(
              vehicle(id: 'v-1', name: 'Renamed elsewhere', updatedAt: tNew),
              updatedAt: tNew),
        ],
      });

      final localStale =
          vehicle(id: 'v-1', name: 'Old name', updatedAt: tOld);
      final result = await VehiclesSync.merge([localStale], transport: fake);

      expect(fake.upsertCalls, isEmpty);
      expect(result.single.name, 'Renamed elsewhere');
    });
  });

  group('SyncHelper.lwwSplit policy', () {
    Map<String, dynamic> row(String id, DateTime? stamp) => {
          'id': id,
          if (stamp != null) 'updated_at': stamp.toIso8601String(),
        };

    test('tie → skip; missing either stamp → skip', () {
      final local = [
        (id: 'tie', stamp: tNew),
        (id: 'no-local', stamp: null),
        (id: 'no-server', stamp: tNew),
      ];
      final split = SyncHelper.lwwSplit(
        local: local,
        serverRows: [
          row('tie', tNew),
          row('no-local', tOld),
          row('no-server', null),
        ],
        id: (r) => r.id,
        localStamp: (r) => r.stamp,
      );
      expect(split.localNewer, isEmpty);
      expect(split.serverNewer, isEmpty);
    });

    test('strict inequality decides the winner in both directions', () {
      final local = [
        (id: 'local-wins', stamp: tNew),
        (id: 'server-wins', stamp: tOld),
      ];
      final split = SyncHelper.lwwSplit(
        local: local,
        serverRows: [row('local-wins', tOld), row('server-wins', tNew)],
        id: (r) => r.id,
        localStamp: (r) => r.stamp,
      );
      expect(split.localNewer.map((r) => r.id), ['local-wins']);
      expect(split.serverNewer.map((r) => r['id']), ['server-wins']);
    });
  });
}
