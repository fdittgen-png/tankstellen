// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../background/background_service.dart';
import '../../../core/notifications/notification_providers.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/sync/sync_provider.dart';
import '../../../core/sync/alerts_sync.dart';
import '../../../core/sync/sync_helper.dart';
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

/// Signature of the alert delete propagation (#3121). Defaults to
/// [AlertsSync.delete]; overridable in tests so the delete-resurrection
/// regression test can model the server without standing up Supabase.
typedef AlertsDeleteFn = Future<void> Function(String id);

/// Injectable delete-propagation function. Production code uses the real
/// [AlertsSync.delete]; tests override this provider with a fake.
@Riverpod(keepAlive: true)
AlertsDeleteFn alertsDeleteFn(Ref ref) => AlertsSync.delete;

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
    // #3121 — propagate the delete: remove the server row and record a
    // `deletions` tombstone so the launch pull (#3077) or another
    // device's union merge can't resurrect the alert. Local-first: the
    // local delete above already happened, and fireAndForget swallows a
    // server failure (the tombstone still filters the id from every
    // later merge).
    await SyncHelper.fireAndForget(
      ref,
      'Alerts.remove',
      () => ref.read(alertsDeleteFnProvider)(id),
    );
    // #2246 — keep downloads suppressed on the remove path: the server
    // delete above may not have landed on a flaky link, and the
    // tombstone filter inside AlertsSync.merge already guards the next
    // pull. Upload-only keeps the local delete sticky on this device.
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

  /// Explicitly upload local alerts AND pull server-only alerts into local
  /// storage (#3077). Used by the connect / app-launch / "sync now"
  /// triggers — the mutation hooks ([addAlert] / [toggleAlert]) already
  /// pull on every edit, but a device that never edits an alert (a fresh
  /// install signing in on a second device) needs an explicit pull pass to
  /// see alerts created elsewhere. Returns the count of newly-persisted
  /// (downloaded) alerts. No-op when TankSync is disabled.
  Future<int> pullFromServer() =>
      _syncAlertsIfConnected(applyDownloads: true);

  /// Push local alerts to the backend and, unless [applyDownloads] is
  /// false, pull server-only alerts back into local storage. Returns the
  /// count of server-only alerts persisted this pass (0 when downloads are
  /// suppressed, TankSync is off, or nothing new came down).
  ///
  /// #2246 — [AlertsSync.merge] returns the merged superset
  /// (`[local, ...server-only downloaded]`). The result used to be
  /// discarded, so an alert created on another device never reached this
  /// one. We now persist the server-only rows via [_applyMergedAlerts].
  Future<int> _syncAlertsIfConnected({bool applyDownloads = true}) async {
    try {
      final syncState = ref.read(syncStateProvider);
      if (syncState.enabled) {
        final merge = ref.read(alertsMergeFnProvider);
        final merged = await merge(state);
        if (applyDownloads) {
          return _applyMergedAlerts(merged);
        }
      }
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {'where': 'AlertProvider: sync failed'}));
    }
    return 0;
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
