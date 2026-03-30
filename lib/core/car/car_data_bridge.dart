import 'package:flutter/services.dart';

/// Bridge between the Flutter app and native car platforms
/// (Android Auto / Apple CarPlay / Huawei HiCar).
///
/// ## Architecture
/// The car head unit runs in a separate process and cannot access
/// Flutter widgets or Riverpod providers. This bridge uses
/// MethodChannel to exchange data between:
/// - **Dart side**: station search, favorites, navigation
/// - **Native side**: Kotlin (Android Auto), Swift (CarPlay)
///
/// ## Supported Platforms
/// - Android Auto: POI category, PlaceListMapTemplate
/// - Apple CarPlay: CPPointOfInterestTemplate
/// - Huawei HiCar: Similar to Android Auto (car app framework)
///
/// ## Data Contract
/// All methods return JSON-serializable maps. The native side
/// parses these into platform-specific templates.
class CarDataBridge {
  static const _channel = MethodChannel('com.tankstellen/car');

  /// Register handlers for native-to-Dart calls.
  ///
  /// Called from main.dart during app initialization.
  /// The native car service calls these methods via MethodChannel
  /// to request data for car display templates.
  static void registerHandlers({
    required Future<List<Map<String, dynamic>>> Function(double lat, double lng, double radiusKm) onSearchNearby,
    required Future<List<Map<String, dynamic>>> Function() onGetFavorites,
    required Future<Map<String, dynamic>?> Function(String stationId) onGetStationDetail,
  }) {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'searchNearby':
          final lat = call.arguments['lat'] as double;
          final lng = call.arguments['lng'] as double;
          final radius = call.arguments['radius'] as double? ?? 10.0;
          return await onSearchNearby(lat, lng, radius);

        case 'getFavorites':
          return await onGetFavorites();

        case 'getStationDetail':
          final id = call.arguments['id'] as String;
          return await onGetStationDetail(id);

        case 'getAppVersion':
          return '4.1.0';

        default:
          throw MissingPluginException('Method ${call.method} not implemented');
      }
    });
  }

  /// Check if we're running in a car context.
  static Future<bool> isCarMode() async {
    try {
      final result = await _channel.invokeMethod<bool>('isCarMode');
      return result ?? false;
    } on MissingPluginException {
      return false; // No native implementation — not in car mode
    }
  }
}
