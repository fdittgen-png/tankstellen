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

@ProviderFor(geolocatorWrapper)
final geolocatorWrapperProvider = GeolocatorWrapperProvider._();

/// Wraps Geolocator's static methods for testability.
///
/// All permission and location calls go through this provider instead of
/// calling Geolocator.checkPermission() etc. directly, so tests can
/// override the provider with a fake implementation.

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
