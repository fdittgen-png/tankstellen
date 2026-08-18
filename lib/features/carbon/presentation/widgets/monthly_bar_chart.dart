// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:flutter/material.dart';
// `intl` also exports a `TextDirection`; hide it so the painter keeps using
// the dart:ui/material one (with `.ltr`).
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/widgets/charts/monthly_bar_chart_base.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/monthly_summary.dart';

// The stacked-segment value type moved to the shared chart base;
// re-exported so existing callers keep resolving `BarSegment`.
export '../../../../core/widgets/charts/monthly_bar_chart_base.dart'
    show BarSegment;

/// Carbon-dashboard monthly bar chart. The paint routine lives in the
/// shared [MonthlyBarChartPainter] base (no external chart library,
/// pure paint operations); this file only extracts the values from the
/// [MonthlySummary] list and owns the empty state.
class MonthlyBarChart extends StatelessWidget {
  /// The summaries to render, oldest first.
  final List<MonthlySummary> summaries;

  /// How to extract the numeric value from a summary (e.g. cost, co2).
  final double Function(MonthlySummary) valueOf;

  /// Bar fill color.
  final Color color;

  /// Unit suffix shown on the max-value label (e.g. "€", "kg").
  final String unitLabel;

  /// Optional per-bar stacked segments (#3691), aligned with
  /// [summaries]. When provided, bar i renders its segments bottom-up
  /// instead of one solid [color] — the additive per-fuel breakdown.
  /// [valueOf] still scales the axis, so segments should sum to it.
  final List<List<BarSegment>>? stacks;

  const MonthlyBarChart({
    super.key,
    required this.summaries,
    required this.valueOf,
    required this.color,
    required this.unitLabel,
    this.stacks,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    if (summaries.isEmpty) {
      final l = AppLocalizations.of(context);
      return SizedBox(
        height: 180,
        child: Center(child: Text(l.noDataAvailable)),
      );
    }
    // Month-axis labels are locale DATA, not a translatable string: resolve
    // the active locale's short-month names via intl (matches price_chart.dart's
    // `DateFormat.Md(locale)` pattern). #2971.
    final locale = Localizations.localeOf(context).toString();
    return SizedBox(
      height: 180,
      child: CustomPaint(
        painter: _CarbonBarChartPainter(
          summaries: summaries,
          valueOf: valueOf,
          color: color,
          unitLabel: unitLabel,
          labelColor: onSurface,
          monthFormat: DateFormat.MMM(locale),
          stacks: stacks,
        ),
        size: Size.infinite,
      ),
    );
  }
}

/// Carbon-facing shim over the shared [MonthlyBarChartPainter]: maps
/// [MonthlySummary] + [valueOf] + [unitLabel] onto the base's
/// primitives. Kept as its own type (name matched by widget tests) and
/// keeps [summaries]/[unitLabel] as public fields for introspection.
class _CarbonBarChartPainter extends MonthlyBarChartPainter {
  final List<MonthlySummary> summaries;
  final String unitLabel;

  _CarbonBarChartPainter({
    required this.summaries,
    required double Function(MonthlySummary) valueOf,
    required super.color,
    required this.unitLabel,
    required super.labelColor,
    required super.monthFormat,
    super.stacks,
  }) : super(
          values: summaries.map(valueOf).toList(growable: false),
          months: summaries
              .map((s) => s.month)
              .toList(growable: false),
          maxLabel: '${summaries.map(valueOf).reduce(math.max).toStringAsFixed(0)} $unitLabel',
        );
}
