import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/sync_repository.dart';
import 'package:tankstellen/features/alerts/data/models/price_alert.dart';
import 'package:tankstellen/features/itinerary/domain/entities/saved_itinerary.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

void main() {
  group('SyncRepository interface', () {
    test('can be implemented by a mock', () {
      final mock = _MockSyncRepository();
      expect(mock, isA<SyncRepository>());
      expect(mock.isConnected, isFalse);
      expect(mock.authenticatedUserId, isNull);
    });

    test('syncFavorites returns merged list', () async {
      final mock = _MockSyncRepository();
      final result = await mock.syncFavorites(['s1', 's2']);
      expect(result, ['s1', 's2']);
    });

    test('syncAlerts returns local alerts when disconnected', () async {
      final mock = _MockSyncRepository();
      final alert = PriceAlert(
        id: 'a1', stationId: 's1', stationName: 'Test',
        fuelType: FuelType.diesel, targetPrice: 1.5,
        createdAt: DateTime.now(),
      );
      final result = await mock.syncAlerts([alert]);
      expect(result.length, 1);
      expect(result.first.id, 'a1');
    });

    test('fetchPriceHistory returns empty when disconnected', () async {
      final mock = _MockSyncRepository();
      final result = await mock.fetchPriceHistory('s1');
      expect(result, isEmpty);
    });

    test('fetchAllUserData returns error when disconnected', () async {
      final mock = _MockSyncRepository();
      final result = await mock.fetchAllUserData();
      expect(result.containsKey('error'), isTrue);
    });
  });
}

class _MockSyncRepository implements SyncRepository {
  @override bool get isConnected => false;
  @override String? get authenticatedUserId => null;

  @override Future<List<String>> syncFavorites(List<String> ids) async => ids;
  @override Future<void> deleteFavorite(String id) async {}
  @override Future<List<String>> syncIgnoredStations(List<String> ids) async => ids;
  @override Future<void> syncRating(String id, int r, {bool shared = false}) async {}
  @override Future<void> deleteRating(String id) async {}
  @override Future<Map<String, int>> fetchRatings() async => {};
  @override Future<List<PriceAlert>> syncAlerts(List<PriceAlert> a) async => a;
  @override Future<List<Map<String, dynamic>>> fetchPriceHistory(String id, {int days = 30}) async => [];
  @override Future<bool> saveItinerary(SavedItinerary i) async => false;
  @override Future<List<SavedItinerary>> fetchItineraries() async => [];
  @override Future<bool> deleteItinerary(String id) async => false;
  @override Future<Map<String, dynamic>> fetchAllUserData() async => {'error': 'disconnected'};
  @override Future<void> deleteAllUserData() async {}
}
