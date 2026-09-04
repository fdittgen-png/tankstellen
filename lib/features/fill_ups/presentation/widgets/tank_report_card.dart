// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/consumption_unit.dart';
import '../../../../core/providers/consumption_display_provider.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/unit_formatter.dart';
import '../../../../core/widgets/primary_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/services/tank_report.dart';
import '../../providers/tank_report_provider.dart';
import '../../../../core/domain/vehicle_profile.dart';
import '../../../../core/error/guarded.dart';
import '../../../trips/api.dart' show TripSummary, tripHistoryListProvider;
import '../../../vehicle/api.dart' show activeVehicleProfileProvider;

/// Per-tank insight card on the Trajets tab (#3616) — the tab's
/// **primary card** since #3950 (Epic #3947).
///
/// Renders the latest CLOSED plein-to-plein window in the visual
/// grammar's roles: the tank's true pump consumption as the card's ONE
/// display-role number with its unit on the same baseline, ONE delta line
/// vs the previous tank, the recorded-coverage bar with ONE sentence that
/// carries coverage + recorded average + calibration residual, up to
/// three behavior deltas that might EXPLAIN the change (with the
/// partial-coverage caveat whenever recordings tell an incomplete story),
/// and the calibration gap. Hidden entirely until a first window closes —
/// no skeleton, the stats card above already owns the "not enough data"
/// narrative.
///
/// #3904 — the recorded-trips lines speak plainly ("Your recorded trips
/// overestimate consumption by 39 %", not "estimates run 39 % over pump
/// truth"), and every consumption figure this card owns renders in the
/// app-wide consumption unit (#3889) rather than a literal `L/100 km`.
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
    // #3889 — the headline + recorded-trips figures follow the app-wide
    // consumption unit; the formatter carries the unit mask itself.
    final unit = ref.watch(consumptionDisplaySettingProvider).unit;
    final evolution = report.evolution;
    final behavior = report.latestBehavior;
    // #3918 — the recorded figure is re-expressed at the active vehicle's
    // CURRENT gain (display only), with the residual that remains after
    // that calibration; the stored `TankBehavior` figure is the fallback
    // when the trip/vehicle graph is not wired (test scopes).
    final calibrated = guard(
      () {
        final VehicleProfile? vehicle = ref.watch(activeVehicleProfileProvider);
        final summaries = <String, TripSummary>{
          for (final t in ref.watch(tripHistoryListProvider)) t.id: t.summary,
        };
        return calibratedTankRecording(latest, summaries, vehicle);
      },
      where: 'TankReportCard: calibrated recording failed',
      fallback: null,
    );
    final recordedLPer100Km =
        calibrated?.recordedLPer100Km ?? behavior.recordedLPer100Km;

    return PrimaryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_gas_station, color: theme.colorScheme.primary),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Text(l.tankReportTitle, style: AppText.title(context)),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          // #3950 — the ONE display number: the pump consumption, with
          // the unit mask on the same alphabetic baseline.
          _Headline(lPer100Km: latest.lPer100Km, unit: unit),
          const SizedBox(height: Spacing.md),
          _TrendLine(evolution: evolution, l: l),
          const SizedBox(height: Spacing.sm),
          Text(
            l.tankReportSincePrevious(
              UnitFormatter.formatDecimal(latest.distanceKm, fractionDigits: 0),
              UnitFormatter.formatDecimal(latest.liters),
              PriceFormatter.formatTotal(latest.pumpedCost),
            ),
            style: AppText.label(context),
          ),
          const SizedBox(height: Spacing.lg),
          _CoverageBar(
            behavior: behavior,
            recordedValue: recordedLPer100Km == null
                ? null
                : UnitFormatter.formatConsumptionLocalized(
                    recordedLPer100Km, unit),
            residual: calibrated == null
                ? null
                : _signedPercent(calibrated.residualPct),
            l: l,
          ),
          if (evolution != null &&
              evolution.explanations.isNotEmpty) ...[
            const SizedBox(height: Spacing.lg),
            Text(l.tankReportExplainHeader, style: AppText.label(context)),
            const SizedBox(height: Spacing.sm),
            for (final e in evolution.explanations.take(3))
              _FactorLine(explanation: e, l: l),
            if (evolution.needsCoverageCaveat) ...[
              const SizedBox(height: Spacing.sm),
              Text(
                l.tankReportCaveat,
                style: AppText.label(context).copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ],
          if (report.calibration != null) ...[
            const SizedBox(height: Spacing.lg),
            _CalibrationLine(calibration: report.calibration!, l: l),
          ],
        ],
      ),
    );
  }
}

