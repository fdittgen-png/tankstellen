// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../core/theme/dark_mode_colors.dart';

/// The metric table of `MonthlyInsightsCard` (#3904) — split out of the
/// card so each file stays well under the 400-line guard. Only the card
/// builds it; the types are public for that one caller.

/// Sentiment band for the trailing delta arrow. `neutral` means the
/// arrow is rendered grey regardless of direction (more activity is
/// not inherently good/bad). `lowerIsBetter` is for fuel — down green,
/// up red.
enum MonthlyMetricSentiment { neutral, lowerIsBetter }

/// One labelled metric of the card: the label, the current value, the
/// previous value (shown when [showPrevious] is true) and the delta that
/// drives the trailing arrow. Pure data — [MonthlyMetricsTable] renders the
/// whole list so the value columns line up across rows.
class MonthlyMetric {
  final String label;
  final String currentValue;
  final String previousValue;
  final num delta;
  final MonthlyMetricSentiment sentiment;
  final bool showPrevious;

  const MonthlyMetric({
    required this.label,
    required this.currentValue,
    required this.previousValue,
    required this.delta,
    required this.sentiment,
    required this.showPrevious,
  });
}

/// Width reserved for the trailing delta-arrow column.
const double _arrowColumnWidth = 20;

/// Gap between the label / value / arrow columns.
const double _columnGap = 8;

/// The metric rows of [MonthlyInsightsCard] as ONE table (#3904).
///
/// The old layout gave every row a `Row` of fixed-flex `Expanded`
/// cells (label 3 : current 2 : previous 2), so a value such as
/// "10,1 L/100 km" received ~⅔ of the label's width and wrapped its unit
/// onto a second line as soon as the card got narrow. Here the two value
/// columns are [IntrinsicColumnWidth] — they take exactly the space their
/// widest figure needs — and the label column is the [FlexColumnWidth]
/// remainder, so the LABEL shrinks first (it wraps onto a second line,
/// then ellipsises). A value never wraps: it is `softWrap: false`, and in
/// the last resort (a 320 dp phone at a 1.3× font setting) it scales
/// down inside its cell rather than breaking — see [_ValueCell].
///
/// Column alignment is why this is a `Table` and not per-row `Row`s:
/// tabular figures only line up when every row shares the same column
/// widths. The previous-value + arrow columns are omitted entirely when
/// the comparison is not reliable, so the current value hugs the edge.
class MonthlyMetricsTable extends StatelessWidget {
  final List<MonthlyMetric> metrics;
  final bool showPreviousColumn;

  const MonthlyMetricsTable({
    super.key,
    required this.metrics,
    required this.showPreviousColumn,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final currentStyle = theme.textTheme.titleMedium?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final previousStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Table(
      key: const ValueKey('monthly_insights_table'),
      columnWidths: <int, TableColumnWidth>{
        0: const FlexColumnWidth(),
        1: const IntrinsicColumnWidth(),
        if (showPreviousColumn) 2: const IntrinsicColumnWidth(),
        if (showPreviousColumn) 3: const FixedColumnWidth(_arrowColumnWidth),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        for (final m in metrics)
          TableRow(
            children: [
              _cell(
                Text(
                  m.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: labelStyle,
                ),
              ),
              _cell(
                _ValueCell(text: m.currentValue, style: currentStyle),
                leading: _columnGap,
              ),
              if (showPreviousColumn)
                _cell(
                  m.showPrevious
                      ? _ValueCell(text: m.previousValue, style: previousStyle)
                      : const SizedBox.shrink(),
                  leading: _columnGap,
                ),
              if (showPreviousColumn)
                _cell(
                  m.showPrevious
                      ? _DeltaArrow(delta: m.delta, sentiment: m.sentiment)
                      : const SizedBox.shrink(),
                  leading: _columnGap / 2,
                ),
            ],
          ),
      ],
    );
  }

  /// Vertical rhythm between rows (3 + 3 = the old 6 dp `SizedBox`) plus
  /// the inter-column gap on the leading edge.
  static Widget _cell(Widget child, {double leading = 0}) => Padding(
        padding: EdgeInsets.only(left: leading, top: 3, bottom: 3),
        child: child,
      );
}

/// A single-line, right-aligned figure that never wraps.
///
/// Wrapped in a [FittedBox] (`scaleDown`) behind [_ShrinkableCell] so the
/// table may — as a last resort, once the label column has already
/// shrunk to its longest word — give the column less than the figure's
/// natural width, in which case the figure scales down a little instead
/// of breaking "L/100 km" onto its own line.
class _ValueCell extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const _ValueCell({required this.text, required this.style});

  @override
  Widget build(BuildContext context) {
    return _ShrinkableCell(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Text(
          text,
          softWrap: false,
          maxLines: 1,
          textAlign: TextAlign.end,
          style: style,
        ),
      ),
    );
  }
}

/// Reports a ZERO minimum intrinsic width while keeping the child's
/// natural maximum, so an [IntrinsicColumnWidth] column still asks for
/// the figure's full width but the table is allowed to shrink it below
/// that when there is genuinely no room (see [MonthlyMetricsTable]). Without
/// this the table would keep the column at the figure's longest fragment
/// and paint past its own right edge instead.
class _ShrinkableCell extends SingleChildRenderObjectWidget {
  const _ShrinkableCell({required Widget super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderShrinkableCell();
}

class _RenderShrinkableCell extends RenderProxyBox {
  @override
  double computeMinIntrinsicWidth(double height) => 0;
}

/// The trailing arrow on a metric row. Hidden when the displayed
/// values are equal (delta == 0). Colour follows [sentiment]:
///   * `neutral`   → grey, both directions
///   * `lowerIsBetter` → up = error, down = primary
class _DeltaArrow extends StatelessWidget {
  final num delta;
  final MonthlyMetricSentiment sentiment;

  const _DeltaArrow({required this.delta, required this.sentiment});

  @override
  Widget build(BuildContext context) {
    if (delta == 0) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final up = delta > 0;
    final color = switch (sentiment) {
      MonthlyMetricSentiment.neutral => theme.colorScheme.onSurfaceVariant,
      MonthlyMetricSentiment.lowerIsBetter =>
        up ? theme.colorScheme.error : DarkModeColors.success(context),
    };
    return Icon(
      up ? Icons.arrow_upward : Icons.arrow_downward,
      size: 16,
      color: color,
    );
  }
}
