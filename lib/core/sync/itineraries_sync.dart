// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/logging/error_logger.dart';
import '../../features/itinerary/domain/entities/saved_itinerary.dart';
import '../utils/json_extensions.dart';
import 'deletions_sync.dart';
import 'entity_sync.dart';
import 'sync_helper.dart';
import 'sync_transport.dart';

/// Saved-itinerary sync with Supabase, pulled out of [SyncService]
/// (#727).
///
/// Unlike the [EntitySync]-merged entities, itineraries are one-way
/// from the server's perspective: the local provider holds the source
/// of truth and pushes explicitly via [save] / [delete] on every user
/// action, then reconciles with [fetchAll] on login. Deduplication
/// happens at the caller (the itinerary provider unions the local list
/// with `fetchAll`'s return before rendering). Since #3127 the I/O
/// rides the injectable [SyncTransport] seam and the delete shares
/// [EntitySync.deleteRow].
class ItinerariesSync {
  ItinerariesSync._();

  static const _table = 'itineraries';

  /// Save or update an itinerary on the server. Returns `true` on
  /// success, `false` when unauthenticated or the upsert fails —
  /// mirrors the original contract so the itinerary provider's
  /// "synced?" badge keeps working.
  static Future<bool> save(
    SavedItinerary itinerary, {
    SyncTransport? transport,
  }) async {
    final t = transport ?? SupabaseSyncTransport.currentOrNull();
    if (t == null) return false;

    try {
      await t.upsert(
        _table,
        [
          {
            'id': itinerary.id,
            'user_id': t.userId,
            'name': itinerary.name,
            'waypoints': itinerary.waypoints,
            'distance_km': itinerary.distanceKm,
            'duration_minutes': itinerary.durationMinutes,
            'avoid_highways': itinerary.avoidHighways,
            'fuel_type': itinerary.fuelType,
            'selected_station_ids': itinerary.selectedStationIds,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          },
        ],
        onConflict: 'id',
      );
      debugPrint('ItinerariesSync.save: saved "${itinerary.name}"');
      return true;
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st,
          context: const {'where': 'ItinerariesSync.save FAILED'}));
      return false;
    }
  }

  /// Fetch every itinerary owned by the authenticated user, newest
  /// edit first. Returns an empty list when unauthenticated or the
  /// query fails — the provider keeps showing whatever was in local
  /// cache.
  static Future<List<SavedItinerary>> fetchAll({
    SyncTransport? transport,
  }) async {
    final t = transport ?? SupabaseSyncTransport.currentOrNull();
    if (t == null) return [];

    try {
      final rows = await t.select(_table, '*');

      // #3078 — never re-hydrate an itinerary deleted on another device.
      final tombstoned =
          await DeletionsSync.fetchTombstonedIds(_table, transport: t);
      final result = SyncHelper.removeTombstoned(
        rows,
        tombstoned,
        key: (r) => r.getString('id'),
      ).map((r) {
        final createdAtStr = r.getString('created_at');
        final updatedAtStr = r.getString('updated_at');
        return SavedItinerary(
          id: r.getString('id') ?? '',
          name: r.getString('name') ?? '',
          waypoints: r.getList<Map<String, dynamic>>('waypoints'),
          distanceKm: r.getDouble('distance_km') ?? 0.0,
          durationMinutes: r.getDouble('duration_minutes') ?? 0.0,
          avoidHighways: r.getBool('avoid_highways') ?? false,
          fuelType: r.getString('fuel_type') ?? 'e10',
          selectedStationIds: r.getList<String>('selected_station_ids'),
          createdAt: createdAtStr != null
              ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
              : DateTime.now(),
          updatedAt: updatedAtStr != null
              ? DateTime.tryParse(updatedAtStr) ?? DateTime.now()
              : DateTime.now(),
        );
      }).toList()
        // The pre-#3127 query ordered server-side
        // (`order('updated_at', ascending: false)`); the transport seam
        // is filter-only, so the same newest-first contract is applied
        // here instead.
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return result;
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st,
          context: const {'where': 'ItinerariesSync.fetchAll FAILED'}));
      return [];
    }
  }

  /// Delete a single itinerary from the server. Returns `true` on
  /// success, `false` when unauthenticated or the delete fails.
  /// Tombstone-first (journal-backed, #3078/#3123) via the shared
  /// [EntitySync.deleteRow].
  static Future<bool> delete(String itineraryId, {SyncTransport? transport}) =>
      EntitySync.deleteRow(
        table: _table,
        idColumn: 'id',
        recordId: itineraryId,
        logContext: 'ItinerariesSync.delete',
        transport: transport,
      );
}
