import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/location/user_position_provider.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/map/presentation/widgets/nearby_map_view.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/search_result_item.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

import '../../helpers/pump_app.dart';

/// #692 — Searching a distant city from the user's location must pan the
/// map to the RESULT area, not to the user's GPS. A user in
/// Castelnau-de-Guers searching "Paris" would otherwise see a 19 km
/// radius drawn around Castelnau with zero stations visible.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('nearby_map_test_');
    Hive.init(tempDir.path);
    await HiveStorage.initForTest();
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  // Two Paris-area stations (around 48.8, 2.3) while user is at
  // Castelnau-de-Guers (43.46, 3.43). If the map centers on the user's
  // position, neither station is visible within a reasonable viewport.
  const parisStations = [
    Station(
      id: 'fr-paris-1',
      name: 'Paris Station 1',
      brand: 'Total',
      street: 'Rue de Rivoli',
      houseNumber: '10',
      postCode: '75001',
      place: 'Paris',
      lat: 48.8606,
      lng: 2.3376,
      dist: 0.5,
      e10: 1.729,
      isOpen: true,
    ),
    Station(
      id: 'fr-paris-2',
      name: 'Paris Station 2',
      brand: 'BP',
      street: 'Avenue Montaigne',
      houseNumber: '25',
      postCode: '75008',
      place: 'Paris',
      lat: 48.8656,
      lng: 2.3100,
      dist: 1.2,
      e10: 1.749,
      isOpen: true,
    ),
  ];

  testWidgets(
    'NearbyMapView centers on the search RESULT area, not on userPosition, '
    'when the user is far from the searched city',
    (tester) async {
      final mapController = MapController();
      addTearDown(mapController.dispose);

      await pumpApp(
        tester,
        SizedBox(
          width: 800,
          height: 1000,
          child: NearbyMapView(
            searchState: AsyncValue.data(
              ServiceResult(
                data: parisStations
                    .map((s) => FuelStationResult(s))
                    .toList(),
                source: ServiceSource.tankerkoenigApi,
                fetchedAt: DateTime.now(),
              ),
            ),
            selectedFuel: FuelType.e10,
            searchRadiusKm: 19,
            mapController: mapController,
          ),
        ),
        overrides: [
          // User physically in Castelnau-de-Guers (~700 km south of Paris).
          userPositionProvider.overrideWith(
            () => _FixedCastelnauPosition(),
          ),
        ],
      );
      await tester.pumpAndSettle();

      // The rendered FlutterMap must anchor near Paris — centroid of the
      // two stations is roughly (48.86, 2.32), and must NOT be anywhere
      // near Castelnau-de-Guers (43.46, 3.43).
      final flutterMap = tester.widget<FlutterMap>(find.byType(FlutterMap));
      final initialCenter = flutterMap.options.initialCenter;
      expect(initialCenter.latitude, closeTo(48.86, 0.5),
          reason:
              'Map must center near Paris centroid, not near user GPS (43.46)');
      expect(initialCenter.longitude, closeTo(2.32, 0.5));
    },
  );
}

class _FixedCastelnauPosition extends UserPosition {
  @override
  UserPositionData? build() => UserPositionData(
        lat: 43.46,
        lng: 3.43,
        updatedAt: DateTime.now(),
        source: 'GPS',
      );
}
