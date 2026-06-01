// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/utils/station_extensions.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../../search/domain/entities/station.dart';
import 'route_station_chip.dart';

/// Horizontal scrollable list of best-stop station chips for the route map.
class RouteBestStopsList extends StatelessWidget {
  final List<Station> stations;
  final Set<String> selectedStationIds;
  final dynamic selectedFuel;
  final void Function(String stationId) onToggleStation;

  /// #2631 — on a cross-border route, maps a station to ITS country's
  /// profile fuel so the chip shows the price that station's driver pays
  /// (Spanish stop → E10) instead of '--'. Null → strict [selectedFuel].
  final FuelType Function(Station)? fuelResolver;

  const RouteBestStopsList({
    super.key,
    required this.stations,
    required this.selectedStationIds,
    required this.selectedFuel,
    required this.onToggleStation,
    this.fuelResolver,
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
          final price = station.priceFor(
              fuelResolver != null ? fuelResolver!(station) : selectedFuel);
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
