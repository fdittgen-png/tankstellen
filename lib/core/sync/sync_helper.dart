import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sync_provider.dart';

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
      debugPrint('SyncHelper[$context]: sync failed: $e\n$st');
    }
  }

  /// Alias for [syncIfEnabled] — both use the same guard logic.
  static Future<void> fireAndForget(
    Ref ref,
    String context,
    Future<void> Function() syncFn,
  ) => syncIfEnabled(ref, context, syncFn);
}
