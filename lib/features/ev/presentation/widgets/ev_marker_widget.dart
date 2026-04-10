import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/entities/charging_station.dart';

/// Visual marker representing an EV [ChargingStation] on the flutter_map.
///
/// Uses an `ev_station` icon with a background color derived from
/// availability:
///  - green:  at least one connector is `available`
///  - red:    all connectors are occupied or out of order
///  - grey:   status unknown
class EvMarkerWidget extends StatelessWidget {
  final ChargingStation station;
  final VoidCallback? onTap;

  const EvMarkerWidget({
    super.key,
    required this.station,
    this.onTap,
  });

  static Color colorFor(ChargingStation station) {
    if (station.connectors.isEmpty) return Colors.grey;
    if (station.hasAvailableConnector) return Colors.green;
    final anyKnown = station.connectors.any(
      (c) => c.status != ConnectorStatus.unknown,
    );
    if (!anyKnown) return Colors.grey;
    return Colors.red;
  }

  /// Build a flutter_map [Marker] for this station.
  static Marker buildMarker(
    ChargingStation station, {
    VoidCallback? onTap,
  }) {
    return Marker(
      point: LatLng(station.latitude, station.longitude),
      width: 44,
      height: 44,
      child: EvMarkerWidget(station: station, onTap: onTap),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFor(station);
    final maxPower = station.maxPowerKw.round();

    return GestureDetector(
      onTap: onTap,
      child: Semantics(
        label: 'EV charging station ${station.name}, $maxPower kW',
        button: true,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
              ),
            ],
          ),
          child: const Icon(
            Icons.ev_station,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}
