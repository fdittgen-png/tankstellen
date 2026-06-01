// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../profile/providers/profile_provider.dart';

part 'route_search_params_provider.g.dart';

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
@Riverpod(keepAlive: true)
class RouteSegmentSearchParam extends _$RouteSegmentSearchParam {
  @override
  double build() => ref.watch(activeProfileProvider)?.routeSegmentKm ?? 50.0;

  void set(double v) => state = v.clamp(50.0, 1000.0);
}

/// Maximum detour budget (km) off the direct route. Defaults to the
/// profile's `routeDetourBudgetKm`; clamped to 2–25 km.
@Riverpod(keepAlive: true)
class RouteDetourSearchParam extends _$RouteDetourSearchParam {
  @override
  double build() =>
      ref.watch(activeProfileProvider)?.routeDetourBudgetKm ?? 5.0;

  void set(double v) => state = v.clamp(2.0, 25.0);
}

/// Minimum saving (€/L) a station must beat the route's cheapest by to be
/// surfaced. `0.0` means "off" — every station is shown. Defaults to the
/// profile's `minRouteSavingPerLiter`; clamped to 0–0.30 €/L.
@Riverpod(keepAlive: true)
class MinRouteSavingSearchParam extends _$MinRouteSavingSearchParam {
  @override
  double build() =>
      ref.watch(activeProfileProvider)?.minRouteSavingPerLiter ?? 0.0;

  void set(double v) => state = v.clamp(0.0, 0.30);
}
