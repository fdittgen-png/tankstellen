// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';

import '../../data/sparkilo_tile_layer.dart';
import '../../../../core/utils/price_utils.dart';
import '../../../../core/widgets/osm_attribution.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../../search/domain/entities/station.dart';
import '../../../search/presentation/widgets/sort_selector.dart';
import 'price_legend.dart';
import 'station_marker.dart';

/// Camera zoom bounds (#1457). Top end matches the OSM tile cap so a
/// `move(camera.zoom + 1)` past the cap doesn't park the user on a
/// grey viewport with no tiles to draw. Bottom end is conservative —
/// flutter_map wraps the world at zoom 0, but anything below ~3 puts
/// every pin in a single pixel which is unhelpful UX.
const double _kMinZoom = 3.0;
const double _kMaxZoom = 19.0;

/// Shared map widget containing all layers: tiles, search radius circle,
/// center marker, station markers with clustering, attribution, zoom
/// controls, and price legend.
///
/// Used by both [MapScreen] (full-screen) and [InlineMap] (split-screen)
/// to eliminate ~130 lines of duplicated map layer code.
///
/// ## One tile path (#2394 / #2398)
///
/// The basemap renders through the single hardened [SparkiloTileLayer].
/// Prior to #2398 this widget ran a *parallel* inline `TileLayer` plus a
/// 12-second cold-start "reset window" that fired `TileLayer.reset` on
/// every camera/size event during cold-start. That storm evicted tiles
/// before they painted on a slow first round-trip — the recurring
/// grey-tile bug (#757 → #1234 → #1316 → #1991 → #2044 → #2096 →
/// #2122 → #2177). The reset machinery is deleted: there is exactly one
/// tile path, every surface shares `abortObsoleteRequests: true`
/// (the upstream default inside [SparkiloTileLayer]), and there is no
/// reset stream to mis-fire. See `tile_layer_consistency_test.dart`
/// (allowlist is now the single `sparkilo_tile_layer.dart`) and
/// `station_map_layers_no_reset_test.dart`.
class StationMapLayers extends StatefulWidget {
  final MapController mapController;
  final List<Station> stations;
  final LatLng center;
  final double zoom;
  final double searchRadiusKm;
  final FuelType selectedFuel;

  /// The active list sort (#2510). Governs which stations are EMPHASIZED
  /// on the map: the top-ranked few keep their full price bubble while
  /// the rest render as compact price-band dots so a bounded result set
  /// stays fully visible without the bubbles overlapping. `price` /
  /// `priceDistance` emphasize the cheapest; everything else (distance,
  /// 24h, rating, name) emphasizes the closest. Defaults to
  /// [SortMode.price] — the savings-first emphasis — for callers (route,
  /// driving, inline) that don't surface a sort selector.
  final SortMode sortMode;

  final bool showRecenterButton;
  final VoidCallback? onRecenter;
  final List<LatLng>? routePolyline;
  final bool showSearchRadius;

  /// When non-null, stations NOT in this set are rendered in pastel.
  /// Stations IN this set use vivid/flashy colors for quick identification.
  final Set<String>? selectedStationIds;

  /// Additional map layers rendered after the station markers, e.g. the
  /// EV charging station overlay.
  final List<Widget> extraLayers;

  /// #2631 — on a cross-border route, maps a station to the fuel of ITS
  /// country's profile (offline, from the station's lat/lng). When set,
  /// marker price, colour and paint order all use that resolved fuel so a
  /// Spanish station shows the E10 price an E85 driver would pay instead
  /// of '--'. Null on a single-country search → strict [selectedFuel]
  /// behaviour (#2510), unchanged.
  final FuelType Function(Station)? fuelResolver;

  const StationMapLayers({
    super.key,
    required this.mapController,
    required this.stations,
    required this.center,
    required this.zoom,
    required this.searchRadiusKm,
    required this.selectedFuel,
    this.sortMode = SortMode.price,
    this.showRecenterButton = false,
    this.onRecenter,
    this.routePolyline,
    this.showSearchRadius = true,
    this.selectedStationIds,
    this.extraLayers = const [],
    this.fuelResolver,
  });

  @override
  State<StationMapLayers> createState() => _StationMapLayersState();

  /// Camera zoom bounds for the +/− button handlers + the [MapOptions]
  /// camera constraints. Aligned with the OSM tile cap (`maxNativeZoom: 19`)
  /// so a programmatic zoom-in past the cap doesn't park the camera at
  /// a level with no tiles to render. The min is conservative — flutter_map
  /// itself wraps the world at zoom 0, but anything below ~3 puts every
  /// pin in a single pixel, which is unhelpful UX. Per #1457.
  @visibleForTesting
  static const double minZoom = _kMinZoom;
  @visibleForTesting
  static const double maxZoom = _kMaxZoom;

