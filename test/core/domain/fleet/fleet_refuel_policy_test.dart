// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fleet/fleet_refuel_policy.dart';
import 'package:tankstellen/core/domain/refuel_economics.dart';
import 'package:tankstellen/core/domain/travel_estimate.dart';

/// #4214 (F6) — the fleet policy is a PURE PRE-FILTER.
///
/// The property the whole slice rests on: removing candidates may not
/// change how the remainder ranks. `RefuelEconomics.decide` is called
/// unchanged on the eligible subset, so the filtered decision must agree,
/// station for station, with the unfiltered decision restricted to that
/// subset.
void main() {
  const context = TravelContext(
    origin: TravelPoint(48.13, 11.58),
    purpose: TravelPurpose.errandReturn,
  );
  final calculatedAt = DateTime.utc(2026, 9, 18, 10);

  StationTravelEstimate routed(String id, double toKm, double minutes) =>
      StationTravelEstimate.routed(
        stationId: id,
        context: context,
        toStation: TravelLeg(distanceKm: toKm, durationMinutes: minutes),
        fromStation: TravelLeg(distanceKm: toKm, durationMinutes: minutes),
        baseline: TravelLeg.zero,
        calculatedAt: calculatedAt,
      );

  RefuelCandidate candidate(
    String id, {
    required double km,
    required double price,
    StationTravelEstimate? travel,
  }) =>
      RefuelCandidate(
        stationId: id,
        oneWayKm: km,
        pricePerLitre: price,
        roadTravel: travel,
      );

  const profile = RefuelProfile(consumptionLPer100km: 6.5);

  group('applyFleetPolicy', () {
    test('an empty policy excludes nothing and preserves input order', () {
      final candidates = [
        candidate('c', km: 3, price: 1.71),
        candidate('a', km: 1, price: 1.80),
        candidate('b', km: 9, price: 1.62),
      ];

      final outcome = applyFleetPolicy(candidates, const FleetRefuelPolicy());

      expect(outcome.excluded, isEmpty);
      expect(
        [for (final c in outcome.eligible) c.stationId],
        ['c', 'a', 'b'],
      );
      expect(identical(outcome.eligible.first, candidates.first), isTrue,
          reason: 'the pre-filter selects candidates, it never rebuilds them');
    });

    test('is deterministic: the same inputs produce an equal outcome', () {
      final candidates = [
        candidate('shell-1', km: 2, price: 1.75),
        candidate('aral-2', km: 12, price: 1.60),
        candidate('free-3', km: 4, price: 1.68),
      ];
      const policy = FleetRefuelPolicy(
        allowedNetworks: {'Shell', 'Aral'},
        maxDetourKm: 5,
      );
      String? brandOf(String id) => switch (id) {
            'shell-1' => 'shell',
            'aral-2' => 'aral',
            _ => 'freie tankstelle',
          };

      final first = applyFleetPolicy(candidates, policy, brandOf: brandOf);
      final second = applyFleetPolicy(candidates, policy, brandOf: brandOf);

      expect([for (final c in second.eligible) c.stationId],
          [for (final c in first.eligible) c.stationId]);
      expect(second.excluded, first.excluded);
    });

    test('brand matching ignores case and surrounding whitespace', () {
      final outcome = applyFleetPolicy(
        [candidate('s1', km: 1, price: 1.7)],
        const FleetRefuelPolicy(allowedNetworks: {'  Shell '}),
        brandOf: (_) => 'SHELL',
      );

      expect(outcome.excluded, isEmpty);
      expect(outcome.eligible, hasLength(1));
    });
  });

  group('exclusion reasons', () {
    test('a station outside allowedNetworks is networkNotAllowed', () {
      final outcome = applyFleetPolicy(
        [candidate('s1', km: 1, price: 1.7)],
        const FleetRefuelPolicy(allowedNetworks: {'shell'}),
        brandOf: (_) => 'jet',
      );

      expect(outcome.eligible, isEmpty);
      expect(outcome.excluded['s1']!.reason,
          PolicyExclusionReason.networkNotAllowed);
      expect(outcome.excluded['s1']!.approximate, isFalse);
    });

    test('an unknown brand under a network policy is networkUnknown, '
        'never silently allowed', () {
      final outcome = applyFleetPolicy(
        [candidate('s1', km: 1, price: 1.7)],
        const FleetRefuelPolicy(allowedNetworks: {'shell'}),
      );

      expect(outcome.eligible, isEmpty);
      expect(
          outcome.excluded['s1']!.reason, PolicyExclusionReason.networkUnknown);
    });

    test('an allowed brand that takes no fuel card is fuelCardNotAccepted', () {
      final outcome = applyFleetPolicy(
        [candidate('s1', km: 1, price: 1.7)],
        const FleetRefuelPolicy(
          allowedNetworks: {'shell', 'jet'},
          fuelCardNetworks: {'shell'},
        ),
        brandOf: (_) => 'jet',
      );

      expect(outcome.excluded['s1']!.reason,
          PolicyExclusionReason.fuelCardNotAccepted);
    });

    test('a road-verified detour over maxDetourKm is detourTooLong, '
        'and NOT approximate', () {
      final outcome = applyFleetPolicy(
        [candidate('s1', km: 1, price: 1.7, travel: routed('s1', 4.5, 6))],
        const FleetRefuelPolicy(maxDetourKm: 5),
      );

      final exclusion = outcome.excluded['s1']!;
      expect(exclusion.reason, PolicyExclusionReason.detourTooLong);
      expect(exclusion.approximate, isFalse);
      expect(exclusion.observed, closeTo(9, 1e-9));
      expect(exclusion.limit, 5);
    });

    test('a road-verified detour over maxDetourMinutes is detourTooSlow', () {
      final outcome = applyFleetPolicy(
        [candidate('s1', km: 1, price: 1.7, travel: routed('s1', 2, 9))],
        const FleetRefuelPolicy(maxDetourMinutes: 10),
      );

      final exclusion = outcome.excluded['s1']!;
      expect(exclusion.reason, PolicyExclusionReason.detourTooSlow);
      expect(exclusion.approximate, isFalse);
      expect(exclusion.observed, closeTo(18, 1e-9));
    });

    test('a detour inside both caps stays eligible', () {
      final outcome = applyFleetPolicy(
        [candidate('s1', km: 1, price: 1.7, travel: routed('s1', 2, 3))],
        const FleetRefuelPolicy(maxDetourKm: 10, maxDetourMinutes: 10),
      );

      expect(outcome.excluded, isEmpty);
      expect(outcome.eligible, hasLength(1));
    });
  });

  group('approximate detour', () {
    test('without a road estimate the cap falls back to crow-flies × the '
        'road factor and the exclusion says so', () {
      final outcome = applyFleetPolicy(
        [candidate('s1', km: 9, price: 1.7)],
        const FleetRefuelPolicy(maxDetourKm: 10),
      );

      final exclusion = outcome.excluded['s1']!;
      expect(exclusion.reason, PolicyExclusionReason.detourTooLong);
      expect(exclusion.approximate, isTrue);
      expect(exclusion.observed, closeTo(9 * kCrowFliesRoadFactor, 1e-9));
    });

    test('a road estimate that is not actionable falls back too', () {
      final unreachable = StationTravelEstimate.withoutRoute(
        stationId: 's1',
        context: context,
        status: TravelEstimateStatus.unreachable,
        calculatedAt: calculatedAt,
      );

      final outcome = applyFleetPolicy(
        [candidate('s1', km: 9, price: 1.7, travel: unreachable)],
        const FleetRefuelPolicy(maxDetourKm: 10),
      );

      expect(outcome.excluded['s1']!.approximate, isTrue);
      expect(outcome.excluded['s1']!.observed,
          closeTo(9 * kCrowFliesRoadFactor, 1e-9));
    });

    test('a real road distance is not multiplied by the road factor', () {
      final outcome = applyFleetPolicy(
        [
          const RefuelCandidate(
            stationId: 's1',
            oneWayKm: 9,
            pricePerLitre: 1.7,
            isRoadDistance: true,
          ),
        ],
        const FleetRefuelPolicy(maxDetourKm: 8),
      );

      expect(outcome.excluded['s1']!.observed, closeTo(9, 1e-9));
      expect(outcome.excluded['s1']!.approximate, isTrue,
          reason: 'a one-way road leg is still not the routed detour');
    });

    test('a minutes cap that cannot be evaluated never excludes — an '
        'unmeasured duration is not a long one', () {
      final outcome = applyFleetPolicy(
        [candidate('s1', km: 40, price: 1.7)],
        const FleetRefuelPolicy(maxDetourMinutes: 5),
      );

      expect(outcome.excluded, isEmpty);
      expect(outcome.eligible, hasLength(1));
    });
  });

  group('ranking preservation (the pre-filter property)', () {
    final candidates = [
      candidate('shell-a', km: 0.8, price: 1.799),
      candidate('aral-b', km: 7.7, price: 1.629),
      candidate('jet-c', km: 2.4, price: 1.689),
      candidate('shell-d', km: 12.0, price: 1.599),
      candidate('free-e', km: 1.1, price: 1.739),
      candidate('aral-f', km: 4.0, price: 1.669),
    ];
    String? brandOf(String id) => id.split('-').first;

    const policy = FleetRefuelPolicy(
      allowedNetworks: {'shell', 'aral', 'jet'},
      fuelCardNetworks: {'shell', 'aral'},
      maxDetourKm: 11,
    );

    test('the filtered ranking equals the unfiltered ranking restricted to '
        'the eligible subset', () {
      final outcome = applyFleetPolicy(candidates, policy, brandOf: brandOf);
      final eligibleIds = {for (final c in outcome.eligible) c.stationId};

      expect(eligibleIds, isNotEmpty);
      expect(eligibleIds.length, lessThan(candidates.length),
          reason: 'the property is vacuous unless something was excluded');

      final unfiltered = RefuelEconomics.decide(candidates, profile);
      final filtered = RefuelEconomics.decide(outcome.eligible, profile);

      String? bestOf(
        double? Function(RefuelQuote) key,
      ) {
        RefuelQuote? winner;
        double? winning;
        for (final q in unfiltered.quotes) {
          if (!eligibleIds.contains(q.candidate.stationId)) continue;
          final v = key(q);
          if (v == null) continue;
          if (winning == null ||
              v < winning ||
              (v == winning &&
                  q.candidate.stationId
                          .compareTo(winner!.candidate.stationId) <
                      0)) {
            winner = q;
            winning = v;
          }
        }
        return winner?.candidate.stationId;
      }

      expect(filtered.cheapest?.candidate.stationId,
          bestOf((q) => q.candidate.pricePerLitre));
      expect(filtered.closest?.candidate.stationId,
          bestOf((q) => RefuelEconomics.travelKm(q.candidate, profile)));
      expect(filtered.bestValue?.candidate.stationId,
          bestOf((q) => q.effectivePricePerLitre));
    });

    test('every surviving quote keeps the cost it had unfiltered', () {
      final outcome = applyFleetPolicy(candidates, policy, brandOf: brandOf);
      final unfiltered = {
        for (final q in RefuelEconomics.decide(candidates, profile).quotes)
          q.candidate.stationId: q,
      };

      for (final q in RefuelEconomics.decide(outcome.eligible, profile).quotes) {
        final before = unfiltered[q.candidate.stationId]!;
        expect(q.cost!.travelKm, before.cost!.travelKm);
        expect(q.cost!.totalCost, before.cost!.totalCost);
        expect(q.effectivePricePerLitre, before.effectivePricePerLitre);
      }
    });

    test('the pairwise order of the survivors is unchanged', () {
      final outcome = applyFleetPolicy(candidates, policy, brandOf: brandOf);
      final eligibleIds = {for (final c in outcome.eligible) c.stationId};

      List<String> byValue(List<RefuelQuote> quotes) => [
            for (final q in quotes
              ..sort((a, b) => a.effectivePricePerLitre!
                  .compareTo(b.effectivePricePerLitre!)))
              q.candidate.stationId,
          ];

      final before = byValue([
        for (final q in RefuelEconomics.decide(candidates, profile).quotes)
          if (eligibleIds.contains(q.candidate.stationId)) q,
      ]);
      final after =
          byValue(RefuelEconomics.decide(outcome.eligible, profile).quotes);

      expect(after, before);
    });
  });

  group('FleetRefuelPolicy.permitsFuel', () {
    test('an empty approvedFuelKeys approves every fuel', () {
      expect(const FleetRefuelPolicy().permitsFuel('e10'), isTrue);
      expect(const FleetRefuelPolicy().permitsFuel(null), isTrue);
    });

    test('a named set approves only its members, case-insensitively', () {
      const policy = FleetRefuelPolicy(approvedFuelKeys: {'Diesel', 'e10'});
      expect(policy.permitsFuel('diesel'), isTrue);
      expect(policy.permitsFuel('E10'), isTrue);
      expect(policy.permitsFuel('e85'), isFalse);
      expect(policy.permitsFuel(null), isFalse);
    });
  });
}
