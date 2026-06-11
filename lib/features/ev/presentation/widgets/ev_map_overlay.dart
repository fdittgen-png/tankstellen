// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/domain/ev/charging_station.dart';
import '../../providers/ev_providers.dart';
import 'ev_marker_widget.dart';

/// Map layer rendering all charging stations for the given [viewport].
///
/// Pulls results from [evStationsProvider], applies the current filter,
/// and clusters markers independently of fuel-station markers so the two
/// layers never collide visually.
class EvMapLayer extends ConsumerStatefulWidget {
  final EvViewport viewport;

  const EvMapLayer({super.key, required this.viewport});

  @override
  ConsumerState<EvMapLayer> createState() => _EvMapLayerState();
}

class _EvMapLayerState extends ConsumerState<EvMapLayer> {
  // #2175 — the marker list is memoised here and recomputed only when
  // the station list identity changes, mirroring the fuel layer's #1774
  // fix. EvMapLayer is rebuilt fresh in NearbyMapView.build on every EV
  // toggle / search / app-resume, so without this it re-allocated every
  // Marker + a fresh onTap closure on each host rebuild.
  List<ChargingStation>? _lastStations;
  List<Marker> _markers = const [];

  void _recomputeMarkers(List<ChargingStation> stations) {
    _markers = stations
        .map(
          (s) => EvMarkerWidget.buildMarker(
            s,
            // #3174 — route to the SAME rich detail screen every other EV
            // entry point uses (search list, favorites, route results),
            // instead of pushing the now-deleted legacy in-feature copy.
            onTap: () => EvStationDetailRoute(s).push<void>(context),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(evStationsProvider(widget.viewport));
    return async.when(
      data: _buildLayer,
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildLayer(List<ChargingStation> stations) {
    if (stations.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    if (!identical(stations, _lastStations)) {
      _lastStations = stations;
      _recomputeMarkers(stations);
    }
    final markers = _markers;

    if (stations.length > 20) {
      return MarkerClusterLayerWidget(
        options: MarkerClusterLayerOptions(
          maxClusterRadius: 80,
          markers: markers,
          builder: (ctx, clusterMarkers) => Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer,
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
  }
}

/// Small toggle button placed on top of the map screen that switches the
/// EV overlay on and off.
class EvToggleButton extends ConsumerWidget {
  const EvToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shown = ref.watch(evShowOnMapProvider);
    final l10n = AppLocalizations.of(context);
    return Material(
      color: shown ? DarkModeColors.success(context) : Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => ref.read(evShowOnMapProvider.notifier).toggle(),
        child: Tooltip(
          message: l10n?.evShowOnMap ?? 'Show EV stations',
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.ev_station,
              color: shown ? Colors.white : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}
