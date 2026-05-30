// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:tankstellen/core/utils/price_formatter.dart';
import 'package:tankstellen/features/price_history/data/models/price_record.dart';
import 'package:tankstellen/features/price_history/presentation/widgets/price_chart.dart';
import 'package:tankstellen/features/price_history/presentation/widgets/price_chart_axes.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  // Use a known country so the €/comma formatting is deterministic.
  setUp(() => PriceFormatter.setCountry('DE'));

  final threeRecords = [
    PriceRecord(
      stationId: 'test-1',
      recordedAt: DateTime(2026, 3, 25),
      diesel: 1.459,
    ),
    PriceRecord(
      stationId: 'test-1',
      recordedAt: DateTime(2026, 3, 26),
      diesel: 1.479,
    ),
    PriceRecord(
      stationId: 'test-1',
      recordedAt: DateTime(2026, 3, 27),
      diesel: 1.469,
    ),
  ];

  group('PriceChart', () {
    testWidgets('renders "No price history yet" when records is empty',
        (tester) async {
      await pumpApp(
        tester,
        const PriceChart(records: [], fuelType: FuelType.diesel),
      );

      expect(find.text('No price history yet'), findsOneWidget);
      expect(find.byType(PriceChart), findsOneWidget);
    });

    testWidgets('renders CustomPaint when records are provided',
        (tester) async {
      await pumpApp(
        tester,
        PriceChart(records: threeRecords, fuelType: FuelType.diesel),
      );

      expect(find.text('No price history yet'), findsNothing);
      expect(find.byType(PriceChart), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(PriceChart),
          matching: find.byType(CustomPaint),
        ),
        findsWidgets,
      );
    });

    testWidgets('renders with a single record without error', (tester) async {
      final records = [
        PriceRecord(
          stationId: 'test-1',
          recordedAt: DateTime(2026, 3, 27),
          diesel: 1.459,
        ),
      ];

      await pumpApp(
        tester,
        PriceChart(records: records, fuelType: FuelType.diesel),
      );

      expect(find.text('No price history yet'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(PriceChart),
          matching: find.byType(CustomPaint),
        ),
        findsWidgets,
      );
    });

    testWidgets('tapping a point reveals a tooltip with its price + date',
        (tester) async {
      // The chart consumes records newest-first (the repository contract)
      // and reverses them so the newest sits on the right.
      await pumpApp(
        tester,
        PriceChart(
          records: threeRecords.reversed.toList(),
          fuelType: FuelType.diesel,
        ),
        locale: const Locale('de'),
      );

      // No tooltip until the user interacts.
      expect(find.textContaining('·'), findsNothing);

      // Tap near the right edge → newest point (1,469 € on 27.03).
      final chart = find.byType(PriceChart);
      final box = tester.getRect(chart);
      await tester.tapAt(Offset(box.right - 4, box.center.dy));
      await tester.pumpAndSettle();

      // Tooltip shows the price and the localized date, joined by "·".
      final tooltip = find.textContaining('·');
      expect(tooltip, findsOneWidget);
      final label = tester.widget<Text>(tooltip).data!;
      expect(label, contains('1,469 €'));
      expect(
        label,
        contains(DateFormat.Md('de').format(DateTime(2026, 3, 27))),
      );
    });
  });

  group('PriceChart.pointsFor', () {
    test('orders points oldest→newest and carries date + price', () {
      // Repository hands newest-first; the chart reverses to oldest-left.
      final newestFirst = threeRecords.reversed.toList();
      final points = PriceChart.pointsFor(newestFirst, FuelType.diesel);

      expect(points.map((p) => p.price), [1.459, 1.479, 1.469]);
      expect(points.first.date, DateTime(2026, 3, 25));
      expect(points.last.date, DateTime(2026, 3, 27));
    });

    test('skips records that lack a price for the fuel type', () {
      final mixed = [
        PriceRecord(
            stationId: 's', recordedAt: DateTime(2026, 1, 1), diesel: 1.5),
        PriceRecord(stationId: 's', recordedAt: DateTime(2026, 1, 2), e10: 1.7),
      ];
      final points = PriceChart.pointsFor(mixed, FuelType.diesel);
      expect(points.length, 1);
      expect(points.single.price, 1.5);
    });
  });

  group('PriceChartAxes', () {
    final points = PriceChart.pointsFor(
      threeRecords.reversed.toList(),
      FuelType.diesel,
    );

    test('Y-axis price ticks span min, mid and max, formatted in €', () {
      const size = Size(300, 132);
      final layout = PriceChartAxes.layout(size, points);

      expect(layout.priceTicks.length, 3);
      expect(layout.priceTicks.first, 1.459); // min
      expect(layout.priceTicks.last, 1.479); // max
      // Mid is the average of min and max.
      expect(layout.priceTicks[1], closeTo(1.469, 1e-9));

      // Each tick renders a € price label via PriceFormatter.
      final labels = layout.priceTicks.map(PriceFormatter.formatPrice).toList();
      expect(labels.first, '1,459 €');
      expect(labels.last, '1,479 €');
    });

    test('X-axis date ticks always include the first and last point', () {
      const size = Size(300, 132);
      final layout = PriceChartAxes.layout(size, points);

      expect(layout.dateTicks.first, 0);
      expect(layout.dateTicks.last, points.length - 1);
    });

    test('narrow charts drop the middle date tick to avoid overlap', () {
      const narrow = Size(120, 132);
      final layout = PriceChartAxes.layout(narrow, points);
      expect(layout.dateTicks, [0, points.length - 1]);
    });

    test('flat series collapses to a single price tick', () {
      final flat = [
        PriceRecord(
            stationId: 's', recordedAt: DateTime(2026, 1, 1), diesel: 1.5),
        PriceRecord(
            stationId: 's', recordedAt: DateTime(2026, 1, 2), diesel: 1.5),
      ];
      final flatPoints =
          PriceChart.pointsFor(flat.reversed.toList(), FuelType.diesel);
      final layout = PriceChartAxes.layout(const Size(300, 132), flatPoints);
      expect(layout.priceTicks, [1.5]);
    });

    test('nearestPointIndex picks the point closest in x', () {
      const size = Size(300, 132);
      final layout = PriceChartAxes.layout(size, points);

      // A tap exactly over the last point resolves to its index.
      final lastX = layout.xForIndex(points.last.index);
      final idx = PriceChartAxes.nearestPointIndex(
        Offset(lastX, 60),
        size,
        points,
      );
      expect(idx, points.length - 1);

      // A tap over the first point resolves to index 0.
      final firstX = layout.xForIndex(points.first.index);
      expect(
        PriceChartAxes.nearestPointIndex(Offset(firstX, 60), size, points),
        0,
      );
    });
  });
}
