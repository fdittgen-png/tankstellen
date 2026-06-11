// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/utils/station_extensions.dart';
import 'package:tankstellen/core/domain/search_params.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/features/station_services/mexico/mexico_station_service.dart';

/// #2717 — Mexican CRE stations must render real PEMEX grade NAMES
/// (Magna / Premium) instead of the European E5 / E98 codes that the
/// physically-correct #2704 mapping (regular→e5, premium→e98) produces.
///
/// Reuse-fidelity: this drives the REAL [MexicoStationService] XML parser
/// against the real CRE wire shape (`<gas_price type="regular|premium|
/// diesel">`), then asserts at the [fuelDisplayLabel] layer — never a
/// request-echoing fake. The underlying e5/e98/diesel slots are exercised
/// exhaustively by mexico_station_service_test.dart; this file owns only
/// the label seam.

/// Fake HTTP adapter that maps request URLs to canned XML responses.
class _FakeCreAdapter implements HttpClientAdapter {
  _FakeCreAdapter({required this.responses});

  final Map<String, String> responses;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = responses[options.uri.toString()];
    if (body == null) {
      return ResponseBody.fromString('not mapped', 404);
    }
    return ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: ['application/xml; charset=utf-8'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _placesUrl = 'https://fake.cre/publicaciones/places';
const _pricesUrl = 'https://fake.cre/publicaciones/prices';

MexicoStationService _serviceWith({
  required String placesXml,
  required String pricesXml,
}) {
  final adapter = _FakeCreAdapter(responses: {
    _placesUrl: placesXml,
    _pricesUrl: pricesXml,
  });
  final dio = Dio()..httpClientAdapter = adapter;
  return MexicoStationService(
    dio: dio,
    baseUrl: 'https://fake.cre/publicaciones',
  );
}

const _cdmxParams = SearchParams(lat: 19.43, lng: -99.13, radiusKm: 10);

void main() {
  group('fuelDisplayLabel — Mexico PEMEX grade names (#2717)', () {
    test(
        'a station parsed by the REAL MexicoStationService renders Magna / '
        'Premium; diesel + other countries fall through unchanged', () async {
      // Build the REAL CRE wire shape and parse it with the REAL service.
      const placesXml = '<?xml version="1.0" encoding="utf-8"?>\n'
          '<places>'
          '<place place_id="11702">'
          '<name>TRENOGAS SA DE CV</name>'
          '<location><x>-99.13</x><y>19.43</y></location>'
          '</place>'
          '</places>';
      const pricesXml = '<?xml version="1.0" encoding="utf-8"?>\n'
          '<places>'
          '<place place_id="11702">'
          '<gas_price type="regular">22.95</gas_price>'
          '<gas_price type="premium">24.89</gas_price>'
          '<gas_price type="diesel">23.45</gas_price>'
          '</place>'
          '</places>';

      final result = await _serviceWith(
        placesXml: placesXml,
        pricesXml: pricesXml,
      ).searchStations(_cdmxParams);

      expect(result.data, hasLength(1));
      final station = result.data.first;
      // Sanity: the #2704 mapping holds (regular→e5, premium→e98).
      expect(station.id, 'mx-11702');
      expect(station.e5, 22.95);
      expect(station.e98, 24.89);
      expect(station.diesel, 23.45);

      // Country resolved from the station id exactly as the call sites do.
      final cc = Countries.countryCodeForStationId(station.id);
      expect(cc, 'MX');

      // The label seam: e5→Magna, e98→Premium.
      expect(fuelDisplayLabel(FuelType.e5, countryCode: cc), 'Magna');
      expect(fuelDisplayLabel(FuelType.e98, countryCode: cc), 'Premium');

      // Diesel is NOT a PEMEX-renamed grade — falls through to the code.
      expect(
        fuelDisplayLabel(FuelType.diesel, countryCode: cc),
        shortFuelLabel(FuelType.diesel),
      );
    });

    test('cross-country guard — DE / FR never see Magna or Premium', () {
      for (final cc in ['DE', 'FR']) {
        expect(
          fuelDisplayLabel(FuelType.e5, countryCode: cc),
          shortFuelLabel(FuelType.e5),
          reason: '$cc e5 must stay the European code',
        );
        expect(
          fuelDisplayLabel(FuelType.e98, countryCode: cc),
          shortFuelLabel(FuelType.e98),
          reason: '$cc e98 must stay the European code',
        );
      }
    });

    test('null-country guard — falls through to shortFuelLabel', () {
      expect(
        fuelDisplayLabel(FuelType.e5, countryCode: null),
        shortFuelLabel(FuelType.e5),
      );
      expect(
        fuelDisplayLabel(FuelType.e98, countryCode: null),
        shortFuelLabel(FuelType.e98),
      );
    });

    test('MX only renames e5/e98 — every other grade keeps its code', () {
      const cc = 'MX';
      for (final fuel in [
        FuelType.e10,
        FuelType.diesel,
        FuelType.dieselPremium,
        FuelType.e85,
        FuelType.lpg,
        FuelType.cng,
        FuelType.hydrogen,
        FuelType.electric,
      ]) {
        expect(
          fuelDisplayLabel(fuel, countryCode: cc),
          shortFuelLabel(fuel),
          reason: '${fuel.apiValue} is not a PEMEX-renamed grade',
        );
      }
    });
  });
}
