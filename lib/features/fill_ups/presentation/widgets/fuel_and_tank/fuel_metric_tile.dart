// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/providers/consumption_display_provider.dart';
import '../../../../../core/theme/app_text.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../core/utils/price_formatter.dart';
import '../../../../../core/utils/unit_formatter.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/services/fuel_and_tank_view.dart';
import 'fuel_and_tank_labels.dart';

/// Which quantity a [MetricView] measures — decides only its format.
enum FuelMetricKind { consumption, costPerKm, range, co2e }

/// Number formatting for the Fuel & Tank surface (#4278): the locale-aware
/// app formatters, never `toStringAsFixed` (#3743).
abstract final class FuelAndTankFormat {
  static String value(
    AppLocalizations l,
    FuelMetricKind kind,
    double v,
    ConsumptionDisplay display,
  ) =>
      switch (kind) {
        FuelMetricKind.consumption =>
          UnitFormatter.formatConsumptionLocalized(v, display.unit),
        FuelMetricKind.costPerKm => costPerKm(l, v),
        FuelMetricKind.range =>
          UnitFormatter.formatDistance(v, fractionDigits: 0),
        FuelMetricKind.co2e => co2eGrams(l, v),
      };

  static String costPerKm(AppLocalizations l, double v) =>
      l.fuelAndTankCostPerKmValue(
          PriceFormatter.formatPerKm(v), PriceFormatter.currency);

  /// kg CO2e per km, shown in grams.
  static String co2eGrams(AppLocalizations l, double kgPerKm) =>
      l.fuelAndTankCo2eValue(gramsFigure(kgPerKm));

  static String gramsFigure(double kgPerKm) =>
      UnitFormatter.formatDecimal(kgPerKm * 1000, fractionDigits: 0);

  /// The 95 % interval, low end first in the DISPLAYED unit (a reciprocal
  /// consumption unit such as mpg flips the order).
  static String? interval(AppLocalizations l, FuelMetricKind kind,
      MetricView m, ConsumptionDisplay display) {
    final bounds = m.interval;
    if (bounds == null) return null;
    var (lo, hi) = bounds;
    if (kind == FuelMetricKind.consumption && display.unit.isReciprocal) {
      (lo, hi) = (hi, lo);
    }
    return l.fuelAndTankInterval(
        value(l, kind, lo, display), value(l, kind, hi, display));
  }

  /// "Measured · 5 samples · medium confidence".
  static String evidence(AppLocalizations l, MetricView m) => [
        if (m.provenance case final ProvenanceKind p)
          FuelAndTankLabels.provenance(l, p),
        l.fuelAndTankSampleCount(m.metric.sampleCount),
        if (m.confidence case final c?) FuelAndTankLabels.confidence(l, c),
      ].join(' · ');
}

/// One figure: its label, its value (or "not enough evidence yet" with
/// the reason — never a number) and the evidence it rests on.
class FuelMetricTile extends ConsumerWidget {
  const FuelMetricTile({
    super.key,
    required this.label,
    required this.kind,
    required this.metric,
  });

  final String label;
  final FuelMetricKind kind;
  final MetricView metric;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final display = ref.watch(consumptionDisplaySettingProvider);
    final value = metric.metric.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.label(context)),
        const SizedBox(height: Spacing.xs),
        if (value != null) ...[
          Text(
            FuelAndTankFormat.value(l, kind, value, display),
            style: AppText.body(context),
          ),
          Text(FuelAndTankFormat.evidence(l, metric),
              style: AppText.label(context)),
        ] else ...[
          Text(l.fuelAndTankNotEnoughEvidence, style: AppText.body(context)),
          Text(
            FuelAndTankLabels.insufficient(
                l, metric.metric.insufficientReason),
            style: AppText.label(context),
          ),
        ],
      ],
    );
  }
}
