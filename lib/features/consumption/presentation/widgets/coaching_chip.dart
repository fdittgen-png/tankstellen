// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/driving_coaching.dart';

/// Compact icon + label chip surfacing a [DrivingCoachingHint] inside
/// the recording banner / PiP tile (#2007).
///
/// Extracted from `trip_recording_banner.dart` so the host file stays
/// under the 400-line guard — the chip is a self-contained widget
/// with no dependencies on the banner's situation / palette logic
/// beyond the foreground / background colours it's handed.
class CoachingChip extends StatelessWidget {
  const CoachingChip({
    super.key,
    required this.hint,
    required this.foreground,
  });

  final DrivingCoachingHint hint;

  /// The banner palette's foreground colour. Used both for the icon /
  /// text colour and (translucent) for the chip's background so the
  /// chip blends into the active band's colour rather than fighting it.
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final (icon, label) = switch (hint) {
      DrivingCoachingHint.shiftUp => (
          Icons.arrow_upward,
          l?.coachingShiftUp ?? 'Shift up',
        ),
      DrivingCoachingHint.shiftDown => (
          Icons.arrow_downward,
          l?.coachingShiftDown ?? 'Shift down',
        ),
      DrivingCoachingHint.easePedal => (
          Icons.eco,
          l?.coachingEasePedal ?? 'Ease off',
        ),
    };
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: foreground.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
