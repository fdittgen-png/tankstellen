// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_search_params_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Per-search route-planning overrides for the criteria screen (#2592).
///
/// In route/itinéraire mode the radius is meaningless — route planning is
/// driven by the corridor segment spacing, the detour budget and the
/// minimum-saving floor. These three notifiers mirror the profile defaults
/// (the same fields the profile-edit sheet writes) but let the user
/// override them for a single search without mutating the saved profile.
///
/// `keepAlive` so the override survives the criteria-screen pop: the results
/// chip and the route-results header read the *same* instance the criteria
/// screen wrote (precedent: `openOnlyFilterProvider` /
/// `selectedAmenitiesProvider`). The `SearchRadius` notifier in
/// `search_filters_provider.dart` is the structural precedent for the
/// profile-defaulted build + clamping `set`.
/// Route-segment spacing (km) — how often the route surfaces a cheapest
/// stop. Defaults to the profile's `routeSegmentKm`; clamped to the same
/// 50–1000 km range as the profile-edit slider.

@ProviderFor(RouteSegmentSearchParam)
final routeSegmentSearchParamProvider = RouteSegmentSearchParamProvider._();

/// Per-search route-planning overrides for the criteria screen (#2592).
///
/// In route/itinéraire mode the radius is meaningless — route planning is
/// driven by the corridor segment spacing, the detour budget and the
/// minimum-saving floor. These three notifiers mirror the profile defaults
/// (the same fields the profile-edit sheet writes) but let the user
/// override them for a single search without mutating the saved profile.
///
/// `keepAlive` so the override survives the criteria-screen pop: the results
/// chip and the route-results header read the *same* instance the criteria
/// screen wrote (precedent: `openOnlyFilterProvider` /
/// `selectedAmenitiesProvider`). The `SearchRadius` notifier in
/// `search_filters_provider.dart` is the structural precedent for the
/// profile-defaulted build + clamping `set`.
/// Route-segment spacing (km) — how often the route surfaces a cheapest
/// stop. Defaults to the profile's `routeSegmentKm`; clamped to the same
/// 50–1000 km range as the profile-edit slider.
final class RouteSegmentSearchParamProvider
    extends $NotifierProvider<RouteSegmentSearchParam, double> {
  /// Per-search route-planning overrides for the criteria screen (#2592).
  ///
  /// In route/itinéraire mode the radius is meaningless — route planning is
  /// driven by the corridor segment spacing, the detour budget and the
  /// minimum-saving floor. These three notifiers mirror the profile defaults
  /// (the same fields the profile-edit sheet writes) but let the user
  /// override them for a single search without mutating the saved profile.
  ///
  /// `keepAlive` so the override survives the criteria-screen pop: the results
  /// chip and the route-results header read the *same* instance the criteria
  /// screen wrote (precedent: `openOnlyFilterProvider` /
  /// `selectedAmenitiesProvider`). The `SearchRadius` notifier in
  /// `search_filters_provider.dart` is the structural precedent for the
  /// profile-defaulted build + clamping `set`.
  /// Route-segment spacing (km) — how often the route surfaces a cheapest
  /// stop. Defaults to the profile's `routeSegmentKm`; clamped to the same
  /// 50–1000 km range as the profile-edit slider.
  RouteSegmentSearchParamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'routeSegmentSearchParamProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$routeSegmentSearchParamHash();

  @$internal
  @override
  RouteSegmentSearchParam create() => RouteSegmentSearchParam();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$routeSegmentSearchParamHash() =>
    r'8238d7acf973b52bbab6ad9b9da7a375d947d230';

/// Per-search route-planning overrides for the criteria screen (#2592).
///
/// In route/itinéraire mode the radius is meaningless — route planning is
/// driven by the corridor segment spacing, the detour budget and the
/// minimum-saving floor. These three notifiers mirror the profile defaults
/// (the same fields the profile-edit sheet writes) but let the user
/// override them for a single search without mutating the saved profile.
///
/// `keepAlive` so the override survives the criteria-screen pop: the results
/// chip and the route-results header read the *same* instance the criteria
/// screen wrote (precedent: `openOnlyFilterProvider` /
/// `selectedAmenitiesProvider`). The `SearchRadius` notifier in
/// `search_filters_provider.dart` is the structural precedent for the
/// profile-defaulted build + clamping `set`.
/// Route-segment spacing (km) — how often the route surfaces a cheapest
/// stop. Defaults to the profile's `routeSegmentKm`; clamped to the same
/// 50–1000 km range as the profile-edit slider.

abstract class _$RouteSegmentSearchParam extends $Notifier<double> {
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

/// Maximum detour budget (km) off the direct route. Defaults to the
/// profile's `routeDetourBudgetKm`; clamped to 2–25 km.

@ProviderFor(RouteDetourSearchParam)
final routeDetourSearchParamProvider = RouteDetourSearchParamProvider._();

/// Maximum detour budget (km) off the direct route. Defaults to the
/// profile's `routeDetourBudgetKm`; clamped to 2–25 km.
final class RouteDetourSearchParamProvider
    extends $NotifierProvider<RouteDetourSearchParam, double> {
  /// Maximum detour budget (km) off the direct route. Defaults to the
  /// profile's `routeDetourBudgetKm`; clamped to 2–25 km.
  RouteDetourSearchParamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'routeDetourSearchParamProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$routeDetourSearchParamHash();

  @$internal
  @override
  RouteDetourSearchParam create() => RouteDetourSearchParam();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$routeDetourSearchParamHash() =>
    r'0acede08bbd6335f337dfbd4147c96c78884a817';

/// Maximum detour budget (km) off the direct route. Defaults to the
/// profile's `routeDetourBudgetKm`; clamped to 2–25 km.

abstract class _$RouteDetourSearchParam extends $Notifier<double> {
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

/// Minimum saving (€/L) a station must beat the route's cheapest by to be
/// surfaced. `0.0` means "off" — every station is shown. Defaults to the
/// profile's `minRouteSavingPerLiter`; clamped to 0–0.30 €/L.

@ProviderFor(MinRouteSavingSearchParam)
final minRouteSavingSearchParamProvider = MinRouteSavingSearchParamProvider._();

/// Minimum saving (€/L) a station must beat the route's cheapest by to be
/// surfaced. `0.0` means "off" — every station is shown. Defaults to the
/// profile's `minRouteSavingPerLiter`; clamped to 0–0.30 €/L.
final class MinRouteSavingSearchParamProvider
    extends $NotifierProvider<MinRouteSavingSearchParam, double> {
  /// Minimum saving (€/L) a station must beat the route's cheapest by to be
  /// surfaced. `0.0` means "off" — every station is shown. Defaults to the
  /// profile's `minRouteSavingPerLiter`; clamped to 0–0.30 €/L.
  MinRouteSavingSearchParamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'minRouteSavingSearchParamProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$minRouteSavingSearchParamHash();

  @$internal
  @override
  MinRouteSavingSearchParam create() => MinRouteSavingSearchParam();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$minRouteSavingSearchParamHash() =>
    r'a42ffd75d49e80ddc61fec7439e2b26cafde6d6b';

/// Minimum saving (€/L) a station must beat the route's cheapest by to be
/// surfaced. `0.0` means "off" — every station is shown. Defaults to the
/// profile's `minRouteSavingPerLiter`; clamped to 0–0.30 €/L.

abstract class _$MinRouteSavingSearchParam extends $Notifier<double> {
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
