// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the station search lifecycle and exposes results as [AsyncValue].
///
/// Wraps every result in [ServiceResult] so the UI can display data source,
/// freshness age, and fallback information (e.g., "cache, 12 min ago").
///
/// Supports three search modes:
/// - [searchByGps] -- uses device GPS to determine coordinates
/// - [searchByZipCode] -- geocodes a postal code, then searches
/// - [searchByCoordinates] -- uses explicit lat/lng (from city search)
///
/// All modes delegate to the country-appropriate [StationService] via
/// the [stationServiceProvider], which applies the full fallback chain
/// (fresh cache -> API -> stale cache -> error).

@ProviderFor(SearchState)
final searchStateProvider = SearchStateProvider._();

/// Manages the station search lifecycle and exposes results as [AsyncValue].
///
/// Wraps every result in [ServiceResult] so the UI can display data source,
/// freshness age, and fallback information (e.g., "cache, 12 min ago").
///
/// Supports three search modes:
/// - [searchByGps] -- uses device GPS to determine coordinates
/// - [searchByZipCode] -- geocodes a postal code, then searches
/// - [searchByCoordinates] -- uses explicit lat/lng (from city search)
///
/// All modes delegate to the country-appropriate [StationService] via
/// the [stationServiceProvider], which applies the full fallback chain
/// (fresh cache -> API -> stale cache -> error).
final class SearchStateProvider
    extends
        $NotifierProvider<
          SearchState,
          AsyncValue<ServiceResult<List<Station>>>
        > {
  /// Manages the station search lifecycle and exposes results as [AsyncValue].
  ///
  /// Wraps every result in [ServiceResult] so the UI can display data source,
  /// freshness age, and fallback information (e.g., "cache, 12 min ago").
  ///
  /// Supports three search modes:
  /// - [searchByGps] -- uses device GPS to determine coordinates
  /// - [searchByZipCode] -- geocodes a postal code, then searches
  /// - [searchByCoordinates] -- uses explicit lat/lng (from city search)
  ///
  /// All modes delegate to the country-appropriate [StationService] via
  /// the [stationServiceProvider], which applies the full fallback chain
  /// (fresh cache -> API -> stale cache -> error).
  SearchStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchStateHash();

  @$internal
  @override
  SearchState create() => SearchState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<ServiceResult<List<Station>>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<AsyncValue<ServiceResult<List<Station>>>>(value),
    );
  }
}

String _$searchStateHash() => r'3a14888c0ec399348363e94cac4ff6766d50c9f5';

/// Manages the station search lifecycle and exposes results as [AsyncValue].
///
/// Wraps every result in [ServiceResult] so the UI can display data source,
/// freshness age, and fallback information (e.g., "cache, 12 min ago").
///
/// Supports three search modes:
/// - [searchByGps] -- uses device GPS to determine coordinates
/// - [searchByZipCode] -- geocodes a postal code, then searches
/// - [searchByCoordinates] -- uses explicit lat/lng (from city search)
///
/// All modes delegate to the country-appropriate [StationService] via
/// the [stationServiceProvider], which applies the full fallback chain
/// (fresh cache -> API -> stale cache -> error).

abstract class _$SearchState
    extends $Notifier<AsyncValue<ServiceResult<List<Station>>>> {
  AsyncValue<ServiceResult<List<Station>>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<ServiceResult<List<Station>>>,
              AsyncValue<ServiceResult<List<Station>>>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<ServiceResult<List<Station>>>,
                AsyncValue<ServiceResult<List<Station>>>
              >,
              AsyncValue<ServiceResult<List<Station>>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

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

String _$selectedFuelTypeHash() => r'7ac6e8dcc8a0d81e2e9de3ac51ada679c0472556';

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
