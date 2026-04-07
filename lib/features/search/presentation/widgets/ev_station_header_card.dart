import 'package:flutter/material.dart';

import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/charging_station.dart';

/// Header card showing status, name, and operator for an EV station.
class EVStationHeaderCard extends StatelessWidget {
  final ChargingStation station;
  final Color evColor;

  const EVStationHeaderCard({
    super.key,
    required this.station,
    required this.evColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: station.isOperational == true
                        ? DarkModeColors.success(context)
                        : DarkModeColors.warning(context),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  station.isOperational == true
                      ? (l10n?.evOperational ?? 'Operational')
                      : (l10n?.evStatusUnknown ?? 'Status unknown'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: station.isOperational == true
                        ? DarkModeColors.success(context)
                        : DarkModeColors.warning(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Icon(Icons.ev_station, color: evColor, size: 28),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              station.name,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (station.operator.isNotEmpty && station.operator != station.name)
              Text(station.operator, style: theme.textTheme.titleMedium?.copyWith(color: evColor)),
          ],
        ),
      ),
    );
  }
}
