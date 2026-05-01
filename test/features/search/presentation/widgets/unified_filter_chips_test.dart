import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/presentation/widgets/unified_filter_chips.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('UnifiedFilterChips', () {
    testWidgets('renders all three chips with localized labels',
        (tester) async {
      await pumpApp(tester, const UnifiedFilterChips());

      // English labels from unified_search_en.arb
      expect(find.text('Fuel'), findsOneWidget);
      expect(find.text('EV'), findsOneWidget);
      expect(find.text('Both'), findsOneWidget);
      expect(find.byType(FilterChip), findsNWidgets(3));
    });

    testWidgets('default selection is Both', (tester) async {
      await pumpApp(tester, const UnifiedFilterChips());

      final bothChip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'Both'),
      );
      final fuelChip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'Fuel'),
      );
      final evChip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'EV'),
      );
      expect(bothChip.selected, isTrue);
      expect(fuelChip.selected, isFalse);
      expect(evChip.selected, isFalse);
    });

    testWidgets('tapping Fuel chip flips the provider state',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: UnifiedFilterChips()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        container.read(unifiedFilterStateProvider),
        UnifiedFilter.both,
      );

      await tester.tap(find.widgetWithText(FilterChip, 'Fuel'));
      await tester.pump();

      expect(
        container.read(unifiedFilterStateProvider),
        UnifiedFilter.fuel,
      );
    });

    testWidgets('tapping EV chip flips the provider state', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: UnifiedFilterChips()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilterChip, 'EV'));
      await tester.pump();

      expect(
        container.read(unifiedFilterStateProvider),
        UnifiedFilter.ev,
      );
    });

    testWidgets('chip selected styling reflects current state',
        (tester) async {
      final container = ProviderContainer(overrides: [
        unifiedFilterStateProvider.overrideWith(_FixedFilter.new),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: UnifiedFilterChips()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Override locks state to UnifiedFilter.ev — only EV is selected.
      final fuelChip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'Fuel'),
      );
      final evChip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'EV'),
      );
      final bothChip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'Both'),
      );
      expect(evChip.selected, isTrue);
      expect(fuelChip.selected, isFalse);
      expect(bothChip.selected, isFalse);
    });

    test('UnifiedFilterState.set updates state imperatively', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(unifiedFilterStateProvider),
        UnifiedFilter.both,
      );
      container
          .read(unifiedFilterStateProvider.notifier)
          .set(UnifiedFilter.fuel);
      expect(
        container.read(unifiedFilterStateProvider),
        UnifiedFilter.fuel,
      );
    });
  });
}

class _FixedFilter extends UnifiedFilterState {
  @override
  UnifiedFilter build() => UnifiedFilter.ev;
}
