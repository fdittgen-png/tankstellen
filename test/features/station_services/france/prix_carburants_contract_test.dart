// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// France against the shared provider contract (#4157, #4180).
///
/// Drives the REAL [PrixCarburantsStationService] over the recorded
/// distance-ordered Paris corridor (`prix_carburants_paris_geo_ordered.json`,
/// a live data.economie.gouv.fr Opendatasoft v2.1 capture, #2966). FR claims
/// the most of any country — hours, amenities and per-price stamps — so it
/// is the country where the contract has the most to catch.
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
    stations = await searchFranceStations(
      File('test/fixtures/prix_carburants_paris_geo_ordered.json')
          .readAsStringSync(),
      // The point the corridor was recorded around.
      params: const SearchParams(lat: 48.8566, lng: 2.3522, radiusKm: 10),
    );
  });

  runStationServiceContract(
    countryCode: 'FR',
    stationsOf: () => stations,
    now: DateTime.utc(2026, 12, 31),
  );
}
