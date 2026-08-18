// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:tankstellen/core/widgets/charts/monthly_bar_chart_base.dart';

void main() {
  setUpAll(() => initializeDateFormatting('en'));

  group('MonthlyBarChartPainter', () {
    final months = [
      DateTime(2026, 1),
      DateTime(2026, 2),
      DateTime(2026, 3),
    ];

    MonthlyBarChartPainter painter({
      List<double> values = const [10, 20, 30],
      List<List<BarSegment>>? stacks,
    }) {
      return MonthlyBarChartPainter(
        values: values,
        months: months,
        color: Colors.teal,
        maxLabel: '30 kg',
        labelColor: Colors.black,
        monthFormat: DateFormat.MMM('en'),
        stacks: stacks,
      );
    }

    Future<void> pumpPainter(
      WidgetTester tester,
      MonthlyBarChartPainter p,
    ) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 180,
              width: 320,
              child: CustomPaint(painter: p, size: Size.infinite),
            ),
          ),
        ),
      );
    }

    testWidgets('paints solid bars without throwing', (tester) async {
      await pumpPainter(tester, painter());
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('paints stacked segments (#3691) without throwing',
        (tester) async {
      await pumpPainter(
        tester,
        painter(
          stacks: const [
            [BarSegment(value: 6, color: Colors.teal)],
            [
              BarSegment(value: 15, color: Colors.teal),
              BarSegment(value: 5, color: Colors.orange),
            ],
            [BarSegment(value: 30, color: Colors.teal)],
          ],
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('all-zero values do not divide by zero', (tester) async {
      await pumpPainter(tester, painter(values: const [0, 0, 0]));
      expect(tester.takeException(), isNull);
    });

    test('shouldRepaint fires on changed values, not on identical config',
        () {
      final a = painter(values: [10, 20, 30]);
      final b = painter(values: [10, 20, 30]);
      // Fresh list instances → identity differs → repaint (same as the
      // old hand-rolled painters' behaviour on rebuild).
      expect(a.shouldRepaint(b), isTrue);
      expect(a.shouldRepaint(a), isFalse);
    });
  });
}
