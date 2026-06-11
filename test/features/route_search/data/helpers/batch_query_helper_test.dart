// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/route_search/data/helpers/batch_query_helper.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/domain/search_result_item.dart';

void main() {
  group('BatchQueryHelper', () {
    test('processes all sample points in batches', () async {
      final queriedPoints = <String>[];
      const helper = BatchQueryHelper(batchSize: 3);

      final points = List.generate(10, (i) => LatLng(48.0 + i * 0.1, 2.0));

      final results = await helper.queryAll(
        samplePoints: points,
        fuelType: FuelType.e10,
        searchRadiusKm: 10.0,
        queryStations: ({
          required double lat,
          required double lng,
          required double radiusKm,
          required FuelType fuelType,
        }) async {
          queriedPoints.add(lat.toStringAsFixed(1));
          return [
            FuelStationResult(Station(
              id: 'st-${lat.toStringAsFixed(1)}',
              name: 'Station',
              brand: 'Test',
              street: '',
              postCode: '',
              place: '',
              lat: lat,
              lng: lng,
              dist: 1.0,
              isOpen: true,
              e10: 1.50,
            )),
          ];
        },
      );

      // All 10 points queried
      expect(queriedPoints, hasLength(10));
      // All 10 stations returned (unique IDs)
      expect(results, hasLength(10));
    });

    test('deduplicates stations from overlapping queries', () async {
      const helper = BatchQueryHelper(batchSize: 2);

      final points = [const LatLng(48.0, 2.0), const LatLng(48.1, 2.0)];

      final results = await helper.queryAll(
        samplePoints: points,
        fuelType: FuelType.e10,
        searchRadiusKm: 10.0,
        queryStations: ({
          required double lat,
          required double lng,
          required double radiusKm,
          required FuelType fuelType,
        }) async {
          // Both points return the same station
          return [
            const FuelStationResult(Station(
              id: 'shared-station',
              name: 'Shared',
              brand: 'Test',
              street: '',
              postCode: '',
              place: '',
              lat: 48.05,
              lng: 2.0,
              dist: 1.0,
              isOpen: true,
              e10: 1.50,
            )),
          ];
        },
      );

      // Deduplicated to 1
      expect(results, hasLength(1));
    });

    test('handles individual query failures gracefully', () async {
      const helper = BatchQueryHelper(batchSize: 2);
      int callCount = 0;

      final points = List.generate(4, (i) => LatLng(48.0 + i * 0.1, 2.0));

      final results = await helper.queryAll(
        samplePoints: points,
        fuelType: FuelType.e10,
        searchRadiusKm: 10.0,
        queryStations: ({
          required double lat,
          required double lng,
          required double radiusKm,
          required FuelType fuelType,
        }) async {
          callCount++;
          // Fail every other query
          if (callCount % 2 == 0) throw Exception('API error');
          return [
            FuelStationResult(Station(
              id: 'st-$callCount',
              name: 'Station',
              brand: 'Test',
              street: '',
              postCode: '',
              place: '',
              lat: lat,
              lng: lng,
              dist: 1.0,
              isOpen: true,
              e10: 1.50,
            )),
          ];
        },
      );

      // 2 out of 4 succeed
      expect(results, hasLength(2));
      // All 4 were attempted
      expect(callCount, 4);
    });

    test('batch size 1 processes sequentially', () async {
      const helper = BatchQueryHelper(batchSize: 1);
      final timestamps = <int>[];

      final points = [const LatLng(48.0, 2.0), const LatLng(49.0, 2.0)];

      await helper.queryAll(
        samplePoints: points,
        fuelType: FuelType.e10,
        searchRadiusKm: 10.0,
        queryStations: ({
          required double lat,
          required double lng,
          required double radiusKm,
          required FuelType fuelType,
        }) async {
          timestamps.add(DateTime.now().millisecondsSinceEpoch);
          return [];
        },
      );

      expect(timestamps, hasLength(2));
    });
  });

  group('top-N per sample point reduce (#2101)', () {
    Station stn(String id, double price, {double lat = 48, double lng = 2}) =>
        Station(
          id: id,
          name: 'Station $id',
          brand: 'T',
          street: '',
          postCode: '',
          place: '',
          lat: lat,
          lng: lng,
          dist: 1.0,
          isOpen: true,
          e10: price,
        );

    test('cheapest criterion keeps the N lowest-priced and orders best-first',
        () {
      final raw = [
        FuelStationResult(stn('a', 1.90)),
        FuelStationResult(stn('b', 1.50)),
        FuelStationResult(stn('c', 1.70)),
        FuelStationResult(stn('d', 1.40)),
        FuelStationResult(stn('e', 2.10)),
      ];
      final result = BatchQueryHelper.topNForPoint(
        raw,
        point: const LatLng(48, 2),
        fuelType: FuelType.e10,
        topN: 3,
        criterion: RouteSearchCriterion.cheapest,
      );
      expect(result.map((r) => (r as FuelStationResult).id), ['d', 'b', 'c']);
    });

    test('nearest criterion keeps the N closest and orders best-first', () {
      // sample point at (48, 2). Stations spread north.
      final raw = [
        FuelStationResult(stn('far', 1.50, lat: 48.5, lng: 2)),
        FuelStationResult(stn('mid', 1.50, lat: 48.2, lng: 2)),
        FuelStationResult(stn('near', 1.50, lat: 48.05, lng: 2)),
        FuelStationResult(stn('outer', 1.50, lat: 49.0, lng: 2)),
      ];
      final result = BatchQueryHelper.topNForPoint(
        raw,
        point: const LatLng(48, 2),
        fuelType: FuelType.e10,
        topN: 2,
        criterion: RouteSearchCriterion.nearest,
      );
      expect(
          result.map((r) => (r as FuelStationResult).id), ['near', 'mid']);
    });

    test('stations with no price for the fuel type sink to the bottom under cheapest', () {
      // Build with no e10 price by passing a Station where e10 is null.
      Station noPrice(String id) => Station(
            id: id,
            name: id,
            brand: 'T',
            street: '',
            postCode: '',
            place: '',
            lat: 48,
            lng: 2,
            dist: 1.0,
            isOpen: true,
          );
      final raw = [
        FuelStationResult(noPrice('np1')),
        FuelStationResult(stn('cheap', 1.40)),
        FuelStationResult(stn('mid', 1.70)),
        FuelStationResult(noPrice('np2')),
      ];
      final result = BatchQueryHelper.topNForPoint(
        raw,
        point: const LatLng(48, 2),
        fuelType: FuelType.e10,
        topN: 3,
        criterion: RouteSearchCriterion.cheapest,
      );
      // 'cheap', 'mid', then the first null-priced one.
      expect(result.first, isA<FuelStationResult>());
      expect((result.first as FuelStationResult).id, 'cheap');
      expect((result[1] as FuelStationResult).id, 'mid');
    });

    test('returns input unchanged when raw.length <= topN', () {
      final raw = [
        FuelStationResult(stn('a', 1.50)),
        FuelStationResult(stn('b', 1.70)),
      ];
      final result = BatchQueryHelper.topNForPoint(
        raw,
        point: const LatLng(48, 2),
        fuelType: FuelType.e10,
        topN: 5,
        criterion: RouteSearchCriterion.cheapest,
      );
      expect(identical(result, raw), isTrue);
    });

    test('queryAll applies the top-N cap per sample point before merge',
        () async {
      const helper = BatchQueryHelper();
      final points = [const LatLng(48, 2), const LatLng(48.5, 2)];

      final results = await helper.queryAll(
        samplePoints: points,
        fuelType: FuelType.e10,
        searchRadiusKm: 10.0,
        topNPerSamplePoint: 2,
        criterion: RouteSearchCriterion.cheapest,
        queryStations: ({
          required double lat,
          required double lng,
          required double radiusKm,
          required FuelType fuelType,
        }) async {
          // Each sample point returns 5 stations.
          return List.generate(
            5,
            (i) => FuelStationResult(
              Station(
                id: 'st-${lat.toStringAsFixed(1)}-$i',
                name: 's',
                brand: 'T',
                street: '',
                postCode: '',
                place: '',
                lat: lat,
                lng: lng,
                dist: 1.0,
                isOpen: true,
                e10: 1.50 + i * 0.10,
              ),
            ),
          );
        },
      );

      // 2 sample points × top 2 = 4 stations max (all unique).
      expect(results, hasLength(4));
    });
  });

  group('incremental onPartial emission (#2103)', () {
    test('emits running accumulator after each batch', () async {
      const helper = BatchQueryHelper();
      final points = List.generate(20, (i) => LatLng(48.0 + i * 0.1, 2.0));
      final emissions = <int>[];

      await helper.queryAll(
        samplePoints: points,
        fuelType: FuelType.e10,
        searchRadiusKm: 10.0,
        onPartial: (partial) => emissions.add(partial.length),
        queryStations: ({
          required double lat,
          required double lng,
          required double radiusKm,
          required FuelType fuelType,
        }) async {
          return [
            FuelStationResult(Station(
              id: 'st-${lat.toStringAsFixed(2)}',
              name: 's',
              brand: 'T',
              street: '',
              postCode: '',
              place: '',
              lat: lat,
              lng: lng,
              dist: 1.0,
              isOpen: true,
              e10: 1.50,
            )),
          ];
        },
      );

      // 20 points / batchSize=8 = 3 batches → 3 emissions.
      expect(emissions, hasLength(3));
      // Each emission strictly grows.
      for (var i = 1; i < emissions.length; i++) {
        expect(emissions[i], greaterThan(emissions[i - 1]));
      }
    });
  });

  group('429 backoff on DioException (#2255)', () {
    DioException dio429({String? retryAfter}) {
      final o = RequestOptions(path: '/x');
      return DioException(
        requestOptions: o,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: o,
          statusCode: 429,
          headers: retryAfter == null
              ? Headers()
              : (Headers()..set('retry-after', retryAfter)),
        ),
      );
    }

    /// Runs [helper.queryAll] over two sample points under [fakeAsync] with
    /// `batchSize: 1` — the first point throws [failOnFirst], the second
    /// succeeds — and returns the fake-clock gap (ms) between the two query
    /// invocations. That gap is exactly the inter-batch pause the helper
    /// applied (0 when the throttle never armed). Deterministic: no
    /// wall-clock, so it can't flake under concurrent suite load.
    int interBatchGapMs({
      required Object failOnFirst,
      required Duration backoffPause,
    }) {
      late int gap;
      fakeAsync((async) {
        final helper = BatchQueryHelper(batchSize: 1, backoffPause: backoffPause);
        final callElapsedMs = <int>[];
        var call = 0;
        final start = async.elapsed;
        var done = false;
        // Capture the future so its completion can be awaited within the fake
        // zone — leaving it dangling lets a thrown sub-future surface as an
        // unhandled zone error under concurrent suite load (#2255 test flake).
        unawaited(helper
            .queryAll(
              samplePoints: [const LatLng(48, 2), const LatLng(49, 2)],
              fuelType: FuelType.e10,
              searchRadiusKm: 10,
              queryStations: ({
                required double lat,
                required double lng,
                required double radiusKm,
                required FuelType fuelType,
              }) async {
                callElapsedMs.add((async.elapsed - start).inMilliseconds);
                if (call++ == 0) throw failOnFirst;
                return const <SearchResultItem>[];
              },
            )
            .whenComplete(() => done = true));
        // Advance the fake clock past any pause and flush all microtasks so
        // the sweep fully settles before we read the recorded gap.
        async.elapse(const Duration(seconds: 2));
        async.flushMicrotasks();
        expect(done, isTrue, reason: 'the sweep must complete');
        expect(callElapsedMs, hasLength(2),
            reason: 'both sample points must be queried');
        gap = callElapsedMs[1] - callElapsedMs[0];
      });
      return gap;
    }

    test('a DioException 429 in the first batch arms the inter-batch pause '
        '(the old http.ClientException catch was dead code)', () {
      final gap = interBatchGapMs(
        failOnFirst: dio429(),
        backoffPause: const Duration(milliseconds: 300),
      );
      expect(gap, 300,
          reason: 'a 429 must re-enable the inter-batch backoff pause');
    });

    test('honours the Retry-After header for the pause duration', () {
      // Retry-After: 0 → the server told us not to wait, so the pause
      // collapses to zero even though the rate-limit flag armed.
      final gap = interBatchGapMs(
        failOnFirst: dio429(retryAfter: '0'),
        backoffPause: const Duration(milliseconds: 250),
      );
      expect(gap, 0,
          reason: 'Retry-After: 0 overrides the flat pause with no wait');
    });

    test('a longer Retry-After widens the pause beyond backoffPause', () {
      final gap = interBatchGapMs(
        failOnFirst: dio429(retryAfter: '1'),
        backoffPause: const Duration(milliseconds: 100),
      );
      expect(gap, 1000,
          reason: 'Retry-After: 1s must override the 100 ms flat pause');
    });

    test('a typed rateLimited ApiException also arms the pause', () {
      final gap = interBatchGapMs(
        failOnFirst: const ApiException(
          message: 'rate limited',
          statusCode: 429,
          kind: FailureKind.rateLimited,
        ),
        backoffPause: const Duration(milliseconds: 300),
      );
      expect(gap, 300,
          reason: 'typed FailureKind.rateLimited must arm the backoff');
    });

    test('a non-rate-limit error (parse) does not arm the pause', () {
      final gap = interBatchGapMs(
        failOnFirst: const ApiException(
          message: 'bad json',
          kind: FailureKind.parse,
        ),
        backoffPause: const Duration(milliseconds: 300),
      );
      expect(gap, 0, reason: 'a parse failure is not rate-limited — no backoff');
    });
  });
}
