import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/impl/supabase_sync_repository.dart';
import 'package:tankstellen/core/data/sync_repository.dart';
import 'package:tankstellen/features/alerts/data/models/price_alert.dart';
import 'package:tankstellen/features/itinerary/domain/entities/saved_itinerary.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

/// Tests that [SupabaseSyncRepository] is a thin adapter delegating to
/// [SyncService]. Since TankSyncClient is not initialized in tests,
/// all methods hit the "not authenticated" fallback path — returning
/// local data unchanged. This verifies the delegation works end-to-end.
void main() {
  late SupabaseSyncRepository repo;

  setUp(() {
    repo = SupabaseSyncRepository();
  });

  group('SupabaseSyncRepository implements SyncRepository', () {
    test('is a SyncRepository', () {
      expect(repo, isA<SyncRepository>());
    });

    test('isConnected returns false when TankSyncClient not initialized', () {
      expect(repo.isConnected, isFalse);
    });

    test('authenticatedUserId returns null when not connected', () {
      expect(repo.authenticatedUserId, isNull);
    });
  });

  group('SupabaseSyncRepository - unauthenticated delegation', () {
    // All methods delegate to SyncService static methods.
    // Without a Supabase connection, they return local data unchanged.

    test('syncFavorites returns local ids when not authenticated', () async {
      final localIds = ['st-1', 'st-2', 'st-3'];
      final result = await repo.syncFavorites(localIds);
      expect(result, localIds);
    });

    test('syncFavorites returns empty list when given empty list', () async {
      final result = await repo.syncFavorites([]);
      expect(result, isEmpty);
    });

    test('deleteFavorite completes without error when not authenticated', () async {
      // Should not throw — just no-ops when not connected
      await expectLater(repo.deleteFavorite('st-1'), completes);
    });

    test('syncIgnoredStations returns local ids when not authenticated', () async {
      final localIds = ['st-10', 'st-20'];
      final result = await repo.syncIgnoredStations(localIds);
      expect(result, localIds);
    });

    test('syncRating completes without error when not authenticated', () async {
      await expectLater(
        repo.syncRating('st-1', 4, shared: false),
        completes,
      );
    });

    test('syncRating with shared flag completes without error', () async {
      await expectLater(
        repo.syncRating('st-1', 5, shared: true),
        completes,
      );
    });

    test('deleteRating completes without error when not authenticated', () async {
      await expectLater(repo.deleteRating('st-1'), completes);
    });

    test('fetchRatings returns empty map when not authenticated', () async {
      final result = await repo.fetchRatings();
      expect(result, isEmpty);
    });

    test('syncAlerts returns local alerts when not authenticated', () async {
      final alerts = [
        PriceAlert(
          id: 'a1',
          stationId: 'st-1',
          stationName: 'Shell',
          fuelType: FuelType.e10,
          targetPrice: 1.40,
          createdAt: DateTime(2026, 3, 1),
        ),
        PriceAlert(
          id: 'a2',
          stationId: 'st-2',
          stationName: 'BP',
          fuelType: FuelType.diesel,
          targetPrice: 1.55,
          createdAt: DateTime(2026, 3, 15),
        ),
      ];

      final result = await repo.syncAlerts(alerts);
      expect(result.length, 2);
      expect(result.first.id, 'a1');
      expect(result.last.id, 'a2');
    });

    test('syncAlerts returns empty list when given empty list', () async {
      final result = await repo.syncAlerts([]);
      expect(result, isEmpty);
    });

    test('fetchPriceHistory returns empty list when not authenticated', () async {
      final result = await repo.fetchPriceHistory('st-1');
      expect(result, isEmpty);
    });

    test('fetchPriceHistory with custom days returns empty list', () async {
      final result = await repo.fetchPriceHistory('st-1', days: 7);
      expect(result, isEmpty);
    });

    test('saveItinerary returns false when not authenticated', () async {
      final itinerary = SavedItinerary(
        id: 'itin-1',
        name: 'Berlin to Munich',
        waypoints: [
          {'lat': 52.52, 'lng': 13.41, 'label': 'Berlin'},
        ],
        distanceKm: 584.0,
        durationMinutes: 330.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = await repo.saveItinerary(itinerary);
      expect(result, isFalse);
    });

    test('fetchItineraries returns empty list when not authenticated', () async {
      final result = await repo.fetchItineraries();
      expect(result, isEmpty);
    });

    test('deleteItinerary returns false when not authenticated', () async {
      final result = await repo.deleteItinerary('itin-1');
      expect(result, isFalse);
    });

    test('fetchAllUserData returns error when not authenticated', () async {
      final result = await repo.fetchAllUserData();
      expect(result.containsKey('error'), isTrue);
    });

    test('deleteAllUserData completes without error when not authenticated', () async {
      await expectLater(repo.deleteAllUserData(), completes);
    });
  });
}
