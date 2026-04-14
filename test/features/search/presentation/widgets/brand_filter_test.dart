import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/domain/entities/station_amenity.dart';
import 'package:tankstellen/features/search/presentation/widgets/brand_filter_chips.dart';

import '../../../../helpers/pump_app.dart';

/// Test stations with distinct brands and station types.
const _shellStation = Station(
  id: 'shell-1', name: 'Shell Berlin', brand: 'SHELL',
  street: 'Hauptstr.', postCode: '10115', place: 'Berlin',
  lat: 52.52, lng: 13.40, isOpen: true,
);

const _aralStation = Station(
  id: 'aral-1', name: 'Aral Berlin', brand: 'ARAL',
  street: 'Friedrichstr.', postCode: '10117', place: 'Berlin',
  lat: 52.51, lng: 13.39, isOpen: true,
);

const _jetStation = Station(
  id: 'jet-1', name: 'JET Berlin', brand: 'JET',
  street: 'Berliner Str.', postCode: '10178', place: 'Berlin',
  lat: 52.52, lng: 13.41, isOpen: true,
);

const _highwayStation = Station(
  id: 'highway-1', name: 'Autobahn Tank', brand: 'TOTAL',
  street: 'A1 Raststätte', postCode: '10000', place: 'Autobahn',
  lat: 52.50, lng: 13.35, isOpen: true, stationType: 'A',
);

const _emptyBrandStation = Station(
  id: 'empty-brand', name: 'No Brand Station', brand: '',
  street: 'Unknown Str.', postCode: '10000', place: 'Berlin',
  lat: 52.50, lng: 13.36, isOpen: true,
);

