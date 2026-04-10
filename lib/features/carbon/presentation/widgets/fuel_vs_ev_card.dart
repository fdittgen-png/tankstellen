import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/milestone.dart';

/// Compares the user's fuel CO2 against an EV equivalent for the same
/// distance and offers a copy-to-clipboard "share" of the headline
/// number. Uses [Clipboard] instead of share_plus to stay platform-
/// agnostic and avoid pulling in another dependency.
class FuelVsEvCard extends StatelessWidget {
  final double fuelCo2Kg;
  final double distanceKm;

  const FuelVsEvCard({
    super.key,
    required this.fuelCo2Kg,
    required this.distanceKm,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final evCo2 = MilestoneEngine.evEquivalentCo2(distanceKm);
    final diff = fuelCo2Kg - evCo2;
    final maxVal = fuelCo2Kg > evCo2 ? fuelCo2Kg : evCo2;
    final fuelFrac = maxVal > 0 ? fuelCo2Kg / maxVal : 0.0;
    final evFrac = maxVal > 0 ? evCo2 / maxVal : 0.0;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l?.fuelVsEvTitle ?? 'Fuel vs EV',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              l?.fuelVsEvSubtitle ??
                  'CO2 comparison for the same distance driven',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _Row(
              label: l?.fuelVsEvYourFuel ?? 'Your fuel',
              valueKg: fuelCo2Kg,
              fraction: fuelFrac,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 12),
            _Row(
              label: l?.fuelVsEvEquivalent ?? 'Equivalent EV',
              valueKg: evCo2,
              fraction: evFrac,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              '${l?.fuelVsEvDistance ?? 'Distance'}: '
              '${distanceKm.toStringAsFixed(0)} km',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            if (diff > 0)
              Text(
                '${l?.fuelVsEvDifference ?? 'Difference'}: '
                '+${diff.toStringAsFixed(1)} kg CO2',
                style: theme.textTheme.bodyMedium,
              ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                key: const Key('carbon_share_button'),
                onPressed: () => _share(context, l),
                icon: const Icon(Icons.share),
                label: Text(l?.shareProgress ?? 'Share'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _share(BuildContext context, AppLocalizations? l) async {
    // Privacy-respecting: no location, no cost, just CO2 + app name.
    final text =
        '${l?.shareCo2Message(fuelCo2Kg.toStringAsFixed(0)) ?? 'I tracked ${fuelCo2Kg.toStringAsFixed(0)} kg CO2 with Tankstellen.'}';
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l?.shareCopied ?? 'Copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final double valueKg;
  final double fraction;
  final Color color;

  const _Row({
    required this.label,
    required this.valueKg,
    required this.fraction,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.bodyMedium),
            Text(
              '${valueKg.toStringAsFixed(1)} kg',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: fraction.clamp(0.0, 1.0),
            minHeight: 8,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            backgroundColor: color.withAlpha(40),
          ),
        ),
      ],
    );
  }
}
