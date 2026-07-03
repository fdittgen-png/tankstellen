// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/favorites_sync.dart';

import '../../fakes/fake_hive_storage.dart';
import '../../helpers/silence_error_logger.dart';
import 'fake_sync_transport.dart';

/// #3452 — EV favorites + favorite-station payloads round-trip.
///
/// Acceptance criterion of the issue: a favorite (fuel AND EV) added on
/// device A appears WITH its station payload on device B after a sync
/// pull — previously only fuel IDs synced, so device B rendered nothing
/// until the station was visited there, and EV favorites never synced at
/// all.
///
/// Driven through the real [FavoritesSync] merge + persist over the
/// shared [FakeSyncTransport] (the "server"), with two [FakeHiveStorage]
/// instances standing in for the two devices.
void main() {
  silenceErrorLoggerSpool();

  const fuelPayload = <String, dynamic>{
    'name': 'Shell Alpha',
    'brand': 'Shell',
    'lat': 52.5,
    'lng': 13.4,
  };
  const evPayload = <String, dynamic>{
    'name': 'Ionity Berchem',
    'operator': 'Ionity',
    'latitude': 49.55,
    'longitude': 6.12,
  };

  /// One device's full sync pass: local records → merge → persist.
  Future<void> syncPass(FakeHiveStorage storage, FakeSyncTransport t) async {
    final merged = await FavoritesSync.merge(
      FavoritesSync.localRecords(storage),
      transport: t,
    );
    await FavoritesSync.persist(storage, merged);
  }

  test('fuel + EV favorite added on A arrives on B WITH payload', () async {
    final transport = FakeSyncTransport();
    final deviceA = FakeHiveStorage();
    final deviceB = FakeHiveStorage();

    // Device A: one fuel + one EV favorite, both with payloads.
    await deviceA.addFavorite('de-1');
    await deviceA.saveFavoriteStationData('de-1', fuelPayload);
    await deviceA.addEvFavorite('ocm-9');
    await deviceA.saveEvFavoriteStationData('ocm-9', evPayload);

    await syncPass(deviceA, transport);

    // The server rows carry kind + data + station_name.
    final rows = transport.tables['favorites']!;
    expect(rows, hasLength(2));
    final fuelRow = rows.singleWhere((r) => r['station_id'] == 'de-1');
    expect(fuelRow['kind'], 'fuel');
    expect((fuelRow['data'] as Map)['name'], 'Shell Alpha');
    expect(fuelRow['station_name'], 'Shell Alpha');
    final evRow = rows.singleWhere((r) => r['station_id'] == 'ocm-9');
    expect(evRow['kind'], 'ev');
    expect((evRow['data'] as Map)['operator'], 'Ionity');

    // Device B: fresh install pulls both, WITH payloads, each into the
    // right store.
    await syncPass(deviceB, transport);
    expect(deviceB.getFavoriteIds(), ['de-1']);
    expect(deviceB.getEvFavoriteIds(), ['ocm-9']);
    expect(deviceB.getFavoriteStationData('de-1')?['name'], 'Shell Alpha',
        reason: 'the payload must arrive so the favorite renders '
            'name/coords immediately');
    expect(deviceB.getEvFavoriteStationData('ocm-9')?['operator'], 'Ionity');
  });

  test('a server ocm-* row NEVER lands in the fuel store — even when a '
      'legacy row says kind=fuel (#3455 guard)', () async {
    final transport = FakeSyncTransport(tables: {
      'favorites': [
        {
          'user_id': 'user-1',
          'station_id': 'ocm-196522',
          'kind': 'fuel', // legacy/defaulted column value
          'data': evPayload,
        },
      ],
    });
    final device = FakeHiveStorage();

    await syncPass(device, transport);

    expect(device.getFavoriteIds(), isEmpty,
        reason: 'an EV id in the fuel store is exactly the #3455 '
            '400-storm input');
    expect(device.getEvFavoriteIds(), ['ocm-196522']);
    expect(
        device.getEvFavoriteStationData('ocm-196522')?['name'],
        'Ionity Berchem');
  });

  test('payload backfill: a pre-v5 id-only server row gets the local '
      'payload re-upserted', () async {
    final transport = FakeSyncTransport(tables: {
      'favorites': [
        // Pre-v5 row: id only, no payload.
        {'user_id': 'user-1', 'station_id': 'de-1', 'data': null},
      ],
    });
    final device = FakeHiveStorage();
    await device.addFavorite('de-1');
    await device.saveFavoriteStationData('de-1', fuelPayload);

    await syncPass(device, transport);

    final row = transport.tables['favorites']!
        .singleWhere((r) => r['station_id'] == 'de-1');
    expect((row['data'] as Map?)?['name'], 'Shell Alpha',
        reason: 'reuploadWhen must backfill the payload onto the '
            'id-only row — the union alone never re-uploads '
            'both-sides ids');
  });

  test('pulled payload never clobbers an existing local payload '
      '(local wins)', () async {
    final transport = FakeSyncTransport(tables: {
      'favorites': [
        {
          'user_id': 'user-1',
          'station_id': 'de-1',
          'kind': 'fuel',
          'data': {'name': 'Server Name'},
        },
      ],
    });
    final device = FakeHiveStorage();
    await device.addFavorite('de-1');
    await device.saveFavoriteStationData('de-1', fuelPayload);

    await syncPass(device, transport);

    expect(device.getFavoriteStationData('de-1')?['name'], 'Shell Alpha');
  });

  test('EV favorite deleted on A stays dead on B (tombstone round-trip)',
      () async {
    final transport = FakeSyncTransport();
    final deviceA = FakeHiveStorage();
    final deviceB = FakeHiveStorage();

    await deviceA.addEvFavorite('ocm-9');
    await deviceA.saveEvFavoriteStationData('ocm-9', evPayload);
    await syncPass(deviceA, transport);
    await syncPass(deviceB, transport);
    expect(deviceB.getEvFavoriteIds(), ['ocm-9']);

    // A deletes → tombstone + row delete.
    await deviceA.removeEvFavorite('ocm-9');
    await deviceA.removeEvFavoriteStationData('ocm-9');
    await FavoritesSync.delete('ocm-9', transport: transport);

    // B's next pass removes it locally instead of resurrecting it.
    await syncPass(deviceB, transport);
    expect(deviceB.getEvFavoriteIds(), isEmpty,
        reason: 'the tombstone must remove the deleted EV favorite from '
            'device B and keep it from re-uploading');
    expect(transport.tables['favorites'] ?? const [], isEmpty);
  });
}
