// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/core/domain/search_params.dart';
import 'package:tankstellen/features/station_services/france/prix_carburants_flux_parser.dart'
    as flux;
import 'package:tankstellen/features/station_services/france/prix_carburants_parsers.dart'
    as parser;
import 'package:tankstellen/features/station_services/france/prix_carburants_flux_station_service.dart';

/// #2277 — the FR *flux instantané* bulk-file path: download the whole-country
/// ZIP once, parse (ZIP → XML → Station), persist, local-filter. Covers
/// bulk-parse, results-preserved (same fuel→field mapping + `fr-` ids as the
/// legacy JSON parser), download-once, and the empty-result / error contract.

/// A minimal flux XML doc. Coordinates are GeoDecimal × 100000; prix valeur in
/// euros; the documented fuel names map onto the same Station fields the legacy
/// JSON parser uses.
String _fluxXml(List<Map<String, dynamic>> pdvs) {
  final buf = StringBuffer('<?xml version="1.0" encoding="UTF-8"?>\n<pdv_liste>');
  for (final p in pdvs) {
    buf.write('<pdv id="${p['id']}" '
        'latitude="${p['lat']}" longitude="${p['lng']}" '
        'cp="${p['cp'] ?? ''}" pop="${p['pop'] ?? 'R'}">');
    buf.write('<adresse>${p['adresse'] ?? ''}</adresse>');
    buf.write('<ville>${p['ville'] ?? ''}</ville>');
    final prices = (p['prices'] as Map<String, dynamic>? ?? {});
    prices.forEach((nom, valeur) {
      buf.write('<prix nom="$nom" valeur="$valeur" '
          'maj="2026-05-29T08:00:00+00:00"/>');
    });
    // #2710 — optional opening-hours block, mirroring the real gouv.fr flux
    // schema: `<horaires automate-24-24="0"><jour nom="Lundi"><horaire
    // ouverture="07.00" fermeture="18.30"/></jour>...</horaires>`. `hours` is
    // `automate?,List<(nom, ouverture, fermeture)>`.
    if (p['hours'] != null) {
      final hours = p['hours'] as Map<String, dynamic>;
      final automate = hours['automate'] as bool? ?? false;
      buf.write('<horaires automate-24-24="${automate ? '1' : '0'}">');
      final jours = hours['jours'] as List<dynamic>? ?? const [];
      for (final j in jours) {
        final row = j as List<dynamic>;
        buf.write('<jour nom="${row[0]}"><horaire '
            'ouverture="${row[1]}" fermeture="${row[2]}"/></jour>');
      }
      buf.write('</horaires>');
    }
    buf.write('</pdv>');
  }
  buf.write('</pdv_liste>');
  return buf.toString();
}

