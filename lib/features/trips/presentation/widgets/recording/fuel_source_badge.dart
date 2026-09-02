// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../../core/domain/vehicle_profile.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../obd2/api.dart';

/// Where the live consumption figure comes from (#3916, Epic #3914) —
/// the four honest answers the consumption card's badge can give.
enum FuelSourceKind {
  /// A measured ECU fuel-flow PID (0x5E / 0x9D / 0xA2).
  measured,

  /// An air-mass estimate (MAF / speed-density) scaled by a pump-anchored
  /// gain the vehicle learned from full-to-full windows (#3886).
  estimatedCalibrated,

  /// An air-mass estimate with no pump-gain samples yet.
  estimatedUncalibrated,

  /// No engine data — the GPS physics estimate.
  gpsEstimate,
}

/// The badge's resolved state: the kind plus, for the calibrated
/// estimate, the gain's distance from 1 in whole percent.
@immutable
class FuelSourceBadgeState {
  const FuelSourceBadgeState(this.kind, {this.calibrationPercent});

  final FuelSourceKind kind;
  final int? calibrationPercent;

  @override
  bool operator ==(Object other) =>
      other is FuelSourceBadgeState &&
      other.kind == kind &&
      other.calibrationPercent == calibrationPercent;

  @override
  int get hashCode => Object.hash(kind, calibrationPercent);
}

/// Pure resolver: which badge the consumption card shows for [live] on
/// [vehicle] (#3916). Null when nothing is known yet (no reading, or a
/// reading with neither a fuel-rate provenance nor a GPS estimate) so
/// the card shows no badge rather than a guess.
FuelSourceBadgeState? resolveFuelSourceBadge({
  required TripLiveReading? live,
  required VehicleProfile? vehicle,
}) {
  if (live == null) return null;
  switch (live.fuelRateIsMeasured) {
    case true:
      return const FuelSourceBadgeState(FuelSourceKind.measured);
    case false:
      final samples = vehicle?.pumpGainSamples ?? 0;
      if (samples <= 0) {
        return const FuelSourceBadgeState(FuelSourceKind.estimatedUncalibrated);
      }
      final gain = vehicle?.pumpGain ?? 1.0;
      return FuelSourceBadgeState(
        FuelSourceKind.estimatedCalibrated,
        calibrationPercent: ((1.0 - gain).abs() * 100.0).round(),
      );
    case null:
      final gpsEstimate = live.gpsEstimatedLPer100Km != null ||
          live.gpsEstimatedAvgLPer100Km != null ||
          live.gpsEstimatedFuelLitersSoFar != null;
      if (gpsEstimate) {
        return const FuelSourceBadgeState(FuelSourceKind.gpsEstimate);
      }
      return null;
  }
}

/// Localized badge text for [state] (#3916). Pure, so the text-expansion
/// test and the card share one mapping.
String fuelSourceBadgeLabel(AppLocalizations l, FuelSourceBadgeState state) {
  switch (state.kind) {
    case FuelSourceKind.measured:
      return l.fuelSourceMeasured;
    case FuelSourceKind.estimatedCalibrated:
      return l.fuelSourceEstimatedCalibrated(state.calibrationPercent ?? 0);
    case FuelSourceKind.estimatedUncalibrated:
      return l.fuelSourceEstimatedUncalibrated;
    case FuelSourceKind.gpsEstimate:
      return l.fuelSourceGpsEstimate;
  }
}

/// The consumption card's fuel-source badge (#3916): a small tinted pill
/// that says whether the figure is measured, estimated (and how well
/// calibrated), or the GPS estimate. Wraps onto a second line under a
/// text-expansion locale rather than clipping.
class FuelSourceBadge extends StatelessWidget {
  const FuelSourceBadge({super.key, required this.state});

  final FuelSourceBadgeState state;

  IconData get _icon {
    switch (state.kind) {
      case FuelSourceKind.measured:
        return Icons.verified_outlined;
      case FuelSourceKind.estimatedCalibrated:
        return Icons.local_gas_station_outlined;
      case FuelSourceKind.estimatedUncalibrated:
        return Icons.help_outline;
      case FuelSourceKind.gpsEstimate:
        return Icons.satellite_alt_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final measured = state.kind == FuelSourceKind.measured;
    final background =
        measured ? scheme.primaryContainer : scheme.surfaceContainerHighest;
    final foreground =
        measured ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;
    return DecoratedBox(
      decoration: BoxDecoration(color: background, borderRadius: AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: 14, color: foreground),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                fuelSourceBadgeLabel(l, state),
                key: const Key('fuelSourceBadgeLabel'),
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: foreground),
                softWrap: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
