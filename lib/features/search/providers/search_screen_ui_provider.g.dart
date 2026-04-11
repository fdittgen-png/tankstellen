// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_screen_ui_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The currently selected sort mode for the search results list.

@ProviderFor(SelectedSortMode)
final selectedSortModeProvider = SelectedSortModeProvider._();

/// The currently selected sort mode for the search results list.
final class SelectedSortModeProvider
    extends $NotifierProvider<SelectedSortMode, SortMode> {
  /// The currently selected sort mode for the search results list.
  SelectedSortModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedSortModeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedSortModeHash();

  @$internal
  @override
  SelectedSortMode create() => SelectedSortMode();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SortMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SortMode>(value),
    );
  }
}

String _$selectedSortModeHash() => r'bee5aedaae37772d7269ada2fc72fa69f071a22d';

/// The currently selected sort mode for the search results list.

abstract class _$SelectedSortMode extends $Notifier<SortMode> {
  SortMode build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SortMode, SortMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SortMode, SortMode>,
              SortMode,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Whether the filter section (fuel type + radius) is expanded on the search
/// screen. Starts expanded; collapses automatically when a search is triggered
/// and in landscape orientation.

@ProviderFor(FiltersExpanded)
final filtersExpandedProvider = FiltersExpandedProvider._();

/// Whether the filter section (fuel type + radius) is expanded on the search
/// screen. Starts expanded; collapses automatically when a search is triggered
/// and in landscape orientation.
final class FiltersExpandedProvider
    extends $NotifierProvider<FiltersExpanded, bool> {
  /// Whether the filter section (fuel type + radius) is expanded on the search
  /// screen. Starts expanded; collapses automatically when a search is triggered
  /// and in landscape orientation.
  FiltersExpandedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filtersExpandedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filtersExpandedHash();

  @$internal
  @override
  FiltersExpanded create() => FiltersExpanded();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$filtersExpandedHash() => r'7b5ea1fa35a684303482e405904a71f87b268692';

/// Whether the filter section (fuel type + radius) is expanded on the search
/// screen. Starts expanded; collapses automatically when a search is triggered
/// and in landscape orientation.

abstract class _$FiltersExpanded extends $Notifier<bool> {
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

/// The route search strategy selected by the user on the search screen.

@ProviderFor(SelectedRouteStrategy)
final selectedRouteStrategyProvider = SelectedRouteStrategyProvider._();

/// The route search strategy selected by the user on the search screen.
final class SelectedRouteStrategyProvider
    extends $NotifierProvider<SelectedRouteStrategy, RouteSearchStrategyType> {
  /// The route search strategy selected by the user on the search screen.
  SelectedRouteStrategyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedRouteStrategyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedRouteStrategyHash();

  @$internal
  @override
  SelectedRouteStrategy create() => SelectedRouteStrategy();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RouteSearchStrategyType value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RouteSearchStrategyType>(value),
    );
  }
}

String _$selectedRouteStrategyHash() =>
    r'5dcf181c66745fff31e854b48fafa1c23231df3a';

/// The route search strategy selected by the user on the search screen.

abstract class _$SelectedRouteStrategy
    extends $Notifier<RouteSearchStrategyType> {
  RouteSearchStrategyType build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<RouteSearchStrategyType, RouteSearchStrategyType>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RouteSearchStrategyType, RouteSearchStrategyType>,
              RouteSearchStrategyType,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Whether the brand filter chips section is expanded in the search results.
/// Starts collapsed; the user can expand via an ExpansionTile-like toggle.

@ProviderFor(BrandFiltersExpanded)
final brandFiltersExpandedProvider = BrandFiltersExpandedProvider._();

/// Whether the brand filter chips section is expanded in the search results.
/// Starts collapsed; the user can expand via an ExpansionTile-like toggle.
final class BrandFiltersExpandedProvider
    extends $NotifierProvider<BrandFiltersExpanded, bool> {
  /// Whether the brand filter chips section is expanded in the search results.
  /// Starts collapsed; the user can expand via an ExpansionTile-like toggle.
  BrandFiltersExpandedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'brandFiltersExpandedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$brandFiltersExpandedHash();

  @$internal
  @override
  BrandFiltersExpanded create() => BrandFiltersExpanded();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$brandFiltersExpandedHash() =>
    r'fdf2689d6ec5a84799675be08dcac31351532220';

/// Whether the brand filter chips section is expanded in the search results.
/// Starts collapsed; the user can expand via an ExpansionTile-like toggle.

abstract class _$BrandFiltersExpanded extends $Notifier<bool> {
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

/// Whether to show the all-prices detail view instead of the compact card view.

@ProviderFor(AllPricesViewEnabled)
final allPricesViewEnabledProvider = AllPricesViewEnabledProvider._();

/// Whether to show the all-prices detail view instead of the compact card view.
final class AllPricesViewEnabledProvider
    extends $NotifierProvider<AllPricesViewEnabled, bool> {
  /// Whether to show the all-prices detail view instead of the compact card view.
  AllPricesViewEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allPricesViewEnabledProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allPricesViewEnabledHash();

  @$internal
  @override
  AllPricesViewEnabled create() => AllPricesViewEnabled();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$allPricesViewEnabledHash() =>
    r'924d65fb587142a85579e732270436519ce54e39';

/// Whether to show the all-prices detail view instead of the compact card view.

abstract class _$AllPricesViewEnabled extends $Notifier<bool> {
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

/// Whether results should be filtered to currently-open stations only.
/// Toggled from the search criteria screen; consumed by the results list.

@ProviderFor(OpenOnlyFilter)
final openOnlyFilterProvider = OpenOnlyFilterProvider._();

/// Whether results should be filtered to currently-open stations only.
/// Toggled from the search criteria screen; consumed by the results list.
final class OpenOnlyFilterProvider
    extends $NotifierProvider<OpenOnlyFilter, bool> {
  /// Whether results should be filtered to currently-open stations only.
  /// Toggled from the search criteria screen; consumed by the results list.
  OpenOnlyFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'openOnlyFilterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$openOnlyFilterHash();

  @$internal
  @override
  OpenOnlyFilter create() => OpenOnlyFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$openOnlyFilterHash() => r'50e083a0306412be1ee048b0d8cc618f7ef8b9c6';

/// Whether results should be filtered to currently-open stations only.
/// Toggled from the search criteria screen; consumed by the results list.

abstract class _$OpenOnlyFilter extends $Notifier<bool> {
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

/// The set of amenities the user wants stations to provide.
/// Empty set means "no amenity filter" (all stations pass).

@ProviderFor(SelectedAmenities)
final selectedAmenitiesProvider = SelectedAmenitiesProvider._();

/// The set of amenities the user wants stations to provide.
/// Empty set means "no amenity filter" (all stations pass).
final class SelectedAmenitiesProvider
    extends $NotifierProvider<SelectedAmenities, Set<StationAmenity>> {
  /// The set of amenities the user wants stations to provide.
  /// Empty set means "no amenity filter" (all stations pass).
  SelectedAmenitiesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedAmenitiesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedAmenitiesHash();

  @$internal
  @override
  SelectedAmenities create() => SelectedAmenities();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<StationAmenity> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<StationAmenity>>(value),
    );
  }
}

String _$selectedAmenitiesHash() => r'6ab13fbbedab28a4422a45b315c32865b2cacce3';

/// The set of amenities the user wants stations to provide.
/// Empty set means "no amenity filter" (all stations pass).

abstract class _$SelectedAmenities extends $Notifier<Set<StationAmenity>> {
  Set<StationAmenity> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Set<StationAmenity>, Set<StationAmenity>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<StationAmenity>, Set<StationAmenity>>,
              Set<StationAmenity>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
