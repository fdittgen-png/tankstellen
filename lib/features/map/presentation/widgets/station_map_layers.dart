import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_constants.dart';
import '../../data/retry_network_tile_provider.dart';
import '../../../../core/utils/station_extensions.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../../search/domain/entities/station.dart';
import 'price_legend.dart';
import 'station_marker.dart';

/// Shared map widget containing all layers: tiles, search radius circle,
/// center marker, station markers with clustering, attribution, zoom
/// controls, and price legend.
///
/// Used by both [MapScreen] (full-screen) and [InlineMap] (split-screen)
/// to eliminate ~130 lines of duplicated map layer code.
///
/// ## Why this is stateful (#1234 follow-up to #1164)
///
/// The earlier grey-tile fix (LayoutBuilder gate + tab-flip incarnation
/// rebuild) covers the offstage IndexedStack viewport-capture race, but
/// the screen still rendered grey on cold-start in some scenarios. The
/// reason: [RetryNetworkTileProvider] was created inside `build()` and
/// rebuilt on every parent state change. flutter_map's TileLayer
/// preserves its [TileImage] objects across `didUpdateWidget`, but each
/// existing TileImage holds a reference to the OLD provider's
/// [http.Client]; meanwhile the *new* provider's client is what fresh
/// tile fetches use. The leaked-client churn produced two pathologies:
///   1. The very first tile fetches went through an http.Client that
///      was about to be discarded, occasionally racing with the next
///      build's replacement provider before completing.
///   2. The default `BuiltInMapCachingProvider` instance — created
///      lazily inside the image provider — was being asked to cache
///      tiles whose request was abandoned, leaving holes that only got
///      backfilled when a later rebuild happened to re-issue the same
///      coordinates against a stable provider.
/// Holding a single tile provider per [StationMapLayers] lifetime —
/// created in `initState`, disposed in `dispose` — eliminates both
/// pathologies. The KeyedSubtree+incarnation rebuild in [MapScreen]
/// already destroys this state on tab-flip, so the provider lifetime
/// is bounded by the visible-tab lifetime.
///
/// ## Cold-start tile reset window (#1316 phase 3)
///
/// The single `addPostFrameCallback` reset added in #1234 fires
/// before two later events that also invalidate TileLayer's captured
/// viewport:
///   1. `NearbyMapView` schedules its own post-frame `fitCamera` call
///      every build — that move arrives AFTER the initState reset, so
///      TileLayer reloads against the bootstrap camera and never
///      sees the settled camera the user actually wants tiles for.
///   2. `FlutterMap` only emits `MapEventNonRotatedSizeChange` once
///      its internal LayoutBuilder lays out — also AFTER the
///      initState reset. If the bootstrap layout was small (the
///      <100px LayoutBuilder gate in [MapScreen] only catches the
///      worst placeholder layouts), TileLayer captured a tiny tile
///      range that survives the size update.
/// Both produced the "3 tile patches over a grey background"
/// symptom the user reported. The fix subscribes to
/// [MapController.mapEventStream] for [_coldStartResetWindow] (3 s)
/// and re-emits on the reset stream every time a programmatic move,
/// `fitCamera`, or `nonRotatedSizeChange` event arrives. After the
/// window the subscription cancels itself so steady-state pans use
/// TileLayer's normal load-on-event path (resetting on every pan
/// would briefly blank the visible tiles).
class StationMapLayers extends StatefulWidget {
  final MapController mapController;
  final List<Station> stations;
  final LatLng center;
  final double zoom;
  final double searchRadiusKm;
  final FuelType selectedFuel;
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

  const StationMapLayers({
    super.key,
    required this.mapController,
    required this.stations,
    required this.center,
    required this.zoom,
    required this.searchRadiusKm,
    required this.selectedFuel,
    this.showRecenterButton = false,
    this.onRecenter,
    this.routePolyline,
    this.showSearchRadius = true,
    this.selectedStationIds,
    this.extraLayers = const [],
  });

  @override
  State<StationMapLayers> createState() => _StationMapLayersState();

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

