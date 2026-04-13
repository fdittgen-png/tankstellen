import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/vehicle_profile.dart';

/// Compact summary card for one [VehicleProfile].
///
/// Shows the name, powertrain badge, and a line of key specs. Used in the
/// [VehicleListScreen] and as a preview in settings.
class VehicleCard extends StatelessWidget {
  final VehicleProfile vehicle;
  final bool isActive;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onSetActive;

  const VehicleCard({
    super.key,
    required this.vehicle,
    this.isActive = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onSetActive,
  });

  IconData _iconForType(VehicleType type) {
    switch (type) {
      case VehicleType.ev:
        return Icons.electric_car;
      case VehicleType.hybrid:
        return Icons.directions_car_filled;
      case VehicleType.combustion:
        return Icons.local_gas_station;
    }
  }

  String _subtitle() {
    final parts = <String>[];
    if (vehicle.isEv) {
      if (vehicle.batteryKwh != null) {
        parts.add('${vehicle.batteryKwh!.toStringAsFixed(0)} kWh');
      }
      if (vehicle.maxChargingKw != null) {
        parts.add('${vehicle.maxChargingKw!.toStringAsFixed(0)} kW');
      }
      if (vehicle.supportedConnectors.isNotEmpty) {
        parts.add(vehicle.supportedConnectors.map((c) => c.label).join(', '));
      }
    }
    if (vehicle.isCombustion) {
      if (vehicle.tankCapacityL != null) {
        parts.add('${vehicle.tankCapacityL!.toStringAsFixed(0)} L');
      }
      if (vehicle.preferredFuelType != null) {
        parts.add(vehicle.preferredFuelType!);
      }
    }
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final subtitle = _subtitle();

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            _iconForType(vehicle.type),
            color: isActive
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurface,
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                vehicle.name,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.check_circle,
                size: 16,
                color: theme.colorScheme.primary,
              ),
            ],
          ],
        ),
        subtitle: subtitle.isEmpty ? null : Text(subtitle),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                onEdit?.call();
                break;
              case 'delete':
                onDelete?.call();
                break;
              case 'activate':
                onSetActive?.call();
                break;
            }
          },
          itemBuilder: (context) => [
            if (!isActive)
              PopupMenuItem(
                value: 'activate',
                child: Text(l10n?.vehicleSetActive ?? 'Set active'),
              ),
            PopupMenuItem(
                value: 'edit', child: Text(l10n?.edit ?? 'Edit')),
            PopupMenuItem(
                value: 'delete', child: Text(l10n?.delete ?? 'Delete')),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
