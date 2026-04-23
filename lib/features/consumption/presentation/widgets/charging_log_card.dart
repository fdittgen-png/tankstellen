import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../ev/domain/entities/charging_log.dart';

/// Compact card showing a single [ChargingLog] entry (#582 phase 2).
///
/// Mirrors the fuel-side [FillUpCard] — same ListTile shape, same
/// leading avatar + trailing label — so the two lists feel like the
/// same product when the user toggles between them. Differences are
/// intentional:
/// - leading icon is `Icons.ev_station` instead of `local_gas_station`
/// - subtitle shows `kWh · cost · charge-time` instead of
///   `litres · cost · EUR/L`
/// - trailing label reads `kWh` so blind-scrolling users can
///   distinguish an EV session from a diesel fill without reading the
///   leading icon's colour.
class ChargingLogCard extends StatelessWidget {
  final ChargingLog log;
  final VoidCallback? onTap;

  const ChargingLogCard({
    super.key,
    required this.log,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    final dateStr =
        '${log.date.year}-${_pad(log.date.month)}-${_pad(log.date.day)}';
    final kwhStr = '${log.kWh.toStringAsFixed(1)} kWh';
    final costStr = '${log.costEur.toStringAsFixed(2)} €';
    final timeStr =
        log.chargeTimeMin > 0 ? ' · ${log.chargeTimeMin} min' : '';
    final title = log.stationName ?? (l?.chargingLogStationLabel ?? 'Station');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.secondaryContainer,
          child: Icon(
            Icons.ev_station,
            color: theme.colorScheme.onSecondaryContainer,
          ),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$dateStr · ${log.odometerKm} km'),
            Text(
              '$kwhStr · $costStr$timeStr',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        trailing: Text(
          'kWh',
          style: theme.textTheme.labelSmall,
        ),
      ),
    );
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}