  /// Get min/max price range for color gradient.
  static (double, double) _getPriceRange(List<Station> stations, FuelType fuel) {
    double minP = double.infinity;
    double maxP = 0;
    for (final s in stations) {
      final p = s.priceFor(fuel);
      if (p != null) {
        if (p < minP) minP = p;
        if (p > maxP) maxP = p;
      }
    }
    if (minP == double.infinity) return (0, 0);
    return (minP, maxP);
  }
}

class _StationMapLayersState extends State<StationMapLayers> {
  /// Held in state so a single [http.Client] lives for the entire
  /// visible lifetime of the map. Recreating the provider on every
  /// build (the prior bug) churned http.Client instances and produced
  /// the cold-start grey-tile regression (#1234).
  late final RetryNetworkTileProvider _tileProvider;

  /// Stream that, when emitted, makes [TileLayer] drop all current
  /// tile images and re-fetch the visible range from scratch. We fire
  /// it once after the first frame to cover the case where TileLayer's
  /// initial `didChangeDependencies` ran against a degenerate camera
  /// and never re-issued requests when the camera settled.
  final StreamController<void> _resetController =
      StreamController<void>.broadcast();

  /// Subscription on [MapController.mapEventStream] used during the
  /// cold-start window to force a tile-reset every time the map size
  /// or camera moves programmatically. Cancelled after
  /// [_coldStartResetWindow] so steady-state interactions are not
  /// disturbed (#1316 phase 3 — see class doc).
  StreamSubscription<MapEvent>? _coldStartEventSub;

  /// Timer that closes the cold-start reset window. Cancelled in
  /// [dispose] so a late firing cannot touch a disposed state.
  Timer? _coldStartCloseTimer;

  /// How long to keep firing tile-resets on programmatic
  /// size/camera changes after init. Three seconds covers the worst
  /// observed cold-start sequence (offstage IndexedStack pre-mount
  /// → onstage promotion → LayoutBuilder gate clears → FlutterMap
  /// internal LayoutBuilder lays out → `fitCamera` post-frame
  /// callback fires → camera settles). Shorter windows missed the
  /// late `fitCamera` on slow devices; longer windows risk
  /// interfering with the user's first deliberate zoom.
  static const Duration _coldStartResetWindow = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _tileProvider = RetryNetworkTileProvider(abortObsoleteRequests: false);

