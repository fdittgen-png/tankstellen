import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../l10n/app_localizations.dart';
import 'trip_detail_charts.dart';

/// Trip-detail map card rendering the GPS-recorded path of a trip
/// (#1374 phase 2).
///
/// Reads `(latitude, longitude)` pairs from the supplied
/// [TripDetailSample]s — Phase 1 plumbed those fields through the
/// recorder, persistence layer and `_toDetailSample` converter. Skips
/// entirely (returns [SizedBox.shrink]) when the trip carries no
/// usable GPS samples — legacy trips, opted-out trips and trips that
/// never got a fix all fall through to the no-card path so the
/// trip-detail screen layout stays unchanged for them.
///
/// ## Phase 2 scope
/// * Single-color polyline (theme `colorScheme.primary`).
/// * Two markers — first and last GPS sample — for trip start and end.
/// * Auto-fits the viewport to the polyline bounds.
///
/// Phase 3 (out of scope here) will replace the single colour with a
/// per-segment heatmap derived from the speed / RPM / engine-load
/// telemetry, and add the corresponding colour-bucket legend.
class TripPathMapCard extends StatelessWidget {
  final List<TripDetailSample> samples;

  const TripPathMapCard({super.key, required this.samples});

  @override
  Widget build(BuildContext context) {
    // Build the polyline from samples that carry BOTH lat and lng.
    // Half-set fixes are dropped — the recorder writes the pair
    // atomically (see `TripSample` doc) but the type still allows it,
    // so be defensive at the read site.
    final points = <LatLng>[];
    for (final s in samples) {
      final lat = s.latitude;
      final lng = s.longitude;
      if (lat != null && lng != null) {
        points.add(LatLng(lat, lng));
      }
    }
    if (points.isEmpty) {
      // No GPS coords at all — skip the card entirely per the issue's
      // Phase 2 spec ("legacy trips, opted-out trips"). Rendering an
      // empty placeholder would just clutter the trip-detail layout
      // for trips that pre-date the feature.
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final title = l?.tripPathCardTitle ?? 'Trip path';
    final subtitle = l?.tripPathCardSubtitle ?? 'GPS-recorded route';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 220,
              child: _TripPathMap(points: points),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stateful inner map so the [MapController] can survive rebuilds and
/// the post-frame `fitCamera` callback can target a stable controller
/// instance. Mirrors the pattern used by [StationMapLayers] — the
/// outer card stays a [StatelessWidget] so callers don't have to
/// worry about lifecycle.
class _TripPathMap extends StatefulWidget {
  final List<LatLng> points;

  const _TripPathMap({required this.points});

  @override
  State<_TripPathMap> createState() => _TripPathMapState();
}

class _TripPathMapState extends State<_TripPathMap> {
  late final MapController _mapController = MapController();

  /// Pre-computed bounds for the polyline. Single-point polylines fall
  /// back to a degenerate bounds object centered on the point — the
  /// `fitCamera` call handles those by centering on the point at a
  /// sane default zoom rather than throwing.
  late final LatLngBounds _bounds = _computeBounds(widget.points);

  /// Fallback initial camera so the very first frame paints something
  /// reasonable before the post-frame `fitCamera` callback fires.
  late final LatLng _initialCenter = _bounds.center;

  static LatLngBounds _computeBounds(List<LatLng> points) {
    if (points.length == 1) {
      // Single-point polyline — synthesize a tiny bounds box around
      // the point so flutter_map's CameraFit doesn't divide-by-zero.
      final p = points.first;
      const eps = 0.0005; // ~50 m at the equator; fine for any latitude
      return LatLngBounds(
        LatLng(p.latitude - eps, p.longitude - eps),
        LatLng(p.latitude + eps, p.longitude + eps),
      );
    }
    return LatLngBounds.fromPoints(points);
  }

  @override
  void initState() {
    super.initState();
    // Fit the camera to the polyline bounds once the map has laid out.
    // Mirrors the pattern in `nearby_map_view.dart`: schedule via
    // `addPostFrameCallback` so the MapController has a real viewport
    // size by the time `fitCamera` runs.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: _bounds,
            padding: const EdgeInsets.all(24),
          ),
        );
      } catch (e, st) {
        debugPrint('TripPathMapCard fitCamera failed: $e\n$st');
      }
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = widget.points.first;
    final end = widget.points.last;
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _initialCenter,
        initialZoom: 13,
        // Steady-state pinch / drag stays enabled — the user may want
        // to inspect the path. Rotation is disabled for the same
        // reason `StationMapLayers` does it: trip overlays read more
        // naturally with a north-up orientation.
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: AppConstants.osmTileUrl,
          userAgentPackageName: AppConstants.osmUserAgent,
          maxNativeZoom: 19,
          maxZoom: 19,
          evictErrorTileStrategy:
              EvictErrorTileStrategy.notVisibleRespectMargin,
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: widget.points,
              // Phase 2 — single colour. Phase 3 swaps this for a
              // per-segment heatmap derived from the speed / RPM /
              // engine-load telemetry; do NOT inline a fixed colour
              // here.
              color: theme.colorScheme.primary,
              strokeWidth: 4.0,
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: start,
              width: 28,
              height: 28,
              child: _PathPin(
                color: theme.colorScheme.primary,
                icon: Icons.play_arrow,
              ),
            ),
            Marker(
              point: end,
              width: 28,
              height: 28,
              child: _PathPin(
                color: theme.colorScheme.tertiary,
                icon: Icons.flag,
              ),
            ),
          ],
        ),
        const RichAttributionWidget(
          attributions: [
            TextSourceAttribution('OpenStreetMap contributors'),
          ],
        ),
      ],
    );
  }
}

/// Small circular pin used for the trip start / end markers. Mirrors
/// the centre-marker style in `StationMapLayers` so the visual
/// vocabulary stays consistent across the app's maps.
class _PathPin extends StatelessWidget {
  final Color color;
  final IconData icon;

  const _PathPin({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 3,
          ),
        ],
      ),
      child: Icon(icon, size: 16, color: Colors.white),
    );
  }
}