/// Zip the flux XML the way the real flux ZIP is shaped: a single inner XML.
Uint8List _fluxZip(String xml) {
  final archive = Archive()
    ..addFile(
      ArchiveFile.bytes(
        'PrixCarburants_instantane.xml',
        utf8.encode(xml),
      ),
    );
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

/// Serves the same ZIP bytes for every request and counts downloads.
class _ZipAdapter implements HttpClientAdapter {
  final Uint8List bytes;
  int requestCount = 0;

  _ZipAdapter(this.bytes);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestCount++;
    return ResponseBody.fromBytes(
      bytes,
      200,
      headers: {
        Headers.contentTypeHeader: ['application/zip'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Serves a network error for every request.
class _FailingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
      error: 'offline',
    );
  }

  @override
  void close({bool force = false}) {}
}

// 120 RUE LECLERC, Castelnau — lat 43.45, lng 3.52 (×100000 in the flux).
Map<String, dynamic> _pdv({
  required String id,
  required double lat,
  required double lng,
  String adresse = '120 RUE LECLERC',
  String ville = 'CASTELNAU',
  String cp = '34290',
  Map<String, dynamic>? prices,
}) =>
    {
      'id': id,
      'lat': (lat * 100000).round(),
      'lng': (lng * 100000).round(),
      'adresse': adresse,
      'ville': ville,
      'cp': cp,
      'prices': prices ??
          {
            'SP95': 1.879,
            'E10': 1.799,
            'SP98': 1.929,
            'Gazole': 1.659,
            'E85': 0.899,
            'GPLc': 0.999,
          },
    };

const _castelnau = SearchParams(lat: 43.45, lng: 3.52, radiusKm: 10);

void main() {
  group('prix_carburants_flux_parser (pure XML)', () {
    test('parses a pdv: coords ÷100000, fuel names → Station fields, fr- id',
        () {
      final stations = flux.parseFluxXml(_fluxXml([
        _pdv(id: '34200002', lat: 43.45, lng: 3.52),
      ]));

      expect(stations, hasLength(1));
      final s = stations.first;
      expect(s.id, 'fr-34200002');
      expect(s.lat, closeTo(43.45, 0.0001));
      expect(s.lng, closeTo(3.52, 0.0001));
      expect(s.street, '120 RUE LECLERC');
      expect(s.postCode, '34290');
      expect(s.place, 'CASTELNAU');
      // Same fuel→field mapping as the legacy JSON parser.
      expect(s.e5, closeTo(1.879, 0.0001)); // SP95
      expect(s.e10, closeTo(1.799, 0.0001)); // E10
      expect(s.e98, closeTo(1.929, 0.0001)); // SP98
      expect(s.diesel, closeTo(1.659, 0.0001)); // Gazole
      expect(s.e85, closeTo(0.899, 0.0001)); // E85
      expect(s.lpg, closeTo(0.999, 0.0001)); // GPLc
      expect(s.updatedAt, contains('29/05'));
    });

    test('autoroute brand when pop=A', () {
      final xml = _fluxXml([
        {
          'id': '1',
          'lat': 4345000,
          'lng': 352000,
          'adresse': 'AIRE',
          'ville': '',
          'cp': '',
          'pop': 'A',
          'prices': {'Gazole': 1.7},
        },
      ]);
      expect(flux.parseFluxXml(xml).first.brand, 'Autoroute');
    });

    test(
        '#3198 — flux path detects chain brands from adresse/ville like '
        'the JSON path (no more path-dependent brand)', () {
      final xml = _fluxXml([
        _pdv(id: '11', lat: 43.45, lng: 3.52, adresse: 'CC CARREFOUR RN 113'),
        _pdv(id: '12', lat: 43.46, lng: 3.53, adresse: 'AVENUE TOTALENERGIES'),
        _pdv(id: '13', lat: 43.47, lng: 3.54, adresse: '1 RUE DES FLEURS',
            ville: 'PAU'),
      ]);
      final byId = {for (final s in flux.parseFluxXml(xml)) s.id: s};
      // Same substring map the legacy JSON path uses
      // (detectPrixCarburantsBrand) — and the same value it would return.
      expect(byId['fr-11']!.brand, 'Carrefour');
      expect(byId['fr-11']!.brand,
          parser.detectPrixCarburantsBrand('CC CARREFOUR RN 113', null,
              <String, dynamic>{'ville': 'CASTELNAU'}));
      expect(byId['fr-12']!.brand, 'TotalEnergies');
      // Genuinely unbranded stays the #482 Independent sentinel.
      expect(byId['fr-13']!.brand, 'Independent');
    });

    test('skips a pdv with no/zero coordinates', () {
      final xml = _fluxXml([
        {'id': 'BAD', 'lat': 0, 'lng': 0, 'prices': {'SP95': 1.8}},
      ]);
      expect(flux.parseFluxXml(xml), isEmpty);
    });

    test('thousandths fallback: valeur 1659 → 1.659', () {
      final xml = _fluxXml([
        _pdv(id: '5', lat: 43.45, lng: 3.52, prices: {'Gazole': 1659}),
      ]);
      expect(flux.parseFluxXml(xml).first.diesel, closeTo(1.659, 0.0001));
    });

    test('returns empty on malformed XML rather than throwing', () {
      expect(flux.parseFluxXml('<not-closed'), isEmpty);
    });

    test('parseFluxZip: ZIP bytes → stations end-to-end', () {
      final zip = _fluxZip(_fluxXml([_pdv(id: '9', lat: 43.45, lng: 3.52)]));
      final stations = flux.parseFluxZip(zip);
      expect(stations, hasLength(1));
      expect(stations.first.id, 'fr-9');
    });

    test('omits opening hours when the pdv carries no <horaires> (#2710)', () {
      final s = flux.parseFluxXml(_fluxXml([
        _pdv(id: '34200002', lat: 43.45, lng: 3.52),
      ])).first;
      expect(s.openingHoursText, isNull);
      expect(s.is24h, isFalse);
    });

    test('flattens <horaires> into the legacy openingHoursText (#2710)', () {
      final s = flux.parseFluxXml(_fluxXml([
        {
          'id': '34200002',
          'lat': 4345000,
          'lng': 352000,
          'adresse': '120 RUE LECLERC',
          'ville': 'CASTELNAU',
          'cp': '34290',
          'prices': {'SP95': 1.879},
          'hours': {
            'automate': false,
            'jours': [
              ['Lundi', '07.00', '18.30'],
              // split shift: same day, two <jour> rows
              ['Mardi', '08.00', '12.00'],
              ['Mardi', '14.00', '19.00'],
            ],
          },
        },
      ])).first;

      // Legacy text reads like the polling path — day un-glued, `.`→`:`.
      expect(s.openingHoursText, contains('Lundi 07:00-18:30'));
      expect(s.openingHoursText, isNot(contains('Lundi07')));
      expect(s.is24h, isFalse);
    });

    test('automate-24-24="1" sets is24h on the flux Station (#2710)', () {
      final s = flux.parseFluxXml(_fluxXml([
        {
          'id': '7',
          'lat': 4345000,
          'lng': 352000,
          'prices': {'Gazole': 1.7},
          'hours': {
            'automate': true,
            'jours': [
              ['Lundi', '07.00', '18.30'],
            ],
          },
        },
      ])).first;
      expect(s.is24h, isTrue);
    });
  });

  group('PrixCarburantsFluxStationService', () {
    Dio dioWith(Uint8List bytes) =>
        Dio()..httpClientAdapter = _ZipAdapter(bytes);

    test('implements StationService', () {
      expect(PrixCarburantsFluxStationService(), isA<StationService>());
    });

    test('default ZIP URL targets the gouv.fr flux instantané', () {
      expect(
        PrixCarburantsFluxStationService.defaultZipUrl,
        contains('donnees.roulez-eco.fr/opendata/instantane'),
      );
    });

    test('downloads the ZIP and local-filters by radius', () async {
      final zip = _fluxZip(_fluxXml([
        _pdv(id: 'NEAR', lat: 43.45, lng: 3.52),
        // ~600 km away — well outside a 10 km radius.
        _pdv(id: 'FAR', lat: 48.85, lng: 2.35, cp: '75001'),
      ]));
      final svc = PrixCarburantsFluxStationService(dio: dioWith(zip));

      final result = await svc.searchStations(_castelnau);
      expect(result.source, ServiceSource.prixCarburantsApi);
      expect(result.data, hasLength(1));
      expect(result.data.first.id, 'fr-NEAR');
    });

    test('downloads ONCE then serves later searches locally (no per-search poll)',
        () async {
      final adapter = _ZipAdapter(
        _fluxZip(_fluxXml([_pdv(id: 'A', lat: 43.45, lng: 3.52)])),
      );
      final svc =
          PrixCarburantsFluxStationService(dio: Dio()..httpClientAdapter = adapter);

      await svc.searchStations(_castelnau);
      await svc.searchStations(_castelnau);
      await svc.searchStations(
        const SearchParams(lat: 43.46, lng: 3.53, radiusKm: 5),
      );

      expect(adapter.requestCount, 1,
          reason: 'one flux download serves every search — never poll per-station');
    });

    test('results PRESERVED: same fuel→field mapping + fr- ids as the parser',
        () async {
      final pdvs = [
        _pdv(id: '1', lat: 43.451, lng: 3.521),
        _pdv(id: '2', lat: 43.452, lng: 3.522),
      ];
      final svc =
          PrixCarburantsFluxStationService(dio: dioWith(_fluxZip(_fluxXml(pdvs))));
      final result = await svc.searchStations(_castelnau);

      final ids = result.data.map((s) => s.id).toSet();
      expect(ids, {'fr-1', 'fr-2'});
      expect(result.data.first.e5, closeTo(1.879, 0.0001));
    });

    test('far-from-France search returns empty (radius contract, not error)',
        () async {
      final zip = _fluxZip(_fluxXml([_pdv(id: 'A', lat: 43.45, lng: 3.52)]));
      final svc = PrixCarburantsFluxStationService(dio: dioWith(zip));

      // Middle of the Pacific.
      final result = await svc.searchStations(
        const SearchParams(lat: 0, lng: -170, radiusKm: 5),
      );
      expect(result.data, isEmpty);
      expect(result.source, ServiceSource.prixCarburantsApi);
    });

    test('network failure with no cached/persisted dataset surfaces an error',
        () async {
      // Fixes the FR empty-result/cache contract: the legacy path swallowed a
      // network error into an empty ServiceResult (so the chain cached nothing
      // and re-hit next search). Here a first-ever-search failure with nothing
      // to serve is surfaced to the chain instead of masked as "no stations".
      final svc = PrixCarburantsFluxStationService(
        dio: Dio()..httpClientAdapter = _FailingAdapter(),
      );
      expect(
        () => svc.searchStations(_castelnau),
        throwsA(isA<Exception>()),
      );
    });

    test(
        '#3152 — search output is unchanged by the off-isolate parse + '
        'filter-before-copy restructure (full characterization)', () async {
      // Mixed fixture: two in-radius stations at distinct distances (so the
      // distance-sort order is observable) + one far outside the radius.
      final zip = _fluxZip(_fluxXml([
        _pdv(id: 'NEAR-2', lat: 43.49, lng: 3.56, prices: {'Gazole': 1.70}),
        _pdv(id: 'NEAR-1', lat: 43.451, lng: 3.521, prices: {'Gazole': 1.65}),
        // Paris — ~600 km away, must never appear in the result.
        _pdv(id: 'FAR', lat: 48.85, lng: 2.35, cp: '75001'),
      ]));
      final svc = PrixCarburantsFluxStationService(dio: dioWith(zip));

      final result = await svc.searchStations(_castelnau);

      // Exactly the in-radius survivors, distance-sorted (default sort).
      expect(result.data.map((s) => s.id).toList(),
          ['fr-NEAR-1', 'fr-NEAR-2']);
      // Each survivor carries the SAME rounded Haversine distance the
      // pre-#3152 copy-then-filter shape stamped (rounded to 1 decimal).
      final near1 = result.data[0];
      final near2 = result.data[1];
      expect(near1.dist, closeTo(0.1, 0.051),
          reason: 'rounded 1-decimal distance must be stamped on survivors');
      expect(near2.dist, greaterThan(near1.dist));
      expect(near2.dist, lessThanOrEqualTo(_castelnau.radiusKm));
      // Prices / fields survive the isolate round-trip untouched.
      expect(near1.diesel, closeTo(1.65, 0.0001));
      expect(near2.diesel, closeTo(1.70, 0.0001));
      expect(result.source, ServiceSource.prixCarburantsApi);
    });

    test('a fresh in-memory dataset serves a later search with no re-download',
        () async {
      // After one successful load the dataset is fresh (within the soft TTL),
      // so a search that would otherwise fail the network never even attempts
      // it — the cached set answers directly.
      final adapter = _ZipAdapter(
        _fluxZip(_fluxXml([_pdv(id: 'A', lat: 43.45, lng: 3.52)])),
      );
      final dio = Dio()..httpClientAdapter = adapter;
      final svc = PrixCarburantsFluxStationService(dio: dio);

      await svc.searchStations(_castelnau);
      // Swap in a failing adapter; the fresh in-memory dataset must answer
      // without touching the network.
      dio.httpClientAdapter = _FailingAdapter();
      final second = await svc.searchStations(_castelnau);
      expect(second.data, hasLength(1));
      expect(adapter.requestCount, 1);
    });
  });
}
