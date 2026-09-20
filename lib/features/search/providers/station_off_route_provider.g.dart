// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'station_off_route_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Station id → how far that station lies OFF the active route, in km
/// (#4432).
///
/// ## What this is, exactly
///
/// The straight-line distance from the route's own geometry to the
/// station, computed against THIS route via [RouteProjection] — the
/// same projection the refuel plan uses (#4146), so "off the route" has
/// one definition. It is a **geometric estimate**: the map distance to
/// the line, not a driven distance. It is therefore neither the
/// distance from the driver nor the extra driving a stop would cost,
/// and the row that shows it says so.
///
/// ## The bug it replaces
///
/// A route row showed `Auchan · 4,4 km` in exactly the typography a
/// proximity row uses for "4.4 km from you". That number was
/// `Station.dist` — computed by the country service from whichever
/// sample point's query happened to return the station first, and kept
/// by the dedup — so it was not a stable quantity at all: the same
/// station could carry a different figure depending on batch order. The
/// route surfaces must not show it, and must not substitute the radar's
/// `roadDistancesProvider` value either, which is keyed by station id
/// from a different search's origin.
///
/// ## Why a side channel
///
/// Same shape as `roadDistancesProvider` and
/// `highwayExitInfoMapProvider`: the station card is shared by the
/// search list, the favourites list, the radar and the route list, and
/// threading one more value through every call site costs more than it
/// buys (and would push `StationCard` past the #3985 constructor-arity
/// gate). A row asks this map whether IT belongs to the active route;
/// every other surface reads an empty map and renders as before.
///
/// Empty unless a route search is the active one, so a route result
/// left in memory cannot relabel the distances in a nearby search.

@ProviderFor(stationOffRouteKm)
final stationOffRouteKmProvider = StationOffRouteKmProvider._();

/// Station id → how far that station lies OFF the active route, in km
/// (#4432).
///
/// ## What this is, exactly
///
/// The straight-line distance from the route's own geometry to the
/// station, computed against THIS route via [RouteProjection] — the
/// same projection the refuel plan uses (#4146), so "off the route" has
/// one definition. It is a **geometric estimate**: the map distance to
/// the line, not a driven distance. It is therefore neither the
/// distance from the driver nor the extra driving a stop would cost,
/// and the row that shows it says so.
///
/// ## The bug it replaces
///
/// A route row showed `Auchan · 4,4 km` in exactly the typography a
/// proximity row uses for "4.4 km from you". That number was
/// `Station.dist` — computed by the country service from whichever
/// sample point's query happened to return the station first, and kept
/// by the dedup — so it was not a stable quantity at all: the same
/// station could carry a different figure depending on batch order. The
/// route surfaces must not show it, and must not substitute the radar's
/// `roadDistancesProvider` value either, which is keyed by station id
/// from a different search's origin.
///
/// ## Why a side channel
///
/// Same shape as `roadDistancesProvider` and
/// `highwayExitInfoMapProvider`: the station card is shared by the
/// search list, the favourites list, the radar and the route list, and
/// threading one more value through every call site costs more than it
/// buys (and would push `StationCard` past the #3985 constructor-arity
/// gate). A row asks this map whether IT belongs to the active route;
/// every other surface reads an empty map and renders as before.
///
/// Empty unless a route search is the active one, so a route result
/// left in memory cannot relabel the distances in a nearby search.

final class StationOffRouteKmProvider
    extends
        $FunctionalProvider<
          Map<String, double>,
          Map<String, double>,
          Map<String, double>
        >
    with $Provider<Map<String, double>> {
  /// Station id → how far that station lies OFF the active route, in km
  /// (#4432).
  ///
  /// ## What this is, exactly
  ///
  /// The straight-line distance from the route's own geometry to the
  /// station, computed against THIS route via [RouteProjection] — the
  /// same projection the refuel plan uses (#4146), so "off the route" has
  /// one definition. It is a **geometric estimate**: the map distance to
  /// the line, not a driven distance. It is therefore neither the
  /// distance from the driver nor the extra driving a stop would cost,
  /// and the row that shows it says so.
  ///
  /// ## The bug it replaces
  ///
  /// A route row showed `Auchan · 4,4 km` in exactly the typography a
  /// proximity row uses for "4.4 km from you". That number was
  /// `Station.dist` — computed by the country service from whichever
  /// sample point's query happened to return the station first, and kept
  /// by the dedup — so it was not a stable quantity at all: the same
  /// station could carry a different figure depending on batch order. The
  /// route surfaces must not show it, and must not substitute the radar's
  /// `roadDistancesProvider` value either, which is keyed by station id
  /// from a different search's origin.
  ///
  /// ## Why a side channel
  ///
  /// Same shape as `roadDistancesProvider` and
  /// `highwayExitInfoMapProvider`: the station card is shared by the
  /// search list, the favourites list, the radar and the route list, and
  /// threading one more value through every call site costs more than it
  /// buys (and would push `StationCard` past the #3985 constructor-arity
  /// gate). A row asks this map whether IT belongs to the active route;
  /// every other surface reads an empty map and renders as before.
  ///
  /// Empty unless a route search is the active one, so a route result
  /// left in memory cannot relabel the distances in a nearby search.
  StationOffRouteKmProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'stationOffRouteKmProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$stationOffRouteKmHash();

  @$internal
  @override
  $ProviderElement<Map<String, double>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<String, double> create(Ref ref) {
    return stationOffRouteKm(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, double> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, double>>(value),
    );
  }
}

String _$stationOffRouteKmHash() => r'116fde11531b606702bf04ca80398526cebc0e52';