  /// Calculate zoom level from search radius.
  static double zoomForRadius(double radiusKm) {
    if (radiusKm <= 5) return 13;
    if (radiusKm <= 10) return 12;
    if (radiusKm <= 15) return 11;
    if (radiusKm <= 25) return 10;
    return 9;
  }

  /// Compute the [LatLngBounds] of a circle of [radiusKm] around [center].
  ///
  /// Uses a flat-earth approximation that is accurate enough for the
  /// search radii we deal with (< 100 km). 1 degree latitude is ~111 km;
  /// the longitude degree shrinks with the cosine of the latitude.
  static LatLngBounds boundsForRadius(LatLng center, double radiusKm) {
    const double kmPerLatDegree = 111.0;
    final double latDelta = radiusKm / kmPerLatDegree;
    final double cosLat = math.cos(center.latitude * math.pi / 180.0).abs();
    // Guard against the poles where cos(lat) approaches zero.
    final double safeCos = cosLat < 0.01 ? 0.01 : cosLat;
    final double lngDelta = radiusKm / (kmPerLatDegree * safeCos);
    final double south = (center.latitude - latDelta).clamp(-90.0, 90.0);
    final double north = (center.latitude + latDelta).clamp(-90.0, 90.0);
    final double west = (center.longitude - lngDelta).clamp(-180.0, 180.0);
    final double east = (center.longitude + lngDelta).clamp(-180.0, 180.0);
    return LatLngBounds(
      LatLng(south, west),
      LatLng(north, east),
    );
  }

  /// Calculate center point from a list of stations.
  static LatLng centerOf(List<Station> stations) {
    double sumLat = 0, sumLng = 0;
    for (final s in stations) {
      sumLat += s.lat;
      sumLng += s.lng;
    }
    return LatLng(sumLat / stations.length, sumLng / stations.length);
  }

  /// Order [stations] so that, when their markers are handed to the
  /// marker layer, the CHEAPEST (green/günstig) marker is painted ON
  /// TOP of any more-expensive (orange/red) markers it overlaps (#2434).
  ///
  /// flutter_map paints markers in the order of the source list — a marker
  /// LATER in the list is painted on top of earlier ones. So the rule is:
  ///   - sort by the SELECTED-fuel price (`station.priceFor(selectedFuel)`)
  ///     — the SAME price the marker is COLOURED by and the SAME strict
  ///     resolution the search list uses (#2510, reverting the #2400
  ///     fallback chain) — DESCENDING: most expensive first (painted at
  ///     the bottom), cheapest last (painted on top), so colour and
  ///     stacking always agree;
  ///   - markers with NO selected-fuel price (the grey "--" bubble) sort
  ///     to the very FRONT (the bottom of the stack) so a price-less
  ///     marker can never cover a real green one.
  ///
  /// Returns a NEW list; the input is not mutated. A stable sort keeps the
  /// relative order of equal-priced stations.
  static List<Station> orderedByPriceForPainting(
    List<Station> stations,
    FuelType selectedFuel, {
    FuelType Function(Station)? fuelResolver,
  }) {
    // A null selected-fuel price is treated as the most-expensive bucket
    // (+infinity) so, under a descending sort, it lands first → painted
    // at the very bottom, beneath every priced marker. #2631 — when a
    // cross-border resolver is set, the key is each station's OWN country
    // fuel price so the cheapest ES (E10) marker still paints on top.
    double sortKey(Station s) =>
        priceForFuelType(s, fuelResolver != null ? fuelResolver(s) : selectedFuel) ??
        double.infinity;
    final ordered = List<Station>.of(stations);
    // Descending: highest price first (bottom), lowest last (top).
    mergeSort<Station>(ordered,
        compare: (a, b) => sortKey(b).compareTo(sortKey(a)));
    return ordered;
  }

  /// How many top-ranked stations keep their full price label; the rest
  /// render as compact price-band dots (#2510). Small enough that the
  /// emphasized bubbles stay legible at the search zoom, large enough to
  /// surface the handful of stations a driver actually compares.
  @visibleForTesting
  static const int emphasisCount = 4;

  /// At or above this many stations the map falls back to count-clustering
  /// (#2510). A bounded nearby search (the 10-station / 10 km case) stays
  /// well under this, so every result renders as its own marker; only a
  /// genuinely huge / zoomed-far set collapses into tappable clusters
  /// rather than painting hundreds of overlapping dots.
  @visibleForTesting
  static const int clusterThreshold = 80;

