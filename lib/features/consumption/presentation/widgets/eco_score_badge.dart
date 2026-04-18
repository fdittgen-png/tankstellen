import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/eco_score.dart';

/// Compact "eco-score" badge shown on each fill-up card.
///
/// Renders as "6.8 L/100 km · ⬇︎ 4%" (or metric equivalent) with an
/// arrow and tint that tells the user at a glance whether this tank
/// beat their recent driving average.
///
/// The rolling-average window is 3 fill-ups — see [EcoScore] for the
/// rationale. This widget never computes anything; it just draws the
/// pre-computed score.
class EcoScoreBadge extends StatelessWidget {
  final EcoScore score;

  const EcoScoreBadge({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final (icon, color) = _styleFor(score.direction, theme);

    final deltaText =
        '${score.deltaPercent >= 0 ? '+' : ''}${score.deltaPercent.toStringAsFixed(0)}%';
    final lp100Text = score.litersPer100Km.toStringAsFixed(1);
    final avgText = score.rollingAverage.toStringAsFixed(1);

    // Compose the badge text from the localised consumption unit +
    // the raw delta; the delta itself (+/− and %) is locale-neutral.
    final consumptionText =
        l10n?.ecoScoreConsumption(lp100Text) ?? '$lp100Text L/100 km';
    final badgeText = '$consumptionText · $deltaText';

    final tooltip = l10n?.ecoScoreTooltip(avgText) ??
        'Compared to the rolling average over your last 3 fill-ups '
            '($avgText L/100 km).';
    final semanticsLabel = l10n?.ecoScoreSemantics(lp100Text, deltaText) ??
        'Consumption $lp100Text L/100 km, $deltaText versus your '
            'rolling average';

    return Semantics(
      label: semanticsLabel,
      child: Tooltip(
        message: tooltip,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              badgeText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, Color) _styleFor(EcoScoreDirection dir, ThemeData theme) {
    switch (dir) {
      case EcoScoreDirection.improving:
        return (Icons.arrow_downward, Colors.green.shade700);
      case EcoScoreDirection.worsening:
        return (Icons.arrow_upward, Colors.orange.shade800);
      case EcoScoreDirection.stable:
        return (Icons.arrow_forward, theme.colorScheme.onSurfaceVariant);
    }
  }
}
