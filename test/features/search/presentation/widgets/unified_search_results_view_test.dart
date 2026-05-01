import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/refuel/refuel_availability.dart';
import 'package:tankstellen/core/refuel/refuel_option.dart';
import 'package:tankstellen/core/refuel/refuel_price.dart';
import 'package:tankstellen/core/refuel/refuel_provider.dart';
import 'package:tankstellen/core/refuel/unified_search_results_provider.dart';
import 'package:tankstellen/features/search/presentation/widgets/refuel_option_card.dart';
import 'package:tankstellen/features/search/presentation/widgets/unified_filter_chips.dart';
import 'package:tankstellen/features/search/presentation/widgets/unified_search_results_view.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Hand-rolled minimal subtype for the view tests. Mirrors the helper
/// in `refuel_option_card_test.dart` so we can drive every filter
/// branch without leaning on a real adapter.
class _FakeRefuelOption extends RefuelOption {
  @override
  ({double lat, double lng}) get coordinates => (lat: 0.0, lng: 0.0);
  @override
  final RefuelPrice? price;
  @override
  final RefuelProvider provider;
  @override
  final RefuelAvailability availability;
  @override
  final String id;

  const _FakeRefuelOption({
    required this.id,
    required this.provider,
    required this.availability,
    this.price,
  });
}

const _fuelOption = _FakeRefuelOption(
  id: 'fuel:1',
  provider: RefuelProvider(name: 'Total', kind: RefuelProviderKind.fuel),
  availability: RefuelAvailability.open,
  price: RefuelPrice(value: 179.9, unit: RefuelPriceUnit.centsPerLiter),
);

const _evOption = _FakeRefuelOption(
  id: 'ev:1',
  provider: RefuelProvider(name: 'Ionity', kind: RefuelProviderKind.ev),
  availability: RefuelAvailability.open,
  price: RefuelPrice(value: 39.0, unit: RefuelPriceUnit.centsPerKwh),
);

const _mixedOption = _FakeRefuelOption(
  id: 'mixed:1',
  provider:
      RefuelProvider(name: 'Total + Recharge', kind: RefuelProviderKind.both),
  availability: RefuelAvailability.open,
);

Future<void> _pumpView(
  WidgetTester tester, {
  required List<RefuelOption> options,
  UnifiedFilter? initialFilter,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        unifiedSearchResultsProvider.overrideWith((ref) => options),
        if (initialFilter != null)
          unifiedFilterStateProvider.overrideWith(
            () => _FixedFilter(initialFilter),
          ),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: UnifiedSearchResultsView()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('UnifiedSearchResultsView', () {
    testWidgets('Both filter renders one card per option (1 fuel + 1 EV)',
        (tester) async {
      await _pumpView(
        tester,
        options: const [_fuelOption, _evOption],
      );

      // Default filter is Both — both cards visible.
      expect(find.byType(RefuelOptionCard), findsNWidgets(2));
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('Ionity'), findsOneWidget);
    });

    testWidgets('Fuel filter keeps only fuel-kind options', (tester) async {
      await _pumpView(
        tester,
        options: const [_fuelOption, _evOption],
        initialFilter: UnifiedFilter.fuel,
      );

      expect(find.byType(RefuelOptionCard), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('Ionity'), findsNothing);
    });

    testWidgets('EV filter keeps only ev-kind options', (tester) async {
      await _pumpView(
        tester,
        options: const [_fuelOption, _evOption],
        initialFilter: UnifiedFilter.ev,
      );

      expect(find.byType(RefuelOptionCard), findsOneWidget);
      expect(find.text('Ionity'), findsOneWidget);
      expect(find.text('Total'), findsNothing);
    });

    testWidgets(
        'mixed-kind providers (kind = both) appear under Fuel AND EV filters',
        (tester) async {
      await _pumpView(
        tester,
        options: const [_mixedOption],
        initialFilter: UnifiedFilter.fuel,
      );
      expect(find.byType(RefuelOptionCard), findsOneWidget,
          reason: 'mixed-site provider must be visible under Fuel filter');

      await _pumpView(
        tester,
        options: const [_mixedOption],
        initialFilter: UnifiedFilter.ev,
      );
      expect(find.byType(RefuelOptionCard), findsOneWidget,
          reason: 'mixed-site provider must be visible under EV filter');
    });

    testWidgets('empty list renders the localized empty-state text',
        (tester) async {
      await _pumpView(tester, options: const []);

      expect(find.byType(RefuelOptionCard), findsNothing);
      expect(find.text('No results match this filter'), findsOneWidget);
    });

    testWidgets(
        'Fuel filter on an EV-only list renders the empty-state text',
        (tester) async {
      // Filter strips everything → empty-state placeholder must show.
      await _pumpView(
        tester,
        options: const [_evOption],
        initialFilter: UnifiedFilter.fuel,
      );

      expect(find.byType(RefuelOptionCard), findsNothing);
      expect(find.text('No results match this filter'), findsOneWidget);
    });

    testWidgets('the filter chip row is always rendered, even when empty',
        (tester) async {
      await _pumpView(tester, options: const []);

      // Chip row stays visible so the user can switch filters off
      // their empty-state.
      expect(find.byType(UnifiedFilterChips), findsOneWidget);
    });
  });
}

class _FixedFilter extends UnifiedFilterState {
  _FixedFilter(this._initial);
  final UnifiedFilter _initial;

  @override
  UnifiedFilter build() => _initial;
}
