// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';

import '../../../../core/utils/station_extensions.dart';
import '../../../../core/domain/fuel_type.dart';
import '../../../../core/domain/station.dart';
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

    // #4121 — the shell's docked search button is centred on the bottom
    // bar's top edge and protrudes ~28 dp above it, straight through the
    // middle of this row. The row scrolls horizontally, so no chip is
    // unreachable — but the obstruction is FIXED and the list is not, so
    // reading the row means scrolling every item around a hole in the
    // centre, and stop 2 of a ranked list is what usually sits in it.
    //
    // The chips are lifted clear of the protrusion rather than the row
    // being made taller only to be covered. The band's own surface still
    // meets the bar, so nothing shows through underneath.
    const fabProtrusion = 32.0;

    return Container(
      height: 52 + fabProtrusion,
      color: theme.colorScheme.surfaceContainerHighest,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 4 + fabProtrusion),
        itemCount: stations.length,
        itemBuilder: (context, index) {
          final station = stations[index];
          final isSelected = selectedStationIds.contains(station.id);
          final price = station.priceFor(
              fuelResolver != null
                  ? fuelResolver!(station)
                  : selectedFuel as FuelType);
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