  /// Rank [stations] for marker EMPHASIS per the active [sortMode] (#2510):
  /// the cheapest stations first for a price-oriented sort, the closest
  /// first otherwise. The first [StationMapLayers.emphasisCount] entries
  /// get the full price bubble; the rest become compact dots. Stations
  /// without a comparable value sort last so they never steal emphasis
  /// from a station that has a real price/distance.
  ///
  /// Returns a NEW list; the input is not mutated. Stable for ties.
  static List<Station> rankForEmphasis(
    List<Station> stations,
    FuelType selectedFuel,
    SortMode sortMode,
  ) {
    final ranked = List<Station>.of(stations);
    final byPrice =
        sortMode == SortMode.price || sortMode == SortMode.priceDistance;
    int compare(Station a, Station b) {
      if (byPrice) {
        // Cheapest first; price-less stations sort last (sentinel handled
        // inside compareByPrice).
        return compareByPrice(a, b, selectedFuel);
      }
      // Closest first for distance / 24h / rating / name sorts — distance
      // is the universally available, savings-relevant tie-breaker.
      return a.dist.compareTo(b.dist);
    }

    mergeSort<Station>(ranked, compare: compare);
    return ranked;
  }
}

class _StationMapLayersState extends State<StationMapLayers> {
  /// #1774 — the marker list and the price range are memoised here and
  /// recomputed only when `stations` / `selectedFuel` /
  /// `selectedStationIds` actually change. `MapScreen` watches four
  /// providers, so without this every unrelated rebuild (or an
  /// app-resume widget refresh) re-ran `_getPriceRange` over every
  /// station and rebuilt every `Marker`.
  late List<Marker> _markers;
  late (double, double) _priceRange;

  /// True once FlutterMap has laid out and emitted `onMapReady`. The
  /// guarded `didUpdateWidget` fit waits on this so a `fitCamera` call
  /// never lands before the controller has a real viewport (#2399).
  bool _mapReady = false;

  /// The bounds the camera was last fitted to. Held so a redundant
  /// rebuild (EV-toggle, app resume, unrelated provider change) does not
  /// re-schedule an identical `fitCamera`. Set at SCHEDULE time so a
  /// fit→rebuild→fit loop cannot form (the next build computes the same
  /// bounds, finds them equal, skips) — relocated from `NearbyMapView`
  /// in #2399. First paint is positioned by `MapOptions.initialCameraFit`,
  /// so this only handles the stations-arrived / centre-moved transition.
  LatLngBounds? _lastFitBounds;

  /// Bounds of the search circle around the current centre — the camera
  /// target for both `initialCameraFit` and the post-ready re-fit.
  LatLngBounds get _fitBounds =>
      StationMapLayers.boundsForRadius(widget.center, widget.searchRadiusKm);

  /// Recompute the memoised price range + marker list from the current
  /// widget inputs.
  void _recomputeMarkers() {
    // #2510 — colour by the SELECTED-fuel price (the same strict
    // resolution the list uses), not a fallback chain. A station without
    // the selected fuel paints grey ("--") instead of being re-coloured
    // by E10's price. #2631 — when a cross-border resolver is set, each
    // station's price is taken for ITS country fuel, so the colour range
    // is computed over those resolved prices to keep colour ↔ price aligned.
    final resolver = widget.fuelResolver;
    _priceRange = resolver == null
        ? priceRange(widget.stations, widget.selectedFuel)
        : _resolvedRange(widget.stations, resolver);
    final ids = widget.selectedStationIds;
    final hasSelection = ids != null && ids.isNotEmpty;

    // #2510 — emphasis: the top-ranked stations per the active sort
    // (cheapest for a price sort, closest otherwise) keep the full price
    // bubble; the rest render as compact price-band dots so a bounded
    // result set stays fully visible without the bubbles overlapping into
    // an illegible pile. The set is small, so a Set lookup is cheap.
    final emphasized = StationMapLayers.rankForEmphasis(
      widget.stations,
      widget.selectedFuel,
      widget.sortMode,
    ).take(StationMapLayers.emphasisCount).map((s) => s.id).toSet();

    // #2434 — order so the cheapest (green) marker paints ON TOP of the
    // more-expensive ones it overlaps. The marker layer paints in
    // source-list order (later = on top), so we sort price-descending:
    // expensive at the bottom, cheapest last/on top, price-less markers
    // beneath everything. Same price the marker is coloured by.
    final ordered = StationMapLayers.orderedByPriceForPainting(
      widget.stations,
      widget.selectedFuel,
      fuelResolver: resolver,
    );
    _markers = ordered.map((station) {
      final isPastel = hasSelection && !ids.contains(station.id);
      return StationMarkerBuilder.build(
        context,
        station,
        widget.selectedFuel,
        _priceRange.$1,
        _priceRange.$2,
        pastel: isPastel,
        compact: !emphasized.contains(station.id),
        fuelResolver: resolver,
      );
    }).toList();
  }

