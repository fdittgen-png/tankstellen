import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/storage/hive_storage.dart';
import '../../../core/sync/sync_provider.dart';
import '../../../core/sync/sync_service.dart';
import '../data/models/price_alert.dart';
import '../data/repositories/alert_repository.dart';

part 'alert_provider.g.dart';

@Riverpod(keepAlive: true)
AlertRepository alertRepository(Ref ref) {
  final storage = ref.watch(hiveStorageProvider);
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
    final repo = ref.read(alertRepositoryProvider);
    await repo.saveAlert(alert);
    state = repo.getAlerts();
    await _syncAlertsIfConnected();
  }

  Future<void> removeAlert(String id) async {
    final repo = ref.read(alertRepositoryProvider);
    await repo.deleteAlert(id);
    state = repo.getAlerts();
    await _syncAlertsIfConnected();
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
  }

  Future<void> _syncAlertsIfConnected() async {
    try {
      final syncState = ref.read(syncStateProvider);
      if (syncState.enabled && syncState.userId != null) {
        await SyncService.syncAlerts(state, syncState.userId!);
      }
    } catch (e) { debugPrint('Silent catch: ');
      // Don't block local operation if sync fails
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
