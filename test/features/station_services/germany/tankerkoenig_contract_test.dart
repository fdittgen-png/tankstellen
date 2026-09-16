// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Germany against the shared provider contract (#4157, #4180).
///
/// Drives the REAL [TankerkoenigStationService] over the recorded Berlin
/// `list.php` slice (`de_tankerkoenig_list_slice.json`, #3197). The
/// recording was taken with the public demo key, which serves the real
/// field layout but pins every price to 1.009 — so the price checks here
/// prove shape and range, not market plausibility.
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
    stations = await searchGermanyStations(
      File('test/fixtures/de_tankerkoenig_list_slice.json').readAsStringSync(),
      // The recorded `list.php?lat=52.52&lng=13.405&rad=3` query.
      params: const SearchParams(lat: 52.52, lng: 13.405, radiusKm: 3),
    );
  });

  runStationServiceContract(
    countryCode: 'DE',
    stationsOf: () => stations,
    now: DateTime.utc(2026, 12, 31),
  );
}
