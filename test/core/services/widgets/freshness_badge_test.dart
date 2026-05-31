// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/widgets/freshness_badge.dart';
import 'package:tankstellen/core/theme/dark_mode_colors.dart';

void main() {
  Widget wrapInApp(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  /// Resolves the semantic warning / error colours against the same theme
  /// the badge renders under, so the freshness colour assertions compare
  /// against live tokens rather than baked-in hex.
  Future<({Color warning, Color error})> tokensOf(WidgetTester tester) async {
    late Color warning;
    late Color error;
    await tester.pumpWidget(wrapInApp(Builder(builder: (context) {
      warning = DarkModeColors.warning(context);
      error = DarkModeColors.error(context);
      return const SizedBox();
    })));
    return (warning: warning, error: error);
  }

  /// The colour the badge paints its leading icon (== foreground colour).
  Color iconColor(WidgetTester tester, IconData icon) =>
      tester.widget<Icon>(find.byIcon(icon)).color!;

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

    testWidgets(
        'shows amber (warning, not error-red) warning icon for old data '
        '(> 15 min) [#2492]', (tester) async {
      final result = ServiceResult(
        data: <String>[],
        source: ServiceSource.tankerkoenigApi,
        fetchedAt: DateTime.now().subtract(const Duration(minutes: 20)),
      );
      final tokens = await tokensOf(tester);

      await tester.pumpWidget(wrapInApp(FreshnessBadge(result: result)));

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.textContaining('20 min'), findsOneWidget);
      // #2492 — very-stale stays in the amber/warning family, NOT error-red.
      final c = iconColor(tester, Icons.warning_amber_rounded);
      expect(c, tokens.warning);
      expect(c, isNot(tokens.error));
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

    testWidgets('shows stale with amber icon even for recent stale data',
        (tester) async {
      final result = ServiceResult(
        data: <String>[],
        source: ServiceSource.cache,
        fetchedAt: DateTime.now().subtract(const Duration(minutes: 1)),
        isStale: true,
      );
      final tokens = await tokensOf(tester);

      await tester.pumpWidget(wrapInApp(FreshnessBadge(result: result)));

      // Stale flag overrides the age-based color
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.textContaining('Stale'), findsOneWidget);
      // #2492 — stale is an attention state (amber), never error-red.
      final c = iconColor(tester, Icons.warning_amber_rounded);
      expect(c, tokens.warning);
      expect(c, isNot(tokens.error));
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

    testWidgets('boundary: 16 minutes shows the warning icon (amber)',
        (tester) async {
      final result = ServiceResult(
        data: <String>[],
        source: ServiceSource.tankerkoenigApi,
        fetchedAt: DateTime.now().subtract(const Duration(minutes: 16)),
      );
      final tokens = await tokensOf(tester);

      await tester.pumpWidget(wrapInApp(FreshnessBadge(result: result)));

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(iconColor(tester, Icons.warning_amber_rounded), tokens.warning);
    });
  });
}
