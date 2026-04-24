import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../../../core/country/country_config.dart';
import '../../../core/data/storage_repository.dart';
import '../../../core/services/station_service.dart';
import '../../../core/storage/storage_keys.dart';
import '../../profile/data/models/user_profile.dart';
import '../../search/domain/entities/fuel_type.dart';
import 'home_widget_json.dart';
import 'nearest_widget_data_builder.dart';

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
// Single provider class (#713) — the widget toggles between favorites
// and nearest modes internally. The old NearestWidgetProvider receiver
// was dropped from the manifest.
const _widgetAndroidName = 'FuelPriceWidgetProvider';

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
      // #610 — if the user picked a specific profile for this widget via
      // the configure activity, prefer it over the active profile. Shared
      // JSON payload means we resolve to one profile per render; the
      // per-widget key read here picks the first installed widget's choice,
      // which is the only one that could ever differ from the active profile.
      final perWidgetProfileId = await _readFirstPerWidgetProfileId();
      final context = _resolveDisplayContext(
        profileStorage,
        settingsStorage,
        perWidgetProfileId: perWidgetProfileId,
      );

      if (favoriteIds.isEmpty) {
        await HomeWidget.saveWidgetData('station_count', 0);
        await HomeWidget.saveWidgetData('stations_json', '[]');
        await HomeWidget.updateWidget(
          androidName: _widgetAndroidName,
        );
        return;
      }

      final stations = _buildStationList(storage, favoriteIds, context);

      await HomeWidget.saveWidgetData('station_count', stations.length);
      await HomeWidget.saveWidgetData(
        'stations_json',
        encodeStationsForWidget(stations),
      );
      await HomeWidget.saveWidgetData(
        'updated_at',
        DateTime.now().toIso8601String(),
      );

      await HomeWidget.updateWidget(
        androidName: _widgetAndroidName,
      );
      debugPrint('HomeWidget: favorites updated with ${stations.length} stations');
    } catch (e) {
      debugPrint('HomeWidget: favorites update failed: $e');
    }
  }

  /// Update the nearest stations home screen widget.
  ///
  /// When [stationService] is provided, the widget is populated from a
  /// real nearby-station search against the active country's API (#609) —
  /// so the widget works for users with no favorites. When [stationService]
  /// is null (e.g. background isolate where a fully wired service chain
  /// is not available), falls back to the legacy favorites-distance mode
  /// so existing users still see something.
  ///
  /// When [profileStorage] is non-null, the rendered price uses the active
  /// profile's preferred fuel type (falls back to e10 when profile absent).
  static Future<void> updateNearestWidget(
    FavoriteStorage favoriteStorage,
    SettingsStorage settingsStorage, {
    ProfileStorage? profileStorage,
    StationService? stationService,
  }) async {
    try {
      if (stationService != null && profileStorage != null) {
        final builder = NearestWidgetDataBuilder(
          stationService: stationService,
          settingsStorage: settingsStorage,
          profileStorage: profileStorage,
        );
        final payload = await builder.build();
        await HomeWidget.updateWidget(androidName: _widgetAndroidName);
        debugPrint(
          'HomeWidget: nearest (real search) updated — '
          'count=${payload.stations.length} '
          'stale=${payload.isStale} reason=${payload.emptyReason}',
        );
        return;
      }

      // Legacy fallback: derive the list from favorites sorted by distance.
      // Kept for the background isolate and any caller that can't construct
      // a StationService. Will be removed once the background isolate is
      // rewired (#609 follow-up).
      final favoriteIds = favoriteStorage.getFavoriteIds();
      final lat = settingsStorage.getSetting(StorageKeys.userPositionLat)
          as double?;
      final lng = settingsStorage.getSetting(StorageKeys.userPositionLng)
          as double?;

      if (favoriteIds.isEmpty || lat == null || lng == null) {
        await HomeWidget.saveWidgetData('nearest_count', 0);
        await HomeWidget.saveWidgetData('nearest_json', '[]');
        await HomeWidget.saveWidgetData(
          'nearest_empty_reason',
          lat == null || lng == null ? 'no_gps' : 'no_favorites',
        );
        await HomeWidget.saveWidgetData('nearest_is_stale', false);
        await HomeWidget.updateWidget(
          androidName: _widgetAndroidName,
        );
        return;
      }

      // #610 — same per-widget profile override as the favorites path.
      final perWidgetProfileId = await _readFirstPerWidgetProfileId();
      final context = _resolveDisplayContext(
        profileStorage,
        settingsStorage,
        perWidgetProfileId: perWidgetProfileId,
      );

      final stations = _buildNearestStationList(
        favoriteStorage,
        favoriteIds,
        lat,
        lng,
        context,
      );

      await HomeWidget.saveWidgetData('nearest_count', stations.length);
      await HomeWidget.saveWidgetData(
        'nearest_json',
        encodeStationsForWidget(stations),
      );
      await HomeWidget.saveWidgetData(
        'nearest_updated_at',
        DateTime.now().toIso8601String(),
      );
      await HomeWidget.saveWidgetData('nearest_empty_reason', '');
      await HomeWidget.saveWidgetData('nearest_is_stale', false);
      await HomeWidget.saveWidgetData('nearest_lat', lat);
      await HomeWidget.saveWidgetData('nearest_lng', lng);

      await HomeWidget.updateWidget(
        androidName: _widgetAndroidName,
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
    SettingsStorage? settingsStorage, {
    String? perWidgetProfileId,
  }) {
    FuelType? fuel;
    if (profileStorage != null) {
      // #610 — prefer the per-widget profile when set. If the id doesn't
      // resolve (profile deleted since widget was placed), silently fall
      // back to the active profile so the widget keeps working.
      final resolvedId = _resolvePerWidgetProfileId(
        profileStorage,
        perWidgetProfileId,
      );
      if (resolvedId != null) {
        final raw = profileStorage.getProfile(resolvedId);
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

  /// Publish the user's profile list to SharedPreferences so the Android
  /// widget configure activity (#610) can offer them as choices when the
  /// user places a new widget.
  ///
  /// Writes a JSON array to `widget_profiles_json` with only the fields the
  /// activity needs (id, name, preferredFuel, currency). Non-fatal on
  /// failure — the configure activity gracefully falls back to a single
  /// "Default" option when the key is missing or malformed.
  static Future<void> publishProfiles(List<UserProfile> profiles) async {
    try {
      final list = profiles.map((p) {
        final currency = p.countryCode == null
            ? ''
            : (Countries.byCode(p.countryCode!)?.currencySymbol ?? '');
        return <String, dynamic>{
          'id': p.id,
          'name': p.name,
          'preferredFuel': p.preferredFuelType.name,
          'currency': currency,
        };
      }).toList(growable: false);
      await HomeWidget.saveWidgetData(
        'widget_profiles_json',
        jsonEncode(list),
      );
    } catch (e) {
      debugPrint('HomeWidget: publishProfiles failed: $e');
    }
  }

  /// Read the first installed widget's `profile_<id>` key, or null when no
  /// widget has a per-widget profile override. Private so callers go
  /// through [updateWidget] / [updateNearestWidget]. Not exported to tests
  /// directly — the per-widget test exercises the write path via
  /// [HomeWidget.saveWidgetData] and reads back the resolved fuel on the
  /// compact station data.
  static Future<String?> _readFirstPerWidgetProfileId() async {
    try {
      final widgets = await HomeWidget.getInstalledWidgets();
      for (final w in widgets) {
        final id = await HomeWidget.getWidgetData<String>(
          'profile_${w.androidWidgetId}',
        );
        if (id != null && id.isNotEmpty) return id;
      }
      return null;
    } catch (e) {
      debugPrint('HomeWidget: readFirstPerWidgetProfileId failed: $e');
      return null;
    }
  }

  /// Resolve the effective profile id: prefer [perWidgetProfileId] when it
  /// exists in [profileStorage], otherwise fall back to the active profile.
  /// Returns null when neither is set. Visible for testing so the
  /// per-widget profile behaviour can be asserted without widget channel
  /// round-trips.
  @visibleForTesting
  static String? resolvePerWidgetProfileIdForTest(
    ProfileStorage profileStorage,
    String? perWidgetProfileId,
  ) =>
      _resolvePerWidgetProfileId(profileStorage, perWidgetProfileId);

  static String? _resolvePerWidgetProfileId(
    ProfileStorage profileStorage,
    String? perWidgetProfileId,
  ) {
    if (perWidgetProfileId != null &&
        profileStorage.getProfile(perWidgetProfileId) != null) {
      return perWidgetProfileId;
    }
    return profileStorage.getActiveProfileId();
  }

  /// Public test-only entry point for [_resolveDisplayContext], so the
  /// per-widget profile override can be asserted without tapping the
  /// `home_widget` platform channel. Mirrors the internal signature.
  @visibleForTesting
  static Map<String, dynamic> resolveDisplayContextForTest({
    ProfileStorage? profileStorage,
    SettingsStorage? settingsStorage,
    String? perWidgetProfileId,
  }) {
    final ctx = _resolveDisplayContext(
      profileStorage,
      settingsStorage,
      perWidgetProfileId: perWidgetProfileId,
    );
    return <String, dynamic>{
      'preferredFuelType': ctx.preferredFuelType?.apiValue,
      'userLat': ctx.userLat,
      'userLng': ctx.userLng,
    };
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
