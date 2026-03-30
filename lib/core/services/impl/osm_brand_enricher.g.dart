// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'osm_brand_enricher.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(osmBrandEnricher)
final osmBrandEnricherProvider = OsmBrandEnricherProvider._();

final class OsmBrandEnricherProvider
    extends
        $FunctionalProvider<
          OsmBrandEnricher,
          OsmBrandEnricher,
          OsmBrandEnricher
        >
    with $Provider<OsmBrandEnricher> {
  OsmBrandEnricherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'osmBrandEnricherProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$osmBrandEnricherHash();

  @$internal
  @override
  $ProviderElement<OsmBrandEnricher> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  OsmBrandEnricher create(Ref ref) {
    return osmBrandEnricher(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OsmBrandEnricher value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OsmBrandEnricher>(value),
    );
  }
}

String _$osmBrandEnricherHash() => r'577ef820fa936e54b553d8535a1840cdea7e9e67';
