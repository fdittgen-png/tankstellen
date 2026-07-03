// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../obd2/api.dart' show kDistanceSourceGps, kDistanceSourceReal;

/// Compact provenance chip for a trip's distance figure (#3253).
///
/// `TripSummary.distanceSource` has been persisted + exported since #800
/// / #1979 but was rendered NOWHERE — fuel estimates carry the `~` +
/// maturity badge, while the km figure gave no hint whether it came from
/// the car's odometer (ground truth), a haversine-summed GPS track, or
/// the speed-integrated virtual odometer (an estimate). Mirrors
/// [GpsMatrixMaturityBadge]'s chip idiom (#2082): label + tooltip,
/// container tint by trustworthiness.
///
/// Takes the raw source STRING (a primitive, not a summary object) so
/// the widget stays reusable from any row that already knows the value.
/// `virtual` — and any unknown/future value — renders the "Estimated"
/// chip: a distance of unproven provenance must not claim ground truth.
class DistanceSourceBadge extends StatelessWidget {
  /// One of `kDistanceSourceReal` / `kDistanceSourceGps` /
  /// `kDistanceSourceVirtual` (`TripSummary.distanceSource`).
  final String source;

  const DistanceSourceBadge({super.key, required this.source});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final (label, tooltip, icon, bgColor, fgColor) = switch (source) {
      kDistanceSourceReal => (
        l10n.distanceSourceOdometer,
        l10n.distanceSourceOdometerTooltip,
        Icons.speed,
        theme.colorScheme.primaryContainer,
        theme.colorScheme.onPrimaryContainer,
      ),
      kDistanceSourceGps => (
        l10n.distanceSourceGps,
        l10n.distanceSourceGpsTooltip,
        Icons.satellite_alt,
        theme.colorScheme.tertiaryContainer,
        theme.colorScheme.onTertiaryContainer,
      ),
      // kDistanceSourceVirtual — the speed-integrated estimate.
      _ => (
        l10n.distanceSourceEstimated,
        l10n.distanceSourceEstimatedTooltip,
        Icons.functions,
        theme.colorScheme.surfaceContainerHighest,
        theme.colorScheme.onSurfaceVariant,
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
            Icon(icon, size: 14, color: fgColor),
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
