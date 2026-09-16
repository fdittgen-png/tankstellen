// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Denmark against the shared provider contract (#4157, #4180).
///
/// Drives the REAL [DenmarkStationService] over the recorded OK and Shell
/// brand feeds (`dk_ok_prices_slice.json` / `dk_shell_prices_slice.json`,
/// captured 2026-06-10 from mobility-prices.ok.dk and
/// shellpumpepriser.geoapp.me, #3187; street names redacted, structure
/// untouched). Q8 makes no request — it publishes no coordinates. Prices
/// are DKK, checked against the DKK row of the per-currency range.
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
    stations = await searchDenmarkStations(
      okBody: File('test/fixtures/dk_ok_prices_slice.json').readAsStringSync(),
      shellBody:
          File('test/fixtures/dk_shell_prices_slice.json').readAsStringSync(),
      // Between Copenhagen and Odense; wide enough for both slices.
      params: const SearchParams(lat: 55.4, lng: 11.5, radiusKm: 200),
    );
  });

  runStationServiceContract(
    countryCode: 'DK',
    stationsOf: () => stations,
    now: DateTime.utc(2026, 12, 31),
  );
}
