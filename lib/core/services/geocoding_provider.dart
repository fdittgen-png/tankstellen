import 'service_result.dart';

/// Abstract interface for coordinate resolution (ZIP → lat/lng and reverse).
///
/// Multiple implementations exist (native platform, Nominatim OSM).
/// Each declares its [source] for tracking and [isAvailable] for
/// platform detection. The fallback chain tries providers in order.
abstract class GeocodingProvider {
  /// Identifies this provider in ServiceResult and error tracking.
  ServiceSource get source;

  /// Whether this provider works on the current platform.
  bool get isAvailable;

  /// Convert a German ZIP code (PLZ) to coordinates.
  Future<({double lat, double lng})> zipCodeToCoordinates(String zipCode);

  /// Convert coordinates to a human-readable address.
  Future<String> coordinatesToAddress(double lat, double lng);

  /// Reverse-geocode coordinates to an ISO country code (e.g. 'DE', 'FR').
  /// Returns null if not supported or if the call fails.
  Future<String?> coordinatesToCountryCode(double lat, double lng) async =>
      null;
}