    // First-paint reset: kick TileLayer once so any tiles that fetched
    // against the bootstrap camera are dropped + reissued against the
    // settled MapController state. Cheap (no-op when tiles are already
    // loaded for the visible range) and fixes the grey-on-first-open
    // case where neither the LayoutBuilder gate nor the
    // _mapIncarnation listener catches the offstage→onstage transition
    // (#1234).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _resetController.isClosed) return;
      _resetController.add(null);
    });

    // #1316 phase 3 — the single first-paint reset above fires before
    // [NearbyMapView]'s post-frame `fitCamera` runs and before
    // FlutterMap's own LayoutBuilder finishes propagating the real
    // viewport size. Result: reset hits TileLayer with the bootstrap
    // camera, TileLayer fetches a tiny tile set, then `fitCamera`
    // moves the camera + the size-change event arrives — but
    // TileLayer's reaction at that point only loads tiles INSIDE the
    // already-captured (small) viewport, leaving most of the visible
    // map grey (the "3 patches" symptom in the issue's screenshots).
    //
    // Fix: subscribe to the map event stream and re-fire the reset on
    // every programmatic event that changes either the viewport size
    // or the camera position during the [_coldStartResetWindow].
    // After the window, unsubscribe — steady-state pans/zooms do not
    // need a tile-pipeline reset (TileLayer's normal load-on-event
    // path handles them just fine, and gratuitous resets would cause
    // visible tile pop-in on every pan).
    _coldStartEventSub =
        widget.mapController.mapEventStream.listen(_onColdStartEvent);
    _coldStartCloseTimer = Timer(_coldStartResetWindow, () {
      _coldStartEventSub?.cancel();
      _coldStartEventSub = null;
    });
  }

  /// Fire a tile-reset on programmatic size/camera changes during the
  /// cold-start window. Filters to events that actually invalidate the
  /// captured viewport — pure user interaction (drag, scroll-wheel,
  /// pinch) is ignored because if the user is interacting, the bug
  /// did not reproduce on this open and we should not interrupt them.
  void _onColdStartEvent(MapEvent event) {
    if (!mounted || _resetController.isClosed) return;
    final src = event.source;
    final relevant = src == MapEventSource.nonRotatedSizeChange ||
        src == MapEventSource.fitCamera ||
        src == MapEventSource.mapController;
    if (!relevant) return;
    _resetController.add(null);
  }

  @override
  void dispose() {
    _coldStartCloseTimer?.cancel();
    _coldStartEventSub?.cancel();
    _resetController.close();
    _tileProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priceRange = StationMapLayers._getPriceRange(
        widget.stations, widget.selectedFuel);

    return Stack(
      children: [
        FlutterMap(
          mapController: widget.mapController,
          options: MapOptions(
            initialCenter: widget.center,
            initialZoom: widget.zoom,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: AppConstants.osmTileUrl,
              userAgentPackageName: AppConstants.osmUserAgent,
              maxNativeZoom: 19,
              maxZoom: 19,
              // #757 — RetryNetworkTileProvider retries transient
              // HTTP 429 / 5xx / connection errors with jittered
              // backoff (200 ms, 800 ms). Combined with
              // `evictErrorTileStrategy: notVisibleRespectMargin`
              // below, a failed tile gets retried up to 3× and, if
              // all attempts fail, is evicted as soon as it scrolls
              // out of view so the next pan retries cleanly.
              //
              // #930 — flutter_map's default aborts in-flight tile
              // fetches on pan. Our retry layer must not see those
              // cancellations as errors. Hence explicit
              // `abortObsoleteRequests: false` (in initState) plus
              // cancellation-aware retry logic in the provider.
              //
              // #1234 — provider is held in state (initState/dispose),
              // NOT rebuilt every frame. Recreating it churned
              // http.Client instances and produced a cold-start
              // grey-tile race the LayoutBuilder gate could not
              // catch. The reset stream fires once after first paint
              // to drop any tiles that captured a degenerate viewport.
              tileProvider: _tileProvider,
              reset: _resetController.stream,
              evictErrorTileStrategy:
                  EvictErrorTileStrategy.notVisibleRespectMargin,
              errorTileCallback: (tile, error, stackTrace) {
                debugPrint(
                    'TileLayer error at (z:${tile.coordinates.z} '
                    'x:${tile.coordinates.x} y:${tile.coordinates.y}): '
                    '$error');
              },
            ),
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
            // Station markers with clustering
            Builder(builder: (ctx) {
              final hasSelection = widget.selectedStationIds != null &&
                  widget.selectedStationIds!.isNotEmpty;
              final markers = widget.stations.map((station) {
                final isPastel = hasSelection &&
                    !widget.selectedStationIds!.contains(station.id);
                return StationMarkerBuilder.build(
                  ctx,
                  station,
                  widget.selectedFuel,
                  priceRange.$1,
                  priceRange.$2,
                  pastel: isPastel,
                );
              }).toList();
              if (widget.stations.length > 20) {
                return MarkerClusterLayerWidget(
                  options: MarkerClusterLayerOptions(
                    maxClusterRadius: 80,
                    markers: markers,
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
                );
              }
              return MarkerLayer(markers: markers);
            }),
            // Extra layers (e.g. EV overlay)
            ...widget.extraLayers,
            // Attribution
            const RichAttributionWidget(
              attributions: [
                TextSourceAttribution('OpenStreetMap contributors'),
              ],
            ),
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
                  final z = widget.mapController.camera.zoom + 1;
                  widget.mapController
                      .move(widget.mapController.camera.center, z);
                },
              ),
              const SizedBox(height: 8),
              ZoomButton(
                icon: Icons.remove,
                onPressed: () {
                  final z = widget.mapController.camera.zoom - 1;
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