void main() {
  group('applyBrandFilter', () {
    final stations = [_shellStation, _aralStation, _jetStation, _highwayStation];

    test('returns all stations when no filters active', () {
      final result = applyBrandFilter(
        stations, selectedBrands: const {}, excludeHighway: false,
      );
      expect(result.length, 4);
    });

    test('filters by canonical brand names', () {
      // 'Shell' is the canonical name for 'SHELL'
      final result = applyBrandFilter(
        stations, selectedBrands: const {'Shell', 'JET'}, excludeHighway: false,
      );
      expect(result.length, 2);
    });

    test('filters single canonical brand', () {
      final result = applyBrandFilter(
        stations, selectedBrands: const {'Aral'}, excludeHighway: false,
      );
      expect(result.length, 1);
      expect(result.first.brand, 'ARAL');
    });

    test('excludes highway stations', () {
      final result = applyBrandFilter(
        stations, selectedBrands: const {}, excludeHighway: true,
      );
      expect(result.length, 3);
      expect(result.any((s) => s.stationType == 'A'), isFalse);
    });

    test('combines brand filter with highway exclusion', () {
      // TotalEnergies is the canonical name for TOTAL
      final result = applyBrandFilter(
        stations, selectedBrands: const {'TotalEnergies'}, excludeHighway: true,
      );
      expect(result, isEmpty);
    });

    test('Others matches unrecognized brands', () {
      const unknownStation = Station(
        id: 'unk', name: 'Unknown', brand: 'MyLocalGas',
        street: 'Str.', postCode: '10000', place: 'Berlin',
        lat: 52.50, lng: 13.35, isOpen: true,
      );
      final result = applyBrandFilter(
        [unknownStation, _shellStation],
        selectedBrands: const {'Others'}, excludeHighway: false,
      );
      expect(result.length, 1);
      expect(result.first.brand, 'MyLocalGas');
    });

    test('trims brand names when filtering', () {
      const stationWithSpaces = Station(
        id: 'spaces', name: 'Spaced', brand: ' SHELL ',
        street: 'Str.', postCode: '10000', place: 'Berlin',
        lat: 52.50, lng: 13.35, isOpen: true,
      );
      final result = applyBrandFilter(
        [stationWithSpaces], selectedBrands: const {'Shell'}, excludeHighway: false,
      );
      expect(result.length, 1);
    });
  });

  group('applyAmenityAndStatusFilters (#491)', () {
    const wifiShopOpen = Station(
      id: 'a',
      name: 'A',
      brand: 'SHELL',
      street: 'Str',
      postCode: '10000',
      place: 'Berlin',
      lat: 0,
      lng: 0,
      isOpen: true,
      amenities: {StationAmenity.wifi, StationAmenity.shop},
    );
    const wifiOnlyClosed = Station(
      id: 'b',
      name: 'B',
      brand: 'ARAL',
      street: 'Str',
      postCode: '10000',
      place: 'Berlin',
      lat: 0,
      lng: 0,
      isOpen: false,
      amenities: {StationAmenity.wifi},
    );
    const shopOnlyOpen = Station(
      id: 'c',
      name: 'C',
      brand: 'JET',
      street: 'Str',
      postCode: '10000',
      place: 'Berlin',
      lat: 0,
      lng: 0,
      isOpen: true,
      amenities: {StationAmenity.shop},
    );
    const noneOpen = Station(
      id: 'd',
      name: 'D',
      brand: 'TOTAL',
      street: 'Str',
      postCode: '10000',
      place: 'Berlin',
      lat: 0,
      lng: 0,
      isOpen: true,
    );

    final all = [wifiShopOpen, wifiOnlyClosed, shopOnlyOpen, noneOpen];

    test('empty amenity set + openOnly false → no filtering', () {
      final result = applyAmenityAndStatusFilters(
        all,
        requiredAmenities: const {},
        openOnly: false,
      );
      expect(result.length, 4);
    });

    test('single amenity (wifi) → only stations with wifi pass', () {
      final result = applyAmenityAndStatusFilters(
        all,
        requiredAmenities: const {StationAmenity.wifi},
        openOnly: false,
      );
      expect(result.map((s) => s.id), containsAll(['a', 'b']));
      expect(result.length, 2);
    });

    test('multiple amenities use AND semantics, not OR', () {
      // Require wifi AND shop → only station A has both.
      final result = applyAmenityAndStatusFilters(
        all,
        requiredAmenities: const {StationAmenity.wifi, StationAmenity.shop},
        openOnly: false,
      );
      expect(result.length, 1);
      expect(result.first.id, 'a');
    });

    test('openOnly excludes closed stations', () {
      final result = applyAmenityAndStatusFilters(
        all,
        requiredAmenities: const {},
        openOnly: true,
      );
      expect(result.map((s) => s.id), containsAll(['a', 'c', 'd']));
      expect(result.any((s) => s.id == 'b'), isFalse);
    });

    test('amenity + openOnly combine — wifi AND open', () {
      final result = applyAmenityAndStatusFilters(
        all,
        requiredAmenities: const {StationAmenity.wifi},
        openOnly: true,
      );
      // B has wifi but is closed → excluded.
      expect(result.length, 1);
      expect(result.first.id, 'a');
    });

    test('station with no amenities fails every non-empty amenity filter', () {
      final result = applyAmenityAndStatusFilters(
        [noneOpen],
        requiredAmenities: const {StationAmenity.shop},
        openOnly: false,
      );
      expect(result, isEmpty);
    });
  });

  group('BrandFilterChips widget', () {
    final stations = [_shellStation, _aralStation, _jetStation];

    testWidgets('shows All chip and grouped brand chips', (tester) async {
      await pumpApp(tester, BrandFilterChips(stations: stations));
      expect(find.text('All'), findsOneWidget);
      // Brands shown with count: "Shell (1)", "Aral (1)", "JET (1)"
      expect(find.textContaining('Shell'), findsOneWidget);
      expect(find.textContaining('Aral'), findsOneWidget);
      expect(find.textContaining('JET'), findsOneWidget);
    });

    testWidgets('does not show chips when station list is empty', (tester) async {
      await pumpApp(tester, const BrandFilterChips(stations: []));
      expect(find.text('All'), findsNothing);
    });

    testWidgets('skips empty brand names', (tester) async {
      await pumpApp(
        tester,
        const BrandFilterChips(stations: [_shellStation, _emptyBrandStation]),
      );
      expect(find.text('All'), findsOneWidget);
      expect(find.textContaining('Shell'), findsOneWidget);
    });

    testWidgets('shows highway filter when highway stations exist', (tester) async {
      await pumpApp(
        tester,
        BrandFilterChips(stations: [...stations, _highwayStation]),
      );
      expect(find.text('No highway'), findsOneWidget);
    });

    testWidgets('tapping a brand chip toggles it', (tester) async {
      await pumpApp(tester, BrandFilterChips(stations: stations));
      await tester.tap(find.textContaining('Shell'));
      await tester.pumpAndSettle();
    });

    testWidgets('unrecognized brands grouped as Others', (tester) async {
      const unknownStation = Station(
        id: 'unk', name: 'Unknown', brand: 'MyLocalGas',
        street: 'Str.', postCode: '10000', place: 'Berlin',
        lat: 52.50, lng: 13.35, isOpen: true,
      );
      await pumpApp(
        tester,
        const BrandFilterChips(stations: [_shellStation, unknownStation]),
      );
      expect(find.textContaining('Others'), findsOneWidget);
    });
  });
}
