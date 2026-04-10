import 'package:flutter/material.dart';

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
    final litersStr = fillUp.liters.toStringAsFixed(2);
    final costStr = fillUp.totalCost.toStringAsFixed(2);
    final pplStr = fillUp.pricePerLiter.toStringAsFixed(3);
    final odoStr = fillUp.odometerKm.toStringAsFixed(0);

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
            Text('$dateStr · $odoStr km'),
            Text(
              '$litersStr L · $costStr · $pplStr/L',
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
