// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/background/background_service.dart';
import '../../../core/notifications/notification_providers.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/sync/sync_provider.dart';
import '../../../core/sync/alerts_sync.dart';
import '../data/models/price_alert.dart';
import '../data/repositories/alert_repository.dart';
import '../../../core/logging/error_logger.dart';

part 'alert_provider.g.dart';

@Riverpod(keepAlive: true)
AlertRepository alertRepository(Ref ref) {
  final storage = ref.watch(storageRepositoryProvider);
  return AlertRepository(storage);
}

/// Signature of the bidirectional alerts merge. Defaults to
/// [AlertsSync.merge]; overridable in tests so the #2246 merge-download
/// regression test can supply a fake superset without standing up
/// Supabase.
typedef AlertsMergeFn = Future<List<PriceAlert>> Function(
    List<PriceAlert> localAlerts);

/// Injectable merge function. Production code uses the real
/// [AlertsSync.merge]; tests override this provider with a fake.
@Riverpod(keepAlive: true)
AlertsMergeFn alertsMergeFn(Ref ref) => AlertsSync.merge;

@Riverpod(keepAlive: true)
class AlertNotifier extends _$AlertNotifier {
  @override
  List<PriceAlert> build() {
    final repo = ref.watch(alertRepositoryProvider);
    return repo.getAlerts();
  }

  Future<void> addAlert(PriceAlert alert) async {
    final repo = ref.read(alertRepositoryProvider);
    await repo.saveAlert(alert);
    state = repo.getAlerts();
    // #2209 — request the OS notification permission at the moment the
    // user creates their first alert (clear intent → highest grant
    // rate). Without it, Android 13+ silently drops every alert.
    unawaited(ref.read(notificationServiceProvider).requestPermission());
    // #2246 — apply the merge-download here: uploading the just-added
    // alert AND pulling down any alerts created on the user's other
    // devices is exactly the cross-device superset we want.
    await _syncAlertsIfConnected();
    await BackgroundService.reconcile();
  }

  Future<void> removeAlert(String id) async {
    final repo = ref.read(alertRepositoryProvider);
    await repo.deleteAlert(id);
    state = repo.getAlerts();
    // #2246 — do NOT apply downloads after a delete: the server still
    // holds the just-deleted row (AlertsSync has no delete propagation
    // yet), so re-downloading it would resurrect the alert the user just
    // removed. Upload-only keeps the local delete sticky on this device.
    await _syncAlertsIfConnected(applyDownloads: false);
    await BackgroundService.reconcile();
  }

  Future<void> toggleAlert(String id) async {
    final repo = ref.read(alertRepositoryProvider);
    final alerts = repo.getAlerts();
    final index = alerts.indexWhere((a) => a.id == id);
    if (index < 0) return;

    final alert = alerts[index];
    await repo.saveAlert(alert.copyWith(isActive: !alert.isActive));
    state = repo.getAlerts();
    await _syncAlertsIfConnected();
    await BackgroundService.reconcile();
  }

  /// Push local alerts to the backend and, unless [applyDownloads] is
  /// false, pull server-only alerts back into local storage.
  ///
  /// #2246 — [AlertsSync.merge] returns the merged superset
  /// (`[local, ...server-only downloaded]`). The result used to be
  /// discarded, so an alert created on another device never reached this
  /// one. We now persist the server-only rows via [_applyMergedAlerts].
  Future<void> _syncAlertsIfConnected({bool applyDownloads = true}) async {
    try {
      final syncState = ref.read(syncStateProvider);
      if (syncState.enabled) {
        final merge = ref.read(alertsMergeFnProvider);
        final merged = await merge(state);
        if (applyDownloads) {
          await _applyMergedAlerts(merged);
        }
      }
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {'where': 'AlertProvider: sync failed'}));
    }
  }

  /// Persist any [merged] alert whose id isn't already in local storage,
  /// then refresh state. Server-only downloads from [AlertsSync.merge]
  /// land here; local rows are left untouched (their ids already exist).
  /// Returns the count of newly-persisted (downloaded) alerts.
  Future<int> _applyMergedAlerts(List<PriceAlert> merged) async {
    final repo = ref.read(alertRepositoryProvider);
    final localIds = repo.getAlerts().map((a) => a.id).toSet();
    var added = 0;
    for (final alert in merged) {
      if (localIds.contains(alert.id)) continue;
      await repo.saveAlert(alert);
      added++;
    }
    if (added > 0) {
      state = repo.getAlerts();
    }
    return added;
  }

  /// Returns unique station IDs that have active alerts,
  /// useful for background price checks.
  List<String> getAlertStationIds() {
    return state
        .where((a) => a.isActive)
        .map((a) => a.stationId)
        .toSet()
        .toList();
  }
}

/// AsyncValue wrapper around [alertProvider] (#858).
///
/// The legacy [alertProvider] is a synchronous NotifierProvider, so if the
/// underlying storage throws on read the error propagates to
/// [ErrorWidget] with no retry affordance. This derived provider re-exposes
/// the same list as an [AsyncValue] so screens can render a proper
/// `ServiceChainErrorWidget` via `.when(..., error: ...)`.
///
/// Existing consumers of [alertProvider] keep working untouched; only
/// screens that want a user-visible error branch need to switch.
@riverpod
AsyncValue<List<PriceAlert>> alertsAsync(Ref ref) {
  try {
    return AsyncValue.data(ref.watch(alertProvider));
  } catch (e, st) {
    return AsyncValue.error(e, st);
  }
}
