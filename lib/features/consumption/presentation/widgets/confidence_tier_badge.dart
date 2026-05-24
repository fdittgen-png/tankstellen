import 'package:flutter/material.dart';

import '../../../vehicle/domain/calibration_confidence_tier.dart';

/// Chip labelling the trustworthiness of the consumption estimate
/// (#2027). A = GPS-only / no fill-ups, B = fill-ups but no OBD2 trip
/// yet, C = full fill-ups + OBD2 stack. Tooltip carries the expected
/// error band for each tier.
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
    final (label, tooltip, bg, fg) = _styleFor(tier, theme);
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: fg,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  (String, String, Color, Color) _styleFor(
    CalibrationConfidenceTier tier,
    ThemeData theme,
  ) {
    final scheme = theme.colorScheme;
    switch (tier) {
      case CalibrationConfidenceTier.a:
        return (
          'Confidence: A — ±40-60%',
          'GPS-only — no fill-ups have anchored the consumption model yet. '
              'Add a couple of full fill-ups to upgrade to tier B.',
          scheme.errorContainer,
          scheme.onErrorContainer,
        );
      case CalibrationConfidenceTier.b:
        return (
          'Confidence: B — ±10-20%',
          'Fill-ups have anchored the consumption model, but no OBD2 trip '
              'has fed the loop yet. Record one with OBD2 connected to '
              'reach tier C.',
          scheme.tertiaryContainer,
          scheme.onTertiaryContainer,
        );
      case CalibrationConfidenceTier.c:
        return (
          'Confidence: C — ±3-7%',
          'Full calibration: fill-ups + OBD2-recorded trips. The L/100 km '
              'figure tracks reality to within a few percent.',
          scheme.primaryContainer,
          scheme.onPrimaryContainer,
        );
    }
  }
}
