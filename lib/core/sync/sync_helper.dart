// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sync_provider.dart';
import '../../core/logging/error_logger.dart';

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
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: {'where': 'SyncHelper[$context]: sync failed'}));
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
}
