// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'brand_filter_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the set of selected brand names for filtering search results.
///
/// Screen-scoped (not keepAlive) — resets when the user navigates away.
/// Empty set means "show all brands" (no filter active).

@ProviderFor(SelectedBrands)
final selectedBrandsProvider = SelectedBrandsProvider._();

/// Manages the set of selected brand names for filtering search results.
///
/// Screen-scoped (not keepAlive) — resets when the user navigates away.
/// Empty set means "show all brands" (no filter active).
final class SelectedBrandsProvider
    extends $NotifierProvider<SelectedBrands, Set<String>> {
  /// Manages the set of selected brand names for filtering search results.
  ///
  /// Screen-scoped (not keepAlive) — resets when the user navigates away.
  /// Empty set means "show all brands" (no filter active).
  SelectedBrandsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedBrandsProvider',
        isAutoDispose: true,
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

String _$selectedBrandsHash() => r'1b406f31ffd0f3d2d9e85cb714fc260df69384de';

/// Manages the set of selected brand names for filtering search results.
///
/// Screen-scoped (not keepAlive) — resets when the user navigates away.
/// Empty set means "show all brands" (no filter active).

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

@ProviderFor(ExcludeHighwayStations)
final excludeHighwayStationsProvider = ExcludeHighwayStationsProvider._();

/// Whether the motorway/highway station filter is active.
/// When true, stations with stationType == "A" (autoroute) are excluded.
final class ExcludeHighwayStationsProvider
    extends $NotifierProvider<ExcludeHighwayStations, bool> {
  /// Whether the motorway/highway station filter is active.
  /// When true, stations with stationType == "A" (autoroute) are excluded.
  ExcludeHighwayStationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'excludeHighwayStationsProvider',
        isAutoDispose: true,
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
    r'11cf69d65c49220d2904629b9fb8fb5f92df333f';

/// Whether the motorway/highway station filter is active.
/// When true, stations with stationType == "A" (autoroute) are excluded.

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
