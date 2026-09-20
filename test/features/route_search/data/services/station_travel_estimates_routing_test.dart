// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #4359 — station travel estimates through the REAL [RoutingService].
///
/// `test/fixtures/osrm_table_berlin_errand.json`,
/// `osrm_table_berlin_en_route.json`,
/// `osrm_table_exclude_unsupported.json` and
/// `osrm_route_berlin_two_stops.json` are unmodified responses recorded on
/// 2026-09-16 from the free public server the app already uses
/// (`router.project-osrm.org`):
///
///  * errand: `/table/v1/driving/13.405,52.52;<10 Tankerkönig Berlin
///    stations from de_tankerkoenig_list_slice.json>?annotations=
///    distance,duration`
///  * en route: the same with destination `13.2877,52.5588` (Tegel) second;
///  * `…&exclude=ferry` — the public server's real refusal;
///  * `/route/v1/driving/origin;Aral;Total;Tegel?overview=false`.
///
/// A replaying Dio adapter answers them; no test touches the network.
library;

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/travel_estimate.dart';
import 'package:tankstellen/features/route_search/data/services/osrm_travel_matrix.dart';
import 'package:tankstellen/features/route_search/data/services/routing_service.dart';

class _Replay implements HttpClientAdapter {
  _Replay(this.bodyFor);
  final String? Function(RequestOptions o) bodyFor;
  final requests = <Uri>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options.uri);
    final body = bodyFor(options);
    if (body == null) {
      throw DioException(
          requestOptions: options, error: 'no recording for ${options.uri}');
    }
    // OSRM answers 400 for InvalidValue; the body is what matters.
    final status = body.contains('"InvalidValue"') ? 400 : 200;
    return ResponseBody.fromString(body, status, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  final at = DateTime.utc(2026, 9, 16, 22, 56);
  String fixture(String n) => File('test/fixtures/$n').readAsStringSync();

  // The ten recorded Tankerkönig Berlin stations, in request order.
  const stops = <TravelStop>[
    (id: 'aral-holzmarkt', lat: 52.514153, lng: 13.421487),
    (id: 'total-mitte', lat: 52.528899, lng: 13.41808),
    (id: 'shell-oranien', lat: 52.504122, lng: 13.408138),
    (id: 'aral-3', lat: 52.501896, lng: 13.409839),
    (id: 'aral-4', lat: 52.540787, lng: 13.393457),
    (id: 'aral-5', lat: 52.498703, lng: 13.422538),
    (id: 'total-6', lat: 52.530831, lng: 13.440946),
    (id: 'total-7', lat: 52.537242, lng: 13.375376),
    (id: 'total-8', lat: 52.500478, lng: 13.376696),
    (id: 'shell-9', lat: 52.499217, lng: 13.433074),
  ];
  const origin = TravelPoint(52.52, 13.405);

  RoutingService serviceFor(_Replay adapter) =>
      RoutingService(dio: Dio()..httpClientAdapter = adapter);

  group('a return errand, recorded', () {
    late List<StationTravelEstimate> estimates;
    late _Replay adapter;

    setUpAll(() async {
      adapter = _Replay((o) => o.uri.path.startsWith('/table/')
          ? fixture('osrm_table_berlin_errand.json')
          : null);
      estimates = await serviceFor(adapter).stationTravelEstimates(
        context: const TravelContext(
            origin: origin, purpose: TravelPurpose.errandReturn),
        stops: stops,
        now: at,
      );
    });

    test('ONE request quotes all ten stations, both directions', () {
      expect(adapter.requests, hasLength(1));
      expect(adapter.requests.single.queryParameters['annotations'],
          'distance,duration');
      expect(estimates.map((e) => e.stationId), stops.map((s) => s.id));
    });

    test('the return leg is its own leg: 1.5063 km out, 1.7305 km back', () {
      final aral = estimates.first;
      expect(aral.toStation.distanceKm, closeTo(1.5063, 1e-9));
      expect(aral.fromStation.distanceKm, closeTo(1.7305, 1e-9));
      expect(aral.itinerary.distanceKm, closeTo(3.2368, 1e-9),
          reason: 'not 2 × 1.5063 = 3.0126');
      // Durations come from their own matrix: 172.3 s + 192.6 s.
      expect(aral.itinerary.durationMinutes, closeTo(364.9 / 60, 1e-9));
      expect(aral.status, TravelEstimateStatus.roadVerified);
    });
  });

  group('a stop on a journey, recorded', () {
    late List<StationTravelEstimate> estimates;
    late _Replay adapter;

    setUpAll(() async {
      adapter = _Replay((o) => o.uri.path.startsWith('/table/')
          ? fixture('osrm_table_berlin_en_route.json')
          : null);
      estimates = await serviceFor(adapter).stationTravelEstimates(
        context: const TravelContext(
          origin: origin,
          destination: TravelPoint(52.5588, 13.2877),
          purpose: TravelPurpose.stopOnJourney,
          headingDegrees: 92,
        ),
        stops: stops,
        now: at,
      );
    });

    test('the destination is the second coordinate and the origin is '
        'heading-constrained', () {
      final uri = adapter.requests.single;
      expect(uri.path, contains('13.405,52.52;13.2877,52.5588;13.421487'));
      final bearings = uri.queryParameters['bearings']!;
      expect(bearings, startsWith('92,25;'));
      expect(';'.allMatches(bearings), hasLength(11),
          reason: 'one entry per coordinate (12)');
    });

    test('baseline, itinerary and extra are three different numbers', () {
      final aral4 = estimates[4];
      expect(aral4.baseline.distanceKm, closeTo(14.0893, 1e-9));
      expect(aral4.itinerary.distanceKm, closeTo(2.6765 + 11.8951, 1e-9));
      expect(aral4.extraKm, closeTo(0.4823, 1e-9));
      expect(aral4.extraDrivingMinutes, closeTo(177.7 / 60, 1e-9));
    });

    test('two stations at the SAME aerial distance cost different detours',
        () {
      // Both are 1.3 km crow-flies from the origin in the recorded
      // Tankerkönig list; the road disagrees.
      expect(estimates[0].extraKm, closeTo(3.2368, 1e-9));
      expect(estimates[1].extraKm, closeTo(1.5904, 1e-9));
    });
  });

  test('a refused exclusion is reported, never silently dropped', () async {
    final adapter = _Replay((o) => o.uri.path.startsWith('/table/')
        ? fixture('osrm_table_exclude_unsupported.json')
        : null);
    final estimates = await serviceFor(adapter).stationTravelEstimates(
      context: const TravelContext(
        origin: origin,
        destination: TravelPoint(52.5588, 13.2877),
        purpose: TravelPurpose.stopOnJourney,
        constraints: {TravelConstraint.avoidFerries},
      ),
      stops: stops.take(2).toList(),
      now: at,
    );
    expect(adapter.requests, hasLength(1),
        reason: 'no retry that quietly allows the ferry again');
    expect(adapter.requests.single.queryParameters['exclude'], 'ferry');
    expect(estimates.map((e) => e.status),
        everyElement(TravelEstimateStatus.constraintsUnsupported));
    expect(estimates.any((e) => e.isActionable), isFalse);
  });

  test('distance and duration decode independently', () {
    final parsed = parseOsrmTravelMatrix(
      {
        'code': 'Ok',
        // The origin→station distance cell is missing; its duration is not.
        'distances': [
          [0, null],
          [7000, 0],
        ],
        'durations': [
          [0, 300],
          [660, 0],
        ],
      },
      context:
          const TravelContext(origin: origin, purpose: TravelPurpose.errandReturn),
      stops: stops.take(1).toList(),
      calculatedAt: at,
    );
    expect(parsed.single.toStation.distanceKm, isNull);
    expect(parsed.single.toStation.durationMinutes, 5);
    expect(parsed.single.status, TravelEstimateStatus.unreachable);
  });

  test('an ordered two-stop itinerary is routed as one drive', () {
    final legs = parseOsrmRouteLegs(
        jsonDecode(fixture('osrm_route_berlin_two_stops.json'))
            as Map<String, dynamic>)!;
    expect(legs.map((l) => l.distanceKm),
        [closeTo(1.5063, 1e-9), closeTo(2.479, 1e-9), closeTo(14.3096, 1e-9)]);
    expect(legs.map((l) => l.durationMinutes), [
      closeTo(172.3 / 60, 1e-9),
      closeTo(329.5 / 60, 1e-9),
      closeTo(1742.2 / 60, 1e-9),
    ]);
  });
}
