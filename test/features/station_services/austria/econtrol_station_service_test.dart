// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #2780 (Epic #2776 D4) — every parse assertion here drives the REAL
// [EControlStationService.searchStations] through a fixed Dio (see
// `support/real_service_search.dart`), replacing the `_TestableEControlParser`
// copy that re-implemented the parse but never set the structured
// `Station.openingHours` nor the `at-` id prefix — i.e. proved the copy, not the
// production path (the #2776 false-green lesson).
//
// Austria is the worst-case carrier: it polls its API (cache-HIT dominant) AND
// has NO detail endpoint, so the search-result Station is the ONLY thing that
// can ever carry opening hours. A cold favorite/widget tap (no live search
// state) rehydrates that Station from `Station.toJson`/`fromJson`, so that codec
// MUST preserve the hours — the regression this test backfills.

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/core/services/station_service_chain_codec.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/station_detail/domain/opening_hours.dart';
import 'package:tankstellen/features/station_services/austria/econtrol_station_service.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

import '../support/real_service_search.dart';

/// A realistic E-Control `by-address` record: OMV Wien, Mon–Sat 06:30–20:30
/// (closed Sunday) — the real `openingHours[]` shape.
Map<String, dynamic> omvWien({
  String id = '123',
  num? amount = 1.659,
  bool open = true,
  List<Map<String, dynamic>>? openingHours,
}) =>
    {
      'id': id,
      'name': 'OMV Wien Ring',
      'open': open,
      'location': {
        'latitude': 48.2,
        'longitude': 16.37,
        'address': 'Ringstraße 1',
        'postalCode': '1010',
        'city': 'Wien',
      },
      'prices': [
        if (amount != null) {'amount': amount},
      ],
      'openingHours': openingHours ??
          [
            for (final d in const ['MO', 'DI', 'MI', 'DO', 'FR', 'SA'])
              {'day': d, 'label': d, 'from': '06:30', 'to': '20:30'},
          ],
    };

