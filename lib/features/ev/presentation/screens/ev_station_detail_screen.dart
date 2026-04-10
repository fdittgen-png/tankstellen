import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../vehicle/domain/entities/vehicle_profile.dart'
    show ConnectorType;
import '../../domain/entities/charging_station.dart';

/// Read-only detail view for a single [ChargingStation].
///
/// Shows all connectors, status badges, operator/address metadata, and
/// the last-update timestamp. Tariff breakdown is stubbed for now — the
/// detail includes a placeholder row when the connector references a
/// tariff id we don't yet resolve client-side.
class EvStationDetailScreen extends StatelessWidget {
  final ChargingStation station;

  const EvStationDetailScreen({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(station.name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (station.operator != null)
            _row(
              icon: Icons.business,
              label: l10n?.evOperator ?? 'Operator',
              value: station.operator!,
            ),
          if (station.address != null)
            _row(
              icon: Icons.location_on_outlined,
              label: l10n?.address ?? 'Address',
              value: station.address!,
            ),
          _row(
            icon: Icons.bolt,
            label: l10n?.evMaxPower ?? 'Max power',
            value: '${station.maxPowerKw.round()} kW',
          ),
          if (station.lastUpdate != null)
            _row(
              icon: Icons.update,
              label: l10n?.evLastUpdate ?? 'Last update',
              value: station.lastUpdate!.toLocal().toString(),
            ),
          const SizedBox(height: 16),
          Text(
            l10n?.evConnectors(station.connectors.length) ?? 'Connectors',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (station.connectors.isEmpty)
            Text(l10n?.evNoConnectors ?? 'No connector details available'),
          ...station.connectors.map((c) => _ConnectorTile(connector: c)),
        ],
      ),
    );
  }

  Widget _row({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12)),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectorTile extends StatelessWidget {
  final EvConnector connector;
  const _ConnectorTile({required this.connector});

  static String _labelForType(BuildContext context, ConnectorType type) {
    final l10n = AppLocalizations.of(context);
    switch (type) {
      case ConnectorType.type2:
        return l10n?.connectorType2 ?? 'Type 2';
      case ConnectorType.ccs:
        return l10n?.connectorCcs ?? 'CCS';
      case ConnectorType.chademo:
        return l10n?.connectorChademo ?? 'CHAdeMO';
      case ConnectorType.tesla:
        return l10n?.connectorTesla ?? 'Tesla';
      case ConnectorType.schuko:
        return l10n?.connectorSchuko ?? 'Schuko';
      case ConnectorType.type1:
        return l10n?.connectorType1 ?? 'Type 1';
      case ConnectorType.threePin:
        return l10n?.connectorThreePin ?? '3-pin';
    }
  }

  static (String, Color) _statusBadge(
    BuildContext context,
    ConnectorStatus status,
  ) {
    final l10n = AppLocalizations.of(context);
    switch (status) {
      case ConnectorStatus.available:
        return (l10n?.evStatusAvailable ?? 'Available', Colors.green);
      case ConnectorStatus.occupied:
        return (l10n?.evStatusOccupied ?? 'Occupied', Colors.orange);
      case ConnectorStatus.outOfOrder:
        return (l10n?.evStatusOutOfOrder ?? 'Out of order', Colors.red);
      case ConnectorStatus.unknown:
        return (l10n?.evStatusUnknown ?? 'Unknown', Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (statusLabel, color) = _statusBadge(context, connector.status);
    return Card(
      child: ListTile(
        leading: const Icon(Icons.power),
        title: Text(_labelForType(context, connector.type)),
        subtitle: Text('${connector.maxPowerKw.round()} kW'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            statusLabel,
            style: TextStyle(color: color, fontSize: 12),
          ),
        ),
      ),
    );
  }
}
