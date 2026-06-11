// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/sharing/public_file_exporter.dart';
import '../../../../core/widgets/osm_attribution.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../map/data/sparkilo_tile_layer.dart';
import '../../data/exporters/gpx_exporter.dart';
import '../../data/trip_history_repository.dart';
import '../../providers/trip_history_provider.dart';
import '../../../../core/logging/error_logger.dart';

/// Test seam: replace the OS share sheet hand-off with a callback that
/// captures the outgoing payload (#2030). Lets widget tests assert on
/// the GPX bytes without launching `share_plus`.
@visibleForTesting
Future<void> Function({required Uint8List bytes, required String fileName})?
debugTrajetsMapGpxShareOverride;

/// Aggregates the GPS polylines of multiple trajets on a single
/// flutter_map view (#2030).
///
/// Each trip is drawn in a distinct colour cycled from the Material
/// primary palette so the user can visually tell them apart. The view
/// auto-fits its viewport to the bounding box of every plotted point
/// the first time it lays out.
///
/// AppBar action: **Share aggregate GPX** — calls
/// [buildAggregateGpxXml] (#2032) and hands the multi-track file to
/// the OS share sheet via `share_plus`, so the user can open the route
/// set in Google Earth / Strava / etc. Disabled when no plotted points
/// landed (all trips selected are legacy / pre-#1374 samples).
class TrajetsMapScreen extends ConsumerWidget {
  final List<String> tripIds;

  const TrajetsMapScreen({super.key, required this.tripIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final allTrips = ref.watch(tripHistoryListProvider);
    final selected = <TripHistoryEntry>[
      for (final id in tripIds) ...allTrips.where((t) => t.id == id),
    ];

    final tracks = <_TripTrack>[];
    final allPoints = <LatLng>[];
    for (var i = 0; i < selected.length; i++) {
      final trip = selected[i];
      final points = <LatLng>[];
      for (final s in trip.samples) {
        final lat = s.latitude;
        final lon = s.longitude;
        if (lat != null && lon != null) {
          final p = LatLng(lat, lon);
          points.add(p);
          allPoints.add(p);
        }
      }
      if (points.length >= 2) {
        tracks.add(
          _TripTrack(entry: trip, points: points, colour: _colourForIndex(i)),
        );
      }
    }

    final canExport = tracks.isNotEmpty;

    return PageScaffold(
      title: l.trajetsMapTitle,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: l.tooltipBack,
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          key: const Key('trajets_map_share_gpx'),
          icon: const Icon(Icons.ios_share),
          tooltip: l.trajetsMapShareGpx,
          onPressed: canExport
              ? () => unawaited(_shareGpx(context, l, selected))
              : null,
        ),
      ],
      bodyPadding: EdgeInsets.zero,
      body: tracks.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l.trajetsMapEmpty, textAlign: TextAlign.center),
              ),
            )
          : _Map(tracks: tracks, allPoints: allPoints),
    );
  }

  Future<void> _shareGpx(
    BuildContext context,
    AppLocalizations l,
    List<TripHistoryEntry> trips,
  ) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final scheme = Theme.of(context).colorScheme;
    final gpx = buildAggregateGpxXml(trips, l: l);
    final bytes = Uint8List.fromList(utf8.encode(gpx));
    final fileName = trips.length == 1
        ? gpxFileNameFor(trips.first)
        : 'tankstellen-trajets-aggregate.gpx';
    final override = debugTrajetsMapGpxShareOverride;
    try {
      if (override != null) {
        await override(bytes: bytes, fileName: fileName);
        return;
      }
      // 2026-05-24 follow-up — file exports go straight to the device's
      // public Downloads folder via PublicFileExporter. No share sheet
      // / chooser; a single confirmation snackbar points the user at
      // the Downloads folder.
      await PublicFileExporter.saveBytesToDownloads(
        bytes: bytes,
        fileName: fileName,
        mimeType: 'application/gpx+xml',
      );
      if (messenger == null) return;
      final ok = l.savedToDownloadsFolder;
      // #2173 — themed success toast (matches the sibling error path).
      messenger.showSnackBar(SnackBarHelper.successSnackBar(scheme, ok));
    } catch (e, st) {
      unawaited(
        errorLogger.log(
          ErrorLayer.ui,
          e,
          st,
          context: const {'where': 'TrajetsMapScreen save GPX'},
        ),
      );
      if (messenger == null) return;
      final errorMsg = l.trajetsMapShareError;
      messenger.showSnackBar(SnackBarHelper.errorSnackBar(scheme, errorMsg));
    }
  }

  static Color _colourForIndex(int i) {
    const palette = <Color>[
      Color(0xFF1976D2),
      Color(0xFFD32F2F),
      Color(0xFF388E3C),
      Color(0xFFF57C00),
      Color(0xFF7B1FA2),
      Color(0xFF00796B),
      Color(0xFFC2185B),
      Color(0xFF5D4037),
    ];
    return palette[i % palette.length];
  }
}

class _TripTrack {
  final TripHistoryEntry entry;
  final List<LatLng> points;
  final Color colour;

  const _TripTrack({
    required this.entry,
    required this.points,
    required this.colour,
  });
}

class _Map extends StatefulWidget {
  final List<_TripTrack> tracks;
  final List<LatLng> allPoints;

  const _Map({required this.tracks, required this.allPoints});

  @override
  State<_Map> createState() => _MapState();
}

class _MapState extends State<_Map> {
  late final MapController _controller = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
  }

  void _fitBounds() {
    final pts = widget.allPoints;
    if (pts.isEmpty) return;
    double minLat = pts.first.latitude;
    double maxLat = pts.first.latitude;
    double minLng = pts.first.longitude;
    double maxLng = pts.first.longitude;
    for (final p in pts) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    final bounds = LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
    _controller.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(32)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _controller,
      options: MapOptions(
        initialCenter: widget.allPoints.first,
        initialZoom: 13,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        // #2096 — was a raw TileLayer with the default
        // `NetworkTileProvider`. Routed through the hardened
        // wrapper.
        const SparkiloTileLayer(),
        PolylineLayer(
          polylines: [
            for (final t in widget.tracks)
              Polyline(points: t.points, color: t.colour, strokeWidth: 4),
          ],
        ),
        const OsmAttribution(),
      ],
    );
  }
}
