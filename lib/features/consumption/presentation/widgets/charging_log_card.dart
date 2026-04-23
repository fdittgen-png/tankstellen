import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../ev/domain/entities/charging_log.dart';

/// Compact list-tile card for a single [ChargingLog] row on the
/// Consumption screen's Charging tab (#582 phase 2).
///
/// Intentionally mirrors [FillUpCard] in visual weight (leading icon
/// + title + subtitle) so the user sees one consistent list shape
/// regardless of which tab they're on. Phase 3 extends this with
/// per-segment EUR/100km — for now the card shows the raw session
/// numbers only so "can the user verify what they logged?" is the
/// single question it answers.
class ChargingLogCard extends StatelessWidget {
  final ChargingLog log;

  const ChargingLogCard({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dateStr =
        '${log.date.year}-${_pad(log.date.month)}-${_pad(log.date.day)}';
    final title = log.stationName?.trim().isNotEmpty == true
        ? log.stationName!
        : (l?.chargingStationName ?? 'Station');
    final kwhStr = log.kWh.toStringAsFixed(1);
    final costStr = log.costEur.toStringAsFixed(2);
    final subtitle =
        '$dateStr  •  $kwhStr kWh  •  $costStr €  •  ${log.chargeTimeMin} min';

    return Semantics(
      container: true,
      label: '$title, $subtitle',
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: ListTile(
          leading: Icon(
            Icons.ev_station_outlined,
            color: theme.colorScheme.primary,
          ),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: Text(
            '${log.odometerKm} km',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}