void main() {
  group('EControlStationService contract', () {
    final service = EControlStationService();

    test('implements StationService interface', () {
      expect(service, isA<StationService>());
    });

    test('getStationDetail throws ApiException mentioning E-Control', () async {
      expect(
        () => service.getStationDetail('at-123'),
        throwsA(isA<ApiException>()),
      );
      try {
        await service.getStationDetail('at-test');
        fail('Should have thrown');
      } on ApiException catch (e) {
        expect(e.message, contains('E-Control'));
      }
    });

    test('getPrices returns an empty map with E-Control metadata', () async {
      final result = await service.getPrices(['at-1', 'at-2']);
      expect(result.data, isEmpty);
      expect(result.source, ServiceSource.eControlApi);
      expect(result.fetchedAt, isA<DateTime>());
      expect(result.isStale, isFalse);

      expect((await service.getPrices([])).data, isEmpty);
    });
  });

  // The #2780 headline: AT has no detail endpoint, so the search Station is the
  // sole hours carrier — across BOTH codecs a tap can travel through.
  group('AT search-path opening hours (#2780)', () {
    test('REAL search parse populates structured Station.openingHours',
        () async {
      final s = (await searchEcontrolStations([omvWien()]))
          .firstWhere((s) => s.id == 'at-123');
      expect(s.openingHours, isNotNull,
          reason: 'AT has no detail endpoint — the search parse is the only '
              'chance to carry structured hours');
      expect(s.openingHours!.availability,
          isNot(OpeningHoursAvailability.notProvided));
      expect(s.openingHours!.dayFor(OpeningDay.mon)?.state,
          DayState.openRanges);
    });

    test('structured hours survive the search-list cache codec round-trip',
        () async {
      final fresh = (await searchEcontrolStations([omvWien()]))
          .firstWhere((s) => s.id == 'at-123');
      final restored =
          deserializeStationList(serializeStationList([fresh]))!.single;
      expect(restored.openingHours, isNotNull,
          reason: 'cache-HIT rehydration (#2777) must keep the hours');
      expect(restored.openingHours!.dayFor(OpeningDay.mon)?.state,
          DayState.openRanges);
    });

    test(
        'AT favorite/widget cold-tap: hours survive the Station.toJson round-trip',
        () async {
      // A cold favorite/widget tap has no live search state, and AT has no
      // detail endpoint, so the ONLY hours source is the persisted Station
      // rehydrated by FavoriteStations.build via Station.toJson/fromJson. If
      // that codec drops openingHours, the section renders empty forever — the
      // exact #2776 bug. RED before the #2777 codec fix, GREEN after.
      final fresh = (await searchEcontrolStations([omvWien()]))
          .firstWhere((s) => s.id == 'at-123');

      final restored = Station.fromJson(fresh.toJson());
      expect(restored.openingHours, isNotNull,
          reason: 'a persisted AT favorite/widget station must keep its hours '
              'through Station.toJson/fromJson — there is no detail endpoint '
              'to recover them');
      expect(restored.openingHours!.dayFor(OpeningDay.mon)?.state,
          DayState.openRanges);
      // Sunday is absent from the schedule → not open.
      expect(restored.openingHours!.dayFor(OpeningDay.sun)?.state,
          isNot(DayState.openRanges));
    });

    test('empty openingHours[] round-trips as null (back-compat, no crash)',
        () async {
      final fresh = (await searchEcontrolStations(
        [omvWien(openingHours: const [])],
      ))
          .firstWhere((s) => s.id == 'at-123');
      final restored = Station.fromJson(fresh.toJson());
      expect(
        restored.openingHours == null ||
            restored.openingHours!.availability ==
                OpeningHoursAvailability.notProvided,
        isTrue,
      );
    });
  });

  group('E-Control REAL search parse (via the real service + fixed Dio)', () {
    test('parses a station incl. the at- id prefix + merged DIE/SUP prices',
        () async {
      // DIE query → diesel; SUP query → e5/e10. The real service merges by id.
      final stations = await searchEcontrolStations(
        [omvWien(amount: 1.659)],
        superRecords: [omvWien(amount: 1.549)],
      );
      final s = stations.firstWhere((s) => s.id == 'at-123');

      // #753 — the real parse prefixes the numeric upstream id with `at-`.
      expect(s.id, 'at-123');
      expect(s.name, 'OMV Wien Ring');
      expect(s.brand, 'OMV');
      expect(s.street, 'Ringstraße 1');
      expect(s.postCode, '1010');
      expect(s.place, 'Wien');
      expect(s.lat, closeTo(48.2, 0.001));
      expect(s.lng, closeTo(16.37, 0.001));
      expect(s.diesel, closeTo(1.659, 0.001));
      // Austrian "Super 95" maps to both E5 and E10.
      expect(s.e5, closeTo(1.549, 0.001));
      expect(s.e10, closeTo(1.549, 0.001));
      expect(s.isOpen, isTrue);
    });

    test('respects the open=false flag from the payload', () async {
      final s = (await searchEcontrolStations([omvWien(open: false)]))
          .firstWhere((s) => s.id == 'at-123');
      expect(s.isOpen, isFalse);
    });

    test('extracts known Austrian brands from the station name', () async {
      Future<String> brandOf(String name) async {
        final rec = omvWien(id: '9')..['name'] = name;
        final s = (await searchEcontrolStations([rec]))
            .firstWhere((s) => s.id == 'at-9');
        return s.brand;
      }

      expect(await brandOf('Shell Austria Linz'), 'Shell');
      expect(await brandOf('BP Wien Mitte'), 'BP');
      expect(await brandOf('AVANTI - Salzburg'), 'Avanti');
      expect(await brandOf('Turmöl Graz'), 'Turmöl');
      // Unknown brand → first word.
      expect(await brandOf('UnknownBrand Station'), 'UnknownBrand');
    });

    test('a station present in only one fuel query still appears once',
        () async {
      // DIE has station 200, SUP has station 300 — both must survive the merge.
      final stations = await searchEcontrolStations(
        [omvWien(id: '200', amount: 1.699)],
        superRecords: [omvWien(id: '300', amount: 1.519)],
      );
      final ids = stations.map((s) => s.id).toSet();
      expect(ids, containsAll(<String>['at-200', 'at-300']));

      final dieselOnly = stations.firstWhere((s) => s.id == 'at-200');
      expect(dieselOnly.diesel, closeTo(1.699, 0.001));
      expect(dieselOnly.e5, isNull);

      final superOnly = stations.firstWhere((s) => s.id == 'at-300');
      expect(superOnly.e5, closeTo(1.519, 0.001));
      expect(superOnly.e10, closeTo(1.519, 0.001));
      expect(superOnly.diesel, isNull);
    });

    test('GAS-less payload yields no cng/lpg (only DIE+SUP are queried)',
        () async {
      final s = (await searchEcontrolStations([omvWien()]))
          .firstWhere((s) => s.id == 'at-123');
      // The real service only queries DIE + SUP, never GAS.
      expect(s.cng, isNull);
      expect(s.lpg, isNull);
    });

    test('a GAS row maps to cng, never lpg — E-Control GAS is CNG (#3196)',
        () {
      final s = EControlStationService()
          .parseStationForTest(omvWien(amount: 1.234), 48.2, 16.37, 'GAS');
      expect(s, isNotNull);
      expect(s!.cng, closeTo(1.234, 0.001),
          reason: "E-Control's GAS fuel type is CNG (Erdgas), not LPG");
      expect(s.lpg, isNull);
      expect(s.e5, isNull);
      expect(s.diesel, isNull);
    });

    test('search result carries the E-Control source', () async {
      // Drive the service directly to assert ServiceResult metadata.
      final dio = Dio()
        ..httpClientAdapter =
            FixedJsonAdapter(jsonEncode([omvWien()]));
      final result = await EControlStationService(dio: dio).searchStations(
        const SearchParams(lat: 48.2, lng: 16.37, radiusKm: 10.0),
      );
      expect(result.source, ServiceSource.eControlApi);
      expect(result.data, isA<List<Station>>());
    });
  });

  // #2181 — Dio is injectable; assert a passed Dio is actually used for
  // outbound requests (the seam that lets request shape be tested).
  group('Dio injection (#2181)', () {
    test('routes requests through the injected Dio to the e-control endpoint',
        () async {
      final adapter = _RecordingAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      await EControlStationService(dio: dio).searchStations(
        const SearchParams(lat: 48.2, lng: 16.37, radiusKm: 10.0),
      );

      expect(adapter.requestUris, isNotEmpty);
      expect(
        adapter.requestUris.every((u) => u.contains('api.e-control.at')),
        isTrue,
        reason: 'all requests must go through the injected Dio',
      );
    });
  });
}

/// Minimal [HttpClientAdapter] that records request URIs and returns an empty
/// JSON array, so the injection seam can be asserted without a live call.
class _RecordingAdapter implements HttpClientAdapter {
  final List<String> requestUris = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestUris.add(options.uri.toString());
    return ResponseBody.fromString(
      jsonEncode(<dynamic>[]),
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
