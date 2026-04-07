// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(tankerkoenigDio)
final tankerkoenigDioProvider = TankerkoenigDioProvider._();

final class TankerkoenigDioProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
  TankerkoenigDioProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tankerkoenigDioProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tankerkoenigDioHash();

  @$internal
  @override
  $ProviderElement<Dio> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Dio create(Ref ref) {
    return tankerkoenigDio(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Dio>(value),
    );
  }
}

String _$tankerkoenigDioHash() => r'5ade6219b0e5455fcda1bd7d05904c5eb75a770a';

/// Returns the appropriate station service based on whether an API key
/// is configured. With key: Tankerkoenig with full fallback chain.
/// Without key: demo data so the app works immediately.

@ProviderFor(stationService)
final stationServiceProvider = StationServiceProvider._();

/// Returns the appropriate station service based on whether an API key
/// is configured. With key: Tankerkoenig with full fallback chain.
/// Without key: demo data so the app works immediately.

final class StationServiceProvider
    extends $FunctionalProvider<StationService, StationService, StationService>
    with $Provider<StationService> {
  /// Returns the appropriate station service based on whether an API key
  /// is configured. With key: Tankerkoenig with full fallback chain.
  /// Without key: demo data so the app works immediately.
  StationServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'stationServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$stationServiceHash();

  @$internal
  @override
  $ProviderElement<StationService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  StationService create(Ref ref) {
    return stationService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StationService>(value),
    );
  }
}

String _$stationServiceHash() => r'9a4f37e4936e1a923e3c47c2a116889e6416718b';

@ProviderFor(geocodingChain)
final geocodingChainProvider = GeocodingChainProvider._();

final class GeocodingChainProvider
    extends $FunctionalProvider<GeocodingChain, GeocodingChain, GeocodingChain>
    with $Provider<GeocodingChain> {
  GeocodingChainProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'geocodingChainProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$geocodingChainHash();

  @$internal
  @override
  $ProviderElement<GeocodingChain> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GeocodingChain create(Ref ref) {
    return geocodingChain(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GeocodingChain value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GeocodingChain>(value),
    );
  }
}

String _$geocodingChainHash() => r'58e72b3ac8bafb01e903fd9922d65ba82830bc23';
