// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'vehicle_baseline_section.dart';

/// One per-situation row (#3900): label, progress bar, then the capped
/// `min(count, target)/target` readout — with a check once the bucket is
/// full — and, when the raw count exceeds the target, the honest raw
/// figure as secondary text underneath.
class _BaselineRow extends StatelessWidget {
  final String label;
  final int count;
  final int fullConfidenceSamples;

  const _BaselineRow({
    required this.label,
    required this.count,
    required this.fullConfidenceSamples,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final progress = (count / fullConfidenceSamples).clamp(0.0, 1.0);
    final capped = math.min(count, fullConfidenceSamples);
    final full = count >= fullConfidenceSamples;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Expanded(
            flex: 5,
            child: LinearProgressIndicator(value: progress, minHeight: 6),
          ),
          const SizedBox(width: 8),
          // Intrinsic width — the readout never clips under a wide font
          // or a long localized count.
          Flexible(
            flex: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (full) ...[
                      Icon(
                        Icons.check,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 2),
                    ],
                    Text(
                      '$capped/$fullConfidenceSamples',
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.end,
                    ),
                  ],
                ),
                if (count > fullConfidenceSamples)
                  Text(
                    l.vehicleBaselineRawSamples(count),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.end,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// #2514 / #3900 — informational chip listing the driving situations
/// that have never been detected (0 samples). It exists because the
/// coverage bar alone tells the user calibration is incomplete but not
/// *which* buckets are stuck; naming them (e.g. "Stop & go", "Climbing
/// / loaded") points at the root cause tracked by Epic #2512. Neutral
/// tone: an undetected situation is a fact about the drives so far,
/// not a fault.
class _MissingSituationsNote extends StatelessWidget {
  final List<String> situations;

  const _MissingSituationsNote({required this.situations});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // Comma-join is locale-neutral punctuation, not prose.
    final joined = situations.join(', '); // i18n-ignore: list separator
    return Container(
      key: const Key('vehicleBaselineMissingWarning'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: AppRadius.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l.vehicleBaselineMissingWarning(joined),
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
