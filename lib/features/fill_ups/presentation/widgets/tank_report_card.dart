// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/unit_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/services/tank_report.dart';
import '../../providers/tank_report_provider.dart';
import '../../../../core/error/guarded.dart';

/// Per-tank insight card on the Carburant tab (#3616).
///
/// Renders the latest CLOSED plein-to-plein window: the tank's true pump
/// L/100 km, the delta vs the previous tank, the recorded-coverage bar,
/// up to three behavior deltas that might EXPLAIN the change (with the
/// partial-coverage caveat whenever recordings tell an incomplete
/// story), and the residual gap between recorded estimates and pump
/// truth. Hidden entirely until a first window closes — no skeleton, the
/// stats card above already owns the "not enough data" narrative.
class TankReportCard extends ConsumerWidget {
  const TankReportCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Shell-safety (#2163 idiom): since #3648 this card renders on the
    // Trajets tab, whose harnesses don't all wire the fill-up/Hive
    // graph. The card's contract is already "render nothing until a
    // window closes" — an unwired provider is the same nothing.
    final report = guard(
      () => ref.watch(tankReportProvider),
      where: 'TankReportCard: tank report watch failed',
      fallback: null,
    );
    final latest = report?.latest;
    if (report == null || latest == null) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final evolution = report.evolution;
    final behavior = report.latestBehavior;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_gas_station,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(l.tankReportTitle,
                      style: theme.textTheme.titleMedium),
                ),
                Text(
                  l.tankReportHeadline(UnitFormatter.formatDecimal(latest.lPer100Km)),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _TrendLine(evolution: evolution, l: l),
            const SizedBox(height: 4),
            Text(
              l.tankReportSincePrevious(
                UnitFormatter.formatDecimal(latest.distanceKm, fractionDigits: 0),
                UnitFormatter.formatDecimal(latest.liters),
                PriceFormatter.formatTotal(latest.pumpedCost),
              ),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            _CoverageBar(behavior: behavior, l: l),
            if (behavior.recordedLPer100Km != null) ...[
              const SizedBox(height: 4),
              Text(
                l.tankReportRecordedAvg(
                    UnitFormatter.formatDecimal(behavior.recordedLPer100Km!)),
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (evolution != null &&
                evolution.explanations.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(l.tankReportExplainHeader,
                  style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              for (final e in evolution.explanations.take(3))
                _FactorLine(explanation: e, l: l),
              if (evolution.needsCoverageCaveat) ...[
                const SizedBox(height: 4),
                Text(
                  l.tankReportCaveat,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ],
            if (report.calibration != null) ...[
              const SizedBox(height: 12),
              _CalibrationLine(calibration: report.calibration!, l: l),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrendLine extends StatelessWidget {
  const _TrendLine({required this.evolution, required this.l});

  final TankEvolution? evolution;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final evo = evolution;
    if (evo == null) {
      return Text(l.tankReportNoPrevious,
          style: theme.textTheme.bodySmall);
    }
    final delta = evo.deltaLPer100Km;
    // ±0.2 L/100 km is pump-meter noise, not a trend.
    final flat = delta.abs() < 0.2;
    final up = delta > 0;
    final color = flat
        ? theme.colorScheme.outline
        : up
            ? theme.colorScheme.error
            : Colors.green.shade700;
    final text = flat
        ? l.tankReportTrendFlat
        : up
            ? l.tankReportTrendUp(UnitFormatter.formatDecimal(delta.abs()))
            : l.tankReportTrendDown(UnitFormatter.formatDecimal(delta.abs()));
    return Row(
      children: [
        Icon(
          flat
              ? Icons.trending_flat
              : up
                  ? Icons.trending_up
                  : Icons.trending_down,
          size: 18,
          color: color,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: theme.textTheme.bodyMedium?.copyWith(color: color)),
        ),
      ],
    );
  }
}

class _CoverageBar extends StatelessWidget {
  const _CoverageBar({required this.behavior, required this.l});

  final TankBehavior behavior;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = (behavior.coverageShare * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: behavior.coverageShare,
            minHeight: 4,
            backgroundColor:
                theme.colorScheme.surfaceContainerHighest,
          ),
        ),
        const SizedBox(height: 4),
        Text(l.tankReportCoverage('$pct'),
            style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _FactorLine extends StatelessWidget {
  const _FactorLine({required this.explanation, required this.l});

  final TankExplanation explanation;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String pctOf(double share) => (share * 100).round().toString();
    final (icon, text) = switch (explanation.factor) {
      TankFactor.highRpm => (
          Icons.speed,
          l.tankReportFactorHighRpm(
              pctOf(explanation.current), pctOf(explanation.previous)),
        ),
      TankFactor.harshEvents => (
          Icons.warning_amber_outlined,
          l.tankReportFactorHarsh(UnitFormatter.formatDecimal(explanation.current),
              UnitFormatter.formatDecimal(explanation.previous)),
        ),
      TankFactor.coldStarts => (
          Icons.ac_unit,
          l.tankReportFactorColdStarts(
              UnitFormatter.formatDecimal(explanation.current, fractionDigits: 0),
              UnitFormatter.formatDecimal(explanation.previous, fractionDigits: 0)),
        ),
      TankFactor.idle => (
          Icons.hourglass_bottom,
          l.tankReportFactorIdle(
              pctOf(explanation.current), pctOf(explanation.previous)),
        ),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.outline),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}

class _CalibrationLine extends StatelessWidget {
  const _CalibrationLine({required this.calibration, required this.l});

  final PumpCalibration calibration;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gap = calibration.gapPct;
    // A residual under 3% means the η_v learner (#815) has the estimator
    // effectively on pump truth — nothing worth a line.
    if (gap.abs() < 3) return const SizedBox.shrink();
    final text = gap > 0
        ? l.tankReportCalibrationUnder(
            UnitFormatter.formatDecimal(gap.abs(), fractionDigits: 0))
        : l.tankReportCalibrationOver(
            UnitFormatter.formatDecimal(gap.abs(), fractionDigits: 0));
    return Row(
      children: [
        Icon(Icons.tune, size: 16, color: theme.colorScheme.outline),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
      ],
    );
  }
}
