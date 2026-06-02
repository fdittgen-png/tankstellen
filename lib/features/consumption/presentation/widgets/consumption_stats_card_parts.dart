// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'consumption_stats_card.dart';

/// Grey informational banner — partials are pending a plein-complet
/// close. Non-tappable v1; tap-to-jump to fill-up list is a follow-up.
class _OpenWindowBanner extends StatelessWidget {
  final String text;

  const _OpenWindowBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.hourglass_bottom,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Orange-tinted hint — too much of the average comes from auto-
/// corrections. Encourages the user to review the orange entries.
class _CorrectionShareHint extends StatelessWidget {
  final String text;

  const _CorrectionShareHint({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Reuse the orange palette established by the correction fill-up
    // card (#1361) so the visual language stays consistent.
    final orange = DarkModeColors.warning(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: orange.withValues(alpha: 0.40)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_outlined, size: 18, color: orange),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}

/// Engineer-detail pill surfacing the auto-learner's η_v state
/// (#1397 / #815). #2112 — restyled to match [ConfidenceTierBadge]'s
/// recipe so the two land as one harmonised group on the Fuel tab.
///
/// Three branches drive the label:
///   * `samples >= 3` → "η_v: 0.87 · N samples"
///   * `0 < samples < 3` → "η_v: 0.87 · N samples" (same shape; the
///     learning vs calibrated distinction lives on the confidence
///     tier next to it — keep this pill engineer-bare).
///   * `samples == 0` → "η_v: ?? · no plein-complet yet"
///
/// Variance tracking would let us print "± 0.04" alongside the mean,
/// but the existing [VeLearner] only stores the EWMA scalar — adding
/// a Welford branch is left to a follow-up. For now the calibrated
/// branch keeps the bare mean.
class _CalibrationChip extends StatelessWidget {
  final double volumetricEfficiency;
  final int samples;

  const _CalibrationChip({
    required this.volumetricEfficiency,
    required this.samples,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final eta = volumetricEfficiency.toStringAsFixed(2);
    final String label;
    if (samples == 0) {
      label =
          l?.calibrationLearnerStatusNoSamples ??
          'η_v: ?? — no plein-complet yet';
    } else {
      // #2112 — single label shape across learning + calibrated;
      // confidence tier carries the maturity colour.
      label =
          l?.calibrationLearnerEtaCompact(eta, samples) ??
          'η_v: $eta · $samples samples';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // #1902 — the stat figures (litres, total spent, …) read
              // far smaller than the old bold titleMedium: they were
              // dominating the summary card. Weight still sets them
              // apart from the label above.
              Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
