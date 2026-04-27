import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/driving_score.dart';

/// Composite "driving score" card on the Trip detail screen
/// (#1041 phase 5a — Card A).
///
/// Sits at the very top of the Insights group on the trip detail
/// scroll view: a single big 0..100 number, a localized title above
/// it, an `out of 100` caption beneath, and an optional one-line
/// breakdown chip row showing the top one or two penalty contributions
/// so the driver immediately sees *what* dragged the score down.
///
/// The card is purely presentational. Score derivation, weights, and
/// caps live in `driving_score_calculator.dart`; the widget trusts the
/// caller's [DrivingScore] without recomputing anything.
///
/// ## Sub-text follow-up
///
/// The issue body describes a "Better than X% of past trips" sub-text.
/// `BaselineStore` tracks per-vehicle steady-state baselines, not
/// per-trip score percentiles, so wiring up that comparison is its
/// own piece of work. The card surfaces a placeholder caption today;
/// the percentile sub-text lands in a follow-up phase.
///
/// ## EV trips / empty trips
///
/// The parent [TripDetailBody] omits the card entirely for EV trips
/// (RPM-based scoring does not model an EV motor) and for trips with
/// no samples at all. The widget itself is a no-op `SizedBox.shrink()`
/// when handed a [DrivingScore.perfect] derived from an empty trip —
/// belt-and-braces in case a caller forgets to gate it.
class DrivingScoreCard extends StatelessWidget {
  /// Pre-computed composite score for the trip. The widget reads
  /// `score` for the big number and surfaces the top one or two
  /// penalty contributions as small chips beneath.
  final DrivingScore score;

  const DrivingScoreCard({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final scoreText = score.score.toString();
    final outOf =
        l?.drivingScoreCardOutOf ?? '/100';
    final scoreSemanticsLabel =
        l?.drivingScoreCardSemanticsLabel(scoreText) ??
            'Driving score $scoreText out of 100';

    final topPenalties = _topPenalties(l);

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l?.drivingScoreCardTitle ?? 'Driving score',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Semantics(
              label: scoreSemanticsLabel,
              container: true,
              child: ExcludeSemantics(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      scoreText,
                      key: const Key('driving_score_big_number'),
                      style: theme.textTheme.displayLarge?.copyWith(
                        color: _scoreColor(theme, score.score),
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      outOf,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              // Placeholder for the future "Better than X% of past
              // trips" sub-text — see the class docstring for why it's
              // a follow-up.
              l?.drivingScoreCardSubtitle ??
                  'Composite score from idling, hard accelerations, '
                      'hard braking, and high-RPM time.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (topPenalties.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final penalty in topPenalties)
                    _PenaltyChip(label: penalty),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Pick the top one or two penalty contributions to surface as
  /// chips. Returns an empty list when every category is below a
  /// 1-point floor (the trip was clean enough that singling out a
  /// "biggest" contributor would be misleading).
  List<String> _topPenalties(AppLocalizations? l) {
    final entries = <_NamedPenalty>[
      _NamedPenalty(
        value: score.idlingPenalty,
        label: l?.drivingScorePenaltyIdling ?? 'Idling',
      ),
      _NamedPenalty(
        value: score.hardAccelPenalty,
        label: l?.drivingScorePenaltyHardAccel ?? 'Hard accelerations',
      ),
      _NamedPenalty(
        value: score.hardBrakePenalty,
        label: l?.drivingScorePenaltyHardBrake ?? 'Hard braking',
      ),
      _NamedPenalty(
        value: score.highRpmPenalty,
        label: l?.drivingScorePenaltyHighRpm ?? 'High RPM',
      ),
      _NamedPenalty(
        value: score.fullThrottlePenalty,
        label: l?.drivingScorePenaltyFullThrottle ?? 'Full throttle',
      ),
    ]..sort((a, b) => b.value.compareTo(a.value));

    return [
      for (final e in entries)
        if (e.value >= 1.0) e.label,
    ].take(2).toList(growable: false);
  }

  /// Map the numeric score to a colour band: red below 50, amber
  /// 50..74, primary above. The thresholds mirror common eco-coach
  /// conventions ("good / fair / needs work") without leaning on
  /// theme-specific brand colours.
  Color _scoreColor(ThemeData theme, int s) {
    if (s < 50) return theme.colorScheme.error;
    if (s < 75) return theme.colorScheme.tertiary;
    return theme.colorScheme.primary;
  }
}

class _NamedPenalty {
  final double value;
  final String label;
  const _NamedPenalty({required this.value, required this.label});
}

/// Compact chip used in the breakdown row beneath the big number.
/// Visual is a thin outlined pill — keeps the card focused on the
/// score itself rather than on the breakdown.
class _PenaltyChip extends StatelessWidget {
  final String label;

  const _PenaltyChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
