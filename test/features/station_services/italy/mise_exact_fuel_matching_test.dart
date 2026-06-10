// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3188 — Italy exact fuel-name matching, driven by RECORDED REAL CSV slices
// (test/fixtures/it_anagrafica_slice.csv / it_prezzo_slice.csv, captured
// 2026-06-10 from mimit.gov.it, operator names anonymized).
//
// The live prezzo_alle_8.csv carries ~12k premium rows ("Blue Diesel",
// "Gasolio speciale", "Diesel Shell V Power", …). The old
// `contains('benzina')` / `contains('gasolio')||contains('diesel')` matcher
// mis-slotted them into the REGULAR price slots (a premium self-service row
// filled the empty `gasolioSelf` while regular Gasolio was served-only, so
// the self-preferring display showed the premium price as regular diesel)
// and dropped them otherwise. These tests drive the REAL
// [MiseStationService.searchStations] over the recorded payloads (the #2776
// lesson: never assert against a parser copy).

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/station_services/italy/mise_station_service.dart';

/// Routes the MIMIT registry and price CSV URLs to their recorded bodies.
class _MiseCsvAdapter implements HttpClientAdapter {
  _MiseCsvAdapter({required this.anagrafica, required this.prezzo});
  final String anagrafica;
  final String prezzo;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.uri.path;
    final body = path.contains('anagrafica')
        ? anagrafica
        : path.contains('prezzo')
            ? prezzo
            : null;
    if (body == null) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.unknown,
        error: 'no recorded route for ${options.uri}',
      );
    }
    return ResponseBody.fromString(body, 200, headers: {
      'content-type': ['text/csv'],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late List<Station> stations;

  setUpAll(() async {
    final anagrafica =
        File('test/fixtures/it_anagrafica_slice.csv').readAsStringSync();
    final prezzo = File('test/fixtures/it_prezzo_slice.csv').readAsStringSync();
    final dio = Dio(BaseOptions(responseType: ResponseType.plain))
      ..httpClientAdapter =
          _MiseCsvAdapter(anagrafica: anagrafica, prezzo: prezzo);
    final service = MiseStationService(dio: dio);
    // Centre of Italy with a radius wide enough to cover the recorded slice
    // (Lombardy/Veneto down to Sicily).
    final result = await service.searchStations(
      const SearchParams(lat: 41.9, lng: 12.5, radiusKm: 700),
    );
    stations = result.data;
  });

  Station byId(String id) => stations.singleWhere((s) => s.id == id);

  group('IT exact fuel matching (#3188)', () {
    test(
        'a premium self-service diesel row never fills the regular slot when '
        'regular Gasolio is served-only (recorded station 59849)', () {
      // 59849: Benzina 2.094/1.884, Gasolio SERVED-only 2.245,
      // Blue Super 2.049/1.839, Blue Diesel 2.345/2.135.
      final s = byId('it-59849');
      expect(s.diesel, closeTo(2.245, 0.0001),
          reason: 'regular diesel must be the Gasolio price; the old matcher '
              'let the Blue Diesel self row (2.135) fill gasolioSelf');
      expect(s.dieselPremium, closeTo(2.135, 0.0001),
          reason: 'Blue Diesel (self-preferred) must land in dieselPremium');
      expect(s.e98, closeTo(1.839, 0.0001),
          reason: 'Blue Super (self-preferred) must land in e98');
      expect(s.e5, closeTo(1.884, 0.0001));
    });

    test(
        'a station with ONLY premium diesel leaves regular diesel null '
        '(recorded station 6262, Gasolio speciale only)', () {
      final s = byId('it-6262');
      expect(s.diesel, isNull,
          reason: 'Gasolio speciale must never substitute for regular '
              'Gasolio');
      expect(s.dieselPremium, closeTo(2.039, 0.0001));
      expect(s.e5, closeTo(1.899, 0.0001));
    });

    test('Diesel Shell V Power routes to dieselPremium (recorded 4384)', () {
      final s = byId('it-4384');
      expect(s.dieselPremium, closeTo(2.239, 0.0001));
      // 'Gasolio Artico Igloo' is an UNKNOWN name — it must fall through
      // unmapped, never into the regular slot.
      expect(s.diesel, isNull);
      expect(s.lpg, closeTo(0.789, 0.0001));
    });

    test('Blue Diesel premium alongside regular Gasolio (recorded 59183)', () {
      final s = byId('it-59183');
      expect(s.diesel, closeTo(2.039, 0.0001));
      expect(s.dieselPremium, closeTo(2.139, 0.0001));
    });

    test('plain Benzina/Gasolio stations are unaffected (recorded 23778)', () {
      final s = byId('it-23778');
      expect(s.e5, closeTo(1.885, 0.0001));
      expect(s.diesel, closeTo(1.979, 0.0001));
      expect(s.dieselPremium, isNull);
      expect(s.e98, isNull);
    });
  });

  group('IT code-like Nome Impianto fallback (#3188)', () {
    test('numeric-code name "03674" falls back to the brand (recorded 59849)',
        () {
      final s = byId('it-59849');
      expect(s.name, 'Agip Eni',
          reason: 'a code-like Nome Impianto is no station name — the brand '
              'fallback must fire');
    });

    test('letters+digits code "AG021" falls back to the brand (recorded 49195)',
        () {
      expect(byId('it-49195').name, 'Q8');
    });

    test('"19829 AGRIGENTO" (code + comune) falls back (recorded 59183)', () {
      expect(byId('it-59183').name, 'Agip Eni');
    });

    test('real names are kept (recorded 23778, 4384, 6262)', () {
      expect(byId('it-23778').name, 'Stazione Via Imera Ag');
      expect(byId('it-4384').name, 'SHELL STAZIONE BS');
      expect(byId('it-6262').name, 'STAZIONE QUINTO');
    });
  });
}
