// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'geolocator_wrapper.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Wraps Geolocator's static methods for testability.
///
/// All permission and location calls go through this provider instead of
/// calling Geolocator.checkPermission() etc. directly, so tests can
/// override the provider with a fake implementation.
///
/// TODO(#3476): location capability seam for the GMS-free F-Droid architecture
/// (epic #3473). `forceLocationManager` already routes the LIBRE build through
/// Android's LocationManager at runtime, but `geolocator_android`'s
/// `FusedLocationClient` still leaves compile-time `com.google.android.gms.*`
/// REFERENCES in the fdroid dex that `fdroid scanner` rejects. Plan (see
/// `.local-docs/fdroid-gms-free-refactor-notes.md`): vendor + patch
/// `geolocator_android` for the libre build (drop `FusedLocationClient` + the
/// `GoogleApiAvailability` probe), swapped in via a libre-only
/// `pubspec_overrides.yaml` — keeping this Dart API + all 11 call sites
/// unchanged. Refactor TODO: extract `_SharedPositionSource` to its own file
/// and split out a thin permissions seam.

@ProviderFor(geolocatorWrapper)
final geolocatorWrapperProvider = GeolocatorWrapperProvider._();

/// Wraps Geolocator's static methods for testability.
///
/// All permission and location calls go through this provider instead of
/// calling Geolocator.checkPermission() etc. directly, so tests can
/// override the provider with a fake implementation.
///
/// TODO(#3476): location capability seam for the GMS-free F-Droid architecture
/// (epic #3473). `forceLocationManager` already routes the LIBRE build through
/// Android's LocationManager at runtime, but `geolocator_android`'s
/// `FusedLocationClient` still leaves compile-time `com.google.android.gms.*`
/// REFERENCES in the fdroid dex that `fdroid scanner` rejects. Plan (see
/// `.local-docs/fdroid-gms-free-refactor-notes.md`): vendor + patch
/// `geolocator_android` for the libre build (drop `FusedLocationClient` + the
/// `GoogleApiAvailability` probe), swapped in via a libre-only
/// `pubspec_overrides.yaml` — keeping this Dart API + all 11 call sites
/// unchanged. Refactor TODO: extract `_SharedPositionSource` to its own file
/// and split out a thin permissions seam.

final class GeolocatorWrapperProvider
    extends
        $FunctionalProvider<
          GeolocatorWrapper,
          GeolocatorWrapper,
          GeolocatorWrapper
        >
    with $Provider<GeolocatorWrapper> {
  /// Wraps Geolocator's static methods for testability.
  ///
  /// All permission and location calls go through this provider instead of
  /// calling Geolocator.checkPermission() etc. directly, so tests can
  /// override the provider with a fake implementation.
  ///
  /// TODO(#3476): location capability seam for the GMS-free F-Droid architecture
  /// (epic #3473). `forceLocationManager` already routes the LIBRE build through
  /// Android's LocationManager at runtime, but `geolocator_android`'s
  /// `FusedLocationClient` still leaves compile-time `com.google.android.gms.*`
  /// REFERENCES in the fdroid dex that `fdroid scanner` rejects. Plan (see
  /// `.local-docs/fdroid-gms-free-refactor-notes.md`): vendor + patch
  /// `geolocator_android` for the libre build (drop `FusedLocationClient` + the
  /// `GoogleApiAvailability` probe), swapped in via a libre-only
  /// `pubspec_overrides.yaml` — keeping this Dart API + all 11 call sites
  /// unchanged. Refactor TODO: extract `_SharedPositionSource` to its own file
  /// and split out a thin permissions seam.
  GeolocatorWrapperProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'geolocatorWrapperProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$geolocatorWrapperHash();

  @$internal
  @override
  $ProviderElement<GeolocatorWrapper> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GeolocatorWrapper create(Ref ref) {
    return geolocatorWrapper(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GeolocatorWrapper value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GeolocatorWrapper>(value),
    );
  }
}

String _$geolocatorWrapperHash() => r'42e47a8d8284137a6a951e0db65ad8eb71fa1241';
