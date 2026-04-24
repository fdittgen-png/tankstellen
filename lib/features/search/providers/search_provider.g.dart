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
/// Supports three search modes: [searchByGps], [searchByZipCode],
/// [searchByCoordinates]. All modes delegate to the country-appropriate
/// [StationService] via [stationServiceProvider] (fresh cache → API →
/// stale cache → error).
///
/// Pure helpers (result wrapping, distance recalc, postal-code
/// extraction, geocoding-error merging) live in
/// `search_result_helpers.dart`; this file keeps the stateful
/// orchestration (cancel tokens, profile lookups, state mutation).

@ProviderFor(SearchState)
final searchStateProvider = SearchStateProvider._();

/// Manages the station search lifecycle and exposes results as [AsyncValue].
///
/// Wraps every result in [ServiceResult] so the UI can display data source,
/// freshness age, and fallback information (e.g., "cache, 12 min ago").
/// Supports three search modes: [searchByGps], [searchByZipCode],
/// [searchByCoordinates]. All modes delegate to the country-appropriate
/// [StationService] via [stationServiceProvider] (fresh cache → API →
/// stale cache → error).
///
/// Pure helpers (result wrapping, distance recalc, postal-code
/// extraction, geocoding-error merging) live in
/// `search_result_helpers.dart`; this file keeps the stateful
/// orchestration (cancel tokens, profile lookups, state mutation).
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
  /// Supports three search modes: [searchByGps], [searchByZipCode],
  /// [searchByCoordinates]. All modes delegate to the country-appropriate
  /// [StationService] via [stationServiceProvider] (fresh cache → API →
  /// stale cache → error).
  ///
  /// Pure helpers (result wrapping, distance recalc, postal-code
  /// extraction, geocoding-error merging) live in
  /// `search_result_helpers.dart`; this file keeps the stateful
  /// orchestration (cancel tokens, profile lookups, state mutation).
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

String _$searchStateHash() => r'794dccf84672b1c30c6f326acefbd78157ef659a';

/// Manages the station search lifecycle and exposes results as [AsyncValue].
///
/// Wraps every result in [ServiceResult] so the UI can display data source,
/// freshness age, and fallback information (e.g., "cache, 12 min ago").
/// Supports three search modes: [searchByGps], [searchByZipCode],
/// [searchByCoordinates]. All modes delegate to the country-appropriate
/// [StationService] via [stationServiceProvider] (fresh cache → API →
/// stale cache → error).
///
/// Pure helpers (result wrapping, distance recalc, postal-code
/// extraction, geocoding-error merging) live in
/// `search_result_helpers.dart`; this file keeps the stateful
/// orchestration (cancel tokens, profile lookups, state mutation).

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
