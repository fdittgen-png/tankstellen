// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/theme/app_motion.dart';
import '../../../../core/widgets/charts/monthly_line_chart_base.dart';
import '../../../../l10n/app_localizations.dart';

/// The consumption report's single evolution chart (#4175).
///
/// A line with a soft area beneath it, drawn by the shared
/// [MonthlyLineChartPainter] — the sibling of the bar painter the
/// carbon dashboard uses, and like it a plain `CustomPaint`. The repo
/// carries no chart library and this did not change that: a dependency
/// whose only job is to draw a polyline would be a dependency for a
/// polyline.
///
/// Animates its reveal so switching metric reads as the chart redrawing
/// rather than as a hard cut. The reveal is VERTICAL only — the axis
/// and the month labels never move, because a chart whose axis animates
/// is one the eye has to re-read on every frame.
class MonthlyMetricChart extends StatefulWidget {
  const MonthlyMetricChart({
    super.key,
    required this.values,
    required this.months,
    required this.color,
    required this.maxLabel,
  });

  /// PRIMITIVES, not a `MonthlySummary`. The obvious shape was to mirror
  /// [MonthlyBarChart] and take the carbon feature's summary type with a
  /// `valueOf` extractor — and that added a third `fill_ups → carbon`
  /// edge to a cross-feature graph whose baseline only decreases
  /// (#3132). A chart that draws a polyline has no business knowing what
  /// a monthly carbon summary is; the caller already holds both lists.
  final List<double> values;

  /// Month timestamps aligned with [values], oldest first.
  final List<DateTime> months;

  /// Line colour; the area beneath fades it out to nothing.
  final Color color;

  /// Prebuilt max-value label shown top-right (e.g. `42 L`).
  final String maxLabel;

  @override
  State<MonthlyMetricChart> createState() => _MonthlyMetricChartState();
}

class _MonthlyMetricChartState extends State<MonthlyMetricChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reveal;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _reveal = AnimationController(
      vsync: this,
      duration: AppMotion.selection,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // #3948's contract: when the OS asks for reduced motion, render the
    // END STATE rather than running a shorter tween. A decorative
    // reveal is exactly the kind of animation that setting is about.
    if (AppMotion.enabled(context)) {
      unawaited(_reveal.forward());
    } else {
      _reveal.value = 1;
    }
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.values.isEmpty) {
      final l = AppLocalizations.of(context);
      return Center(child: Text(l.noDataAvailable));
    }
    // Month-axis labels are locale DATA, not a translatable string:
    // resolve the active locale's short-month names via intl (#2971).
    final locale = Localizations.localeOf(context).toString();
    return AnimatedBuilder(
      animation: _reveal,
      builder: (context, _) => CustomPaint(
        painter: MonthlyLineChartPainter(
          values: widget.values,
          months: widget.months,
          color: widget.color,
          maxLabel: widget.maxLabel,
          labelColor: theme.colorScheme.onSurface,
          // The panel this is drawn on, so the data dots read as rings
          // in every theme instead of a hard-coded white core.
          surfaceColor: theme.colorScheme.surfaceContainerHighest,
          monthFormat: DateFormat.MMM(locale),
          progress: Curves.easeOutCubic.transform(_reveal.value),
        ),
        size: Size.infinite,
      ),
    );
  }
}
