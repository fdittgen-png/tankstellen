// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../feature_management/application/feature_flags_provider.dart';
import '../../../feature_management/domain/feature.dart';
import '../../../vehicle/providers/vehicle_providers.dart';
import 'confidence_tier_badge.dart';

/// Self-contained app-bar widget showing the active vehicle's consumption
/// confidence tier (#2383). Placed in the Carburant (Fuel) app-bar only —
/// the Trajets section has no per-vehicle confidence context.
///
/// Renders a compact [ConfidenceTierBadge] that reads the same active-vehicle
/// calibration data as the stats card but wraps it as an app-bar action:
/// the badge's Tooltip already carries the ±range detail, so no extra
/// surrounding widget is needed.
///
/// In Developer mode ([Feature.debugMode]) the raw η_v [_DebugEtaChip]
/// appears immediately after the badge, preserving the #2262 decision that
/// non-debug users never see raw η_v values.
///
/// When the active vehicle has no calibration data (null
/// [volumetricEfficiencySamples]) the widget renders nothing — the badge only
/// makes sense once there is something to convey about calibration state.
class FuelConfidenceAppBarBadge extends ConsumerWidget {
  const FuelConfidenceAppBarBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeVehicle = ref.watch(activeVehicleProfileProvider);
    final samples = activeVehicle?.volumetricEfficiencySamples;
    if (samples == null) return const SizedBox.shrink();

    final showDebug =
        ref.watch(enabledFeaturesProvider).contains(Feature.debugMode);
    final eta = activeVehicle?.volumetricEfficiency ?? 0.85;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Wrap in a Padding so the badge doesn't press against neighbouring
        // action icons in the AppBar's action row.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ConfidenceTierBadge(
            samples: samples,
            // hasGpsPlusObd2Trip defaults true — consistent with the stats
            // card's FuelTab call-site which also defaults to true (#2383).
            hasGpsPlusObd2Trip: true,
          ),
        ),
        if (showDebug) _DebugEtaChip(eta: eta, samples: samples),
      ],
    );
  }
}

/// Engineer-detail η_v chip shown ONLY in Developer / debug mode (#2262).
/// Compact replica of [_CalibrationChip] from `consumption_stats_card.dart`,
/// extracted here so it can ride alongside the confidence badge in the
/// app-bar without coupling to the card's private class.
class _DebugEtaChip extends StatelessWidget {
  final double eta;
  final int samples;

  const _DebugEtaChip({required this.eta, required this.samples});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final etaStr = eta.toStringAsFixed(2);
    final label = samples == 0
        ? (l?.calibrationLearnerStatusNoSamples ?? 'η_v: ?? — no plein-complet yet')
        : (l?.calibrationLearnerEtaCompact(etaStr, samples) ??
            'η_v: $etaStr · $samples samples');
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
