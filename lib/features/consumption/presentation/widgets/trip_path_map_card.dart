// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../core/widgets/osm_attribution.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../map/data/sparkilo_tile_layer.dart';
import '../../data/driving_insights_hard_accel_indices.dart';
import 'trip_detail_charts.dart';

// ---------------------------------------------------------------------------
// Phase 3 thresholds (#1374) — fixed defaults.
//
// The GPS-path heatmap colours each segment by its instantaneous
// L/100 km, computed from the OBD-II `fuelRateLPerHour` and `speedKmh`
// at the segment's start sample. Three buckets:
//
//   * efficient   < 6.0 L/100 km  → DarkModeColors.success (green)
//   * borderline  6.0 ≤ x < 10.0  → DarkModeColors.warning (orange)
//   * wasteful    ≥ 10.0          → DarkModeColors.error   (red)
//
// Two safety gates classify a segment as efficient regardless of
// computed L/100 km:
//
//   * `fuelRateLPerHour == null` — legacy / partial samples (no
//     PID 5E and no MAF fallback) shouldn't paint red just because
//     fuel rate wasn't measured.
//   * `speedKmh < 5.0` — too-slow segments produce divide-by-near-
//     zero L/100 km that's meaningless for coaching (creep, idle).
//
// These thresholds are intentionally fixed; a future PR could derive
// them per-vehicle from the consumption profile (tracked separately).
// ---------------------------------------------------------------------------
const double _kEfficientThresholdLPer100Km = 6.0;
const double _kBorderlineThresholdLPer100Km = 10.0;
const double _kMinClassifiableSpeedKmh = 5.0;

/// Heatmap bucket assigned to a single segment between two consecutive
/// GPS samples.
enum _SegmentBucket { efficient, borderline, wasteful }

/// Trip-detail map card rendering the GPS-recorded path of a trip
/// (#1374 phase 3).
///
/// Reads `(latitude, longitude)` pairs from the supplied
/// [TripDetailSample]s — Phase 1 plumbed those fields through the
/// recorder, persistence layer and `_toDetailSample` converter. Skips
/// entirely (returns [SizedBox.shrink]) when the trip carries no
/// usable GPS samples — legacy trips, opted-out trips and trips that
/// never got a fix all fall through to the no-card path so the
/// trip-detail screen layout stays unchanged for them.
///
/// ## Phase 3 scope
/// * Per-segment heatmap polylines coloured by computed L/100 km
///   (see thresholds above).
/// * Two markers — first and last GPS sample — for trip start and end.
/// * Legend below the map showing the three buckets + their labels.
/// * Frames the viewport to the polyline bounds on the first layout pass
///   via [MapOptions.initialCameraFit] (#2624).
class TripPathMapCard extends StatelessWidget {
  final List<TripDetailSample> samples;

  const TripPathMapCard({super.key, required this.samples});

  @override
  Widget build(BuildContext context) {
    // Build the parallel lists of (LatLng, source-sample) so the inner
    // map can colour segments by the source sample's telemetry. Half-
    // set fixes are dropped — the recorder writes the lat/lng pair
    // atomically (see `TripSample` doc) but the type still allows it,
    // so be defensive at the read site.
    final points = <LatLng>[];
    final pointSamples = <TripDetailSample>[];
    for (final s in samples) {
      final lat = s.latitude;
      final lng = s.longitude;
      if (lat != null && lng != null) {
        points.add(LatLng(lat, lng));
        pointSamples.add(s);
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
    final title = l.tripPathCardTitle;
    final subtitle = l.tripPathCardSubtitle;

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
              child: _TripPathMap(points: points, pointSamples: pointSamples),
            ),
            const _TripPathLegend(),
          ],
        ),
      ),
    );
  }
}

/// Stateful inner map so the [MapController] can survive rebuilds and
/// remain available for interaction (pinch / drag). Mirrors the pattern
/// used by [StationMapLayers] — the outer card stays a [StatelessWidget]
/// so callers don't have to worry about lifecycle.
class _TripPathMap extends StatefulWidget {
  final List<LatLng> points;
  final List<TripDetailSample> pointSamples;

  const _TripPathMap({required this.points, required this.pointSamples});

  @override
  State<_TripPathMap> createState() => _TripPathMapState();
}

class _TripPathMapState extends State<_TripPathMap> {
  late final MapController _mapController = MapController();

  /// Pre-computed bounds for the polyline, fed to
  /// [MapOptions.initialCameraFit]. Single-point polylines fall back to a
  /// degenerate bounds box centered on the point (see [_computeBounds]) so
  /// `CameraFit.bounds` centres on the point at a sane zoom rather than
  /// dividing by zero.
  late final LatLngBounds _bounds = _computeBounds(widget.points);

  /// Pre-fit fallback centre used by [MapOptions.initialCenter] for the
  /// degenerate case where layout hasn't run yet; `initialCameraFit`
  /// frames the real viewport on the first layout pass.
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
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  /// Classify a segment between [start] and the next sample by the
  /// instantaneous L/100 km at [start]. The gates documented at the
  /// top of the file (null fuel rate, low speed) collapse to
  /// [_SegmentBucket.efficient] so legacy / idle samples don't paint
  /// red.
  static _SegmentBucket _classify(TripDetailSample start) {
    final fuelRate = start.fuelRateLPerHour;
    final speed = start.speedKmh;
    if (fuelRate == null || speed < _kMinClassifiableSpeedKmh) {
      return _SegmentBucket.efficient;
    }
    final lPer100km = fuelRate / speed * 100.0;
    if (lPer100km < _kEfficientThresholdLPer100Km) {
      return _SegmentBucket.efficient;
    }
    if (lPer100km < _kBorderlineThresholdLPer100Km) {
      return _SegmentBucket.borderline;
    }
    return _SegmentBucket.wasteful;
  }

