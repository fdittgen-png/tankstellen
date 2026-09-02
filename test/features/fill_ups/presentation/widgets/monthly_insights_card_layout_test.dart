// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3904 — the month card's value columns never wrap. The old fixed-flex
// rows squeezed "10,1 L/100 km" into ~⅔ of the label's width and broke
// the unit onto a second line; the card is now ONE table whose value
// columns take their intrinsic width, the label giving way first.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/fill_ups/domain/services/monthly_insights_aggregator.dart';
import 'package:tankstellen/features/fill_ups/presentation/widgets/monthly_insights_card.dart';

import '../../../../helpers/pump_app.dart';

const _summary = MonthlyInsightsSummary(
  currentMonthTripCount: 3,
  previousMonthTripCount: 97,
  currentMonthDriveTime: Duration(hours: 1, minutes: 19),
  previousMonthDriveTime: Duration(hours: 22, minutes: 25),
  currentMonthDistanceKm: 48.0,
  previousMonthDistanceKm: 1039.0,
  currentMonthAvgConsumptionLPer100km: 10.1,
  previousMonthAvgConsumptionLPer100km: 10.6,
  isComparisonReliable: true,
);

/// Every figure the card renders for [_summary].
const _values = <String>[
  '3',
  '97',
  '1h 19',
  '22h 25',
  '48 km',
  '1039 km',
  '10,1 L/100 km',
  '10,6 L/100 km',
];

/// The cell that owns a figure: the `FittedBox` right above its `Text`.
Finder _cellOf(String value) =>
    find.ancestor(of: find.text(value), matching: find.byType(FittedBox));

/// A figure occupies one line when its cell is no taller than the
/// paragraph's own single-line height.
void expectSingleLine(WidgetTester tester, String value) {
  final paragraph = tester.renderObject<RenderParagraph>(find.text(value));
  final oneLine = paragraph.getMaxIntrinsicHeight(double.infinity);
  final cell = tester.getSize(_cellOf(value));
  expect(cell.height, lessThanOrEqualTo(oneLine + 0.01),
      reason: '"$value" wrapped onto a second line');
}

void main() {
  testWidgets(
      'en_XA at 320 dp + 1.3x text scale: no overflow, no figure wraps',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpApp(
      tester,
      const MonthlyInsightsCard(summary: _summary),
      locale: const Locale('en', 'XA'),
    );

    expect(tester.takeException(), isNull,
        reason: 'the card overflows at 320 dp under the pseudo-locale');
    expect(find.byKey(const ValueKey('monthly_insights_table')),
        findsOneWidget);
    for (final v in _values) {
      expectSingleLine(tester, v);
    }
    // The label is the column that gives way: it may wrap (two lines)
    // and then ellipsise — never the figures.
    final labels = tester
        .widgetList<Text>(find.descendant(
          of: find.byType(Table),
          matching: find.byType(Text),
        ))
        .where((t) => !_values.contains(t.data));
    expect(labels, isNotEmpty);
    for (final label in labels) {
      expect(label.maxLines, 2);
      expect(label.overflow, TextOverflow.ellipsis);
    }
  });

  testWidgets('values share one column width and keep tabular figures',
      (tester) async {
    await pumpApp(tester, const MonthlyInsightsCard(summary: _summary));

    // Current-month figures all end on the same right edge; so do the
    // previous-month ones — that is what a Table buys over per-row Rows.
    final currentRight = ['3', '1h 19', '48 km', '10,1 L/100 km']
        .map((v) => tester.getRect(_cellOf(v)).right)
        .toSet();
    expect(currentRight.length, 1,
        reason: 'current-month cells share one right edge');
    final previousRight = ['97', '22h 25', '1039 km', '10,6 L/100 km']
        .map((v) => tester.getRect(_cellOf(v)).right)
        .toSet();
    expect(previousRight.length, 1,
        reason: 'previous-month cells share one right edge');
    expect(currentRight.single, lessThan(previousRight.single));

    for (final v in _values) {
      final text = tester.widget<Text>(find.text(v));
      expect(text.softWrap, isFalse);
      expect(text.style?.fontFeatures, contains(const FontFeature.tabularFigures()));
    }
  });

  testWidgets('at a comfortable width no figure is scaled down',
      (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpApp(tester, const MonthlyInsightsCard(summary: _summary));

    for (final v in _values) {
      final paragraph = tester.getSize(find.text(v));
      final cell = tester.getSize(_cellOf(v));
      expect(cell.height, moreOrLessEquals(paragraph.height, epsilon: 0.01),
          reason: '"$v" was scaled down although the column had room');
    }
  });

  testWidgets('unreliable comparison drops the previous + arrow columns',
      (tester) async {
    const unreliable = MonthlyInsightsSummary(
      currentMonthTripCount: 1,
      previousMonthTripCount: 0,
      currentMonthDriveTime: Duration(minutes: 15),
      previousMonthDriveTime: Duration.zero,
      currentMonthDistanceKm: 7.0,
      previousMonthDistanceKm: 0.0,
      currentMonthAvgConsumptionLPer100km: null,
      previousMonthAvgConsumptionLPer100km: null,
      isComparisonReliable: false,
    );
    await pumpApp(tester, const MonthlyInsightsCard(summary: unreliable));

    final table = tester.widget<Table>(find.byType(Table));
    expect(table.columnWidths?.length, 2);
    for (final row in table.children) {
      expect(row.children.length, 2);
    }
    expect(find.byIcon(Icons.arrow_upward), findsNothing);
    expect(find.byIcon(Icons.arrow_downward), findsNothing);
  });
}
