import '../../../../core/data/storage_repository.dart';
import '../../../../core/utils/station_extensions.dart';
import '../../../search/domain/entities/station.dart';
import '../models/price_alert.dart';

/// Repository for managing price alerts, backed by [AlertStorage].
class AlertRepository {
  final AlertStorage _storage;

  AlertRepository(this._storage);

  /// Returns all stored price alerts.
  List<PriceAlert> getAlerts() {
    final rawList = _storage.getAlerts();
    return rawList.map((e) => PriceAlert.fromJson(e)).toList();
  }

  /// Add or update a price alert.
  Future<void> saveAlert(PriceAlert alert) async {
    final alerts = _storage.getAlerts();
    final index = alerts.indexWhere((a) => a['id'] == alert.id);
    if (index >= 0) {
      alerts[index] = alert.toJson();
    } else {
      alerts.add(alert.toJson());
    }
    await _storage.saveAlerts(alerts);
  }

  /// Remove an alert by its ID.
  Future<void> deleteAlert(String id) async {
    final alerts = _storage.getAlerts();
    alerts.removeWhere((a) => a['id'] == id);
    await _storage.saveAlerts(alerts);
  }

  /// Check current station prices against alert targets.
  ///
  /// Returns the list of alerts whose target price is met or exceeded
  /// (i.e. the current price is at or below the target).
  List<PriceAlert> evaluateAlerts(List<Station> stations) {
    final alerts = getAlerts();
    final stationMap = {for (final s in stations) s.id: s};
    final triggered = <PriceAlert>[];

    for (final alert in alerts) {
      if (!alert.isActive) continue;
      final station = stationMap[alert.stationId];
      if (station == null) continue;

      final currentPrice = station.priceFor(alert.fuelType);
      if (currentPrice == null) continue;

      if (currentPrice <= alert.targetPrice) {
        triggered.add(alert.copyWith(lastTriggeredAt: DateTime.now()));
      }
    }

    return triggered;
  }

}
