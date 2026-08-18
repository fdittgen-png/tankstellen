// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../vehicle/domain/calibration_confidence_tier.dart';

/// Chip labelling the trustworthiness of the consumption estimate
/// (#2027 / #2262). The underlying [CalibrationConfidenceTier] enum +
/// selection logic stay untouched — this widget only changes how the
/// tier is *presented*.
///
/// #2262 — the old `Confidence: A — ±40-60%` (worst) → `C — ±3-7%`
/// (best) letters read back-to-front: users took "A" for the top grade
/// and "C" for a bad mark, when C is actually full calibration. The
/// letters are replaced with a plain accuracy word —
/// tier c → **High**, b → **Medium**, a → **Low** — rendered as
/// `Accuracy: High · ±3-7%`, fronted by a small 3-dot level meter so
/// the trust reads at a glance. The expected-error ± band is kept; the
/// tooltip is reworded to match (how to improve: add fill-ups → record
/// an OBD2 trip).
///
/// Extracted from `consumption_stats_card.dart` so that file stays
/// under the 400-line guard (#1680).
class ConfidenceTierBadge extends StatelessWidget {
  final int samples;
  final bool hasGpsPlusObd2Trip;

  const ConfidenceTierBadge({
    super.key,
    required this.samples,
    required this.hasGpsPlusObd2Trip,
  });

  @override
  Widget build(BuildContext context) {
    final tier = calibrationConfidenceTier(
      volumetricEfficiencySamples: samples,
      hasGpsPlusObd2Trip: hasGpsPlusObd2Trip,
    );
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final spec = _specFor(tier, l, theme.colorScheme);
    final label = l.consumptionAccuracyLabel(spec.levelWord, spec.band);
    return Tooltip(
      message: spec.tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: spec.bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LevelMeter(filled: spec.filledDots, color: spec.fg),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: spec.fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Maps [tier] to its localized level word, the language-neutral ±
  /// band mask, the reworded tooltip, the filled-dot count (1-3) and
  /// the badge colours.
  _AccuracySpec _specFor(
    CalibrationConfidenceTier tier,
    AppLocalizations l,
    ColorScheme scheme,
  ) {
    switch (tier) {
      case CalibrationConfidenceTier.a:
        return _AccuracySpec(
          levelWord: l.consumptionAccuracyLow,
          band: '±40-60%', // i18n-ignore: language-neutral error-band mask
          tooltip: l.consumptionAccuracyTooltipLow,
          filledDots: 1,
          bg: scheme.errorContainer,
          fg: scheme.onErrorContainer,
        );
      case CalibrationConfidenceTier.b:
        return _AccuracySpec(
          levelWord: l.consumptionAccuracyMedium,
          band: '±10-20%', // i18n-ignore: language-neutral error-band mask
          tooltip: l.consumptionAccuracyTooltipMedium,
          filledDots: 2,
          bg: scheme.tertiaryContainer,
          fg: scheme.onTertiaryContainer,
        );
      case CalibrationConfidenceTier.c:
        return _AccuracySpec(
          levelWord: l.consumptionAccuracyHigh,
          band: '±3-7%', // i18n-ignore: language-neutral error-band mask
          tooltip: l.consumptionAccuracyTooltipHigh,
          filledDots: 3,
          bg: scheme.primaryContainer,
          fg: scheme.onPrimaryContainer,
        );
    }
  }
}

/// Resolved presentation data for one [CalibrationConfidenceTier].
class _AccuracySpec {
  final String levelWord;
  final String band;
  final String tooltip;
  final int filledDots;
  final Color bg;
  final Color fg;

  const _AccuracySpec({
    required this.levelWord,
    required this.band,
    required this.tooltip,
    required this.filledDots,
    required this.bg,
    required this.fg,
  });
}

/// Small 3-dot level meter — [filled] of three dots are solid in
/// [color]; the rest are drawn at low opacity. Communicates the
/// accuracy tier visually so the worded label reads as a level rather
/// than a flat tag.
class _LevelMeter extends StatelessWidget {
  final int filled;
  final Color color;

  const _LevelMeter({required this.filled, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final on = i < filled;
        return Padding(
          padding: EdgeInsets.only(right: i < 2 ? 2 : 0),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: on ? color : color.withValues(alpha: 0.25),
            ),
          ),
        );
      }),
    );
  }
}
