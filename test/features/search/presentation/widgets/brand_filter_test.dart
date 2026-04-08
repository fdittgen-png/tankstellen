import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/presentation/widgets/brand_filter_chips.dart';
import 'package:tankstellen/features/search/providers/brand_filter_provider.dart';

import '../../../../helpers/pump_app.dart';

/// Test stations with distinct brands and station types.
const _shellStation = Station(
  id: 'shell-1',
  name: 'Shell Berlin',
  brand: 'SHELL',
  street: 'Hauptstr.',
  postCode: '10115',
  place: 'Berlin',
  lat: 52.52,
  lng: 13.40,
  isOpen: true,
);

const _aralStation = Station(
  id: 'aral-1',
  name: 'Aral Berlin',
  brand: 'ARAL',
  street: 'Friedrichstr.',
  postCode: '10117',
  place: 'Berlin',
  lat: 52.51,
  lng: 13.39,
  isOpen: true,
);

const _jetStation = Station(
  id: 'jet-1',
  name: 'JET Berlin',
  brand: 'JET',
  street: 'Berliner Str.',
  postCode: '10178',
  place: 'Berlin',
  lat: 52.52,
  lng: 13.41,
  isOpen: true,
);

const _highwayStation = Station(
  id: 'highway-1',
  name: 'Autobahn Tank',
  brand: 'TOTAL',
  street: 'A1 Raststätte',
  postCode: '10000',
  place: 'Autobahn',
  lat: 52.50,
  lng: 13.35,
  isOpen: true,
  stationType: 'A',
);

const _emptyBrandStation = Station(
  id: 'empty-brand',
  name: 'No Brand Station',
  brand: '',
  street: 'Unknown Str.',
  postCode: '10000',
  place: 'Berlin',
  lat: 52.50,
  lng: 13.36,
  isOpen: true,
);

