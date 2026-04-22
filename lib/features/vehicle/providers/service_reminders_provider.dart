import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/service_reminder_store.dart';
import '../domain/entities/service_reminder.dart';
import '../domain/service_reminder_checker.dart';

part 'service_reminders_provider.g.dart';

/// Shared [ServiceReminderStore] instance. Kept alive for the app's
/// lifetime so the async notifier below can re-read it without
/// re-instantiating a store per operation.
@Riverpod(keepAlive: true)
ServiceReminderStore serviceReminderStore(Ref ref) =>
    ServiceReminderStore();

/// Vehicle service-reminder state (#584 phase 1).
///
/// Loads the persisted list from the store on first read and exposes
/// [add] / [remove] / [toggle] / [markServiced] for the phase-2 UI
/// layer. Mirrors the shape of `radiusAlertsProvider` so the two
/// feel familiar side-by-side in the Settings screen.
@Riverpod(keepAlive: true)
class ServiceReminders extends _$ServiceReminders {
  static const _checker = ServiceReminderChecker();

  @override
  Future<List<ServiceReminder>> build() async {
    final store = ref.read(serviceReminderStoreProvider);
    return store.list();
  }

  /// Persist [reminder] and refresh state. If a reminder with the
  /// same id already exists it's overwritten (the store's upsert
  /// semantics).
  Future<void> add(ServiceReminder reminder) async {
    final store = ref.read(serviceReminderStoreProvider);
    try {
      await store.upsert(reminder);
    } catch (e) {
      debugPrint('ServiceReminders.add: $e');
    }
    state = AsyncValue.data(await store.list());
  }

  /// Remove the reminder with [id] and refresh state. No-op when
  /// unknown.
  Future<void> remove(String id) async {
    final store = ref.read(serviceReminderStoreProvider);
    try {
      await store.remove(id);
    } catch (e) {
      debugPrint('ServiceReminders.remove: $e');
    }
    state = AsyncValue.data(await store.list());
  }

  /// Flip [ServiceReminder.enabled] on the reminder with [id].
  /// No-op when the id isn't in the current list — mirrors the
  /// radius-alert provider's quiet-no-op behaviour so the UI can
  /// blindly call toggle.
  Future<void> toggle(String id) async {
    final store = ref.read(serviceReminderStoreProvider);
    final current = await store.list();
    final match = current.where((r) => r.id == id).toList();
    if (match.isEmpty) {
      state = AsyncValue.data(current);
      return;
    }
    final updated = match.first.copyWith(enabled: !match.first.enabled);
    try {
      await store.upsert(updated);
    } catch (e) {
      debugPrint('ServiceReminders.toggle: $e');
    }
    state = AsyncValue.data(await store.list());
  }

  /// Record that the service referenced by [id] was performed at
  /// [currentOdometerKm]. Snaps `lastServiceOdometerKm` to the
  /// provided value so the next due threshold sits one interval
  /// ahead. No-op when the id is unknown.
  Future<void> markServiced(String id, int currentOdometerKm) async {
    final store = ref.read(serviceReminderStoreProvider);
    final current = await store.list();
    final match = current.where((r) => r.id == id).toList();
    if (match.isEmpty) {
      state = AsyncValue.data(current);
      return;
    }
    final updated = _checker.markServiced(match.first, currentOdometerKm);
    try {
      await store.upsert(updated);
    } catch (e) {
      debugPrint('ServiceReminders.markServiced: $e');
    }
    state = AsyncValue.data(await store.list());
  }
}
