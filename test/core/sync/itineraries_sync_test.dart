import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/itineraries_sync.dart';
import 'package:tankstellen/features/itinerary/domain/entities/saved_itinerary.dart';

/// Contract tests for [ItinerariesSync] (#727 extract). Higher-
/// fidelity coverage lives at the repository-contract level; these
/// pin the unauthenticated guards for each method.
void main() {
  group('ItinerariesSync auth guards', () {
    test('save returns false when unauthenticated', () async {
      final itinerary = SavedItinerary(
        id: 'it-1',
        name: 'Pomerols → Castelnau',
        waypoints: const [],
        distanceKm: 15.0,
        durationMinutes: 20.0,
        avoidHighways: false,
        fuelType: 'e10',
        selectedStationIds: const [],
        createdAt: DateTime(2026, 4, 22),
        updatedAt: DateTime(2026, 4, 22),
      );
      final result = await ItinerariesSync.save(itinerary);
      expect(result, isFalse);
    });

    test('fetchAll returns empty list when unauthenticated', () async {
      final result = await ItinerariesSync.fetchAll();
      expect(result, isEmpty);
    });

    test('delete returns false when unauthenticated', () async {
      final result = await ItinerariesSync.delete('it-1');
      expect(result, isFalse);
    });
  });
}
