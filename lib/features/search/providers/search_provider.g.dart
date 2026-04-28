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
/// `search_result_helpers.dart`; orchestration helpers (EV dispatch,
/// fuel/radius resolution, error classification, GPS auto-update)
/// live in `search_provider_orchestration.dart`. This file keeps only
/// the public search entry points + state mutation.

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
/// `search_result_helpers.dart`; orchestration helpers (EV dispatch,
/// fuel/radius resolution, error classification, GPS auto-update)
/// live in `search_provider_orchestration.dart`. This file keeps only
/// the public search entry points + state mutation.
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
  /// `search_result_helpers.dart`; orchestration helpers (EV dispatch,
  /// fuel/radius resolution, error classification, GPS auto-update)
  /// live in `search_provider_orchestration.dart`. This file keeps only
  /// the public search entry points + state mutation.
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

String _$searchStateHash() => r'18b410ecf78dd8b652cac24a5f1e7c235658c0a1';

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
/// `search_result_helpers.dart`; orchestration helpers (EV dispatch,
/// fuel/radius resolution, error classification, GPS auto-update)
/// live in `search_provider_orchestration.dart`. This file keeps only
/// the public search entry points + state mutation.

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
