// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Italy against the shared provider contract (#4157, #4180, #4309).
///
/// Drives the REAL [MiseStationService] over the recorded MIMIT CSV slices
/// (`it_anagrafica_slice.csv` + `it_prezzo_slice.csv`, captured 2026-06-10,
/// operator names anonymized, #3188). IT declares `priceTimestamp: true`,
/// so the full `dtComu` stamp must reach `priceUpdatedAt` (#4309).
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
    stations = await searchItalyStations(
      anagraficaCsv:
          File('test/fixtures/it_anagrafica_slice.csv').readAsStringSync(),
      prezzoCsv: File('test/fixtures/it_prezzo_slice.csv').readAsStringSync(),
      // Centre of Italy, wide enough for the whole slice (Lombardy → Sicily).
      params: const SearchParams(lat: 41.9, lng: 12.5, radiusKm: 700),
    );
  });

  runStationServiceContract(
    countryCode: 'IT',
    stationsOf: () => stations,
    now: DateTime.utc(2026, 12, 31),
  );
}
