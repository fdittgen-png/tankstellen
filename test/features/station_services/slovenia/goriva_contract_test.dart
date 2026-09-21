// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// Slovenia against the shared provider contract (#4157, #4180).
///
/// Drives the REAL [SloveniaStationService] over the recorded goriva.si
/// search slice (`si_goriva_search_slice.json`, captured 2026-06-10 around
/// Ljubljana, #3196). SI declares `openingHours: false` — its hours are
/// free text — so the contract checks no structured schedule leaks out.
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
    stations = await searchSloveniaStations(
      File('test/fixtures/si_goriva_search_slice.json').readAsStringSync(),
      // Ljubljana centre — where the slice was recorded.
      params: const SearchParams(lat: 46.0569, lng: 14.5058, radiusKm: 10),
    );
  });

  runStationServiceContract(
    countryCode: 'SI',
    stationsOf: () => stations,
    now: DateTime.utc(2026, 12, 31),
  );
}
