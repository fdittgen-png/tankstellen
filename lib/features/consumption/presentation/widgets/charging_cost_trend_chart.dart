// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:flutter/material.dart';
// `intl` also exports a `TextDirection`; hide it so the painter keeps using
// the dart:ui/material one (with `.ltr`).
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/widgets/charts/monthly_bar_chart_base.dart';
import '../../../../l10n/app_localizations.dart';

/// Monthly-total charging-cost bar chart (#582 phase 3).
///
/// The paint routine lives in the shared [MonthlyBarChartPainter] base
/// (the same base the carbon dashboard uses): one bar per month, short
/// month label below, max-value reference line up top. No chart
/// library — stays consistent with `price_chart.dart` /
/// `monthly_bar_chart.dart`.
///
/// Empty-state: when every month is 0, renders a centred
/// "Not enough data yet" caption so the section still feels
/// intentional instead of blank.
class ChargingCostTrendChart extends StatelessWidget {
  /// Month-start → total-EUR-for-that-month. Oldest key first; six
  /// entries is the usual case (the provider always pads missing
  /// months with 0.0 for continuity).
  final Map<DateTime, double> monthlyCost;

  /// Bar fill. Defaults to `theme.colorScheme.primary` via
  /// [ColorScheme.primary] — caller can override for tests.
  final Color? color;

  const ChargingCostTrendChart({
    super.key,
    required this.monthlyCost,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final effective = color ?? theme.colorScheme.primary;
    final entries = monthlyCost.entries.toList(growable: false)
      ..sort((a, b) => a.key.compareTo(b.key));
    final hasAnyValue = entries.any((e) => e.value > 0);
    if (entries.isEmpty || !hasAnyValue) {
      return SizedBox(
        height: 140,
        child: Center(
          child: Text(
            l.chargingChartsEmpty,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    // Month-axis labels are locale DATA, not a translatable string: resolve
    // the active locale's short-month names via intl (matches price_chart.dart's
    // `DateFormat.Md(locale)` pattern). #2971.
    final locale = Localizations.localeOf(context).toString();
    return SizedBox(
      height: 160,
      child: CustomPaint(
        painter: _CostTrendPainter(
          entries: entries,
          color: effective,
          labelColor: theme.colorScheme.onSurface,
          monthFormat: DateFormat.MMM(locale),
        ),
        size: Size.infinite,
      ),
    );
  }
}

/// Charging-facing shim over the shared [MonthlyBarChartPainter]: maps
/// the month→EUR entries onto the base's primitives. Kept as its own
/// type (name matched by widget tests).
class _CostTrendPainter extends MonthlyBarChartPainter {
  _CostTrendPainter({
    required List<MapEntry<DateTime, double>> entries,
    required super.color,
    required super.labelColor,
    required super.monthFormat,
  }) : super(
          values: entries.map((e) => e.value).toList(growable: false),
          months: entries.map((e) => e.key).toList(growable: false),
          maxLabel:
              '€${entries.map((e) => e.value).reduce(math.max).toStringAsFixed(0)}',
          barWidthFactor: 0.55,
          bottomInset: 22,
        );
}
