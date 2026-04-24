import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/vehicle_profile.dart';

/// Card-free big header rendered at the top of the restyled
/// edit-vehicle form (#751 §3). Shows the vehicle's name as a large
/// title plus a tiny "plate" chip with the drivetrain icon — a
/// visual anchor that turns the edit screen into "this vehicle's
/// page" instead of "a long list of fields".
class VehicleHeader extends StatelessWidget {
  final String name;
  final Color accent;
  final VehicleType type;

  const VehicleHeader({
    super.key,
    required this.name,
    required this.accent,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final displayName = name.trim().isEmpty
        ? (l?.vehicleHeaderUntitled ?? 'New vehicle')
        : name.trim();
    final typeLabel = switch (type) {
      VehicleType.ev => l?.vehicleTypeEv ?? 'Electric',
      VehicleType.hybrid => l?.vehicleTypeHybrid ?? 'Hybrid',
      VehicleType.combustion => l?.vehicleTypeCombustion ?? 'Combustion',
    };
    final typeIcon = switch (type) {
      VehicleType.ev => Icons.electric_car,
      VehicleType.hybrid => Icons.directions_car_filled,
      VehicleType.combustion => Icons.local_gas_station,
    };

    return Semantics(
      container: true,
      label: '$displayName · $typeLabel',
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(typeIcon, size: 36, color: accent),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _PlateChip(label: typeLabel, accent: accent),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlateChip extends StatelessWidget {
  final String label;
  final Color accent;

  const _PlateChip({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: accent,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
