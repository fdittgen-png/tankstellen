import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/itinerary/domain/entities/saved_itinerary.dart';

void main() {
  group('SavedItinerary — construction', () {
    test('requires identity + route metrics and preserves them', () {
      final created = DateTime.utc(2026, 4, 1, 10);
      final updated = DateTime.utc(2026, 4, 2, 11);
      final itinerary = SavedItinerary(
        id: 'abc-123',
        name: 'Weekend trip',
        waypoints: const [
          {'lat': 48.85, 'lng': 2.35, 'label': 'Paris'},
          {'lat': 43.30, 'lng': 5.37, 'label': 'Marseille'},
        ],
        distanceKm: 776.4,
        durationMinutes: 430.0,
        createdAt: created,
        updatedAt: updated,
      );
      expect(itinerary.id, 'abc-123');
      expect(itinerary.name, 'Weekend trip');
      expect(itinerary.waypoints.length, 2);
      expect(itinerary.waypoints.first['label'], 'Paris');
      expect(itinerary.distanceKm, 776.4);
      expect(itinerary.durationMinutes, 430.0);
      expect(itinerary.createdAt, created);
      expect(itinerary.updatedAt, updated);
    });

    test('optional fields default to avoidHighways=false, fuelType=e10, empty stations',
        () {
      // Defaults matter because they land in the cloud-sync payload — a
      // user who never picked a fuel type should not accidentally enshrine
      // "diesel" server-side.
      final itinerary = SavedItinerary(
        id: 'x',
        name: 'n',
        waypoints: const [],
        distanceKm: 0,
        durationMinutes: 0,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
      expect(itinerary.avoidHighways, isFalse);
      expect(itinerary.fuelType, 'e10');
      expect(itinerary.selectedStationIds, isEmpty);
    });

    test('overrides take precedence over defaults', () {
      final itinerary = SavedItinerary(
        id: 'x',
        name: 'n',
        waypoints: const [],
        distanceKm: 0,
        durationMinutes: 0,
        avoidHighways: true,
        fuelType: 'diesel',
        selectedStationIds: const ['s1', 's2'],
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
      expect(itinerary.avoidHighways, isTrue);
      expect(itinerary.fuelType, 'diesel');
      expect(itinerary.selectedStationIds, ['s1', 's2']);
    });
  });

  group('SavedItinerary — copyWith + equality', () {
    test('copyWith(name:) only rewrites the name', () {
      final original = SavedItinerary(
        id: 'x',
        name: 'old',
        waypoints: const [],
        distanceKm: 100,
        durationMinutes: 60,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 2),
      );
      final updated = original.copyWith(name: 'new');
      expect(updated.name, 'new');
      expect(updated.id, 'x');
      expect(updated.distanceKm, 100);
      expect(updated.createdAt, original.createdAt);
    });

    test('two itineraries with identical fields are equal', () {
      final a = SavedItinerary(
        id: 'x',
        name: 'n',
        waypoints: const [],
        distanceKm: 10,
        durationMinutes: 5,
        createdAt: DateTime.utc(2026, 2, 1),
        updatedAt: DateTime.utc(2026, 2, 1),
      );
      final b = SavedItinerary(
        id: 'x',
        name: 'n',
        waypoints: const [],
        distanceKm: 10,
        durationMinutes: 5,
        createdAt: DateTime.utc(2026, 2, 1),
        updatedAt: DateTime.utc(2026, 2, 1),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('SavedItinerary — JSON round-trip', () {
    test('fromJson(toJson(x)) == x for a fully-populated itinerary', () {
      final original = SavedItinerary(
        id: 'it-42',
        name: 'Tour de France',
        waypoints: const [
          {'lat': 48.85, 'lng': 2.35},
          {'lat': 43.30, 'lng': 5.37},
        ],
        distanceKm: 776.4,
        durationMinutes: 430.0,
        avoidHighways: true,
        fuelType: 'diesel',
        selectedStationIds: const ['s1', 's7'],
        createdAt: DateTime.utc(2026, 4, 1, 10),
        updatedAt: DateTime.utc(2026, 4, 2, 11),
      );
      final decoded = SavedItinerary.fromJson(original.toJson());
      expect(decoded, equals(original));
    });
  });
}
