// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'station_off_route_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Station id → where that station sits on the ACTIVE route (#4432):
/// its along-route progress and its geometric offset from the route
/// line, as one [RouteStopMetrics] stamped with the route revision.
///
/// ## What this is, exactly
///
/// Both figures are measured against THIS route's own geometry by
/// `routeStopMetricsFor` — the one `RouteProjection` itinerary pass the
/// corridor filter, the list order and the refuel plan (#4146) share,
/// so "off the route" and "how far along" each have one definition.
/// They are **geometric**: neither is the distance from the driver nor
/// the extra driving a stop would cost (those are the routed
/// `StationTravelEstimate` quantities, #4359), and the row that shows
/// them says so.
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

@ProviderFor(stationRouteMetrics)
final stationRouteMetricsProvider = StationRouteMetricsProvider._();

/// Station id → where that station sits on the ACTIVE route (#4432):
/// its along-route progress and its geometric offset from the route
/// line, as one [RouteStopMetrics] stamped with the route revision.
///
/// ## What this is, exactly
///
/// Both figures are measured against THIS route's own geometry by
/// `routeStopMetricsFor` — the one `RouteProjection` itinerary pass the
/// corridor filter, the list order and the refuel plan (#4146) share,
/// so "off the route" and "how far along" each have one definition.
/// They are **geometric**: neither is the distance from the driver nor
/// the extra driving a stop would cost (those are the routed
/// `StationTravelEstimate` quantities, #4359), and the row that shows
/// them says so.
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

final class StationRouteMetricsProvider
    extends
        $FunctionalProvider<
          Map<String, RouteStopMetrics>,
          Map<String, RouteStopMetrics>,
          Map<String, RouteStopMetrics>
        >
    with $Provider<Map<String, RouteStopMetrics>> {
  /// Station id → where that station sits on the ACTIVE route (#4432):
  /// its along-route progress and its geometric offset from the route
  /// line, as one [RouteStopMetrics] stamped with the route revision.
  ///
  /// ## What this is, exactly
  ///
  /// Both figures are measured against THIS route's own geometry by
  /// `routeStopMetricsFor` — the one `RouteProjection` itinerary pass the
  /// corridor filter, the list order and the refuel plan (#4146) share,
  /// so "off the route" and "how far along" each have one definition.
  /// They are **geometric**: neither is the distance from the driver nor
  /// the extra driving a stop would cost (those are the routed
  /// `StationTravelEstimate` quantities, #4359), and the row that shows
  /// them says so.
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
  StationRouteMetricsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'stationRouteMetricsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$stationRouteMetricsHash();

  @$internal
  @override
  $ProviderElement<Map<String, RouteStopMetrics>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<String, RouteStopMetrics> create(Ref ref) {
    return stationRouteMetrics(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, RouteStopMetrics> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, RouteStopMetrics>>(
        value,
      ),
    );
  }
}

String _$stationRouteMetricsHash() =>
    r'9c063e6d4a5356a3e4352cea55f7c917e9577b40';
