import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'geolocator_wrapper.g.dart';

/// Wraps Geolocator's static methods for testability.
///
/// All permission and location calls go through this provider instead of
/// calling Geolocator.checkPermission() etc. directly, so tests can
/// override the provider with a fake implementation.
@Riverpod(keepAlive: true)
GeolocatorWrapper geolocatorWrapper(Ref ref) {
  return GeolocatorWrapper();
}

class GeolocatorWrapper {
  Future<bool> isLocationServiceEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }

  Future<LocationPermission> checkPermission() {
    return Geolocator.checkPermission();
  }

  Future<LocationPermission> requestPermission() {
    return Geolocator.requestPermission();
  }

  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) {
    return Geolocator.getCurrentPosition(
      locationSettings: locationSettings,
    );
  }

  double distanceBetween(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Returns a stream of position updates for continuous location tracking.
  ///
  /// Used by movement detection in driving mode.
  Stream<Position> getPositionStream({
    LocationSettings? locationSettings,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: locationSettings,
    );
  }
}
