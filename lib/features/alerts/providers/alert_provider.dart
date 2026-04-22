import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/background/background_service.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/sync/sync_provider.dart';
import '../../../core/sync/alerts_sync.dart';
import '../data/models/price_alert.dart';
import '../data/repositories/alert_repository.dart';

part 'alert_provider.g.dart';

@Riverpod(keepAlive: true)
AlertRepository alertRepository(Ref ref) {
  final storage = ref.watch(storageRepositoryProvider);
  return AlertRepository(storage);
}

@Riverpod(keepAlive: true)
class AlertNotifier extends _$AlertNotifier {
  @override
  List<PriceAlert> build() {
    final repo = ref.watch(alertRepositoryProvider);
    return repo.getAlerts();
  }

  Future<void> addAlert(PriceAlert alert) async {
    final hadActive = _hasActive(state);
    final repo = ref.read(alertRepositoryProvider);
    await repo.saveAlert(alert);
    state = repo.getAlerts();
    await _syncAlertsIfConnected();
    await _reconcileBackgroundPolling(hadActive: hadActive);
  }

  Future<void> removeAlert(String id) async {
    final hadActive = _hasActive(state);
    final repo = ref.read(alertRepositoryProvider);
    await repo.deleteAlert(id);
    state = repo.getAlerts();
    await _syncAlertsIfConnected();
    await _reconcileBackgroundPolling(hadActive: hadActive);
  }

  Future<void> toggleAlert(String id) async {
    final hadActive = _hasActive(state);
    final repo = ref.read(alertRepositoryProvider);
    final alerts = repo.getAlerts();
    final index = alerts.indexWhere((a) => a.id == id);
    if (index < 0) return;

    final alert = alerts[index];
    await repo.saveAlert(alert.copyWith(isActive: !alert.isActive));
    state = repo.getAlerts();
    await _syncAlertsIfConnected();
    await _reconcileBackgroundPolling(hadActive: hadActive);
  }

  /// Keep the WorkManager periodic task aligned with user intent (#713):
  /// it only runs when at least one active alert exists — alerts are the
  /// only user-consented reason to poll station prices on a schedule.
  /// Transitioning false→true starts the task, true→false cancels it.
  Future<void> _reconcileBackgroundPolling({required bool hadActive}) async {
    final hasActive = _hasActive(state);
    if (hadActive == hasActive) return;
    try {
      if (hasActive) {
        await BackgroundService.init();
      } else {
        await BackgroundService.cancelAll();
      }
    } catch (e) {
      debugPrint('AlertNotifier: background task reconcile failed: $e');
    }
  }

  static bool _hasActive(List<PriceAlert> alerts) =>
      alerts.any((a) => a.isActive);

  Future<void> _syncAlertsIfConnected() async {
    try {
      final syncState = ref.read(syncStateProvider);
      if (syncState.enabled) {
        await AlertsSync.merge(state);
      }
    } catch (e) {
      debugPrint('AlertProvider: sync failed: $e');
    }
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
