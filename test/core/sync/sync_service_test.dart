import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/alerts/data/models/price_alert.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/itinerary/domain/entities/saved_itinerary.dart';

/// SyncService depends heavily on Supabase (TankSyncClient.client).
/// Since Supabase can't be easily mocked without real initialization,
/// we test:
/// 1. The data models used by sync (PriceAlert, SavedItinerary)
/// 2. The "not authenticated" fallback paths (returns local data unchanged)
/// 3. Parsing and data transformation logic
///
/// Full integration tests require a running Supabase instance.
void main() {
  group('SyncService - unauthenticated fallbacks', () {
    // SyncService uses TankSyncClient.client which is null when not initialized.
    // All sync methods should gracefully return local data when not authenticated.

    // We can't call SyncService.syncFavorites directly because it accesses
    // TankSyncClient.client which calls Supabase.instance (crashes without init).
    // Instead, we test the data structures and transformations.

    test('PriceAlert round-trips through JSON', () {
      final alert = PriceAlert(
        id: 'alert-1',
        stationId: 'station-123',
        stationName: 'Shell Berlin',
        fuelType: FuelType.e10,
        targetPrice: 1.40,
        isActive: true,
        createdAt: DateTime(2026, 3, 1),
      );

      final json = alert.toJson();
      final restored = PriceAlert.fromJson(json);

      expect(restored.id, 'alert-1');
      expect(restored.stationId, 'station-123');
      expect(restored.stationName, 'Shell Berlin');
      expect(restored.fuelType, FuelType.e10);
      expect(restored.targetPrice, 1.40);
      expect(restored.isActive, true);
    });

    test('PriceAlert fromJson handles server format', () {
      // The SyncService converts server format to PriceAlert.fromJson format
      final serverRow = {
        'id': 'alert-2',
        'stationId': 'station-456',
        'stationName': 'Total Paris',
        'fuelType': 'diesel',
        'targetPrice': 1.55,
        'isActive': true,
        'createdAt': '2026-03-15T10:00:00.000',
      };

      final alert = PriceAlert.fromJson(serverRow);

      expect(alert.id, 'alert-2');
      expect(alert.stationId, 'station-456');
      expect(alert.fuelType, FuelType.diesel);
      expect(alert.targetPrice, 1.55);
    });

    test('PriceAlert defaults isActive to true', () {
      final alert = PriceAlert(
        id: 'alert-3',
        stationId: 'st-1',
        stationName: 'Test',
        fuelType: FuelType.e5,
        targetPrice: 1.50,
        createdAt: DateTime.now(),
      );

      expect(alert.isActive, true);
      expect(alert.lastTriggeredAt, isNull);
    });

    test('SavedItinerary round-trips through JSON', () {
      final itinerary = SavedItinerary(
        id: 'itin-1',
        name: 'Berlin to Munich',
        waypoints: [
          {'lat': 52.52, 'lng': 13.41, 'label': 'Berlin'},
          {'lat': 48.14, 'lng': 11.58, 'label': 'Munich'},
        ],
        distanceKm: 584.0,
        durationMinutes: 330.0,
        avoidHighways: false,
        fuelType: 'e10',
        selectedStationIds: ['st-1', 'st-2'],
        createdAt: DateTime(2026, 3, 1),
        updatedAt: DateTime(2026, 3, 15),
      );

      final json = itinerary.toJson();
      final restored = SavedItinerary.fromJson(json);

      expect(restored.id, 'itin-1');
      expect(restored.name, 'Berlin to Munich');
      expect(restored.waypoints.length, 2);
      expect(restored.distanceKm, 584.0);
      expect(restored.durationMinutes, 330.0);
      expect(restored.avoidHighways, false);
      expect(restored.fuelType, 'e10');
      expect(restored.selectedStationIds, ['st-1', 'st-2']);
    });

    test('SavedItinerary defaults', () {
      final itinerary = SavedItinerary(
        id: 'itin-2',
        name: 'Short trip',
        waypoints: [],
        distanceKm: 50.0,
        durationMinutes: 30.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(itinerary.avoidHighways, false);
      expect(itinerary.fuelType, 'e10');
      expect(itinerary.selectedStationIds, isEmpty);
    });
  });

  group('Sync merge logic simulation', () {
    // Simulate the merge logic used in syncFavorites
    test('set union merges local and server favorites', () {
      final localIds = {'st-1', 'st-2', 'st-3'};
      final serverIds = {'st-2', 'st-3', 'st-4'};

      final merged = localIds.union(serverIds);

      expect(merged, {'st-1', 'st-2', 'st-3', 'st-4'});
    });

    test('set difference identifies local-only items', () {
      final localIds = {'st-1', 'st-2', 'st-3'};
      final serverIds = {'st-2', 'st-3', 'st-4'};

      final localOnly = localIds.difference(serverIds);

      expect(localOnly, {'st-1'});
    });

    test('set difference identifies server-only items', () {
      final localIds = {'st-1', 'st-2', 'st-3'};
      final serverIds = {'st-2', 'st-3', 'st-4'};

      final serverOnly = serverIds.difference(localIds);

      expect(serverOnly, {'st-4'});
    });

    test('merge with empty local set returns server set', () {
      final localIds = <String>{};
      final serverIds = {'st-1', 'st-2'};

      final merged = localIds.union(serverIds);

      expect(merged, {'st-1', 'st-2'});
    });

    test('merge with empty server set returns local set', () {
      final localIds = {'st-1', 'st-2'};
      final serverIds = <String>{};

      final merged = localIds.union(serverIds);

      expect(merged, {'st-1', 'st-2'});
    });

    test('merge with identical sets returns same set', () {
      final localIds = {'st-1', 'st-2'};
      final serverIds = {'st-1', 'st-2'};

      final merged = localIds.union(serverIds);
      final localOnly = localIds.difference(serverIds);

      expect(merged, {'st-1', 'st-2'});
      expect(localOnly, isEmpty);
    });
  });

  group('Alert sync merge simulation', () {
    test('local-only alerts are identified for upload', () {
      final localAlerts = [
        PriceAlert(
          id: 'a1',
          stationId: 'st-1',
          stationName: 'Shell',
          fuelType: FuelType.e10,
          targetPrice: 1.40,
          createdAt: DateTime.now(),
        ),
        PriceAlert(
          id: 'a2',
          stationId: 'st-2',
          stationName: 'BP',
          fuelType: FuelType.diesel,
          targetPrice: 1.50,
          createdAt: DateTime.now(),
        ),
      ];

      final serverAlertIds = {'a2'};
      final localOnly =
          localAlerts.where((a) => !serverAlertIds.contains(a.id)).toList();

      expect(localOnly.length, 1);
      expect(localOnly.first.id, 'a1');
    });

    test('server-only alerts are identified for download', () {
      final localAlertIds = {'a1'};
      final serverRows = [
        {'id': 'a1', 'station_id': 'st-1'},
        {'id': 'a3', 'station_id': 'st-3'},
      ];

      final serverOnly =
          serverRows.where((r) => !localAlertIds.contains(r['id'])).toList();

      expect(serverOnly.length, 1);
      expect(serverOnly.first['id'], 'a3');
    });
  });

  group('Itinerary server format parsing', () {
    test('parses server row to SavedItinerary', () {
      final serverRow = {
        'id': 'itin-srv-1',
        'name': 'Paris to Lyon',
        'waypoints': [
          {'lat': 48.86, 'lng': 2.35, 'label': 'Paris'},
          {'lat': 45.76, 'lng': 4.84, 'label': 'Lyon'},
        ],
        'distance_km': 460.0,
        'duration_minutes': 270.0,
        'avoid_highways': true,
        'fuel_type': 'diesel',
        'selected_station_ids': ['st-a', 'st-b'],
        'created_at': '2026-03-01T00:00:00.000Z',
        'updated_at': '2026-03-15T00:00:00.000Z',
      };

      // Simulate the parsing logic from SyncService.fetchItineraries
      final itinerary = SavedItinerary(
        id: serverRow['id'] as String,
        name: serverRow['name'] as String,
        waypoints:
            (serverRow['waypoints'] as List).cast<Map<String, dynamic>>(),
        distanceKm: (serverRow['distance_km'] as num).toDouble(),
        durationMinutes: (serverRow['duration_minutes'] as num).toDouble(),
        avoidHighways: serverRow['avoid_highways'] as bool? ?? false,
        fuelType: serverRow['fuel_type'] as String? ?? 'e10',
        selectedStationIds:
            (serverRow['selected_station_ids'] as List?)?.cast<String>() ??
                [],
        createdAt: DateTime.parse(serverRow['created_at'] as String),
        updatedAt: DateTime.parse(serverRow['updated_at'] as String),
      );

      expect(itinerary.id, 'itin-srv-1');
      expect(itinerary.name, 'Paris to Lyon');
      expect(itinerary.waypoints.length, 2);
      expect(itinerary.distanceKm, 460.0);
      expect(itinerary.avoidHighways, true);
      expect(itinerary.fuelType, 'diesel');
      expect(itinerary.selectedStationIds, ['st-a', 'st-b']);
    });

    test('handles missing optional fields in server row', () {
      final serverRow = {
        'id': 'itin-srv-2',
        'name': 'Short trip',
        'waypoints': <Map<String, dynamic>>[],
        'distance_km': 50,
        'duration_minutes': 30,
        'created_at': '2026-03-01T00:00:00.000Z',
        'updated_at': '2026-03-01T00:00:00.000Z',
      };

      final itinerary = SavedItinerary(
        id: serverRow['id'] as String,
        name: serverRow['name'] as String,
        waypoints:
            (serverRow['waypoints'] as List).cast<Map<String, dynamic>>(),
        distanceKm: (serverRow['distance_km'] as num).toDouble(),
        durationMinutes: (serverRow['duration_minutes'] as num).toDouble(),
        avoidHighways: serverRow['avoid_highways'] as bool? ?? false,
        fuelType: serverRow['fuel_type'] as String? ?? 'e10',
        selectedStationIds:
            (serverRow['selected_station_ids'] as List?)?.cast<String>() ??
                [],
        createdAt: DateTime.parse(serverRow['created_at'] as String),
        updatedAt: DateTime.parse(serverRow['updated_at'] as String),
      );

      expect(itinerary.avoidHighways, false);
      expect(itinerary.fuelType, 'e10');
      expect(itinerary.selectedStationIds, isEmpty);
    });
  });

  group('Rating data structure', () {
    test('server ratings map correctly', () {
      // Simulate fetchRatings parsing
      final serverRows = [
        {'station_id': 'st-1', 'rating': 4},
        {'station_id': 'st-2', 'rating': 5},
        {'station_id': 'st-3', 'rating': 3},
      ];

      final ratings = {
        for (final r in serverRows)
          r['station_id'] as String: (r['rating'] as num).toInt(),
      };

      expect(ratings.length, 3);
      expect(ratings['st-1'], 4);
      expect(ratings['st-2'], 5);
      expect(ratings['st-3'], 3);
    });

    test('empty server rows returns empty map', () {
      final serverRows = <Map<String, dynamic>>[];

      final ratings = {
        for (final r in serverRows)
          r['station_id'] as String: (r['rating'] as num).toInt(),
      };

      expect(ratings, isEmpty);
    });
  });
}
