// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

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
  /// When the app is built with `--dart-define=FORCE_LOCATION_MANAGER=true`
  /// (the F-Droid / GMS-free flavor, #2574), every location request is routed
  /// through Android's legacy [LocationManager] instead of the Play-Services
  /// `FusedLocationProviderClient`.
  ///
  /// The fdroid flavor excludes `com.google.android.gms` from the runtime
  /// classpath, so the fused provider class is simply absent. geolocator_android
  /// already falls back to the LocationManager when GMS is missing, but we set
  /// [AndroidSettings.forceLocationManager] explicitly so the behaviour is
  /// deterministic and does not depend on a runtime class-presence probe.
  ///
  /// Centralising the wrapping HERE keeps all four call sites
  /// (location_service.dart, movement_detection_provider.dart,
  /// approach_state_provider.dart, trip_gps_stream_controller.dart) free of any
  /// flavor branching — they keep passing a plain [LocationSettings].
  static const bool forceLocationManager =
      bool.fromEnvironment('FORCE_LOCATION_MANAGER');

  /// Copies the cross-platform fields of [settings] into an [AndroidSettings]
  /// with `forceLocationManager: true` when [forceLocationManager] is set;
  /// otherwise returns [settings] unchanged. A null in stays null out.
  static LocationSettings? _withForcedLocationManager(
    LocationSettings? settings,
  ) {
    if (!forceLocationManager) return settings;
    // Already an Android-specific settings object: respect its choice but
    // guarantee the LocationManager is forced in the GMS-free flavor.
    if (settings is AndroidSettings) {
      return AndroidSettings(
        forceLocationManager: true,
        accuracy: settings.accuracy,
        distanceFilter: settings.distanceFilter,
        intervalDuration: settings.intervalDuration,
        timeLimit: settings.timeLimit,
        foregroundNotificationConfig: settings.foregroundNotificationConfig,
        useMSLAltitude: settings.useMSLAltitude,
      );
    }
    return AndroidSettings(
      forceLocationManager: true,
      accuracy: settings?.accuracy ?? LocationAccuracy.best,
      distanceFilter: settings?.distanceFilter ?? 0,
      timeLimit: settings?.timeLimit,
    );
  }

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
      locationSettings: _withForcedLocationManager(locationSettings),
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
      locationSettings: _withForcedLocationManager(locationSettings),
    );
  }
}
