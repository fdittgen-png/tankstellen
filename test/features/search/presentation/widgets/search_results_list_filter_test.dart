// Regression tests for #491 — verify that amenity, open-only, and brand
// filter providers actually narrow the visible station list in
// [SearchResultsList]. Before the fix, only the brand filter was applied;
// the amenity and open-only providers were written from the criteria
// screen but never read by the results list, so toggling WiFi / Boutique
// / "Ouvertes uniquement" had zero effect on what the user saw.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/features/search/domain/entities/search_result_item.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/domain/entities/station_amenity.dart';
import 'package:tankstellen/features/search/presentation/widgets/search_results_list.dart';
import 'package:tankstellen/features/search/providers/brand_filter_provider.dart';
import 'package:tankstellen/features/search/providers/search_screen_ui_provider.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

const _totalWifiOpen = Station(
  id: 's1',
  name: 'Total WiFi',
  brand: 'TOTAL',
  street: '1 rue A',
  postCode: '34120',
  place: 'Pézenas',
  lat: 43.45,
  lng: 3.42,
  isOpen: true,
  amenities: {StationAmenity.wifi, StationAmenity.shop},
);
const _essoShopClosed = Station(
  id: 's2',
  name: 'Esso Closed',
  brand: 'ESSO',
  street: '2 rue B',
  postCode: '34120',
  place: 'Pézenas',
  lat: 43.46,
  lng: 3.43,
  isOpen: false,
  amenities: {StationAmenity.shop},
);
const _essoWifiOpen = Station(
  id: 's3',
  name: 'Esso WiFi',
  brand: 'ESSO',
  street: '3 rue C',
  postCode: '34120',
  place: 'Pézenas',
  lat: 43.47,
  lng: 3.44,
  isOpen: true,
  amenities: {StationAmenity.wifi},
);
const _independentOpen = Station(
  id: 's4',
  name: 'Independent',
  brand: '',
  street: '4 rue D',
  postCode: '34120',
  place: 'Pézenas',
  lat: 43.48,
  lng: 3.45,
  isOpen: true,
);

Finder _cardById(String id) => find.byKey(ValueKey('station-$id'));

Future<void> _pumpList(
  WidgetTester tester, {
  List<Object> extraOverrides = const [],
}) async {
  final test = standardTestOverrides();
  when(() => test.mockStorage.hasApiKey()).thenReturn(false);
  when(() => test.mockStorage.getApiKey()).thenReturn(null);
  when(() => test.mockStorage.getIgnoredIds()).thenReturn(<String>[]);
  when(() => test.mockStorage.getRatings()).thenReturn(<String, int>{});

  await pumpApp(
    tester,
    SearchResultsList(
      result: ServiceResult<List<SearchResultItem>>(
        data: const [
          FuelStationResult(_totalWifiOpen),
          FuelStationResult(_essoShopClosed),
          FuelStationResult(_essoWifiOpen),
          FuelStationResult(_independentOpen),
        ],
        source: ServiceSource.cache,
        fetchedAt: DateTime(2026, 4, 14),
      ),
      onRefresh: () {},
    ),
    overrides: [...test.overrides, ...extraOverrides],
  );
}

void main() {
  group('SearchResultsList filter application (#491)', () {
    testWidgets('no filters → all 4 stations visible', (tester) async {
      await _pumpList(tester);
      expect(_cardById('s1'), findsOneWidget);
      expect(_cardById('s2'), findsOneWidget);
      expect(_cardById('s3'), findsOneWidget);
      expect(_cardById('s4'), findsOneWidget);
    });

    testWidgets(
        'amenity filter WiFi → closes-over the two non-wifi stations',
        (tester) async {
      await _pumpList(tester, extraOverrides: [
        selectedAmenitiesProvider
            .overrideWith(() => _FakeAmenities({StationAmenity.wifi})),
      ]);
      expect(_cardById('s1'), findsOneWidget);
      expect(_cardById('s3'), findsOneWidget);
      expect(_cardById('s2'), findsNothing,
          reason: 'Esso Closed has shop but no wifi — must be hidden');
      expect(_cardById('s4'), findsNothing,
          reason: 'Independent has no amenities — must be hidden');
    });

    testWidgets(
        'amenity filter Shop+WiFi (AND) → only Total WiFi passes',
        (tester) async {
      await _pumpList(tester, extraOverrides: [
        selectedAmenitiesProvider.overrideWith(
          () => _FakeAmenities({StationAmenity.wifi, StationAmenity.shop}),
        ),
      ]);
      expect(_cardById('s1'), findsOneWidget);
      expect(_cardById('s2'), findsNothing);
      expect(_cardById('s3'), findsNothing);
      expect(_cardById('s4'), findsNothing);
    });

    testWidgets('openOnly → closed Esso disappears', (tester) async {
      await _pumpList(tester, extraOverrides: [
        openOnlyFilterProvider.overrideWith(() => _FakeOpenOnly(true)),
      ]);
      expect(_cardById('s1'), findsOneWidget);
      expect(_cardById('s3'), findsOneWidget);
      expect(_cardById('s4'), findsOneWidget);
      expect(_cardById('s2'), findsNothing);
    });

    testWidgets('brand filter TotalEnergies → only Total station',
        (tester) async {
      await _pumpList(tester, extraOverrides: [
        selectedBrandsProvider
            .overrideWith(() => _FakeBrands({'TotalEnergies'})),
      ]);
      expect(_cardById('s1'), findsOneWidget);
      expect(_cardById('s2'), findsNothing);
      expect(_cardById('s3'), findsNothing);
      expect(_cardById('s4'), findsNothing);
    });

    testWidgets(
        'brand + amenity + openOnly combine — WiFi + TotalEnergies + open',
        (tester) async {
      await _pumpList(tester, extraOverrides: [
        selectedBrandsProvider
            .overrideWith(() => _FakeBrands({'TotalEnergies'})),
        selectedAmenitiesProvider
            .overrideWith(() => _FakeAmenities({StationAmenity.wifi})),
        openOnlyFilterProvider.overrideWith(() => _FakeOpenOnly(true)),
      ]);
      expect(_cardById('s1'), findsOneWidget);
      expect(_cardById('s2'), findsNothing);
      expect(_cardById('s3'), findsNothing);
      expect(_cardById('s4'), findsNothing);
    });
  });
}

class _FakeAmenities extends SelectedAmenities {
  _FakeAmenities(this._initial);
  final Set<StationAmenity> _initial;
  @override
  Set<StationAmenity> build() => _initial;
}

class _FakeOpenOnly extends OpenOnlyFilter {
  _FakeOpenOnly(this._initial);
  final bool _initial;
  @override
  bool build() => _initial;
}

class _FakeBrands extends SelectedBrands {
  _FakeBrands(this._initial);
  final Set<String> _initial;
  @override
  Set<String> build() => _initial;
}