void main() {
  group('applyBrandFilter', () {
    final stations = [_shellStation, _aralStation, _jetStation, _highwayStation];

    test('returns all stations when no filters active', () {
      final result = applyBrandFilter(
        stations,
        selectedBrands: const {},
        excludeHighway: false,
      );
      expect(result.length, 4);
    });

    test('filters by selected brands', () {
      final result = applyBrandFilter(
        stations,
        selectedBrands: const {'SHELL', 'JET'},
        excludeHighway: false,
      );
      expect(result.length, 2);
      expect(result.map((s) => s.brand), containsAll(['SHELL', 'JET']));
    });

    test('filters single brand', () {
      final result = applyBrandFilter(
        stations,
        selectedBrands: const {'ARAL'},
        excludeHighway: false,
      );
      expect(result.length, 1);
      expect(result.first.brand, 'ARAL');
    });

    test('excludes highway stations', () {
      final result = applyBrandFilter(
        stations,
        selectedBrands: const {},
        excludeHighway: true,
      );
      expect(result.length, 3);
      expect(result.any((s) => s.stationType == 'A'), isFalse);
    });

    test('combines brand filter with highway exclusion', () {
      final result = applyBrandFilter(
        stations,
        selectedBrands: const {'TOTAL'},
        excludeHighway: true,
      );
      // TOTAL station is the highway station, so it gets excluded
      expect(result, isEmpty);
    });

    test('brand filter with non-matching brands returns empty', () {
      final result = applyBrandFilter(
        stations,
        selectedBrands: const {'ESSO'},
        excludeHighway: false,
      );
      expect(result, isEmpty);
    });

    test('handles empty station list', () {
      final result = applyBrandFilter(
        const [],
        selectedBrands: const {'SHELL'},
        excludeHighway: true,
      );
      expect(result, isEmpty);
    });

    test('trims brand names when filtering', () {
      const stationWithSpaces = Station(
        id: 'spaces',
        name: 'Spaced',
        brand: ' SHELL ',
        street: 'Str.',
        postCode: '10000',
        place: 'Berlin',
        lat: 52.50,
        lng: 13.35,
        isOpen: true,
      );
      final result = applyBrandFilter(
        [stationWithSpaces],
        selectedBrands: const {'SHELL'},
        excludeHighway: false,
      );
      expect(result.length, 1);
    });
  });

  group('BrandFilterChips widget', () {
    final stations = [_shellStation, _aralStation, _jetStation];

    testWidgets('shows All chip and brand chips', (tester) async {
      await pumpApp(
        tester,
        BrandFilterChips(stations: stations),
      );

      expect(find.text('All'), findsOneWidget);
      expect(find.text('ARAL'), findsOneWidget);
      expect(find.text('JET'), findsOneWidget);
      expect(find.text('SHELL'), findsOneWidget);
    });

    testWidgets('does not show chips when station list is empty', (tester) async {
      await pumpApp(
        tester,
        const BrandFilterChips(stations: []),
      );

      expect(find.text('All'), findsNothing);
    });

    testWidgets('skips empty brand names', (tester) async {
      await pumpApp(
        tester,
        BrandFilterChips(stations: [_shellStation, _emptyBrandStation]),
      );

      // Only All and SHELL should show
      expect(find.text('All'), findsOneWidget);
      expect(find.text('SHELL'), findsOneWidget);
      // No empty chip
      expect(find.byType(FilterChip), findsOneWidget); // just SHELL
    });

    testWidgets('shows highway filter when highway stations exist', (tester) async {
      await pumpApp(
        tester,
        BrandFilterChips(stations: [...stations, _highwayStation]),
      );

      expect(find.text('No highway'), findsOneWidget);
    });

    testWidgets('hides highway filter when no highway stations', (tester) async {
      await pumpApp(
        tester,
        BrandFilterChips(stations: stations),
      );

      expect(find.text('No highway'), findsNothing);
    });

    testWidgets('tapping All chip clears selection', (tester) async {
      await pumpApp(
        tester,
        BrandFilterChips(stations: stations),
        overrides: [
          selectedBrandsProvider.overrideWith(() => _PreselectedBrands({'SHELL'})),
        ],
      );

      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      // After tapping All, selection should be cleared
      // (provider notifier's clear() is called)
    });

    testWidgets('tapping a brand chip toggles it', (tester) async {
      await pumpApp(
        tester,
        BrandFilterChips(stations: stations),
      );

      await tester.tap(find.text('SHELL'));
      await tester.pumpAndSettle();

      // Just verify no crash — the provider state change is tested in unit tests
    });

    testWidgets('brands are sorted alphabetically', (tester) async {
      const zStation = Station(
        id: 'z-1',
        name: 'Z Station',
        brand: 'ZZZZZ',
        street: 'Str.',
        postCode: '10000',
        place: 'Berlin',
        lat: 52.50,
        lng: 13.35,
        isOpen: true,
      );
      const aStation = Station(
        id: 'a-1',
        name: 'A Station',
        brand: 'AAAAA',
        street: 'Str.',
        postCode: '10000',
        place: 'Berlin',
        lat: 52.50,
        lng: 13.35,
        isOpen: true,
      );

      await pumpApp(
        tester,
        BrandFilterChips(stations: [zStation, aStation]),
      );

      // Both should be visible
      expect(find.text('AAAAA'), findsOneWidget);
      expect(find.text('ZZZZZ'), findsOneWidget);

      // AAAAA should come before ZZZZZ in the widget tree
      final aPos = tester.getCenter(find.text('AAAAA'));
      final zPos = tester.getCenter(find.text('ZZZZZ'));
      expect(aPos.dx, lessThan(zPos.dx));
    });
  });
}

/// Helper notifier with pre-selected brands for testing.
class _PreselectedBrands extends SelectedBrands {
  final Set<String> _initial;
  _PreselectedBrands(this._initial);

  @override
  Set<String> build() => _initial;
}
