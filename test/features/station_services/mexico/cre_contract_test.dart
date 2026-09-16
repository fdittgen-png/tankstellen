// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Mexico against the shared provider contract (#4157, #4180).
///
/// Drives the REAL [MexicoStationService] over the recorded CRE XML feeds
/// (`mx_cre_places_slice.xml` / `mx_cre_prices_slice.xml`, recorded
/// 2026-06-11 and trimmed to 15 CDMX stations with matching place_ids,
/// structure untouched, #3197). Prices are MXN, checked against the MXN
/// row of the per-currency range.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/search_params.dart';
import 'package:tankstellen/core/domain/station.dart';

import '../contract/station_service_contract.dart';
import '../support/recorded_country_search.dart';

void main() {
  late List<Station> stations;

  setUpAll(() async {
    stations = await searchMexicoStations(
      placesXml:
          File('test/fixtures/mx_cre_places_slice.xml').readAsStringSync(),
      pricesXml:
          File('test/fixtures/mx_cre_prices_slice.xml').readAsStringSync(),
      // CDMX centre — every recorded station sits within ~7 km.
      params: const SearchParams(lat: 19.43, lng: -99.13, radiusKm: 10),
    );
  });

  runStationServiceContract(
    countryCode: 'MX',
    stationsOf: () => stations,
    now: DateTime.utc(2026, 12, 31),
  );
}
