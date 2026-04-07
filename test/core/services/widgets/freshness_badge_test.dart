import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/widgets/freshness_badge.dart';

void main() {
  Widget wrapInApp(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('FreshnessBadge', () {
    testWidgets('shows green check icon for fresh data (< 5 min)',
        (tester) async {
      final result = ServiceResult(
        data: <String>[],
        source: ServiceSource.tankerkoenigApi,
        fetchedAt: DateTime.now().subtract(const Duration(minutes: 2)),
      );

      await tester.pumpWidget(wrapInApp(FreshnessBadge(result: result)));

      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.textContaining('ago'), findsOneWidget);
      expect(find.textContaining('2 min'), findsOneWidget);
    });

    testWidgets('shows amber schedule icon for moderately old data (5-15 min)',
        (tester) async {
      final result = ServiceResult(
        data: <String>[],
        source: ServiceSource.tankerkoenigApi,
        fetchedAt: DateTime.now().subtract(const Duration(minutes: 10)),
      );

      await tester.pumpWidget(wrapInApp(FreshnessBadge(result: result)));

      expect(find.byIcon(Icons.schedule), findsOneWidget);
      expect(find.textContaining('10 min'), findsOneWidget);
    });

    testWidgets('shows red warning icon for old data (> 15 min)',
        (tester) async {
      final result = ServiceResult(
        data: <String>[],
        source: ServiceSource.tankerkoenigApi,
        fetchedAt: DateTime.now().subtract(const Duration(minutes: 20)),
      );

      await tester.pumpWidget(wrapInApp(FreshnessBadge(result: result)));

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.textContaining('20 min'), findsOneWidget);
    });

    testWidgets('shows "Stale" prefix when result is stale', (tester) async {
      final result = ServiceResult(
        data: <String>[],
        source: ServiceSource.cache,
        fetchedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        isStale: true,
      );

      await tester.pumpWidget(wrapInApp(FreshnessBadge(result: result)));

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.textContaining('Stale'), findsOneWidget);
      expect(find.textContaining('30 min'), findsOneWidget);
    });

    testWidgets('shows stale with red icon even for recent stale data',
        (tester) async {
      final result = ServiceResult(
        data: <String>[],
        source: ServiceSource.cache,
        fetchedAt: DateTime.now().subtract(const Duration(minutes: 1)),
        isStale: true,
      );

      await tester.pumpWidget(wrapInApp(FreshnessBadge(result: result)));

      // Stale flag overrides the age-based color
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.textContaining('Stale'), findsOneWidget);
    });

    testWidgets('shows "< 1 min" for very fresh data', (tester) async {
      final result = ServiceResult(
        data: <String>[],
        source: ServiceSource.tankerkoenigApi,
        fetchedAt: DateTime.now(),
      );

      await tester.pumpWidget(wrapInApp(FreshnessBadge(result: result)));

      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.textContaining('< 1 min'), findsOneWidget);
    });

    testWidgets('shows hours for data older than 60 min', (tester) async {
      final result = ServiceResult(
        data: <String>[],
        source: ServiceSource.cache,
        fetchedAt: DateTime.now().subtract(const Duration(hours: 3)),
      );

      await tester.pumpWidget(wrapInApp(FreshnessBadge(result: result)));

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.textContaining('3 h'), findsOneWidget);
    });

    testWidgets('shows days for data older than 24 hours', (tester) async {
      final result = ServiceResult(
        data: <String>[],
        source: ServiceSource.cache,
        fetchedAt: DateTime.now().subtract(const Duration(days: 2)),
      );

      await tester.pumpWidget(wrapInApp(FreshnessBadge(result: result)));

      expect(find.textContaining('2 d'), findsOneWidget);
    });

    testWidgets('has a Semantics widget for accessibility', (tester) async {
      final result = ServiceResult(
        data: <String>[],
        source: ServiceSource.tankerkoenigApi,
        fetchedAt: DateTime.now(),
      );

      await tester.pumpWidget(wrapInApp(FreshnessBadge(result: result)));

      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('renders inside a bordered container', (tester) async {
      final result = ServiceResult(
        data: <String>[],
        source: ServiceSource.tankerkoenigApi,
        fetchedAt: DateTime.now(),
      );

      await tester.pumpWidget(wrapInApp(FreshnessBadge(result: result)));

      // Should have a Container with decoration
      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.decoration, isNotNull);
    });

    testWidgets('boundary: exactly 5 minutes shows amber', (tester) async {
      final result = ServiceResult(
        data: <String>[],
        source: ServiceSource.tankerkoenigApi,
        fetchedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      await tester.pumpWidget(wrapInApp(FreshnessBadge(result: result)));

      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });

    testWidgets('boundary: exactly 15 minutes shows amber (not red)',
        (tester) async {
      final result = ServiceResult(
        data: <String>[],
        source: ServiceSource.tankerkoenigApi,
        fetchedAt: DateTime.now().subtract(const Duration(minutes: 15)),
      );

      await tester.pumpWidget(wrapInApp(FreshnessBadge(result: result)));

      // 15 min is >= 5 and not > 15, so amber
      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });

    testWidgets('boundary: 16 minutes shows red', (tester) async {
      final result = ServiceResult(
        data: <String>[],
        source: ServiceSource.tankerkoenigApi,
        fetchedAt: DateTime.now().subtract(const Duration(minutes: 16)),
      );

      await tester.pumpWidget(wrapInApp(FreshnessBadge(result: result)));

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });
  });
}
