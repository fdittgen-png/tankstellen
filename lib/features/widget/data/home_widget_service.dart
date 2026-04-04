import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../../../core/storage/hive_storage.dart';

/// Manages the Android home screen widget data.
///
/// The widget shows nearest favorite station prices. Data flows:
/// 1. Background task fetches prices → stores in Hive cache
/// 2. This service reads cached prices → writes to SharedPreferences via home_widget
/// 3. Native Android widget reads SharedPreferences → renders UI
///
/// Widget group ID must match the `android:authorities` in AndroidManifest.
const _widgetGroupId = 'de.tankstellen.fuelprices.widget';
const _widgetAndroidName = 'FuelPriceWidgetProvider';

class HomeWidgetService {
  /// Update the home screen widget with latest favorite station prices.
  ///
  /// Called from background_service after price refresh, and from
  /// the app when favorites change.
  static Future<void> updateWidget(HiveStorage storage) async {
    try {
      final favoriteIds = storage.getFavoriteIds();
      if (favoriteIds.isEmpty) {
        await HomeWidget.saveWidgetData('station_count', 0);
        await HomeWidget.saveWidgetData('stations_json', '[]');
        await HomeWidget.updateWidget(
          androidName: _widgetAndroidName,
        );
        return;
      }

      // Build compact station data for the widget (max 5 stations)
      final stations = <Map<String, dynamic>>[];
      for (final id in favoriteIds.take(5)) {
        final data = storage.getFavoriteStationData(id);
        if (data != null) {
          stations.add({
            'id': id,
            'name': data['brand'] ?? data['name'] ?? 'Station',
            'place': data['place'] ?? '',
            'e5': data['e5'],
            'e10': data['e10'],
            'diesel': data['diesel'],
            'isOpen': data['isOpen'] ?? false,
          });
        }
      }

      await HomeWidget.saveWidgetData('station_count', stations.length);
      await HomeWidget.saveWidgetData('stations_json', jsonEncode(stations));
      await HomeWidget.saveWidgetData(
        'updated_at',
        DateTime.now().toIso8601String(),
      );

      await HomeWidget.updateWidget(
        androidName: _widgetAndroidName,
      );
      debugPrint('HomeWidget: updated with ${stations.length} stations');
    } catch (e) {
      debugPrint('HomeWidget: update failed: $e');
    }
  }

  /// Initialize home_widget group ID. Call once from main.
  static Future<void> init() async {
    await HomeWidget.setAppGroupId(_widgetGroupId);
  }
}
