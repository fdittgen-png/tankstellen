// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sync_provider.dart';
import '../../core/logging/error_logger.dart';
import '../utils/json_extensions.dart';

/// Shared helper to execute sync operations only when TankSync is connected.
///
/// Eliminates the duplicated pattern across providers:
/// ```dart
/// try {
///   final syncState = ref.read(syncStateProvider);
///   if (syncState.enabled && syncState.userId != null) {
///     await SyncService.syncXxx(state);
///   }
/// } catch (_) { debugPrint('...sync failed'); }
/// ```
///
/// Usage:
/// ```dart
/// await SyncHelper.syncIfEnabled(ref, 'Favorites',
///   () => SyncService.syncFavorites(state),
/// );
/// ```
class SyncHelper {
  SyncHelper._();

  /// Execute [syncFn] only if TankSync is enabled.
  ///
  /// [ref] — Riverpod ref for reading sync state.
  /// [context] — Human-readable name for debug logging (e.g., 'Favorites').
  /// [syncFn] — The sync operation to perform.
  ///
  /// The sync function does NOT receive a userId because SyncService always
  /// reads the authenticated userId from the active JWT session — NOT from
  /// Hive storage. Checking `syncState.enabled` is sufficient; the session
  /// userId is validated inside SyncService methods.
  ///
  /// Failures are caught silently with a debug log — sync must never block
  /// local operations.
  static Future<void> syncIfEnabled(
    Ref ref,
    String context,
    Future<void> Function() syncFn,
  ) async {
    try {
      final syncState = ref.read(syncStateProvider);
      if (syncState.enabled) {
        await syncFn();
      }
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st, context: {'where': 'SyncHelper[$context]: sync failed'}));
    }
  }

  /// Alias for [syncIfEnabled] — both use the same guard logic.
  static Future<void> fireAndForget(
    Ref ref,
    String context,
    Future<void> Function() syncFn,
  ) => syncIfEnabled(ref, context, syncFn);

  /// Drop every element of [serverRows] whose key is in [tombstoned] (#3078).
  ///
  /// The shared tombstone-filter seam for the union-merge sync classes. A
  /// union merge re-adds any server row, so a record one device deleted comes
  /// back from another device's still-local copy — the delete "resurrects".
  /// Each sync class fetches its deletion tombstones
  /// (`DeletionsSync.fetchTombstonedIds`) and runs the **server** rows through
  /// this filter BEFORE the local ∪ server union, so a tombstoned id is never
  /// re-included no matter which side still holds it.
  ///
  /// [key] extracts the record id from each row (identity for a `List<String>`
  /// of ids). Pure + side-effect-free so it is the unit-testable seam the
  /// resurrection regression test pins.
  static Iterable<T> removeTombstoned<T>(
    Iterable<T> serverRows,
    Set<String> tombstoned, {
    required String? Function(T) key,
  }) {
    if (tombstoned.isEmpty) return serverRows;
    return serverRows.where((row) => !tombstoned.contains(key(row)));
  }

  /// Last-write-wins comparison over the ids present on BOTH sides (#3122).
  ///
  /// The id-union merges upload only local-only ids and download only
  /// server-only ids, so a record present on both sides never re-syncs —
  /// an edit to an existing fill-up / vehicle diverges between devices
  /// forever. This is the shared seam that fixes it: for every both-sides
  /// id it compares the server row's `updated_at` against the record's
  /// local modification stamp and splits them into
  ///
  /// - [LwwSplit.localNewer] — local edit is fresher → caller re-upserts;
  /// - [LwwSplit.serverNewer] — server row is fresher → caller decodes the
  ///   row and overwrites the local record.
  ///
  /// **Tie / missing-stamp policy: skip.** A both-sides id is acted on only
  /// when BOTH stamps are present and strictly unequal. Rationale: skipping
  /// is non-destructive (a legacy record without a local stamp keeps
  /// today's behaviour instead of being clobbered by whichever side
  /// happens to hold a stamp), it produces zero churn for records that are
  /// already in sync (equal stamps), and it self-heals — the next edit on
  /// either side stamps the record and LWW propagation kicks in.
  ///
  /// [tombstoned] ids are excluded outright — a deleted record must never
  /// be re-uploaded or re-downloaded by the LWW path.
  static LwwSplit<L> lwwSplit<L>({
    required Iterable<L> local,
    required Iterable<Map<String, dynamic>> serverRows,
    required String? Function(L) id,
    required DateTime? Function(L) localStamp,
    String stampColumn = 'updated_at',
    Set<String> tombstoned = const {},
  }) {
    final serverById = <String, Map<String, dynamic>>{};
    for (final row in serverRows) {
      final rowId = row.getString('id');
      if (rowId != null) serverById[rowId] = row;
    }

    final localNewer = <L>[];
    final serverNewer = <Map<String, dynamic>>[];
    for (final record in local) {
      final recordId = id(record);
      if (recordId == null || tombstoned.contains(recordId)) continue;
      final serverRow = serverById[recordId];
      if (serverRow == null) continue; // local-only — the union path uploads.

      final localTime = localStamp(record)?.toUtc();
      final serverTime =
          DateTime.tryParse(serverRow.getString(stampColumn) ?? '')?.toUtc();
      // Tie / missing stamp → skip (see policy above).
      if (localTime == null || serverTime == null) continue;
      if (localTime.isAfter(serverTime)) {
        localNewer.add(record);
      } else if (serverTime.isAfter(localTime)) {
        serverNewer.add(serverRow);
      }
    }
    return LwwSplit(localNewer: localNewer, serverNewer: serverNewer);
  }
}

/// Result of [SyncHelper.lwwSplit] — the both-sides records each side of
/// the merge must re-sync (#3122).
class LwwSplit<L> {
  /// Local records whose stamp is strictly newer than the server row's —
  /// the caller re-upserts these.
  final List<L> localNewer;

  /// Server rows strictly newer than the local record — the caller decodes
  /// these and overwrites the matching local records.
  final List<Map<String, dynamic>> serverNewer;

  const LwwSplit({required this.localNewer, required this.serverNewer});
}
