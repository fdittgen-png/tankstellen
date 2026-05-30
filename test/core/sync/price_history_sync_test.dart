// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/price_history_sync.dart';

/// Offline tests for [PriceHistorySync] (#727 extract, #2249 DE-gate +
/// dedup-merge). Runs fully offline — exercises the country gate, the
/// "TankSync client is null → empty list" guard, and the pure merge helper
/// without touching Supabase.
///
/// Live counterpart sits at `test/core/data/sync_repository_test.dart`
/// under `@Tags(['network'])`; rerun that file (not this one) when the
/// `price_snapshots` table schema or the TankSync RPC contract changes.
/// See `docs/guides/NETWORK_TESTS.md`.
void main() {
  group('PriceHistorySync.fetch', () {
    test('returns empty for a DE station when client is not configured',
        () async {
      // de- prefix passes the country gate; TankSyncClient.client is null in
      // unit context, so the client-null guard returns empty.
      final rows = await PriceHistorySync.fetch('de-1');
      expect(rows, isEmpty);
    });

    test('short-circuits non-DE stations before any network call (#2249)',
        () async {
      // France/Italy/Spain etc. are not backfilled in Supabase — the gate
      // returns empty without even reaching the client lookup.
      expect(await PriceHistorySync.fetch('fr-123'), isEmpty);
      expect(await PriceHistorySync.fetch('it-456'), isEmpty);
      expect(await PriceHistorySync.fetch('es-789'), isEmpty);
      // Unprefixed legacy id → unknown country → also gated out.
      expect(await PriceHistorySync.fetch('st-1'), isEmpty);
    });

    test('honours custom days parameter without throwing', () async {
      final rows = await PriceHistorySync.fetch('de-1', days: 7);
      expect(rows, isEmpty);
    });
  });

  group('PriceHistorySync.isRemotelyBackfilled', () {
    test('true only for DE-prefixed station ids', () {
      expect(PriceHistorySync.isRemotelyBackfilled('de-42'), isTrue);
      expect(PriceHistorySync.isRemotelyBackfilled('fr-42'), isFalse);
      expect(PriceHistorySync.isRemotelyBackfilled('it-42'), isFalse);
      expect(PriceHistorySync.isRemotelyBackfilled('unknown'), isFalse);
    });

    test('backfilledCountry is DE', () {
      expect(PriceHistorySync.backfilledCountry, 'DE');
    });
  });

  group('PriceHistorySync.mergeRemoteIntoLocal', () {
    Map<String, dynamic> local(String ts, {double? e5}) => {
          'stationId': 'de-1',
          'recordedAt': ts,
          'e5': e5,
        };
    Map<String, dynamic> remote(String ts, {double? e5}) => {
          'station_id': 'de-1',
          'recorded_at': ts,
          'e5': e5,
        };

    test('unions distinct timestamps, newest first', () {
      final merged = PriceHistorySync.mergeRemoteIntoLocal(
        stationId: 'de-1',
        localRecords: [local('2026-05-03T10:00:00Z', e5: 1.7)],
        remoteRows: [
          remote('2026-05-01T10:00:00Z', e5: 1.5),
          remote('2026-05-02T10:00:00Z', e5: 1.6),
        ],
      );
      expect(merged, hasLength(3));
      expect(merged.first['recordedAt'], '2026-05-03T10:00:00Z');
      expect(merged.last['recordedAt'], '2026-05-01T10:00:00Z');
    });

    test('de-duplicates a snapshot present in both stores (local wins)', () {
      const ts = '2026-05-02T10:00:00Z';
      final merged = PriceHistorySync.mergeRemoteIntoLocal(
        stationId: 'de-1',
        localRecords: [local(ts, e5: 1.9)], // local value
        remoteRows: [remote(ts, e5: 1.5)], // remote value for same instant
      );
      expect(merged, hasLength(1));
      // Local record wins on the (stationId, recordedAt) collision.
      expect(merged.single['e5'], 1.9);
    });

    test('normalizes remote snake_case columns into camelCase shape', () {
      final merged = PriceHistorySync.mergeRemoteIntoLocal(
        stationId: 'de-1',
        localRecords: const [],
        remoteRows: [
          {
            'station_id': 'de-9',
            'recorded_at': '2026-05-02T10:00:00Z',
            'e10': 1.79,
            'diesel': 1.69,
            'diesel_premium': 1.85,
          },
        ],
      );
      expect(merged, hasLength(1));
      final r = merged.single;
      expect(r['stationId'], 'de-9');
      expect(r['recordedAt'], '2026-05-02T10:00:00Z');
      expect(r['e10'], 1.79);
      expect(r['diesel'], 1.69);
      expect(r['dieselPremium'], 1.85);
    });

    test('drops records with an unparseable / missing timestamp', () {
      final merged = PriceHistorySync.mergeRemoteIntoLocal(
        stationId: 'de-1',
        localRecords: [
          {'stationId': 'de-1', 'recordedAt': 'not-a-date'},
          {'stationId': 'de-1'}, // no timestamp at all
        ],
        remoteRows: [remote('2026-05-02T10:00:00Z', e5: 1.6)],
      );
      expect(merged, hasLength(1));
      expect(merged.single['recordedAt'], '2026-05-02T10:00:00Z');
    });
  });
}
