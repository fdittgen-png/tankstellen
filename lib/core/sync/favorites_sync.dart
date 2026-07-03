// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../data/storage_repository.dart';
import '../services/non_fuel_station_guard.dart';
import 'entity_sync.dart';
import 'sync_events.dart';
import 'sync_transport.dart';

/// Which favorites store a [FavoriteRecord] belongs to (#3452).
enum FavoriteKind {
  fuel('fuel'),
  ev('ev');

  /// The `favorites.kind` column value.
  final String wire;
  const FavoriteKind(this.wire);

  /// Resolve the kind for a server row: an explicit `kind` column wins,
  /// and an `ocm-*` id ALWAYS resolves to [ev] regardless of the column —
  /// the #3455 routing guard, so a legacy/defaulted `'fuel'` row can never
  /// steer an EV id into the fuel favorites store (whence it would leak
  /// into the fuel detail chains).
  static FavoriteKind of({required String id, String? wire}) {
    if (isNonFuelStationId(id)) return FavoriteKind.ev;
    return wire == FavoriteKind.ev.wire ? FavoriteKind.ev : FavoriteKind.fuel;
  }
}

/// One synced favorite: the station id, which store it belongs to, and
/// the full station JSON payload (#3452) — so a favorite pulled on
/// device B renders name/coords immediately instead of waiting for the
/// station to be visited. [data] is null for legacy favorites saved
/// before payload persistence existed.
class FavoriteRecord {
  final String id;
  final FavoriteKind kind;
  final Map<String, dynamic>? data;

  const FavoriteRecord({required this.id, required this.kind, this.data});
}

/// Signature of [FavoritesSync.merge] — the record-based successor of the
/// #3076 `IdMergeFn` seam, injectable so the pull-persist wiring stays
/// unit-testable without a live Supabase session.
typedef FavoritesMergeFn = Future<List<FavoriteRecord>> Function(
  List<FavoriteRecord> local,
);

/// Favorites sync with Supabase, pulled out of [SyncService] (#727).
///
/// Bidirectional merge over the `favorites` table — local-only records
/// upload (idempotent via `(user_id, station_id)` upsert conflict),
/// and the returned list is the union of local + server. Since #3127
/// this is a thin config over the shared [EntitySync] engine, which
/// carries the tombstone filter (#3078), the durable deletion journal
/// (#3123) and the per-table run-trace counts (#3126).
///
/// ## #3452 — EV favorites + payloads (schema v5)
///
/// The record shape grew from a bare id to [FavoriteRecord]:
///
///  * **kind** — fuel and EV (`ocm-*`) favorites share the one
///    `favorites` table, discriminated by the `kind` column. A sibling
///    table was rejected: it would need its own verifier entry, wizard
///    CREATE + RLS policy, tombstone `table_name`, and a second
///    registered pull — all to store the same `(user_id, station_id,
///    data)` shape. A column extension rides the existing `upgradeSql`
///    ALTER path, keeps the merge ONE seam, and existing tombstones
///    keep working unchanged.
///  * **data** — the full station JSON (`Station.toJson` /
///    `ChargingStation.toJson`), JSONB. [EntitySync.reuploadWhen]
///    backfills payloads onto pre-v5 id-only server rows.
///
/// A pre-v5 self-host schema rejects the new columns (select AND
/// upsert), so the merge degrades to "input returned unchanged" until
/// the wizard SQL is re-run — flagged, not silent: the
/// `kSupabaseSchemaVersion` bump makes `SchemaVerifier.isSchemaOutdated`
/// surface the "re-run the setup SQL" hint.
class FavoritesSync {
  FavoritesSync._();

  static final _sync = EntitySync<FavoriteRecord>(
    table: 'favorites',
    logName: 'FavoritesSync',
    idColumn: 'station_id',
    selectColumns: 'station_id,kind,data',
    onConflict: 'user_id,station_id',
    idOf: (r) => r.id,
    // Uniform keys across every row — a PostgREST bulk upsert requires
    // all rows to carry the same columns, so null payloads stay explicit.
    encode: (r, userId) => {
      'user_id': userId,
      'station_id': r.id,
      'kind': r.kind.wire,
      'data': r.data == null
          ? null
          : {...r.data!, ...EntitySync.forensicStamps()},
      'station_name': r.data?['name'] is String ? r.data!['name'] : null,
    },
    decode: _decodeRow,
    // #3452 — payload backfill: a favorite that existed server-side as a
    // pre-v5 id-only row gets its local payload re-upserted once.
    reuploadWhen: (local, serverRow) =>
        local.data != null && serverRow['data'] == null,
  );

