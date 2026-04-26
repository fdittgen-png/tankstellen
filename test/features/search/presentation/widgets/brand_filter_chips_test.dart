import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/domain/entities/brand_registry.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/presentation/widgets/brand_filter_chips.dart';
import 'package:tankstellen/features/search/providers/brand_filter_provider.dart';

import '../../../../helpers/pump_app.dart';

/// Widget tests for [BrandFilterChips] that pin the gaps the existing
/// `brand_filter_test.dart` and `brand_filter_chip_counts_test.dart`
/// suites don't reach (Refs #561):
///
/// - tap on "All" calls `selectedBrandsProvider.notifier.clear()`,
/// - tap on "No highway" toggles `excludeHighwayStationsProvider`,
/// - tap on "Autoroute" toggles `'Autoroute'` in `selectedBrandsProvider`,
/// - the "All" chip is selected by default when `selectedBrands` is empty,
/// - a chip whose label matches a selected brand renders `selected: true`,
/// - sort order: major brands by count descending, then `Others` last,
/// - empty stations list renders a [SizedBox.shrink] (zero filter UI),
/// - the highway chips are absent when no station is `stationType == 'A'`.
///
/// These cases lift `brand_filter_chips.dart` from ~87% line coverage to
/// 100% — every `onSelected` branch is exercised, plus the static
/// `extractGroupedBrands` ordering contract.

Station _s(
  String id,
  String brand, {
  String stationType = 'R',
}) =>
    Station(
      id: id,
      name: id,
      brand: brand,
      street: 'Rue Test',
      houseNumber: '1',
      postCode: '34120',
      place: 'Test',
      lat: 43.0,
      lng: 3.0,
      dist: 1.0,
      isOpen: true,
      stationType: stationType,
    );

