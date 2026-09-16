// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Great Britain against the shared provider contract (#4157, #4180).
///
/// Drives the REAL [UkStationService] — the keyless production path
/// `buildGbStationService` returns — over the recorded ASDA CMA feed
/// (`uk_asda_cma_slice.json`, captured 2026-06-10 around Manchester,
/// #3191), restricted to that one retailer feed.
///
/// NOT the statutory Fuel Finder path: its `uk_fuel_finder_*` fixtures are
/// contract-derived, not recordings (#3190), so they cannot stand in here.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/search_params.dart';
import 'package:tankstellen/core/domain/station.dart';

import '../../../helpers/silence_error_logger.dart';
import '../contract/station_service_contract.dart';
import '../support/recorded_country_search.dart';

void main() {
  silenceErrorLoggerSpool();
  late List<Station> stations;

  setUpAll(() async {
    stations = await searchUkStations(
      File('test/fixtures/uk_asda_cma_slice.json').readAsStringSync(),
      feedUrl: 'https://storelocator.asda.com/fuel_prices_data.json',
      // Manchester — the recorded slice's home.
      params: const SearchParams(lat: 53.48, lng: -2.24, radiusKm: 15),
    );
  });

  runStationServiceContract(
    countryCode: 'GB',
    stationsOf: () => stations,
    now: DateTime.utc(2026, 12, 31),
  );
}
