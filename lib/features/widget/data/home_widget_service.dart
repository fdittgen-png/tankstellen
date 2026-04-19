import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../../../core/country/country_config.dart';
import '../../../core/data/storage_repository.dart';
import '../../../core/storage/storage_keys.dart';
import '../../search/domain/entities/fuel_type.dart';

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
  ///
  /// When [profileStorage] is non-null, the active profile's preferred fuel
  /// and the last-known user GPS position are read from it so the widget
  /// can show the same fuel and distance the app shows.
  static Future<void> updateWidget(
    FavoriteStorage storage, {
    ProfileStorage? profileStorage,
    SettingsStorage? settingsStorage,
  }) async {
    try {
      final favoriteIds = storage.getFavoriteIds();
      final context = _resolveDisplayContext(profileStorage, settingsStorage);

      if (favoriteIds.isEmpty) {
        await HomeWidget.saveWidgetData('station_count', 0);
        await HomeWidget.saveWidgetData('stations_json', '[]');
        await HomeWidget.updateWidget(
          androidName: _favoritesWidgetAndroidName,
        );
        return;
      }

      final stations = _buildStationList(storage, favoriteIds, context);

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
  ///
  /// When [profileStorage] is non-null, the rendered price uses the active
  /// profile's preferred fuel type (falls back to e10 when profile absent).
  static Future<void> updateNearestWidget(
    FavoriteStorage favoriteStorage,
    SettingsStorage settingsStorage, {
    ProfileStorage? profileStorage,
  }) async {
    try {
      final favoriteIds = favoriteStorage.getFavoriteIds();
      final lat = settingsStorage.getSetting(StorageKeys.userPositionLat) as double?;
      final lng = settingsStorage.getSetting(StorageKeys.userPositionLng) as double?;

      if (favoriteIds.isEmpty || lat == null || lng == null) {
        await HomeWidget.saveWidgetData('nearest_count', 0);
        await HomeWidget.saveWidgetData('nearest_json', '[]');
        await HomeWidget.saveWidgetData(
          'nearest_empty_reason',
          lat == null || lng == null ? 'no_gps' : 'no_favorites',
        );
        await HomeWidget.updateWidget(
          androidName: _nearestWidgetAndroidName,
        );
        return;
      }

      final context = _resolveDisplayContext(profileStorage, settingsStorage);

      final stations = _buildNearestStationList(
        favoriteStorage,
        favoriteIds,
        lat,
        lng,
        context,
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
    _WidgetDisplayContext context,
  ) {
    final stations = <Map<String, dynamic>>[];
    for (final id in favoriteIds.take(_maxWidgetStations)) {
      final data = storage.getFavoriteStationData(id);
      if (data != null) {
        stations.add(_compactStationData(
          id,
          data,
          preferredFuelType: context.preferredFuelType,
          userLat: context.userLat,
          userLng: context.userLng,
        ));
      }
    }
    return stations;
  }

  /// Snapshot of the display preferences the widget should honour for one
  /// render: active profile's preferred fuel type and the user's last-known
  /// GPS. All fields are nullable — the widget degrades gracefully when any
  /// piece is missing (no profile set, no GPS ever obtained, etc.).
  static _WidgetDisplayContext _resolveDisplayContext(
    ProfileStorage? profileStorage,
    SettingsStorage? settingsStorage,
  ) {
    FuelType? fuel;
    if (profileStorage != null) {
      final id = profileStorage.getActiveProfileId();
      if (id != null) {
        final raw = profileStorage.getProfile(id);
        final key = raw?['preferredFuelType']?.toString();
        if (key != null) {
          try {
            fuel = FuelType.fromString(key);
          } catch (e) {
            debugPrint('HomeWidgetService: unknown fuel "$key": $e');
            fuel = null;
          }
        }
      }
    }

    double? lat;
    double? lng;
    if (settingsStorage != null) {
      lat =
          (settingsStorage.getSetting(StorageKeys.userPositionLat) as num?)
              ?.toDouble();
      lng =
          (settingsStorage.getSetting(StorageKeys.userPositionLng) as num?)
              ?.toDouble();
    }

    return _WidgetDisplayContext(
      preferredFuelType: fuel,
      userLat: lat,
      userLng: lng,
    );
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
    _WidgetDisplayContext context,
  ) {
    final stationsWithDistance = <(Map<String, dynamic>, double)>[];

    for (final id in favoriteIds) {
      final data = storage.getFavoriteStationData(id);
      if (data == null) continue;

      final stationLat = _toDouble(data['lat']);
      final stationLng = _toDouble(data['lng']);
      if (stationLat == null || stationLng == null) continue;

      final distanceKm = haversineDistanceKm(lat, lng, stationLat, stationLng);
      final compact = _compactStationData(
        id,
        data,
        preferredFuelType: context.preferredFuelType,
        userLat: lat,
        userLng: lng,
      );
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
  ///
  /// Field parity with the favorites/search screens (#608):
  /// - brand / name / street / postCode / place (identity + address)
  /// - e5 / e10 / diesel (common price fields)
  /// - preferred_fuel_code + preferred_fuel_price (profile-driven main price)
  /// - distance_km (null when GPS unknown — never a misleading 0.0)
  /// - isOpen (default false when missing)
  /// - currency (resolved via country lookup on id prefix / coordinates)
  static Map<String, dynamic> _compactStationData(
    String id,
    Map<String, dynamic> data, {
    FuelType? preferredFuelType,
    double? userLat,
    double? userLng,
  }) {
    final brand = (data['brand'] as String?)?.trim();
    final name = (data['name'] as String?)?.trim();
    // Favorites widget title: prefer the real brand; fall back to the station
    // name so independent or unlabeled stations stay identifiable.
    final displayBrand = (brand != null && brand.isNotEmpty)
        ? brand
        : (name != null && name.isNotEmpty ? name : 'Station');

    final stationLat = _toDouble(data['lat']);
    final stationLng = _toDouble(data['lng']);
    double? distanceKm;
    if (userLat != null &&
        userLng != null &&
        stationLat != null &&
        stationLng != null) {
      final raw = haversineDistanceKm(userLat, userLng, stationLat, stationLng);
      distanceKm = double.parse(raw.toStringAsFixed(1));
    }

    final currency = Countries.countryForStation(
      id: id,
      lat: stationLat ?? 0,
      lng: stationLng ?? 0,
    )?.currencySymbol;

    final fuelPrice = preferredFuelType != null
        ? _priceForFuel(data, preferredFuelType)
        : null;

    return {
      'id': id,
      'brand': displayBrand,
      'name': name ?? displayBrand,
      'street': data['street'] ?? '',
      'postCode': data['postCode']?.toString() ?? '',
      'place': data['place'] ?? '',
      'e5': data['e5'],
      'e10': data['e10'],
      'diesel': data['diesel'],
      'isOpen': data['isOpen'] ?? false,
      'currency': ?currency,
      if (preferredFuelType != null)
        'preferred_fuel_code': preferredFuelType.apiValue,
      if (preferredFuelType != null) 'preferred_fuel_price': fuelPrice,
      'distance_km': distanceKm,
    };
  }

  /// Read the price for [fuelType] from a raw favorite-station JSON map.
  ///
  /// Returns null when the station has no price for that fuel.
  static double? _priceForFuel(Map<String, dynamic> data, FuelType fuelType) {
    final key = switch (fuelType) {
      FuelType.e5 => 'e5',
      FuelType.e10 => 'e10',
      FuelType.e98 => 'e98',
      FuelType.diesel => 'diesel',
      FuelType.dieselPremium => 'dieselPremium',
      FuelType.e85 => 'e85',
      FuelType.lpg => 'lpg',
      FuelType.cng => 'cng',
      _ => null,
    };
    if (key == null) return null;
    return _toDouble(data[key]);
  }

  /// Public test-only entry point for [_compactStationData].
  ///
  /// Widget field parity logic is complex enough (profile fuel, distance,
  /// currency, defaults) that unit tests need direct access. Kept separate
  /// from the real API so consumers use the private method via the update
  /// flow, not this one.
  @visibleForTesting
  static Map<String, dynamic> compactStationDataForTest(
    String id,
    Map<String, dynamic> data, {
    FuelType? preferredFuelType,
    double? userLat,
    double? userLng,
  }) =>
      _compactStationData(
        id,
        data,
        preferredFuelType: preferredFuelType,
        userLat: userLat,
        userLng: userLng,
      );

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

/// Bundled context (profile + GPS) used by both widget update paths.
/// Private so callers go through [HomeWidgetService.updateWidget] /
/// [HomeWidgetService.updateNearestWidget] rather than building this
/// directly.
class _WidgetDisplayContext {
  final FuelType? preferredFuelType;
  final double? userLat;
  final double? userLng;

  const _WidgetDisplayContext({
    this.preferredFuelType,
    this.userLat,
    this.userLng,
  });
}
