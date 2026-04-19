import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/charging_station.dart';
import '../../providers/ev_providers.dart';
import '../screens/ev_station_detail_screen.dart';
import 'ev_marker_widget.dart';

/// Map layer rendering all charging stations for the given [viewport].
///
/// Pulls results from [evStationsProvider], applies the current filter,
/// and clusters markers independently of fuel-station markers so the two
/// layers never collide visually.
class EvMapLayer extends ConsumerWidget {
  final EvViewport viewport;

  const EvMapLayer({super.key, required this.viewport});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(evStationsProvider(viewport));
    return async.when(
      data: (stations) => _buildLayer(context, stations),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildLayer(BuildContext context, List<ChargingStation> stations) {
    if (stations.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    final markers = stations
        .map(
          (s) => EvMarkerWidget.buildMarker(
            s,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EvStationDetailScreen(station: s),
              ),
            ),
          ),
        )
        .toList();

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
      color: shown ? Colors.green : Colors.white,
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
