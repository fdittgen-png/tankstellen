// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/vehicle_profile.dart';
import '../../../../core/error/guarded.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../vehicle/api.dart';

/// Engineer-detail pill on the Fuel tab's consumption card surfacing the
/// pump-anchored fuel gain (#3901, Epic #3886 / ADR 0020) — the
/// calibration that replaced the deleted η_v learner. Reads the active
/// vehicle's `pumpGain` / `pumpGainSamples`; the card itself stays
/// vehicle-agnostic.
///
/// Two states:
///   * `pumpGainSamples == 0` → "Not pump-calibrated yet" (neutral);
///   * `> 0` → "Pump-calibrated · N fill-ups · ±x %" where x is the
///     gain's distance from 1.0 in percent, rounded.
///
/// Styled like [ConfidenceTierBadge] (#2112) so the two land as one
/// harmonised group.
class PumpGainChip extends ConsumerWidget {
  const PumpGainChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The vehicle providers reach storage; an unwired test scope must
    // read as "not calibrated", never crash the card.
    final profile = guard(
      () => ref.watch(activeVehicleProfileProvider),
      where: 'PumpGainChip: active vehicle lookup failed',
      fallback: null as VehicleProfile?,
    );
    return PumpGainChipView(
      pumpGain: profile?.pumpGain ?? 1.0,
      samples: profile?.pumpGainSamples ?? 0,
    );
  }
}

/// The pure, provider-free rendering of [PumpGainChip].
class PumpGainChipView extends StatelessWidget {
  final double pumpGain;
  final int samples;

  const PumpGainChipView({
    super.key,
    required this.pumpGain,
    required this.samples,
  });

  /// |1 − gain| in whole percent — how far the pump pulled the estimate.
  static int correctionPercent(double pumpGain) =>
      ((1 - pumpGain).abs() * 100).round();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final label = samples == 0
        ? l.pumpGainChipNotCalibrated
        : l.pumpGainChipCalibrated(samples, correctionPercent(pumpGain));
    return Container(
      key: const Key('pumpGainChip'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: AppRadius.lg,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
