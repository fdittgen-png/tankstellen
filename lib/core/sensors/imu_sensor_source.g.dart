// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'imu_sensor_source.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Wraps `sensors_plus` behind a testable, app-lifetime provider (#2760).
///
/// ## The single `sensors_plus` import site
///
/// This is the ONLY file in the codebase that imports `sensors_plus`, the
/// loosely-coupled-plugin idiom the project mandates (mirroring
/// `geolocator_wrapper.dart`): the platform plugin is touched in exactly one
/// place, never with an inline `if (Platform.isX)`, so the GPS+IMU pipeline
/// and its tests depend on the plain [ImuSample] value type rather than on
/// the plugin's event classes. Tests override [imuSensorSourceProvider] with
/// a fake emitting a fixed synthetic [ImuSample] stream.
///
/// `keepAlive` because a trip — and the sensor stream feeding its detector —
/// outlives widget rebuilds as the driver navigates the app mid-trip, exactly
/// like the geolocator wrapper.

@ProviderFor(imuSensorSource)
final imuSensorSourceProvider = ImuSensorSourceProvider._();

/// Wraps `sensors_plus` behind a testable, app-lifetime provider (#2760).
///
/// ## The single `sensors_plus` import site
///
/// This is the ONLY file in the codebase that imports `sensors_plus`, the
/// loosely-coupled-plugin idiom the project mandates (mirroring
/// `geolocator_wrapper.dart`): the platform plugin is touched in exactly one
/// place, never with an inline `if (Platform.isX)`, so the GPS+IMU pipeline
/// and its tests depend on the plain [ImuSample] value type rather than on
/// the plugin's event classes. Tests override [imuSensorSourceProvider] with
/// a fake emitting a fixed synthetic [ImuSample] stream.
///
/// `keepAlive` because a trip — and the sensor stream feeding its detector —
/// outlives widget rebuilds as the driver navigates the app mid-trip, exactly
/// like the geolocator wrapper.

final class ImuSensorSourceProvider
    extends
        $FunctionalProvider<ImuSensorSource, ImuSensorSource, ImuSensorSource>
    with $Provider<ImuSensorSource> {
  /// Wraps `sensors_plus` behind a testable, app-lifetime provider (#2760).
  ///
  /// ## The single `sensors_plus` import site
  ///
  /// This is the ONLY file in the codebase that imports `sensors_plus`, the
  /// loosely-coupled-plugin idiom the project mandates (mirroring
  /// `geolocator_wrapper.dart`): the platform plugin is touched in exactly one
  /// place, never with an inline `if (Platform.isX)`, so the GPS+IMU pipeline
  /// and its tests depend on the plain [ImuSample] value type rather than on
  /// the plugin's event classes. Tests override [imuSensorSourceProvider] with
  /// a fake emitting a fixed synthetic [ImuSample] stream.
  ///
  /// `keepAlive` because a trip — and the sensor stream feeding its detector —
  /// outlives widget rebuilds as the driver navigates the app mid-trip, exactly
  /// like the geolocator wrapper.
  ImuSensorSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'imuSensorSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$imuSensorSourceHash();

  @$internal
  @override
  $ProviderElement<ImuSensorSource> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ImuSensorSource create(Ref ref) {
    return imuSensorSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImuSensorSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ImuSensorSource>(value),
    );
  }
}

String _$imuSensorSourceHash() => r'0df5d3689f54a0056b9cd4adf97a0146aa3ee606';