/// `+3` / `-12` — the residual's sign is the information (#3918).
String _signedPercent(double pct) {
  final rounded = pct.round();
  return rounded > 0 ? '+$rounded' : '$rounded';
}

/// The display-role number + its unit mask, baseline-aligned (#3950).
/// The figure is converted into the user's consumption unit the same way
/// `UnitFormatter.formatConsumptionLocalized` does, but split so the unit
/// can take the label-derived [AppText.unit] role beside the number.
class _Headline extends StatelessWidget {
  const _Headline({required this.lPer100Km, required this.unit});

  final double lPer100Km;
  final ConsumptionUnit unit;

  @override
  Widget build(BuildContext context) {
    final converted = unit.fromLPer100Km(lPer100Km);
    // The number and its unit never wrap or overflow: as a last resort
    // (a 320 dp phone at a large font setting) the pair scales down
    // together, keeping the one baseline.
    return Align(
      alignment: Alignment.centerLeft,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              UnitFormatter.formatDecimal(
                converted,
                fractionDigits: unit.fractionDigits,
              ),
              key: const Key('tankReportHeadline'),
              style: AppText.display(context),
            ),
            const SizedBox(width: Spacing.sm),
            // The language-neutral unit mask (`L/100 km`, `mpg (UK)`).
            Text(
              unit.mask,
              key: const Key('tankReportHeadlineUnit'),
              style: AppText.unit(context),
            ),
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
      return Text(l.tankReportNoPrevious, style: AppText.body(context));
    }
    final delta = evo.deltaLPer100Km;
    // ±0.2 L/100 km is pump-meter noise, not a trend.
    final flat = delta.abs() < 0.2;
    final up = delta > 0;
    final color = flat
        ? theme.colorScheme.outline
        : up
            ? theme.colorScheme.error
            : DarkModeColors.success(context);
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
        const SizedBox(width: Spacing.sm + Spacing.xs),
        Expanded(
          child: Text(text, style: AppText.body(context).copyWith(color: color)),
        ),
      ],
    );
  }
}

/// The recorded-coverage bar and, under it, ONE sentence (#3950) that
/// carries the three recorded-trips facts the card used to stack as
/// three lines: the coverage share, the recorded average (in the user's
/// unit) and the signed residual after calibration. Each fact that is
/// unavailable simply drops out of the sentence.
class _CoverageBar extends StatelessWidget {
  const _CoverageBar({
    required this.behavior,
    required this.recordedValue,
    required this.residual,
    required this.l,
  });

  final TankBehavior behavior;

  /// Recorded trips' average consumption WITH its unit, or null when the
  /// recordings carry no fuel figure.
  final String? recordedValue;

  /// `+3` / `-12`, or null when no calibration residual is available.
  final String? residual;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = '${(behavior.coverageShare * 100).round()}';
    final value = recordedValue;
    final gap = residual;
    final sentence = value == null
        ? l.tankReportRecordedTripsCoverage(pct)
        : gap == null
            ? l.tankReportRecordedSummaryNoResidual(pct, value)
            : l.tankReportRecordedSummary(pct, value, gap);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: AppRadius.sm,
          child: LinearProgressIndicator(
            value: behavior.coverageShare,
            minHeight: 4,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          sentence,
          key: const Key('tankReportRecordedSummary'),
          style: AppText.body(context),
        ),
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
      padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.outline),
          const SizedBox(width: Spacing.sm + Spacing.xs),
          Expanded(child: Text(text, style: AppText.body(context))),
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
    // A residual under 3% means the pump gain (Epic #3886) has the
    // estimator effectively on pump truth — nothing worth a line.
    if (gap.abs() < 3) return const SizedBox.shrink();
    // gapPct > 0 = the pump burned MORE than the recordings claimed, i.e.
    // the recorded trips UNDER-estimate consumption (#3904 plain wording).
    final pct = UnitFormatter.formatDecimal(gap.abs(), fractionDigits: 0);
    final text = gap > 0
        ? l.tankReportRecordedTripsUnderestimate(pct)
        : l.tankReportRecordedTripsOverestimate(pct);
    return Row(
      children: [
        Icon(Icons.tune, size: 16, color: theme.colorScheme.outline),
        const SizedBox(width: Spacing.sm + Spacing.xs),
        Expanded(child: Text(text, style: AppText.body(context))),
      ],
    );
  }
}
