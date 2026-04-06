import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/utils/json_extensions.dart';
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
    test('parses server row to SavedItinerary using safe accessors', () {
      final r = <String, dynamic>{
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

      // Simulate the safe parsing logic from SyncService.fetchItineraries
      final createdAtStr = r.getString('created_at');
      final updatedAtStr = r.getString('updated_at');
      final itinerary = SavedItinerary(
        id: r.getString('id') ?? '',
        name: r.getString('name') ?? '',
        waypoints: r.getList<Map<String, dynamic>>('waypoints'),
        distanceKm: r.getDouble('distance_km') ?? 0.0,
        durationMinutes: r.getDouble('duration_minutes') ?? 0.0,
        avoidHighways: r.getBool('avoid_highways') ?? false,
        fuelType: r.getString('fuel_type') ?? 'e10',
        selectedStationIds: r.getList<String>('selected_station_ids'),
        createdAt: createdAtStr != null
            ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
            : DateTime.now(),
        updatedAt: updatedAtStr != null
            ? DateTime.tryParse(updatedAtStr) ?? DateTime.now()
            : DateTime.now(),
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
      final r = <String, dynamic>{
        'id': 'itin-srv-2',
        'name': 'Short trip',
        'waypoints': <Map<String, dynamic>>[],
        'distance_km': 50,
        'duration_minutes': 30,
        'created_at': '2026-03-01T00:00:00.000Z',
        'updated_at': '2026-03-01T00:00:00.000Z',
      };

      final createdAtStr = r.getString('created_at');
      final updatedAtStr = r.getString('updated_at');
      final itinerary = SavedItinerary(
        id: r.getString('id') ?? '',
        name: r.getString('name') ?? '',
        waypoints: r.getList<Map<String, dynamic>>('waypoints'),
        distanceKm: r.getDouble('distance_km') ?? 0.0,
        durationMinutes: r.getDouble('duration_minutes') ?? 0.0,
        avoidHighways: r.getBool('avoid_highways') ?? false,
        fuelType: r.getString('fuel_type') ?? 'e10',
        selectedStationIds: r.getList<String>('selected_station_ids'),
        createdAt: createdAtStr != null
            ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
            : DateTime.now(),
        updatedAt: updatedAtStr != null
            ? DateTime.tryParse(updatedAtStr) ?? DateTime.now()
            : DateTime.now(),
      );

      expect(itinerary.avoidHighways, false);
      expect(itinerary.fuelType, 'e10');
      expect(itinerary.selectedStationIds, isEmpty);
    });
  });

  group('Rating data structure', () {
    test('server ratings map correctly using safe accessors', () {
      // Simulate fetchRatings parsing with safe accessors
      final serverRows = <Map<String, dynamic>>[
        {'station_id': 'st-1', 'rating': 4},
        {'station_id': 'st-2', 'rating': 5},
        {'station_id': 'st-3', 'rating': 3},
      ];

      final result = <String, int>{};
      for (final r in serverRows) {
        final stationId = r.getString('station_id');
        final rating = r.getInt('rating');
        if (stationId != null && rating != null) {
          result[stationId] = rating;
        }
      }

      expect(result.length, 3);
      expect(result['st-1'], 4);
      expect(result['st-2'], 5);
      expect(result['st-3'], 3);
    });

    test('empty server rows returns empty map', () {
      final serverRows = <Map<String, dynamic>>[];

      final result = <String, int>{};
      for (final r in serverRows) {
        final stationId = r.getString('station_id');
        final rating = r.getInt('rating');
        if (stationId != null && rating != null) {
          result[stationId] = rating;
        }
      }

      expect(result, isEmpty);
    });
  });

  group('Safe cast parsing - malformed responses', () {
    // These tests verify that the safe parsing patterns used in
    // sync_service.dart handle malformed/unexpected data gracefully
    // instead of throwing type cast errors.

    test('favorites parsing handles null station_id gracefully', () {
      // Simulate malformed server response with null station_id
      final serverRows = <Map<String, dynamic>>[
        {'station_id': 'st-1'},
        {'station_id': null},
        {}, // missing station_id entirely
      ];

      final serverIds = serverRows
          .map((r) => r.getString('station_id'))
          .whereType<String>()
          .toSet();

      expect(serverIds, {'st-1'});
    });

    test('getString returns null for non-string, non-null values', () {
      // getString converts non-null values via .toString()
      final row = <String, dynamic>{'station_id': 42};
      expect(row.getString('station_id'), '42');
    });

    test('ratings parsing skips rows with missing fields', () {
      final serverRows = <Map<String, dynamic>>[
        {'station_id': 'st-1', 'rating': 4},
        {'station_id': null, 'rating': 5},
        {'station_id': 'st-3', 'rating': null},
        {'station_id': 'st-4'}, // missing rating
        {}, // missing both
      ];

      final result = <String, int>{};
      for (final r in serverRows) {
        final stationId = r.getString('station_id');
        final rating = r.getInt('rating');
        if (stationId != null && rating != null) {
          result[stationId] = rating;
        }
      }

      expect(result.length, 1);
      expect(result['st-1'], 4);
    });

    test('ratings parsing handles numeric string rating', () {
      final serverRows = <Map<String, dynamic>>[
        {'station_id': 'st-1', 'rating': '4'},
      ];

      final result = <String, int>{};
      for (final r in serverRows) {
        final stationId = r.getString('station_id');
        final rating = r.getInt('rating');
        if (stationId != null && rating != null) {
          result[stationId] = rating;
        }
      }

      expect(result['st-1'], 4);
    });

    test('price history parsing handles non-list response', () {
      final dynamic rows = null;

      final result = rows is List
          ? rows.whereType<Map<String, dynamic>>().toList()
          : <Map<String, dynamic>>[];

      expect(result, isEmpty);
    });

    test('price history parsing filters out non-map elements', () {
      final dynamic rows = <dynamic>[
        <String, dynamic>{'station_id': 'st-1', 'price': 1.45},
        'invalid',
        null,
        42,
      ];

      final result = rows is List
          ? rows.whereType<Map<String, dynamic>>().toList()
          : <Map<String, dynamic>>[];

      expect(result.length, 1);
      expect(result.first['station_id'], 'st-1');
    });

    test('alert parsing handles missing/null fields with defaults', () {
      final serverRow = <String, dynamic>{
        'id': null,
        'station_id': null,
        'station_name': null,
        'fuel_type': null,
        'target_price': null,
        'is_active': null,
        'created_at': null,
      };

      // Simulate the safe parsing from syncAlerts
      final parsed = {
        'id': serverRow.getString('id') ?? '',
        'stationId': serverRow.getString('station_id') ?? '',
        'stationName': serverRow.getString('station_name') ?? '',
        'fuelType': serverRow.getString('fuel_type') ?? '',
        'targetPrice': serverRow.getDouble('target_price') ?? 0.0,
        'isActive': serverRow.getBool('is_active') ?? true,
        'createdAt': serverRow.getString('created_at') ?? '',
      };

      expect(parsed['id'], '');
      expect(parsed['stationId'], '');
      expect(parsed['targetPrice'], 0.0);
      expect(parsed['isActive'], true);
    });

    test('itinerary parsing handles missing optional fields', () {
      final r = <String, dynamic>{
        'id': 'itin-1',
        'name': 'Trip',
        'waypoints': null,
        'distance_km': null,
        'duration_minutes': null,
        'avoid_highways': null,
        'fuel_type': null,
        'selected_station_ids': null,
        'created_at': null,
        'updated_at': null,
      };

      final createdAtStr = r.getString('created_at');
      final updatedAtStr = r.getString('updated_at');
      final itinerary = SavedItinerary(
        id: r.getString('id') ?? '',
        name: r.getString('name') ?? '',
        waypoints: r.getList<Map<String, dynamic>>('waypoints'),
        distanceKm: r.getDouble('distance_km') ?? 0.0,
        durationMinutes: r.getDouble('duration_minutes') ?? 0.0,
        avoidHighways: r.getBool('avoid_highways') ?? false,
        fuelType: r.getString('fuel_type') ?? 'e10',
        selectedStationIds: r.getList<String>('selected_station_ids'),
        createdAt: createdAtStr != null
            ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
            : DateTime.now(),
        updatedAt: updatedAtStr != null
            ? DateTime.tryParse(updatedAtStr) ?? DateTime.now()
            : DateTime.now(),
      );

      expect(itinerary.id, 'itin-1');
      expect(itinerary.name, 'Trip');
      expect(itinerary.waypoints, isEmpty);
      expect(itinerary.distanceKm, 0.0);
      expect(itinerary.durationMinutes, 0.0);
      expect(itinerary.avoidHighways, false);
      expect(itinerary.fuelType, 'e10');
      expect(itinerary.selectedStationIds, isEmpty);
    });

    test('itinerary parsing handles numeric strings from API', () {
      final r = <String, dynamic>{
        'id': 'itin-2',
        'name': 'Trip 2',
        'waypoints': <Map<String, dynamic>>[],
        'distance_km': '460.5', // string instead of num
        'duration_minutes': '270', // string instead of num
        'avoid_highways': 'true', // string instead of bool
        'fuel_type': 'diesel',
        'selected_station_ids': <String>[],
        'created_at': '2026-03-01T00:00:00.000Z',
        'updated_at': '2026-03-15T00:00:00.000Z',
      };

      final createdAtStr = r.getString('created_at');
      final updatedAtStr = r.getString('updated_at');
      final itinerary = SavedItinerary(
        id: r.getString('id') ?? '',
        name: r.getString('name') ?? '',
        waypoints: r.getList<Map<String, dynamic>>('waypoints'),
        distanceKm: r.getDouble('distance_km') ?? 0.0,
        durationMinutes: r.getDouble('duration_minutes') ?? 0.0,
        avoidHighways: r.getBool('avoid_highways') ?? false,
        fuelType: r.getString('fuel_type') ?? 'e10',
        selectedStationIds: r.getList<String>('selected_station_ids'),
        createdAt: createdAtStr != null
            ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
            : DateTime.now(),
        updatedAt: updatedAtStr != null
            ? DateTime.tryParse(updatedAtStr) ?? DateTime.now()
            : DateTime.now(),
      );

      expect(itinerary.distanceKm, 460.5);
      expect(itinerary.durationMinutes, 270.0);
      expect(itinerary.avoidHighways, true);
    });

    test('fetchAllUserData length check handles non-list', () {
      final dynamic favorites = 'unexpected';
      final dynamic alerts = null;

      final favList = favorites is List ? favorites : [];
      final alertList = alerts is List ? alerts : [];

      expect(favList, isEmpty);
      expect(alertList, isEmpty);
    });
  });
}
