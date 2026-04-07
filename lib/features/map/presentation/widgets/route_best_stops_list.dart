import 'package:flutter/material.dart';

import '../../../../core/utils/station_extensions.dart';
import '../../../search/domain/entities/station.dart';
import 'route_station_chip.dart';

/// Horizontal scrollable list of best-stop station chips for the route map.
class RouteBestStopsList extends StatelessWidget {
  final List<Station> stations;
  final Set<String> selectedStationIds;
  final dynamic selectedFuel;
  final void Function(String stationId) onToggleStation;

  const RouteBestStopsList({
    super.key,
    required this.stations,
    required this.selectedStationIds,
    required this.selectedFuel,
    required this.onToggleStation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 52,
      color: theme.colorScheme.surfaceContainerHighest,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        itemCount: stations.length,
        itemBuilder: (context, index) {
          final station = stations[index];
          final isSelected = selectedStationIds.contains(station.id);
          final price = station.priceFor(selectedFuel);
          final stopNumber = index + 1;
          return RouteStationChip(
            key: ValueKey('route-station-${station.id}'),
            station: station,
            stopNumber: stopNumber,
            isSelected: isSelected,
            price: price,
            onTap: () => onToggleStation(station.id),
          );
        },
      ),
    );
  }
}
