// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_provider_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the active [MapProvider] implementation.
///
/// Currently always returns [FlutterMapProvider] (OpenStreetMap).
/// A future version could check user settings (e.g. a Google Maps API key)
/// and return a different implementation accordingly.

@ProviderFor(mapProvider)
final mapProviderProvider = MapProviderProvider._();

/// Provides the active [MapProvider] implementation.
///
/// Currently always returns [FlutterMapProvider] (OpenStreetMap).
/// A future version could check user settings (e.g. a Google Maps API key)
/// and return a different implementation accordingly.

final class MapProviderProvider
    extends $FunctionalProvider<MapProvider, MapProvider, MapProvider>
    with $Provider<MapProvider> {
  /// Provides the active [MapProvider] implementation.
  ///
  /// Currently always returns [FlutterMapProvider] (OpenStreetMap).
  /// A future version could check user settings (e.g. a Google Maps API key)
  /// and return a different implementation accordingly.
  MapProviderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mapProviderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mapProviderHash();

  @$internal
  @override
  $ProviderElement<MapProvider> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MapProvider create(Ref ref) {
    return mapProvider(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MapProvider value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MapProvider>(value),
    );
  }
}

String _$mapProviderHash() => r'ce7eb628b46d2c510e4bd9b6732cc2e220ad120d';
