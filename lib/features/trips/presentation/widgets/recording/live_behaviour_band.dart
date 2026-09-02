// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/utils/unit_formatter.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../driving_score/api.dart';

/// The live driving-behaviour band (#3845): one traffic-light colour
/// for the rolling 0..100 score, with the band name and the number
/// beside it.
///
/// Colour is never the only channel — the band name and score are both
/// rendered, so the widget still reads correctly for a colour-blind
/// driver and in a screen-reader announcement.
///
/// #3916 — extracted from `MinimalDriveSummary` (the recording hero)
/// under the file-length cap; keys and behaviour unchanged.
class LiveBehaviourBand extends StatelessWidget {
  const LiveBehaviourBand({super.key, required this.score});

  final int score;

  /// The four bands the user asked for, in order good → bad. Fixed
  /// traffic-light colours rather than scheme roles: "green / yellow /
  /// orange / red" is the shared driving vocabulary here, and a theme
  /// that maps `tertiary` to something else would break the reading.
  static Color colorFor(DrivingStyleClass c) {
    switch (c) {
      case DrivingStyleClass.veryGood:
        return const Color(0xFF2E7D32); // green 800
      case DrivingStyleClass.good:
        return const Color(0xFFF9A825); // yellow 800
      case DrivingStyleClass.average:
        return const Color(0xFFEF6C00); // orange 800
      case DrivingStyleClass.bad:
        return const Color(0xFFC62828); // red 800
    }
  }

  static String labelFor(AppLocalizations l, DrivingStyleClass c) {
    switch (c) {
      case DrivingStyleClass.veryGood:
        return l.drivingScoreClassVeryGood;
      case DrivingStyleClass.good:
        return l.drivingScoreClassGood;
      case DrivingStyleClass.average:
        return l.drivingScoreClassAverage;
      case DrivingStyleClass.bad:
        return l.drivingScoreClassBad;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final styleClass = DrivingStyleClass.fromScore(score);
    final color = colorFor(styleClass);
    final bandLabel = labelFor(l, styleClass);

    return Semantics(
      key: const Key('minimal_drive_behaviour_band'),
      label: '${l.minimalDriveBehaviour}: $bandLabel',
      value: '$score',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                l.minimalDriveBehaviour,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                bandLabel,
                key: const Key('minimal_drive_behaviour_label'),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                // The 0..100 score through the locale-aware formatter —
                // a bare '$score' would render Western digits on locales
                // that use their own numerals.
                UnitFormatter.formatDecimal(score.toDouble(),
                    fractionDigits: 0),
                key: const Key('minimal_drive_behaviour_score'),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // The bar fills in proportion to the score, so the colour and
          // the length say the same thing twice.
          ClipRRect(
            borderRadius: AppRadius.sm,
            child: LinearProgressIndicator(
              value: score / 100.0,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
