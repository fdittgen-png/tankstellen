// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_filters_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Stores the resolved search location for display (ZIP + city).

@ProviderFor(SearchLocation)
final searchLocationProvider = SearchLocationProvider._();

/// Stores the resolved search location for display (ZIP + city).
final class SearchLocationProvider
    extends $NotifierProvider<SearchLocation, String> {
  /// Stores the resolved search location for display (ZIP + city).
  SearchLocationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchLocationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchLocationHash();

  @$internal
  @override
  SearchLocation create() => SearchLocation();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$searchLocationHash() => r'4124b3937facdcf880e61a31db54b613df22f2ab';

/// Stores the resolved search location for display (ZIP + city).

abstract class _$SearchLocation extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(SelectedFuelType)
final selectedFuelTypeProvider = SelectedFuelTypeProvider._();

final class SelectedFuelTypeProvider
    extends $NotifierProvider<SelectedFuelType, FuelType> {
  SelectedFuelTypeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedFuelTypeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedFuelTypeHash();

  @$internal
  @override
  SelectedFuelType create() => SelectedFuelType();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FuelType value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FuelType>(value),
    );
  }
}

String _$selectedFuelTypeHash() => r'71813a25d506b09ebe59bc4ed00192c9f714c60a';

abstract class _$SelectedFuelType extends $Notifier<FuelType> {
  FuelType build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<FuelType, FuelType>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FuelType, FuelType>,
              FuelType,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(SearchRadius)
final searchRadiusProvider = SearchRadiusProvider._();

final class SearchRadiusProvider
    extends $NotifierProvider<SearchRadius, double> {
  SearchRadiusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchRadiusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchRadiusHash();

  @$internal
  @override
  SearchRadius create() => SearchRadius();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$searchRadiusHash() => r'814c1d14dba718cfe054f358930daa84cbfc3f5d';

abstract class _$SearchRadius extends $Notifier<double> {
  double build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<double, double>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<double, double>,
              double,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Extracts fuel [Station] objects from the unified search results.
///
/// Convenience for consumers that need [List<Station>] (cross-border
/// comparisons, driving mode, station detail lookup, brand filter chips).

@ProviderFor(fuelStations)
final fuelStationsProvider = FuelStationsProvider._();

/// Extracts fuel [Station] objects from the unified search results.
///
/// Convenience for consumers that need [List<Station>] (cross-border
/// comparisons, driving mode, station detail lookup, brand filter chips).

final class FuelStationsProvider
    extends $FunctionalProvider<List<Station>, List<Station>, List<Station>>
    with $Provider<List<Station>> {
  /// Extracts fuel [Station] objects from the unified search results.
  ///
  /// Convenience for consumers that need [List<Station>] (cross-border
  /// comparisons, driving mode, station detail lookup, brand filter chips).
  FuelStationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fuelStationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fuelStationsHash();

  @$internal
  @override
  $ProviderElement<List<Station>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Station> create(Ref ref) {
    return fuelStations(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Station> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Station>>(value),
    );
  }
}

String _$fuelStationsHash() => r'5238084b6dd78061bafabf616c603bcf7b03077b';
