// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/domain/gps_calibration_matrix.dart';

/// Compact A/B/C-style chip rendering the maturity of a vehicle's
/// [GpsCalibrationMatrix] (#2082 / Epic #2055).
///
/// Mirrors the OBD2 `ConfidenceTierBadge` (#2027) — same shape,
/// different data source. Visible on the per-vehicle calibration
/// surface alongside the existing η_v tier badge so the user can see
/// at a glance how trustworthy each fuel-estimation channel is:
///
/// - **cold** — fewer than 3 fill-up reconciliations OR residual
///   variance > 1.5 (L/100 km)². Rendered with `errorContainer`
///   tint; tooltip explains the matrix is provisional and that GPS
///   L/100 km figures should be read with `~` prefix as estimates.
/// - **warming** — 3–7 reconciliations + variance ≤ 1.5. Rendered
///   with `tertiaryContainer` tint.
/// - **converged** — 8+ reconciliations + variance ≤ 0.5. Rendered
///   with `primaryContainer` tint.
class GpsMatrixMaturityBadge extends StatelessWidget {
  final GpsCalibrationMatrix matrix;

  const GpsMatrixMaturityBadge({super.key, required this.matrix});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final tier = matrix.maturity;
    final (label, tooltip, bgColor, fgColor) = switch (tier) {
      GpsCalibrationMaturity.cold => (
        l10n.gpsMatrixMaturityCold,
        l10n.gpsMatrixMaturityColdTooltip(matrix.fillUpReconciliationCount),
        theme.colorScheme.errorContainer,
        theme.colorScheme.onErrorContainer,
      ),
      GpsCalibrationMaturity.warming => (
        l10n.gpsMatrixMaturityWarming,
        l10n.gpsMatrixMaturityWarmingTooltip(matrix.fillUpReconciliationCount),
        theme.colorScheme.tertiaryContainer,
        theme.colorScheme.onTertiaryContainer,
      ),
      GpsCalibrationMaturity.converged => (
        l10n.gpsMatrixMaturityConverged,
        l10n.gpsMatrixMaturityConvergedTooltip(
          matrix.fillUpReconciliationCount,
        ),
        theme.colorScheme.primaryContainer,
        theme.colorScheme.onPrimaryContainer,
      ),
    };

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              tier == GpsCalibrationMaturity.converged
                  ? Icons.check_circle
                  : tier == GpsCalibrationMaturity.warming
                  ? Icons.hourglass_bottom
                  : Icons.fiber_new_outlined,
              size: 14,
              color: fgColor,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: fgColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
