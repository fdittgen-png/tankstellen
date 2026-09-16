// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Luxembourg against the shared provider contract (#4157, #4180).
///
/// Drives the REAL [LuxembourgStationService] over the unmodified LUSTAT
/// SDMX responses (`lu_lustat_essence_slice.json` /
/// `lu_lustat_diesel_slice.json`, recorded live 2026-06-10, #3195).
///
/// LU publishes one regulated national price and no stations; the service
/// stands in city centroids, which the capability declares
/// (`coordinates: false`).
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
    stations = await searchLuxembourgStations(
      essenceBody:
          File('test/fixtures/lu_lustat_essence_slice.json').readAsStringSync(),
      dieselBody:
          File('test/fixtures/lu_lustat_diesel_slice.json').readAsStringSync(),
      // Luxembourg-Ville, wide enough for every centroid.
      params: const SearchParams(lat: 49.6116, lng: 6.1319, radiusKm: 50),
    );
  });

  runStationServiceContract(
    countryCode: 'LU',
    stationsOf: () => stations,
    now: DateTime.utc(2026, 12, 31),
    exemptions: const {ContractExemption.syntheticCoordinates},
  );
}
