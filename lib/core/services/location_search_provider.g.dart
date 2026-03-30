// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_search_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(locationSearchService)
final locationSearchServiceProvider = LocationSearchServiceProvider._();

final class LocationSearchServiceProvider
    extends
        $FunctionalProvider<
          LocationSearchService,
          LocationSearchService,
          LocationSearchService
        >
    with $Provider<LocationSearchService> {
  LocationSearchServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'locationSearchServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$locationSearchServiceHash();

  @$internal
  @override
  $ProviderElement<LocationSearchService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LocationSearchService create(Ref ref) {
    return locationSearchService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocationSearchService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocationSearchService>(value),
    );
  }
}

String _$locationSearchServiceHash() =>
    r'14062d33162a12e998bca21dc6cb34ed84d6769f';
