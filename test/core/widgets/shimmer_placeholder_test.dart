import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tankstellen/core/widgets/shimmer_placeholder.dart';

/// Shimmer animates forever, so `pumpAndSettle` hangs. Use a single
/// `pumpWidget` + one `pump()` to lay the tree out, then assert.
Future<void> _pumpOnce(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: child)),
  );
  await tester.pump();
}

void main() {
  group('ShimmerStationCard', () {
    testWidgets('wraps content in a Shimmer.fromColors', (tester) async {
      await _pumpOnce(tester, const ShimmerStationCard());
      expect(find.byType(Shimmer), findsOneWidget);
    });

    testWidgets('renders the leading avatar + two text lines + trailing '
        'price bar', (tester) async {
      // The four white Container rectangles are the skeleton shapes.
      // We assert the Row contains at least 4 Containers (avatar,
      // name line, address line, price bar). Guards against a
      // refactor accidentally collapsing the layout.
      await _pumpOnce(tester, const ShimmerStationCard());
      final containers =
          tester.widgetList<Container>(find.byType(Container)).length;
      expect(containers, greaterThanOrEqualTo(4));
    });
  });

  group('ShimmerStationList', () {
    testWidgets('renders 5 ShimmerStationCards by default', (tester) async {
      await _pumpOnce(tester, const ShimmerStationList());
      expect(find.byType(ShimmerStationCard), findsNWidgets(5));
    });

    testWidgets('respects a custom count', (tester) async {
      await _pumpOnce(tester, const ShimmerStationList(count: 2));
      expect(find.byType(ShimmerStationCard), findsNWidgets(2));
    });

    testWidgets('count 0 renders no cards', (tester) async {
      await _pumpOnce(tester, const ShimmerStationList(count: 0));
      expect(find.byType(ShimmerStationCard), findsNothing);
    });
  });

  group('ShimmerStationDetail', () {
    testWidgets('wraps content in a Shimmer', (tester) async {
      await _pumpOnce(tester, const ShimmerStationDetail());
      expect(find.byType(Shimmer), findsOneWidget);
    });

    testWidgets('has three price-row skeletons', (tester) async {
      // The detail shimmer mocks the three fuel-type rows; keep that
      // pinned so the loading state matches the real detail screen's
      // density.
      await _pumpOnce(tester, const ShimmerStationDetail());
      // Each price row has a 24x24 leading icon + a 14x80 label
      // + a 16x60 price. The Row count should be at least 3 (plus
      // the status row), so assert ≥ 4.
      final rows = tester.widgetList<Row>(find.byType(Row)).length;
      expect(rows, greaterThanOrEqualTo(4));
    });
  });
}
