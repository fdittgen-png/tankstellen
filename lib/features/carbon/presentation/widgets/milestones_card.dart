import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/milestone.dart';

/// Displays the full milestone catalog with progress bars.
///
/// Unlocked milestones are shown first with a filled check icon;
/// in-progress milestones show a linear progress indicator.
class MilestonesCard extends StatelessWidget {
  final List<MilestoneProgress> progress;

  const MilestonesCard({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final sorted = [...progress]
      ..sort((a, b) {
        if (a.unlocked == b.unlocked) return 0;
        return a.unlocked ? -1 : 1;
      });
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l?.milestonesTitle ?? 'Milestones',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            for (final p in sorted) _MilestoneRow(progress: p),
          ],
        ),
      ),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  final MilestoneProgress progress;

  const _MilestoneRow({required this.progress});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final label = _labelFor(progress.milestone, l);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            progress.unlocked
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            color: progress.unlocked
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress.fraction,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${progress.current.toStringAsFixed(0)} / '
                  '${progress.milestone.target.toStringAsFixed(0)} '
                  '${progress.milestone.unit}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _labelFor(Milestone m, AppLocalizations? l) {
    switch (m.id) {
      case 'first_fill_up':
        return l?.milestoneFirstFillUp ?? 'First fill-up logged';
      case 'ten_fill_ups':
        return l?.milestoneTenFillUps ?? '10 fill-ups tracked';
      case 'fifty_fill_ups':
        return l?.milestoneFiftyFillUps ?? '50 fill-ups tracked';
      case 'hundred_liters':
        return l?.milestoneHundredLiters ?? '100 L tracked';
      case 'thousand_liters':
        return l?.milestoneThousandLiters ?? '1000 L tracked';
      case 'hundred_kg_co2':
        return l?.milestoneHundredKgCo2 ?? '100 kg CO2 tracked';
      case 'one_tonne_co2':
        return l?.milestoneOneTonneCo2 ?? '1 tonne CO2 tracked';
      case 'thousand_km':
        return l?.milestoneThousandKm ?? '1000 km driven';
      case 'ten_thousand_km':
        return l?.milestoneTenThousandKm ?? '10,000 km driven';
    }
    return m.id;
  }
}
