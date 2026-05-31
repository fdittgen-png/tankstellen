// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/features/calculator/presentation/screens/calculator_screen.dart';
import 'package:tankstellen/features/calculator/presentation/widgets/use_mine_chip.dart';
import 'package:tankstellen/features/calculator/providers/calculator_prefill_provider.dart';
import 'package:tankstellen/features/calculator/providers/calculator_provider.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../helpers/mock_providers.dart';

/// Pumps the calculator inside a GoRouter (the screen's back button uses
/// `context.go`) with the given prefill + extra overrides.
Future<ProviderContainer> _pumpCalculator(
  WidgetTester tester, {
  required CalculatorPrefill prefill,
  double? initialPrice,
}) async {
  final test = standardTestOverrides();
  when(() => test.mockStorage.hasApiKey()).thenReturn(false);

  final container = ProviderContainer(
    overrides: [
      ...test.overrides,
      calculatorPrefillProvider.overrideWithValue(prefill),
    ].cast(),
  );
  addTearDown(container.dispose);

  final router = GoRouter(
    initialLocation: '/calc',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SizedBox.shrink(),
      ),
      GoRoute(
        path: '/calc',
        builder: (context, state) =>
            CalculatorScreen(initialPrice: initialPrice),
      ),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  group('CalculatorScreen', () {
    testWidgets('renders the result hero and three input fields',
        (tester) async {
      await _pumpCalculator(tester, prefill: const CalculatorPrefill());

      expect(find.text('Fuel Cost Calculator'), findsOneWidget);
      expect(find.text('Trip Cost'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(3));
    });

    testWidgets('result hero shows -- before input and fills live',
        (tester) async {
      final container =
          await _pumpCalculator(tester, prefill: const CalculatorPrefill());

      // Cold: hero + breakdown read `--`.
      expect(find.text('--'), findsWidgets);

      // Enter all three inputs — the hero fills.
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '100'); // distance
      await tester.enterText(fields.at(1), '7'); // consumption
      await tester.enterText(fields.at(2), '2'); // price
      await tester.pumpAndSettle();

      final state = container.read(calculatorProvider);
      expect(state.hasInput, isTrue);
      // 14.00 € total (FR default locale comma).
      expect(find.text('14,00 €'), findsOneWidget);
    });

    testWidgets('cold open hides all use-mine chips, manual entry works',
        (tester) async {
      // No prefill sources at all (cold install): every chip hidden.
      final container = await _pumpCalculator(
        tester,
        prefill: const CalculatorPrefill(),
      );

      expect(find.byType(UseMineChip), findsNothing);

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '50');
      await tester.pumpAndSettle();
      expect(container.read(calculatorProvider).distanceKm, 50);
    });

    testWidgets('a distance prefill chip applies its source', (tester) async {
      final container = await _pumpCalculator(
        tester,
        prefill: const CalculatorPrefill(distanceKm: 150),
      );

      // Exactly one chip (only the distance source is available).
      expect(find.byType(UseMineChip), findsOneWidget);
      // Distance is still 0 until the chip is tapped.
      expect(container.read(calculatorProvider).distanceKm, 0);

      await tester.tap(find.byType(UseMineChip));
      await tester.pumpAndSettle();

      expect(container.read(calculatorProvider).distanceKm, 150);
    });

    testWidgets('route initialPrice pre-applies and shows the Applied chip',
        (tester) async {
      final container = await _pumpCalculator(
        tester,
        prefill: const CalculatorPrefill(),
        initialPrice: 1.899,
      );
      await tester.pumpAndSettle();

      expect(container.read(calculatorProvider).pricePerLiter, 1.899);
      expect(find.textContaining('Applied'), findsOneWidget);
    });
  });
}
