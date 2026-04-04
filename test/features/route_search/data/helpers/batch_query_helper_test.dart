import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/features/route_search/data/helpers/batch_query_helper.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/domain/entities/search_result_item.dart';

void main() {
  group('BatchQueryHelper', () {
    test('processes all sample points in batches', () async {
      final queriedPoints = <String>[];
      const helper = BatchQueryHelper(batchSize: 3);

      final points = List.generate(10, (i) => LatLng(48.0 + i * 0.1, 2.0));

      final results = await helper.queryAll(
        samplePoints: points,
        fuelType: FuelType.e10,
        searchRadiusKm: 10.0,
        queryStations: ({
          required double lat,
          required double lng,
          required double radiusKm,
          required FuelType fuelType,
        }) async {
          queriedPoints.add('${lat.toStringAsFixed(1)}');
          return [
            FuelStationResult(Station(
              id: 'st-${lat.toStringAsFixed(1)}',
              name: 'Station',
              brand: 'Test',
              street: '',
              postCode: '',
              place: '',
              lat: lat,
              lng: lng,
              dist: 1.0,
              isOpen: true,
              e10: 1.50,
            )),
          ];
        },
      );

      // All 10 points queried
      expect(queriedPoints, hasLength(10));
      // All 10 stations returned (unique IDs)
      expect(results, hasLength(10));
    });

    test('deduplicates stations from overlapping queries', () async {
      const helper = BatchQueryHelper(batchSize: 2);

      final points = [const LatLng(48.0, 2.0), const LatLng(48.1, 2.0)];

      final results = await helper.queryAll(
        samplePoints: points,
        fuelType: FuelType.e10,
        searchRadiusKm: 10.0,
        queryStations: ({
          required double lat,
          required double lng,
          required double radiusKm,
          required FuelType fuelType,
        }) async {
          // Both points return the same station
          return [
            FuelStationResult(Station(
              id: 'shared-station',
              name: 'Shared',
              brand: 'Test',
              street: '',
              postCode: '',
              place: '',
              lat: 48.05,
              lng: 2.0,
              dist: 1.0,
              isOpen: true,
              e10: 1.50,
            )),
          ];
        },
      );

      // Deduplicated to 1
      expect(results, hasLength(1));
    });

    test('handles individual query failures gracefully', () async {
      const helper = BatchQueryHelper(batchSize: 2);
      int callCount = 0;

      final points = List.generate(4, (i) => LatLng(48.0 + i * 0.1, 2.0));

      final results = await helper.queryAll(
        samplePoints: points,
        fuelType: FuelType.e10,
        searchRadiusKm: 10.0,
        queryStations: ({
          required double lat,
          required double lng,
          required double radiusKm,
          required FuelType fuelType,
        }) async {
          callCount++;
          // Fail every other query
          if (callCount % 2 == 0) throw Exception('API error');
          return [
            FuelStationResult(Station(
              id: 'st-$callCount',
              name: 'Station',
              brand: 'Test',
              street: '',
              postCode: '',
              place: '',
              lat: lat,
              lng: lng,
              dist: 1.0,
              isOpen: true,
              e10: 1.50,
            )),
          ];
        },
      );

      // 2 out of 4 succeed
      expect(results, hasLength(2));
      // All 4 were attempted
      expect(callCount, 4);
    });

    test('batch size 1 processes sequentially', () async {
      const helper = BatchQueryHelper(batchSize: 1);
      final timestamps = <int>[];

      final points = [const LatLng(48.0, 2.0), const LatLng(49.0, 2.0)];

      await helper.queryAll(
        samplePoints: points,
        fuelType: FuelType.e10,
        searchRadiusKm: 10.0,
        queryStations: ({
          required double lat,
          required double lng,
          required double radiusKm,
          required FuelType fuelType,
        }) async {
          timestamps.add(DateTime.now().millisecondsSinceEpoch);
          return [];
        },
      );

      expect(timestamps, hasLength(2));
    });
  });
}
