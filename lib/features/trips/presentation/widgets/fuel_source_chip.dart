// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/calibrated_trip_figures.dart';
import '../../domain/trip_fuel_source.dart';

/// Fuel-source badge on a trip row / the trip detail (#3919, Epic
/// #3914): *Measured* (ECU fuel PID, never rescaled) · *Estimated ·
/// calibrated* (air-mass estimate with a pump gain) · *Estimated* (raw
/// estimate) · *GPS* (physics estimate, no engine data). Renders nothing
/// when the trip carries no fuel figure. The tooltip names the branch
/// and appends "recalculated" when the figure was re-expressed at the
/// vehicle's current gain ([CalibratedTripFigures.reExpressed]).
class FuelSourceChip extends StatelessWidget {
  const FuelSourceChip({super.key, required this.figures, this.compact = false});

  final CalibratedTripFigures figures;
  final bool compact;

  /// The chip label for [figures], or null when no chip applies.
  static String? labelFor(AppLocalizations l, CalibratedTripFigures f) =>
      switch (f.kind) {
        TripFuelSourceKind.measured => l.tripFuelSourceMeasured,
        TripFuelSourceKind.estimated => f.calibrated
            ? l.tripFuelSourceEstimatedCalibrated
            : l.tripFuelSourceEstimated,
        TripFuelSourceKind.gps => l.tripFuelSourceGps,
        TripFuelSourceKind.none => null,
      };

  static String tooltipFor(AppLocalizations l, CalibratedTripFigures f) {
    final base = switch (f.kind) {
      TripFuelSourceKind.measured => l.tripFuelSourceMeasuredTooltip,
      TripFuelSourceKind.estimated => l.tripFuelSourceEstimatedTooltip,
      TripFuelSourceKind.gps => l.tripFuelSourceGpsTooltip,
      TripFuelSourceKind.none => '',
    };
    return f.reExpressed ? '$base · ${l.tripFuelSourceRecalculated}' : base;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final label = labelFor(l, figures);
    if (label == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final measured = figures.kind == TripFuelSourceKind.measured;
    final bg = measured ? scheme.primaryContainer : scheme.surfaceContainerHighest;
    final fg = measured ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;
    final icon = switch (figures.kind) {
      TripFuelSourceKind.measured => Icons.verified_outlined,
      TripFuelSourceKind.estimated =>
        figures.calibrated ? Icons.tune : Icons.calculate_outlined,
      TripFuelSourceKind.gps => Icons.satellite_alt_outlined,
      TripFuelSourceKind.none => Icons.help_outline,
    };
    return Tooltip(
      message: tooltipFor(l, figures),
      child: Container(
        key: const Key('fuelSourceChip'),
        padding: EdgeInsets.symmetric(
            horizontal: compact ? 6 : 8, vertical: compact ? 1 : 2),
        decoration: BoxDecoration(color: bg, borderRadius: AppRadius.lg),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 12 : 14, color: fg),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
