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
          AsyncValue<ServiceResult<List<SearchResultItem>>>
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
  Override overrideWithValue(
    AsyncValue<ServiceResult<List<SearchResultItem>>> value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<AsyncValue<ServiceResult<List<SearchResultItem>>>>(
            value,
          ),
    );
  }
}

String _$searchStateHash() => r'ca6a2ba8f1cbdd3a1042d75f94149c820fc90cb0';

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
    extends $Notifier<AsyncValue<ServiceResult<List<SearchResultItem>>>> {
  AsyncValue<ServiceResult<List<SearchResultItem>>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<ServiceResult<List<SearchResultItem>>>,
              AsyncValue<ServiceResult<List<SearchResultItem>>>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<ServiceResult<List<SearchResultItem>>>,
                AsyncValue<ServiceResult<List<SearchResultItem>>>
              >,
              AsyncValue<ServiceResult<List<SearchResultItem>>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
