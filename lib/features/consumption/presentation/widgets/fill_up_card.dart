import 'package:flutter/material.dart';

import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/unit_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/fill_up.dart';

/// Compact card showing a single [FillUp] entry.
class FillUpCard extends StatelessWidget {
  final FillUp fillUp;
  final VoidCallback? onTap;

  const FillUpCard({super.key, required this.fillUp, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    final dateStr =
        '${fillUp.date.year}-${_pad(fillUp.date.month)}-${_pad(fillUp.date.day)}';
    // Until the FillUp model carries an origin-country code (tracked in
    // #626 follow-up), fall back to the active country's units. Old
    // records logged before this change will re-format on the fly when
    // the user changes country — acceptable as a transitional step.
    final distance = UnitFormatter.formatDistance(fillUp.odometerKm);
    final volume = UnitFormatter.formatVolume(fillUp.liters);
    final costStr =
        '${fillUp.totalCost.toStringAsFixed(2)} ${PriceFormatter.currency}';
    final ppl = UnitFormatter.formatPricePerUnit(fillUp.pricePerLiter);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.local_gas_station,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          fillUp.stationName ?? fillUp.fuelType.apiValue.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$dateStr · $distance'),
            Text(
              '$volume · $costStr · $ppl',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        trailing: Text(
          fillUp.fuelType.apiValue.toUpperCase(),
          style: theme.textTheme.labelSmall,
          semanticsLabel: l?.fuelType ?? 'Fuel type',
        ),
      ),
    );
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}
