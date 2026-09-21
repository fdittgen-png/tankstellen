// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// #4359 — the travel-leg contract, by its own worked numbers.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/travel_estimate.dart';

void main() {
  final at = DateTime.utc(2026, 9, 16, 12);
  const origin = TravelPoint(48.0, 2.0);
  const destination = TravelPoint(48.9, 2.3);

  const journey = TravelContext(
    origin: origin,
    destination: destination,
    purpose: TravelPurpose.stopOnJourney,
  );
  const errand =
      TravelContext(origin: origin, purpose: TravelPurpose.errandReturn);

  group('a stop on a journey: three quantities, never one', () {
    // Direct 100 km / 80 min; via the station 112 km / 98 min.
    final e = StationTravelEstimate.routed(
      stationId: 's',
      context: journey,
      toStation: const TravelLeg(distanceKm: 40, durationMinutes: 35),
      fromStation: const TravelLeg(distanceKm: 72, durationMinutes: 63),
      baseline: const TravelLeg(distanceKm: 100, durationMinutes: 80),
      calculatedAt: at,
    );

    test('to the station, the itinerary, and the extra are all carried', () {
      expect(e.toStation.distanceKm, 40);
      expect(e.itinerary.distanceKm, 112);
      expect(e.itinerary.durationMinutes, 98);
      expect(e.extraKm, 12, reason: '112 km is the itinerary, not the detour');
      expect(e.extraDrivingMinutes, 18);
      expect(e.status, TravelEstimateStatus.roadVerified);
      expect(e.isActionable, isTrue);
    });

    test('stop overhead is an estimate kept OUT of the road duration', () {
      expect(e.stopOverheadMinutes, kDefaultStopOverheadMinutes);
      expect(e.extraDrivingMinutes, 18);
    });

    test('charges are unknown, never free', () {
      expect(e.charges.isKnown, isFalse);
      expect(e.charges.amount, isNull);
    });
  });

  test('a 3 km outbound / 7 km return errand is 10 km, not 6', () {
    final e = StationTravelEstimate.routed(
      stationId: 's',
      context: errand,
      toStation: const TravelLeg(distanceKm: 3, durationMinutes: 5),
      fromStation: const TravelLeg(distanceKm: 7, durationMinutes: 11),
      baseline: TravelLeg.zero,
      calculatedAt: at,
    );
    expect(e.itinerary.distanceKm, 10);
    expect(e.extraKm, 10);
    expect(e.extraDrivingMinutes, 16);
  });

  test('a one-way errand counts only the outbound leg', () {
    final e = StationTravelEstimate.routed(
      stationId: 's',
      context:
          const TravelContext(origin: origin, purpose: TravelPurpose.errandOneWay),
      toStation: const TravelLeg(distanceKm: 3, durationMinutes: 5),
      fromStation: const TravelLeg(),
      baseline: TravelLeg.zero,
      calculatedAt: at,
    );
    expect(e.extraKm, 3);
    expect(e.isActionable, isTrue);
  });

  group('failures stay failures', () {
    test('a missing distance is unreachable — never filled by a duration',
        () {
      final e = StationTravelEstimate.routed(
        stationId: 's',
        context: errand,
        toStation: const TravelLeg(durationMinutes: 5),
        fromStation: const TravelLeg(distanceKm: 7, durationMinutes: 11),
        baseline: TravelLeg.zero,
        calculatedAt: at,
      );
      expect(e.itinerary.distanceKm, isNull);
      expect(e.itinerary.durationMinutes, 16);
      expect(e.status, TravelEstimateStatus.unreachable);
      expect(e.isActionable, isFalse);
    });

    test('an unknown duration is never "fastest": extra minutes stay null',
        () {
      final e = StationTravelEstimate.routed(
        stationId: 's',
        context: errand,
        toStation: const TravelLeg(distanceKm: 3),
        fromStation: const TravelLeg(distanceKm: 7, durationMinutes: 11),
        baseline: TravelLeg.zero,
        calculatedAt: at,
      );
      expect(e.extraKm, 10);
      expect(e.extraDrivingMinutes, isNull);
    });

    test('a negative detour beyond tolerance is flagged for revalidation',
        () {
      final e = StationTravelEstimate.routed(
        stationId: 's',
        context: journey,
        toStation: const TravelLeg(distanceKm: 40, durationMinutes: 30),
        fromStation: const TravelLeg(distanceKm: 55, durationMinutes: 45),
        baseline: const TravelLeg(distanceKm: 100, durationMinutes: 80),
        calculatedAt: at,
      );
      expect(e.extraKm, -5);
      expect(e.status, TravelEstimateStatus.inconsistentBaseline);
      expect(e.isActionable, isFalse);
    });

    test('snap noise inside the tolerance is not a mismatch', () {
      final e = StationTravelEstimate.routed(
        stationId: 's',
        context: journey,
        toStation: const TravelLeg(distanceKm: 40, durationMinutes: 30),
        fromStation: const TravelLeg(distanceKm: 59.9, durationMinutes: 50),
        baseline: const TravelLeg(distanceKm: 100, durationMinutes: 80),
        calculatedAt: at,
      );
      expect(e.status, TravelEstimateStatus.roadVerified);
    });
  });

  group('the context is the identity', () {
    test('constraints, heading, purpose, destination and revision all key',
        () {
      final keys = {
        journey.cacheKey,
        errand.cacheKey,
        const TravelContext(
          origin: origin,
          destination: destination,
          purpose: TravelPurpose.stopOnJourney,
          constraints: {TravelConstraint.avoidFerries},
        ).cacheKey,
        const TravelContext(
          origin: origin,
          destination: destination,
          purpose: TravelPurpose.stopOnJourney,
          headingDegrees: 180,
        ).cacheKey,
        const TravelContext(
          origin: origin,
          destination: TravelPoint(47.0, 2.3),
          purpose: TravelPurpose.stopOnJourney,
        ).cacheKey,
        const TravelContext(
          origin: origin,
          destination: destination,
          purpose: TravelPurpose.stopOnJourney,
          routeRevision: 1,
        ).cacheKey,
      };
      expect(keys, hasLength(6));
    });

    test('GPS jitter inside one cell reuses the key (request budget)', () {
      const jittered = TravelContext(
          origin: TravelPoint(48.0003, 2.0002),
          purpose: TravelPurpose.errandReturn);
      expect(jittered.cacheKey, errand.cacheKey);
    });

    test('a quote is current only for its own context and age', () {
      final e = StationTravelEstimate.routed(
        stationId: 's',
        context: errand,
        toStation: const TravelLeg(distanceKm: 3, durationMinutes: 5),
        fromStation: const TravelLeg(distanceKm: 7, durationMinutes: 11),
        baseline: TravelLeg.zero,
        calculatedAt: at,
      );
      expect(e.isCurrentFor(errand, at.add(const Duration(minutes: 5))),
          isTrue);
      expect(e.isCurrentFor(journey, at), isFalse);
      expect(
          e.isCurrentFor(
              errand, at.add(kTravelEstimateMaxAge + const Duration(seconds: 1))),
          isFalse);
    });
  });
}
