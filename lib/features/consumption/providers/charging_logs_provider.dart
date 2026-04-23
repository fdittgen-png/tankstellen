import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../ev/domain/entities/charging_log.dart';
import '../data/charging_log_store.dart';

part 'charging_logs_provider.g.dart';

/// Shared [ChargingLogStore] instance. Kept alive for the app's
/// lifetime so the notifier below can re-read it without
/// instantiating a new store per operation — mirrors the shape of
/// [radiusAlertStoreProvider] (#578) and
/// [serviceReminderRepositoryProvider] (#584).
@Riverpod(keepAlive: true)
ChargingLogStore chargingLogStore(Ref ref) => ChargingLogStore();

/// Charging-log list state (#582 phase 1).
///
/// Loads every persisted log on first read and exposes `add` /
/// `update` / `remove` mutators for the phase-2 UI layer. The
/// notifier shape follows the [RadiusAlerts] (#578) / [ServiceReminderList]
/// (#584) pattern: each mutator writes through the store, then
/// refreshes state from a fresh `store.list()` call so the list
/// stays canonical (including sort order).
///
/// [edit] preserves the incoming [ChargingLog.id] and overwrites
/// every other field — the caller is expected to `copyWith` their
/// edits onto the existing entry before calling. Named `edit`
/// instead of `update` to avoid shadowing [AsyncNotifier.update],
/// whose signature rebuilds state from a reducer callback.
@Riverpod(keepAlive: true)
class ChargingLogs extends _$ChargingLogs {
  @override
  Future<List<ChargingLog>> build() async {
    final store = ref.read(chargingLogStoreProvider);
    return store.list();
  }

  /// Persist [log] and refresh state. If a log with the same id
  /// exists it's overwritten — matches the store's upsert semantics.
  Future<void> add(ChargingLog log) async {
    final store = ref.read(chargingLogStoreProvider);
    try {
      await store.upsert(log);
    } catch (e) {
      debugPrint('ChargingLogs.add: $e');
    }
    state = AsyncValue.data(await store.list());
  }

  /// Replace the log carrying the same id as [log] with the supplied
  /// instance. Upserts rather than guarding on "must exist" so the
  /// UI layer doesn't need to pre-check — the net effect of updating
  /// a missing id is "create", which matches the user's mental
  /// model for any save action.
  Future<void> edit(ChargingLog log) async {
    final store = ref.read(chargingLogStoreProvider);
    try {
      await store.upsert(log);
    } catch (e) {
      debugPrint('ChargingLogs.edit: $e');
    }
    state = AsyncValue.data(await store.list());
  }

  /// Remove the log with [id] and refresh state. No-op if unknown —
  /// mirrors the quiet-no-op behaviour of the sibling providers so
  /// the UI can fire off a delete without pre-checking.
  Future<void> remove(String id) async {
    final store = ref.read(chargingLogStoreProvider);
    try {
      await store.remove(id);
    } catch (e) {
      debugPrint('ChargingLogs.remove: $e');
    }
    state = AsyncValue.data(await store.list());
  }
}

/// Derived view: every charging log attached to [vehicleId].
///
/// Mirrors the [serviceRemindersForVehicle] (#584) pattern — a
/// family-style selector is cheaper than making every screen filter
/// the full list by hand, and it isolates vehicle A's charts from
/// edits on vehicle B.
@riverpod
Future<List<ChargingLog>> chargingLogsForVehicle(
  Ref ref,
  String vehicleId,
) async {
  final all = await ref.watch(chargingLogsProvider.future);
  return all.where((log) => log.vehicleId == vehicleId).toList();
}