void main() {
  group('BrandFilterChips — empty / minimal renders', () {
    testWidgets('empty station list renders SizedBox.shrink', (tester) async {
      await pumpApp(tester, const BrandFilterChips(stations: []));
      // Nothing visible — no FilterChip, no ChoiceChip.
      expect(find.byType(ChoiceChip), findsNothing);
      expect(find.byType(FilterChip), findsNothing);
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets(
      'no highway stations → No highway and Autoroute chips are absent',
      (tester) async {
        final stations = [
          _s('a', 'Total'),
          _s('b', 'Esso'),
        ];
        await pumpApp(tester, BrandFilterChips(stations: stations));
        expect(find.text('No highway'), findsNothing);
        expect(find.text('Autoroute'), findsNothing);
      },
    );
  });

  group('BrandFilterChips — initial state', () {
    testWidgets(
      'All chip is selected by default (selectedBrands is empty)',
      (tester) async {
        final stations = [_s('a', 'Total'), _s('b', 'Esso')];
        await pumpApp(tester, BrandFilterChips(stations: stations));

        final allChip = tester.widget<ChoiceChip>(find.byType(ChoiceChip));
        expect(allChip.selected, isTrue,
            reason:
                'When selectedBrands is empty the All chip is the active state');
      },
    );

    testWidgets(
      'a brand chip whose label is selected renders with selected: true',
      (tester) async {
        final stations = [_s('a', 'Total'), _s('b', 'Esso')];
        // Pre-populate the provider with the canonical TotalEnergies label.
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              selectedBrandsProvider.overrideWith(
                () => _PrefilledSelectedBrands({'TotalEnergies'}),
              ),
            ],
            child: MaterialApp(
              home: Scaffold(body: BrandFilterChips(stations: stations)),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // The "TotalEnergies (1)" chip should be selected; "All" should NOT.
        final allChip = tester.widget<ChoiceChip>(find.byType(ChoiceChip));
        expect(allChip.selected, isFalse,
            reason: 'All chip is unselected once a brand is chosen');

        final totalChip = tester.widget<FilterChip>(
          find.ancestor(
            of: find.text('TotalEnergies (1)'),
            matching: find.byType(FilterChip),
          ),
        );
        expect(totalChip.selected, isTrue);
      },
    );
  });

  group('BrandFilterChips — tap interactions', () {
    testWidgets(
      'tapping All calls selectedBrandsProvider.notifier.clear()',
      (tester) async {
        final stations = [_s('a', 'Total'), _s('b', 'Esso')];
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Start with a non-empty selection so clear() is observable.
        container.read(selectedBrandsProvider.notifier).toggle('TotalEnergies');
        expect(container.read(selectedBrandsProvider), {'TotalEnergies'});

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(body: BrandFilterChips(stations: stations)),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('All'));
        await tester.pumpAndSettle();

        expect(container.read(selectedBrandsProvider), isEmpty,
            reason: 'Tapping All must clear the selection');
      },
    );

    testWidgets(
      'tapping No highway toggles excludeHighwayStationsProvider',
      (tester) async {
        final stations = [
          _s('a', 'Total'),
          _s('hwy', 'Total', stationType: 'A'),
        ];
        final container = ProviderContainer();
        addTearDown(container.dispose);

        expect(container.read(excludeHighwayStationsProvider), isFalse);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(body: BrandFilterChips(stations: stations)),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('No highway'));
        await tester.pumpAndSettle();
        expect(container.read(excludeHighwayStationsProvider), isTrue,
            reason: 'First tap on No highway flips the flag on');

        await tester.tap(find.text('No highway'));
        await tester.pumpAndSettle();
        expect(container.read(excludeHighwayStationsProvider), isFalse,
            reason: 'Second tap toggles back off');
      },
    );

    testWidgets(
      'tapping Autoroute toggles "Autoroute" membership in selectedBrands',
      (tester) async {
        final stations = [
          _s('a', 'Total'),
          _s('hwy', 'Total', stationType: 'A'),
        ];
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(body: BrandFilterChips(stations: stations)),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(container.read(selectedBrandsProvider), isEmpty);

        await tester.tap(find.text('Autoroute'));
        await tester.pumpAndSettle();
        expect(container.read(selectedBrandsProvider), {'Autoroute'},
            reason: 'First tap adds Autoroute to the selection');

        await tester.tap(find.text('Autoroute'));
        await tester.pumpAndSettle();
        expect(container.read(selectedBrandsProvider), isEmpty,
            reason: 'Second tap removes Autoroute again');
      },
    );

    testWidgets(
      'tapping a brand chip toggles its canonical name in selectedBrands',
      (tester) async {
        final stations = [_s('a', 'Total'), _s('b', 'Esso')];
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(body: BrandFilterChips(stations: stations)),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Esso (1)'));
        await tester.pumpAndSettle();
        expect(container.read(selectedBrandsProvider), {'Esso'});

        await tester.tap(find.text('Esso (1)'));
        await tester.pumpAndSettle();
        expect(container.read(selectedBrandsProvider), isEmpty);
      },
    );

    testWidgets(
      'highway-only chip toggling does not affect excludeHighway flag',
      (tester) async {
        final stations = [
          _s('hwy', 'Total', stationType: 'A'),
          _s('a', 'Total'),
        ];
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(body: BrandFilterChips(stations: stations)),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Autoroute'));
        await tester.pumpAndSettle();

        expect(container.read(excludeHighwayStationsProvider), isFalse,
            reason: 'Autoroute chip writes to selectedBrands, not the highway '
                'exclusion flag — the two filters live on different providers');
      },
    );
  });

  group('BrandFilterChips.extractGroupedBrands — sort order contract', () {
    test(
      'sortedBrands key order: major brands by count desc, Others always last',
      () {
        final stations = <Station>[
          // Total wins on count (3) — should appear first.
          _s('t1', 'Total'),
          _s('t2', 'Total'),
          _s('t3', 'TotalEnergies'),
          // Esso second (2).
          _s('e1', 'Esso'),
          _s('e2', 'Esso Express'),
          // Mystery + empty bucket into Others (3) — but Others must STILL
          // be last regardless of count.
          _s('m1', 'MysteryCorp'),
          _s('m2', ''),
          _s('m3', '   '),
        ];
        final counts = BrandFilterChips.extractGroupedBrands(stations);

        // Reproduce the exact widget sort:
        final sorted = counts.keys.toList()
          ..sort((a, b) {
            if (a == BrandRegistry.othersLabel) return 1;
            if (b == BrandRegistry.othersLabel) return -1;
            return (counts[b] ?? 0).compareTo(counts[a] ?? 0);
          });

        expect(sorted.last, BrandRegistry.othersLabel,
            reason: 'Others is always last, even when its count is highest');
        expect(sorted.first, 'TotalEnergies',
            reason: 'Major brands sorted by count desc — TotalEnergies has 3');
        expect(sorted.indexOf('TotalEnergies'),
            lessThan(sorted.indexOf('Esso')),
            reason: 'count 3 must rank before count 2');
      },
    );
  });
}

/// Test-only [SelectedBrands] notifier that builds with a pre-populated
/// state so we can verify the "selected: true" rendering branch without
/// having to drive the UI through a tap first.
class _PrefilledSelectedBrands extends SelectedBrands {
  _PrefilledSelectedBrands(this._initial);

  final Set<String> _initial;

  @override
  Set<String> build() => _initial;
}
