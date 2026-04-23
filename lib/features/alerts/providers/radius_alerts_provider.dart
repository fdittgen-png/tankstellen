import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/radius_alert_dedup.dart';
import '../data/radius_alert_store.dart';
import '../domain/entities/radius_alert.dart';

part 'radius_alerts_provider.g.dart';

/// Shared [RadiusAlertStore] instance. Kept alive for the app's
/// lifetime so the async notifier below can re-read it without
/// re-instantiating a store per operation.
@Riverpod(keepAlive: true)
RadiusAlertStore radiusAlertStore(Ref ref) => RadiusAlertStore();

/// Shared [RadiusAlertDedup] instance. Owns the per-(alert, station)
/// "last notified" state consumed by the BG runner (#578 phase 3).
/// Exposed here so the provider layer can purge dedup rows when a
/// radius alert is deleted — otherwise stale rows would leak in the
/// shared alerts box forever.
@Riverpod(keepAlive: true)
RadiusAlertDedup radiusAlertDedup(Ref ref) => RadiusAlertDedup();

/// Radius-watchlist state (#578 phase 1).
///
/// Loads the persisted list from the store on first read and exposes
/// [add] / [remove] / [toggle] for the phase-2 UI layer. Mirrors the
/// per-station [AlertNotifier] shape so users of either can swap
/// between the two in follow-up PRs without relearning the surface.
@Riverpod(keepAlive: true)
class RadiusAlerts extends _$RadiusAlerts {
  @override
  Future<List<RadiusAlert>> build() async {
    final store = ref.read(radiusAlertStoreProvider);
    return store.list();
  }

  /// Persist [alert] and refresh state. If an alert with the same id
  /// already exists it's overwritten (the store's upsert semantics).
  Future<void> add(RadiusAlert alert) async {
    final store = ref.read(radiusAlertStoreProvider);
    try {
      await store.upsert(alert);
    } catch (e) {
      debugPrint('RadiusAlerts.add: $e');
    }
    state = AsyncValue.data(await store.list());
  }

  /// Remove the alert with [id] and refresh state. No-op if unknown.
  Future<void> remove(String id) async {
    final store = ref.read(radiusAlertStoreProvider);
    final dedup = ref.read(radiusAlertDedupProvider);
    try {
      await store.remove(id);
      // #578 phase 3 — purge dedup rows so the shared alerts box
      // doesn't accumulate stale (alertId, stationId) entries after
      // the user deletes the alert.
      await dedup.clearForAlert(id);
    } catch (e) {
      debugPrint('RadiusAlerts.remove: $e');
    }
    state = AsyncValue.data(await store.list());
  }

  /// Flip [RadiusAlert.enabled] on the alert with [id]. No-op when
  /// the id isn't in the current list — mirrors the legacy alert
  /// provider's quiet-no-op behaviour so the UI can blindly call
  /// toggle on whatever id the user tapped.
  Future<void> toggle(String id) async {
    final store = ref.read(radiusAlertStoreProvider);
    final current = await store.list();
    final match = current.where((a) => a.id == id).toList();
    if (match.isEmpty) {
      // Keep state fresh in case the list changed under us.
      state = AsyncValue.data(current);
      return;
    }
    final updated = match.first.copyWith(enabled: !match.first.enabled);
    try {
      await store.upsert(updated);
    } catch (e) {
      debugPrint('RadiusAlerts.toggle: $e');
    }
    state = AsyncValue.data(await store.list());
  }
}