  static FavoriteRecord? _decodeRow(JsonRow row) {
    final id = row['station_id'];
    if (id is! String || id.isEmpty) return null;
    final data = row['data'];
    return FavoriteRecord(
      id: id,
      kind: FavoriteKind.of(
        id: id,
        wire: row['kind'] is String ? row['kind'] as String : null,
      ),
      data: data is Map<String, dynamic> ? data : null,
    );
  }

  /// Merge [local] with the user's `favorites` rows on Supabase.
  /// Returns the superset (local ∪ server), payloads included.
  /// Unauthenticated path returns the input unchanged. [transport] is
  /// injectable for tests.
  static Future<List<FavoriteRecord>> merge(
    List<FavoriteRecord> local, {
    SyncTransport? transport,
  }) =>
      _sync.merge(local, transport: transport);

  /// Every locally-stored favorite — fuel AND EV (#3452) — as the
  /// records [merge] consumes, each carrying its persisted station
  /// payload when one exists. An `ocm-*` id found in the FUEL store (the
  /// legacy #3455 leak state) resolves to [FavoriteKind.ev], so the next
  /// [persist] self-heals it into the EV store.
  static List<FavoriteRecord> localRecords(StorageRepository storage) => [
        for (final id in storage.getFavoriteIds())
          FavoriteRecord(
            id: id,
            kind: FavoriteKind.of(id: id, wire: FavoriteKind.fuel.wire),
            data: storage.getFavoriteStationData(id),
          ),
        for (final id in storage.getEvFavoriteIds())
          FavoriteRecord(
            id: id,
            kind: FavoriteKind.ev,
            data: storage.getEvFavoriteStationData(id),
          ),
      ];

  /// Persist the [merge] result back into local storage: ids split per
  /// store ([FavoriteKind.of] keeps `ocm-*` ids out of the fuel store —
  /// the #3455 leak guard), and pulled payloads are written ONLY where
  /// the device has none yet (local wins — an in-flight local edit is
  /// never clobbered, mirroring the ratings pull policy).
  ///
  /// Returns the number of payload blobs written, so [syncAndPersist]'s
  /// #3446 emit also fires when only payloads (not ids) changed.
  static Future<int> persist(
    StorageRepository storage,
    List<FavoriteRecord> merged,
  ) async {
    final fuelIds = <String>[];
    final evIds = <String>[];
    for (final record in merged) {
      (record.kind == FavoriteKind.ev ? evIds : fuelIds).add(record.id);
    }
    await storage.setFavoriteIds(fuelIds);
    await storage.setEvFavoriteIds(evIds);
    var payloadWrites = 0;
    for (final record in merged) {
      final data = record.data;
      if (data == null) continue;
      if (record.kind == FavoriteKind.ev) {
        if (storage.getEvFavoriteStationData(record.id) == null) {
          await storage.saveEvFavoriteStationData(record.id, data);
          payloadWrites++;
        }
      } else if (storage.getFavoriteStationData(record.id) == null) {
        await storage.saveFavoriteStationData(record.id, data);
        payloadWrites++;
      }
    }
    return payloadWrites;
  }

  /// The one favorites pull-persist seam (#3076/#3452): build the local
  /// records (fuel + EV, payloads), [merge] them with the server, write
  /// the union back per store, and emit the #3446 [SyncTableChanged]
  /// AFTER the persist — the delta spans BOTH id sets AND the pulled
  /// payload writes, so a payload arriving for an already-known id still
  /// refreshes the favorites UI. Returns the changed count.
  static Future<int> syncAndPersist(
    StorageRepository storage, {
    FavoritesMergeFn merge = FavoritesSync.merge,
  }) async {
    Set<String> allIds() =>
        {...storage.getFavoriteIds(), ...storage.getEvFavoriteIds()};
    final before = allIds();
    final merged = await merge(localRecords(storage));
    final payloadWrites = await persist(storage, merged);
    final after = allIds();
    final changed = after.difference(before).length +
        before.difference(after).length +
        payloadWrites;
    SyncEvents.instance.emit(SyncTableChanged(SyncTables.favorites, changed));
    return changed;
  }

  /// Delete a single favorite (fuel or EV) from the server. Called only
  /// when the user explicitly removes a favorite on this device — the
  /// union merge path never deletes. Tombstone-first (#3078/#3123): the
  /// durable "this id is dead" record must not depend on the row
  /// delete succeeding.
  static Future<void> delete(String stationId, {SyncTransport? transport}) =>
      _sync.delete(stationId, transport: transport);
}
