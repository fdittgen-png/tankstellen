import 'package:flutter/material.dart';

import '../../domain/entities/charging_station.dart';

/// A single connector row showing type, power, current type, quantity, and status.
class EVConnectorTile extends StatelessWidget {
  final Connector connector;
  const EVConnectorTile({super.key, required this.connector});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _connectorColor(connector.type).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              connector.type,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _connectorColor(connector.type)),
            ),
          ),
          const SizedBox(width: 12),
          Text('${connector.powerKW.round()} kW', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          if (connector.currentType != null)
            Text(connector.currentType!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const Spacer(),
          if (connector.quantity > 0)
            Text('x${connector.quantity}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          if (connector.status != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _statusColor(connector.status).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_statusIcon(connector.status), size: 12, color: _statusColor(connector.status)),
                  const SizedBox(width: 3),
                  Text(connector.status!, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: _statusColor(connector.status))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _statusColor(String? status) {
    if (status == null) return Colors.grey;
    if (status.contains('Available') || status == 'Operational') return Colors.green;
    if (status == 'In Use') return Colors.orange;
    if (status.contains('Unavailable') || status == 'Not Operational') return Colors.red;
    if (status == 'Partly Operational') return Colors.amber;
    return Colors.grey;
  }

  IconData _statusIcon(String? status) {
    if (status == null) return Icons.help_outline;
    if (status.contains('Available') || status == 'Operational') return Icons.check_circle;
    if (status == 'In Use') return Icons.access_time;
    if (status.contains('Unavailable') || status == 'Not Operational') return Icons.cancel;
    if (status == 'Partly Operational') return Icons.warning;
    return Icons.help_outline;
  }

  Color _connectorColor(String type) {
    if (type.contains('CCS')) return const Color(0xFF2196F3);
    if (type.contains('Type 2')) return const Color(0xFF4CAF50);
    if (type.contains('CHAdeMO')) return const Color(0xFFFF9800);
    if (type.contains('Tesla')) return const Color(0xFFE91E63);
    return const Color(0xFF757575);
  }
}
