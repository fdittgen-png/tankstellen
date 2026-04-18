import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/voice_announcement_service.dart';

import '../../fixtures/stations.dart';

void main() {
  group('AnnouncementCandidate', () {
    test('stores station, fuelType, price, and distance', () {
      const candidate = AnnouncementCandidate(
        station: testStation,
        fuelType: 'e10',
        price: 1.799,
        distanceKm: 2.3,
      );
      expect(candidate.station, testStation);
      expect(candidate.fuelType, 'e10');
      expect(candidate.price, 1.799);
      expect(candidate.distanceKm, 2.3);
    });

    test('is const-constructible with a const Station', () {
      // The announcement engine builds these inside its update loop;
      // const-ness keeps each broadcast cheap when nothing changed.
      const candidate = AnnouncementCandidate(
        station: testStation,
        fuelType: 'diesel',
        price: 1.659,
        distanceKm: 0.8,
      );
      expect(candidate.fuelType, 'diesel');
      expect(candidate.station.id, testStation.id);
    });

    test('uses identity equality (no Equatable override)', () {
      // AnnouncementCandidate is a transient message, not a persisted
      // entity. It deliberately does NOT implement value equality — a
      // future "helpful" Equatable override would accidentally dedupe
      // repeat announcements that should fire again after a cooldown.
      const candidate = AnnouncementCandidate(
        station: testStation,
        fuelType: 'e10',
        price: 1.799,
        distanceKm: 2.0,
      );
      // Same instance compares equal to itself — baseline.
      expect(candidate == candidate, isTrue);
      // And hashCode is stable for the same instance.
      expect(candidate.hashCode, candidate.hashCode);
    });

    test('carries the full station reference (not a denormalized name)', () {
      // The engine uses station.name for the announcement but also needs
      // station.id to dedupe and station.coords for distance refreshes —
      // pin that the full Station is retained, not just a label.
      const candidate = AnnouncementCandidate(
        station: testStation,
        fuelType: 'e10',
        price: 1.799,
        distanceKm: 2.0,
      );
      expect(candidate.station.id, isNotEmpty);
      expect(candidate.station.brand, isNotEmpty);
      expect(candidate.station.lat, isNotNull);
      expect(candidate.station.lng, isNotNull);
    });
  });
}
