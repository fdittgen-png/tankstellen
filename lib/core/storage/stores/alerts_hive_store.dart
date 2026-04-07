import 'package:hive_flutter/hive_flutter.dart';

import '../../data/storage_repository.dart';
import '../hive_boxes.dart';

/// Hive-backed implementation of [AlertStorage].
///
/// Manages user-configured price alerts for specific stations.
class AlertsHiveStore implements AlertStorage {
  Box get _alerts => Hive.box(HiveBoxes.alerts);

  @override
  List<Map<String, dynamic>> getAlerts() {
    final data = _alerts.get('alerts');
    if (data == null) return [];
    return (data as List)
        .map((e) => HiveBoxes.toStringDynamicMap(e))
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  @override
  Future<void> saveAlerts(List<Map<String, dynamic>> alerts) =>
      _alerts.put('alerts', alerts);

  @override
  Future<void> clearAlerts() => _alerts.clear();

  @override
  int get alertCount => getAlerts().length;
}