  /// (min, max) over each station's per-country resolved-fuel price (#2631),
  /// used to colour cross-border markers consistently with the price each
  /// one actually shows. Mirrors [priceRange] but resolves the fuel per
  /// station via [resolver]. Returns `(0, 0)` when none resolve to a price.
  static (double, double) _resolvedRange(
    List<Station> stations,
    FuelType Function(Station) resolver,
  ) {
    double minP = double.infinity;
    double maxP = 0;
    for (final s in stations) {
      final p = priceForFuelType(s, resolver(s));
      if (p != null) {
        if (p < minP) minP = p;
        if (p > maxP) maxP = p;
      }
    }
    return minP == double.infinity ? (0, 0) : (minP, maxP);
  }

  @override
  void initState() {
    super.initState();
    _recomputeMarkers();
    // First paint is positioned by `MapOptions.initialCameraFit`, so the
    // initial fit is already accounted for; record it so the post-ready
    // re-fit doesn't redundantly re-snap to the same bounds.
    _lastFitBounds = _fitBounds;
  }

  @override
  void didUpdateWidget(StationMapLayers oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Riverpod hands back the same `stations` / `selectedStationIds`
    // references until the underlying value changes, so identity
    // comparison is enough to skip the recompute on an unrelated
    // `MapScreen` rebuild.
    final stationsChanged = !identical(oldWidget.stations, widget.stations);
    if (stationsChanged ||
        oldWidget.selectedFuel != widget.selectedFuel ||
        oldWidget.sortMode != widget.sortMode ||
        // #2631 — a changed cross-border resolver re-prices every marker.
        !identical(oldWidget.fuelResolver, widget.fuelResolver) ||
        !identical(oldWidget.selectedStationIds, widget.selectedStationIds)) {
      _recomputeMarkers();
    }

    // #2399 — the SINGLE re-fit. When stations are present and the
    // camera-anchoring centre changed VALUE (e.g. a new search landed
    // after a cold open, or a ZIP search jumped to another city),
    // schedule exactly ONE post-frame `fitCamera`. Guarded by:
    //   - non-empty stations (nothing to frame otherwise),
    //   - a value-distinct centre (`LatLng` has value `==`),
    //   - bounds not already fitted (`LatLngBounds` value `==`),
    //   - `mounted` + `_mapReady` inside the callback.
    // `_lastFitBounds` is set HERE (at schedule time, not in the
    // callback) so a fit→rebuild→fit loop cannot form. This replaces the
    // per-build post-frame fit that used to live in `NearbyMapView` and
    // land inside the cold-start reset window (deleted in #2398).
    final centerChanged = widget.center != oldWidget.center;
    if (widget.stations.isNotEmpty && centerChanged) {
      final bounds = _fitBounds;
      // `LatLngBounds` has value `==`, so this skips an identical re-fit.
      // `NearbyMapView.shouldFit` is the same pure predicate, kept there
      // for its unit test; inlined here to avoid an import cycle.
      if (_lastFitBounds != bounds) {
        _lastFitBounds = bounds;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_mapReady) return;
          widget.mapController.fitCamera(
            CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(32)),
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        FlutterMap(
          mapController: widget.mapController,
          options: MapOptions(
            initialCenter: widget.center,
            initialZoom: widget.zoom,
            // #2399 — frame the search circle during the FIRST layout
            // pass, not via a post-frame `fitCamera`. The old post-frame
            // fit raced the (now-deleted) cold-start reset window and
            // could land on a degenerate viewport. Positioning the
            // camera as part of layout means the very first tile fetch
            // already targets the right viewport — no reset needed.
            initialCameraFit: CameraFit.bounds(
              bounds:
                  StationMapLayers.boundsForRadius(
                      widget.center, widget.searchRadiusKm),
              padding: const EdgeInsets.all(32),
            ),
            // #2399 — keep the FlutterMap (and its loaded tiles) alive
            // when offstage in an IndexedStack so a tab flip back to the
            // map doesn't tear down + cold-rebuild the tile pipeline.
            keepAlive: true,
            onMapReady: () {
              if (mounted) _mapReady = true;
            },
            // #1457 — clamp the camera to the tile-layer's max zoom (19)
            // so a programmatic `move(camera.zoom + 1)` past 19 doesn't
            // leave the user staring at a grey viewport (tiles only
            // render up to maxNativeZoom). The default flutter_map
            // MapOptions.maxZoom is 25 — that lets the camera stride
            // past where there are tiles to draw, which looks broken to
            // the user. Min clamp guards against accidental zoom-out
            // beyond the world wrap.
            minZoom: _kMinZoom,
            maxZoom: _kMaxZoom,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            // #2398 — the SINGLE hardened tile path. No inline TileLayer,
            // no reset stream: the cold-start reset storm that evicted
            // tiles before they painted is gone. `SparkiloTileLayer`
            // owns its retry provider lifecycle and uses the upstream
            // default `abortObsoleteRequests: true`, unified with every
            // other map surface.
            const SparkiloTileLayer(key: ValueKey('main-tiles')),
            // Route polyline (if in route search mode)
            if (widget.routePolyline != null &&
                widget.routePolyline!.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: widget.routePolyline!,
                    color: theme.colorScheme.primary,
                    strokeWidth: 4.0,
                  ),
                ],
              ),
            // Search radius circle
            if (widget.showSearchRadius)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: widget.center,
                    radius: widget.searchRadiusKm * 1000,
                    useRadiusInMeter: true,
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderColor:
                        theme.colorScheme.primary.withValues(alpha: 0.3),
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
            // Center marker
            MarkerLayer(
              markers: [
                Marker(
                  point: widget.center,
                  width: 20,
                  height: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Station markers. #1774 — `_markers` is memoised; this
            // builder just places the pre-built list.
            //
            // #2510 — a BOUNDED nearby-search result set renders every
            // station as its OWN marker (a plain [MarkerLayer]), so a
            // 10-station / 10 km search shows all ten — never hidden behind
            // count bubbles. De-overlap is by emphasis, not aggregation:
            // the top-ranked stations (cheapest / closest per the active
            // sort) keep the full price label, the rest are compact dots
            // (see `_recomputeMarkers`). This reverses the #2490
            // over-correction that routed EVERY set through
            // [MarkerClusterLayerWidget] and so collapsed a small radius
            // search into "4"/"2"/"3" count clusters.
            //
            // Clustering is kept ONLY as a fallback for a genuinely huge /
            // zoomed-far set ([StationMapLayers.clusterThreshold]+), where
            // painting hundreds of overlapping dots would itself be
            // illegible; the bounded nearby case never reaches it.
            if (_markers.isNotEmpty)
              if (widget.stations.length >= StationMapLayers.clusterThreshold)
                MarkerClusterLayerWidget(
                  options: MarkerClusterLayerOptions(
                    maxClusterRadius: 50,
                    markers: _markers,
                    builder: (context, clusterMarkers) => Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${clusterMarkers.length}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                )
              else
                MarkerLayer(markers: _markers),
            // Extra layers (e.g. EV overlay)
            ...widget.extraLayers,
            // Attribution — localized OSM credit (#2402).
            const OsmAttribution(),
          ],
        ),
        // Zoom controls
        Positioned(
          right: 16,
          top: 16,
          child: Column(
            children: [
              ZoomButton(
                icon: Icons.add,
                onPressed: () {
                  // #1457 — clamp to [_kMinZoom, _kMaxZoom]. Without
                  // the clamp, a + tap at the cap silently no-ops AND
                  // pushes the camera to a zoom level with no tiles
                  // (the user sees a grey screen and assumes the button
                  // is broken). The clamp turns it into a graceful
                  // no-op AT the cap — the visible feedback is "I'm
                  // already at max zoom" instead of "the button is
                  // dead".
                  final z = (widget.mapController.camera.zoom + 1)
                      .clamp(_kMinZoom, _kMaxZoom);
                  widget.mapController
                      .move(widget.mapController.camera.center, z);
                },
              ),
              const SizedBox(height: 8),
              ZoomButton(
                icon: Icons.remove,
                onPressed: () {
                  final z = (widget.mapController.camera.zoom - 1)
                      .clamp(_kMinZoom, _kMaxZoom);
                  widget.mapController
                      .move(widget.mapController.camera.center, z);
                },
              ),
              if (widget.showRecenterButton) ...[
                const SizedBox(height: 8),
                ZoomButton(
                  icon: Icons.my_location,
                  onPressed: widget.onRecenter ??
                      () => widget.mapController
                          .move(widget.center, widget.zoom),
                ),
              ],
            ],
          ),
        ),
        // Price legend
        const Positioned(
          left: 16,
          bottom: 16,
          child: PriceLegend(),
        ),
      ],
    );
  }
}
