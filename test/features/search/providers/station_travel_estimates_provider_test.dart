// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #4359 — the travel-estimate provider and its production consumers.
///
/// Road answers reach the providers through the REAL [RoutingService]
/// over a replaying Dio adapter (the injected seam is the HTTP layer,
/// not a fake that echoes the request), or — where the point is ORDER —
/// through a fetcher whose completion the test controls.
library;

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/refuel_economics.dart';
import 'package:tankstellen/core/domain/refuel_profile_provider.dart';
import 'package:tankstellen/core/domain/search_result_item.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/domain/travel_estimate.dart';
import 'package:tankstellen/core/time/app_clock.dart';
import 'package:tankstellen/features/route_search/data/services/routing_service.dart';
import 'package:tankstellen/features/search/providers/refuel_decision_provider.dart';
import 'package:tankstellen/features/search/providers/refuel_travel_origin_provider.dart';
import 'package:tankstellen/features/search/providers/search_filters_provider.dart';
import 'package:tankstellen/features/search/providers/station_travel_estimates_provider.dart';

class _FixedFuel extends SelectedFuelType {
  @override
  FuelType build() => FuelType.e10;
}

/// Replays one `/table` body for every request and counts them.
class _Replay implements HttpClientAdapter {
  _Replay(this.body);
  final String body;
  int requests = 0;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    requests++;
    return ResponseBody.fromString(body, 200, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  final now = DateTime.utc(2026, 9, 16, 12);
  const origin = TravelPoint(48.85, 2.35);
  const errand =
      TravelContext(origin: origin, purpose: TravelPurpose.errandReturn);

  StationTravelEstimate routed(String id, TravelContext ctx, double km) =>
      StationTravelEstimate.routed(
        stationId: id,
        context: ctx,
        toStation: TravelLeg(distanceKm: km / 2, durationMinutes: km),
        fromStation: TravelLeg(distanceKm: km / 2, durationMinutes: km),
        baseline: TravelLeg.zero,
        calculatedAt: now,
      );

  group('stale-result protection', () {
    test('the new selection wins when responses arrive out of order',
        () async {
      final pending = <String, Completer<List<StationTravelEstimate>>>{};
      final c = ProviderContainer(overrides: [
        travelEstimateFetcherProvider.overrideWithValue((ctx, stops) {
          final done = Completer<List<StationTravelEstimate>>();
          pending[stops.map((s) => s.id).join()] = done;
          return done.future;
        }),
      ]);
      addTearDown(c.dispose);

      final first = TravelQuoteRequest.budgeted(errand, const [
        (id: 'fr-a', lat: 48.85, lng: 2.36),
        (id: 'fr-b', lat: 48.86, lng: 2.35),
      ]);
      final second = TravelQuoteRequest.budgeted(errand, const [
        (id: 'fr-a', lat: 48.85, lng: 2.36),
      ]);

      final sub = c.listen(stationTravelEstimatesProvider(first), (_, _) {});
      await Future<void>.delayed(Duration.zero);
      sub.close(); // the consumer moves on
      final current = <AsyncValue<Map<String, StationTravelEstimate>>>[];
      c.listen(stationTravelEstimatesProvider(second),
          (_, next) => current.add(next),
          fireImmediately: true);
      await Future<void>.delayed(Duration.zero);

      // The NEW request answers first, the old one late.
      pending['fr-a']!.complete([routed('fr-a', errand, 4)]);
      await Future<void>.delayed(Duration.zero);
      pending['fr-afr-b']!.complete([
        routed('fr-a', errand, 40),
        routed('fr-b', errand, 2),
      ]);
      await Future<void>.delayed(Duration.zero);

      final last = current.last.value!;
      expect(last.keys, ['fr-a'],
          reason: 'the removed station keeps no quote');
      expect(last['fr-a']!.extraKm, 4,
          reason: 'the late answer for the old selection never lands');
    });

    test('an answer for another context is fenced out', () async {
      const other =
          TravelContext(origin: TravelPoint(43.3, 5.4), purpose: TravelPurpose.errandReturn);
      final c = ProviderContainer(overrides: [
        travelEstimateFetcherProvider.overrideWithValue(
            (ctx, stops) async => [routed('fr-a', other, 3)]),
      ]);
      addTearDown(c.dispose);
      final request = TravelQuoteRequest.budgeted(
          errand, const [(id: 'fr-a', lat: 48.85, lng: 2.36)]);
      final map = await c.read(stationTravelEstimatesProvider(request).future);
      expect(map, isEmpty);
    });

    test('an unreachable update replaces an actionable quote', () {
      final request = TravelQuoteRequest.budgeted(
          errand, const [(id: 'fr-a', lat: 48.85, lng: 2.36)]);
      final unreachable = StationTravelEstimate.withoutRoute(
        stationId: 'fr-a',
        context: errand,
        status: TravelEstimateStatus.unreachable,
        calculatedAt: now,
      );
      expect(
          actionableTravelEstimate(
              AsyncValue.data({'fr-a': unreachable}), request, 'fr-a', now),
          isNull);
      expect(
          actionableTravelEstimate(
              AsyncValue.data({'fr-a': routed('fr-a', errand, 3)}),
              request,
              'fr-a',
              now.add(kTravelEstimateMaxAge * 2)),
          isNull,
          reason: 'an aged quote is not promoted to current');
    });
  });

  group('the request budget', () {
    test('reference-price locations never start access routing (#4348)', () {
      final request = TravelQuoteRequest.budgeted(errand, const [
        (id: 'lu-luxembourg-ville', lat: 49.61, lng: 6.13),
        (id: 'gr-attica', lat: 37.98, lng: 23.72),
        (id: 'fr-a', lat: 48.85, lng: 2.36),
      ]);
      expect(request.stops.map((s) => s.id), ['fr-a']);
    });

    test('a selection beyond the radar top eight is still quoted, capped at '
        'the documented budget', () {
      final many = [
        for (var i = 0; i < 40; i++)
          (id: 'fr-$i', lat: 48.85 + i / 1000, lng: 2.35),
      ];
      final request = TravelQuoteRequest.budgeted(errand, many);
      expect(request.stops, hasLength(kTravelQuoteMaxStations));
      expect(request.stops.map((s) => s.id), contains('fr-11'),
          reason: 'the twelfth station is outside the old top-8 subset');
    });
  });

  group('the decision provider consumes road estimates', () {
    // INJECTED fixture (not a recording): two stations at the SAME
    // crow-flies distance, one a 2 km return drive, the other 20 km —
    // the #4359 acceptance case, in OSRM's own response shape.
    final table = jsonEncode({
      'code': 'Ok',
      'distances': [
        [0, 1000, 10000],
        [1000, 0, 0],
        [10000, 0, 0],
      ],
      'durations': [
        [0, 120, 900],
        [120, 0, 0],
        [900, 0, 0],
      ],
    });

    Station station(String id, double price) => Station(
          id: id,
          name: id,
          brand: 'B',
          street: 's',
          postCode: '1',
          place: 'Paris',
          lat: 48.853,
          lng: 2.35,
          dist: 0.9,
          e10: price,
        );

    test('same aerial distance, 2 km vs 20 km: different economics and '
        'distance ranking', () async {
      final adapter = _Replay(table);
      final service = RoutingService(dio: Dio()..httpClientAdapter = adapter);
      final c = ProviderContainer(overrides: [
        selectedFuelTypeProvider.overrideWith(_FixedFuel.new),
        refuelProfileProvider.overrideWithValue(
            const RefuelProfile(consumptionLPer100km: 10, litresIntended: 40)),
        appClockProvider.overrideWithValue(FixedClock(now)),
        travelEstimateFetcherProvider.overrideWithValue((ctx, stops) =>
            service.stationTravelEstimates(
                context: ctx, stops: stops, now: now)),
      ]);
      addTearDown(c.dispose);
      c.read(refuelTravelOriginProvider.notifier).set(origin);

      final items = <SearchResultItem>[
        FuelStationResult(station('fr-near-road', 1.80)),
        FuelStationResult(station('fr-far-road', 1.80)),
      ];
      final sub = c.listen(refuelDecisionProvider(items), (_, _) {});
      addTearDown(sub.close);

      // Before the road answer: identical crow-flies figures.
      final before = c.read(refuelDecisionProvider(items));
      expect(before.quotes[0].cost!.travelKm,
          before.quotes[1].cost!.travelKm);

      // Wait for the replayed router answer deterministically — a fixed
      // delay is a race on a loaded machine.
      for (var i = 0;
          i < 500 &&
              !c.read(refuelDecisionProvider(items)).quotes[0].candidate
                  .isRoadDistance;
          i++) {
        await Future<void>.delayed(const Duration(milliseconds: 2));
      }
      final after = c.read(refuelDecisionProvider(items));
      final near = after.quotes[0].cost!, far = after.quotes[1].cost!;
      expect(adapter.requests, 1);
      expect(near.travelKm, closeTo(2, 1e-9));
      expect(far.travelKm, closeTo(20, 1e-9));
      // 40 L at €1.80 plus 0.2 L vs 2.0 L burned.
      expect(near.totalCost, closeTo(40.2 * 1.80, 1e-9));
      expect(far.totalCost, closeTo(42.0 * 1.80, 1e-9));
      expect(after.closest!.candidate.stationId, 'fr-near-road');
      expect(after.bestValue!.candidate.stationId, 'fr-near-road');
      expect(after.quotes[0].candidate.isRoadDistance, isTrue);
    });
  });
}
