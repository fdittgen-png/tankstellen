import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../../../core/data/storage_repository.dart';
import '../../../core/storage/storage_keys.dart';

/// Manages data for the Android home screen widgets.
///
/// Two widget types are supported:
/// 1. **Favorites widget** — shows favorite stations with current prices
/// 2. **Nearest widget** — shows stations closest to user's last known position
///
/// Data flows:
/// 1. Background task fetches prices -> stores in Hive cache
/// 2. This service reads cached data -> writes to SharedPreferences via home_widget
/// 3. Native Android widgets read SharedPreferences -> render UI
///
/// Widget group ID must match the `android:authorities` in AndroidManifest.
const _widgetGroupId = 'de.tankstellen.fuelprices.widget';
const _favoritesWidgetAndroidName = 'FuelPriceWidgetProvider';
const _nearestWidgetAndroidName = 'NearestWidgetProvider';

/// Maximum number of stations to include in widget data.
const _maxWidgetStations = 5;

class HomeWidgetService {
  /// Update the favorites home screen widget with latest station prices.
  ///
  /// Called from background_service after price refresh, and from
  /// the app when favorites change.
  static Future<void> updateWidget(FavoriteStorage storage) async {
    try {
      final favoriteIds = storage.getFavoriteIds();
      if (favoriteIds.isEmpty) {
        await HomeWidget.saveWidgetData('station_count', 0);
        await HomeWidget.saveWidgetData('stations_json', '[]');
        await HomeWidget.updateWidget(
          androidName: _favoritesWidgetAndroidName,
        );
        return;
      }

      final stations = _buildStationList(storage, favoriteIds);

      await HomeWidget.saveWidgetData('station_count', stations.length);
      await HomeWidget.saveWidgetData('stations_json', jsonEncode(stations));
      await HomeWidget.saveWidgetData(
        'updated_at',
        DateTime.now().toIso8601String(),
      );

      await HomeWidget.updateWidget(
        androidName: _favoritesWidgetAndroidName,
      );
      debugPrint('HomeWidget: favorites updated with ${stations.length} stations');
    } catch (e) {
      debugPrint('HomeWidget: favorites update failed: $e');
    }
  }

  /// Update the nearest stations home screen widget.
  ///
  /// Reads the user's last known GPS position from settings storage,
  /// computes distances to all favorite stations, and writes the closest
  /// ones to SharedPreferences for the native widget to display.
  static Future<void> updateNearestWidget(
    FavoriteStorage favoriteStorage,
    SettingsStorage settingsStorage,
  ) async {
    try {
      final favoriteIds = favoriteStorage.getFavoriteIds();
      final lat = settingsStorage.getSetting(StorageKeys.userPositionLat) as double?;
      final lng = settingsStorage.getSetting(StorageKeys.userPositionLng) as double?;

      if (favoriteIds.isEmpty || lat == null || lng == null) {
        await HomeWidget.saveWidgetData('nearest_count', 0);
        await HomeWidget.saveWidgetData('nearest_json', '[]');
        await HomeWidget.updateWidget(
          androidName: _nearestWidgetAndroidName,
        );
        return;
      }

      final stations = _buildNearestStationList(
        favoriteStorage,
        favoriteIds,
        lat,
        lng,
      );

      await HomeWidget.saveWidgetData('nearest_count', stations.length);
      await HomeWidget.saveWidgetData('nearest_json', jsonEncode(stations));
      await HomeWidget.saveWidgetData(
        'nearest_updated_at',
        DateTime.now().toIso8601String(),
      );
      await HomeWidget.saveWidgetData('nearest_lat', lat);
      await HomeWidget.saveWidgetData('nearest_lng', lng);

      await HomeWidget.updateWidget(
        androidName: _nearestWidgetAndroidName,
      );
      debugPrint('HomeWidget: nearest updated with ${stations.length} stations');
    } catch (e) {
      debugPrint('HomeWidget: nearest update failed: $e');
    }
  }

  /// Build a compact station data list from favorite IDs (max [_maxWidgetStations]).
  static List<Map<String, dynamic>> _buildStationList(
    FavoriteStorage storage,
    List<String> favoriteIds,
  ) {
    final stations = <Map<String, dynamic>>[];
    for (final id in favoriteIds.take(_maxWidgetStations)) {
      final data = storage.getFavoriteStationData(id);
      if (data != null) {
        stations.add(_compactStationData(id, data));
      }
    }
    return stations;
  }

  /// Build a list of nearest stations sorted by distance from [lat],[lng].
  ///
  /// Uses the Haversine formula to compute distance between the user's
  /// position and each favorite station. Returns at most [_maxWidgetStations].
  static List<Map<String, dynamic>> _buildNearestStationList(
    FavoriteStorage storage,
    List<String> favoriteIds,
    double lat,
    double lng,
  ) {
    final stationsWithDistance = <(Map<String, dynamic>, double)>[];

    for (final id in favoriteIds) {
      final data = storage.getFavoriteStationData(id);
      if (data == null) continue;

      final stationLat = _toDouble(data['lat']);
      final stationLng = _toDouble(data['lng']);
      if (stationLat == null || stationLng == null) continue;

      final distanceKm = haversineDistanceKm(lat, lng, stationLat, stationLng);
      final compact = _compactStationData(id, data);
      compact['distance_km'] = double.parse(distanceKm.toStringAsFixed(1));
      stationsWithDistance.add((compact, distanceKm));
    }

    // Sort by distance ascending
    stationsWithDistance.sort((a, b) => a.$2.compareTo(b.$2));

    return stationsWithDistance
        .take(_maxWidgetStations)
        .map((e) => e.$1)
        .toList();
  }

  /// Create a compact station map suitable for widget display.
  static Map<String, dynamic> _compactStationData(
    String id,
    Map<String, dynamic> data,
  ) {
    return {
      'id': id,
      'name': data['brand'] ?? data['name'] ?? 'Station',
      'place': data['place'] ?? '',
      'e5': data['e5'],
      'e10': data['e10'],
      'diesel': data['diesel'],
      'isOpen': data['isOpen'] ?? false,
    };
  }

  /// Haversine formula to calculate distance in km between two GPS points.
  ///
  /// Public for testing.
  @visibleForTesting
  static double haversineDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) => degrees * pi / 180;

  static double? _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Initialize home_widget group ID. Call once from main.
  static Future<void> init() async {
    await HomeWidget.setAppGroupId(_widgetGroupId);
  }
}
