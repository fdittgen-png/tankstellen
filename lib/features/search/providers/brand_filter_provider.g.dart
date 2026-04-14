// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'brand_filter_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the set of selected brand names for filtering search results.
///
/// App-lifetime state (keepAlive) so the filter selection survives the
/// criteria screen ⇄ results screen navigation. Previously screen-scoped,
/// which auto-disposed the state between navigation frames and silently
/// reset the filter to empty (#491). Empty set means "show all brands".

@ProviderFor(SelectedBrands)
final selectedBrandsProvider = SelectedBrandsProvider._();

/// Manages the set of selected brand names for filtering search results.
///
/// App-lifetime state (keepAlive) so the filter selection survives the
/// criteria screen ⇄ results screen navigation. Previously screen-scoped,
/// which auto-disposed the state between navigation frames and silently
/// reset the filter to empty (#491). Empty set means "show all brands".
final class SelectedBrandsProvider
    extends $NotifierProvider<SelectedBrands, Set<String>> {
  /// Manages the set of selected brand names for filtering search results.
  ///
  /// App-lifetime state (keepAlive) so the filter selection survives the
  /// criteria screen ⇄ results screen navigation. Previously screen-scoped,
  /// which auto-disposed the state between navigation frames and silently
  /// reset the filter to empty (#491). Empty set means "show all brands".
  SelectedBrandsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedBrandsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedBrandsHash();

  @$internal
  @override
  SelectedBrands create() => SelectedBrands();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$selectedBrandsHash() => r'80ae4d8d00fd95b4aa9b7d86167a257f240488b6';

/// Manages the set of selected brand names for filtering search results.
///
/// App-lifetime state (keepAlive) so the filter selection survives the
/// criteria screen ⇄ results screen navigation. Previously screen-scoped,
/// which auto-disposed the state between navigation frames and silently
/// reset the filter to empty (#491). Empty set means "show all brands".

abstract class _$SelectedBrands extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Whether the motorway/highway station filter is active.
/// When true, stations with stationType == "A" (autoroute) are excluded.
///
/// keepAlive so the toggle survives navigation, matching [SelectedBrands] (#491).

@ProviderFor(ExcludeHighwayStations)
final excludeHighwayStationsProvider = ExcludeHighwayStationsProvider._();

/// Whether the motorway/highway station filter is active.
/// When true, stations with stationType == "A" (autoroute) are excluded.
///
/// keepAlive so the toggle survives navigation, matching [SelectedBrands] (#491).
final class ExcludeHighwayStationsProvider
    extends $NotifierProvider<ExcludeHighwayStations, bool> {
  /// Whether the motorway/highway station filter is active.
  /// When true, stations with stationType == "A" (autoroute) are excluded.
  ///
  /// keepAlive so the toggle survives navigation, matching [SelectedBrands] (#491).
  ExcludeHighwayStationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'excludeHighwayStationsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$excludeHighwayStationsHash();

  @$internal
  @override
  ExcludeHighwayStations create() => ExcludeHighwayStations();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$excludeHighwayStationsHash() =>
    r'c07895ef69caf31407c10ad9dd0d12171116d781';

/// Whether the motorway/highway station filter is active.
/// When true, stations with stationType == "A" (autoroute) are excluded.
///
/// keepAlive so the toggle survives navigation, matching [SelectedBrands] (#491).

abstract class _$ExcludeHighwayStations extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