  static Color _bucketColor(BuildContext context, _SegmentBucket bucket) {
    switch (bucket) {
      case _SegmentBucket.efficient:
        return DarkModeColors.success(context);
      case _SegmentBucket.borderline:
        return DarkModeColors.warning(context);
      case _SegmentBucket.wasteful:
        return DarkModeColors.error(context);
    }
  }

  /// Walk consecutive segments and group runs of the same bucket into
  /// a single polyline. Each polyline's points are the run's start
  /// sample's coord followed by the end coord of every segment in the
  /// run, so adjacent runs share the boundary point and the line
  /// stays visually continuous.
  List<Polyline> _buildHeatmapPolylines(BuildContext context) {
    final pts = widget.points;
    if (pts.length < 2) {
      // Single-sample edge case — no segments to colour, but the start
      // marker still anchors the viewport. Returning an empty list
      // keeps the PolylineLayer harmless.
      return const <Polyline>[];
    }

    final polylines = <Polyline>[];
    var runStartIdx = 0;
    var runBucket = _classify(widget.pointSamples[0]);

    for (var i = 1; i < pts.length; i++) {
      // The bucket for the segment ending at `i` is determined by the
      // sample at `i - 1` (the segment's start). When that bucket
      // changes, close the run [runStartIdx .. i - 1] and start a new
      // run at `i - 1` so the runs share the boundary point.
      final segBucket = _classify(widget.pointSamples[i - 1]);
      if (segBucket != runBucket) {
        polylines.add(
          Polyline(
            points: pts.sublist(runStartIdx, i),
            color: _bucketColor(context, runBucket),
            strokeWidth: 4.0,
          ),
        );
        runStartIdx = i - 1;
        runBucket = segBucket;
      }
    }
    // Flush the final run all the way through the last point.
    polylines.add(
      Polyline(
        points: pts.sublist(runStartIdx),
        color: _bucketColor(context, runBucket),
        strokeWidth: 4.0,
      ),
    );
    return polylines;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = widget.points.first;
    final end = widget.points.last;
    final polylines = _buildHeatmapPolylines(context);

    // Hard-acceleration markers (#1458 phase 1). The recorder writes
    // monotonic timestamps so `widget.pointSamples` is already sorted
    // by timestamp, which means [hardAccelSampleIndices]'s indices line
    // up 1:1 with `widget.points`. The helper sorts defensively so a
    // future caller that passes unsorted samples won't silently mismap
    // markers — but if that ever changes we'd need to sort here too.
    final hardAccelIndices = hardAccelSampleIndices(widget.pointSamples);
    final hardAccelMarkers = <Marker>[
      for (final idx in hardAccelIndices)
        if (idx >= 0 && idx < widget.points.length)
          Marker(
            point: widget.points[idx],
            width: 20,
            height: 20,
            child: Icon(Icons.bolt, size: 16, color: theme.colorScheme.error),
          ),
    ];

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _initialCenter,
        initialZoom: 13,
        // #2624 — frame the polyline bounds during the FIRST layout pass
        // via `initialCameraFit`, not a post-frame `fitCamera`. The old
        // post-frame fit (now removed) jumped the camera after the first
        // tile fetch had already targeted the fallback viewport, leaving
        // grey tiles. Mirrors the main map page's #2398/#2399 fix
        // (`station_map_layers.dart`): positioning the camera as part of
        // layout means the first tile fetch already targets the right
        // viewport. `initialCenter`/`initialZoom` above stay as the
        // pre-fit fallback for the degenerate no-layout-yet frame.
        initialCameraFit: CameraFit.bounds(
          bounds: _bounds,
          padding: const EdgeInsets.all(32),
        ),
        // Steady-state pinch / drag stays enabled — the user may want
        // to inspect the path. Rotation is disabled for the same
        // reason `StationMapLayers` does it: trip overlays read more
        // naturally with a north-up orientation.
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        // #2096 — was a raw TileLayer with the default
        // `NetworkTileProvider`, which silently produced grey on
        // every OSM transient + every rebuild abort. Routed
        // through the hardened wrapper for retry + cancellation
        // resilience.
        const SparkiloTileLayer(),
        PolylineLayer(polylines: polylines),
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
            ...hardAccelMarkers,
          ],
        ),
        const OsmAttribution(),
      ],
    );
  }
}

/// Three-swatch legend rendered below the heatmap map. The swatches
/// reuse the same [DarkModeColors] entries the polylines do, so the
/// legend and overlay stay in sync if a future tweak shifts the
/// colour palette.
class _TripPathLegend extends StatelessWidget {
  const _TripPathLegend();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final efficient = l.tripPathLegendEfficient;
    final borderline = l.tripPathLegendBorderline;
    final wasteful = l.tripPathLegendWasteful;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _LegendSwatch(
            color: DarkModeColors.success(context),
            label: efficient,
          ),
          _LegendSwatch(
            color: DarkModeColors.warning(context),
            label: borderline,
          ),
          _LegendSwatch(color: DarkModeColors.error(context), label: wasteful),
        ],
      ),
    );
  }
}

class _LegendSwatch extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendSwatch({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: theme.textTheme.bodySmall),
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
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 3),
        ],
      ),
      child: Icon(icon, size: 16, color: Colors.white),
    );
  }
}
