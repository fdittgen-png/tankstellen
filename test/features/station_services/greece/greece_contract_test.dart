// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Greece against the shared provider contract (#4157, #4180).
///
/// Drives the REAL [GreeceStationService] over its production PRIMARY
/// source: `gr_selfpublished_latest.json`, the actual output of
/// `tool/gr_fuel/publish_gr_fuel.py` run 2026-07-14 against the live
/// ministry bulletins (#3549), verified equal to the mirror for the same
/// day. The clock is the day after the newest bulletin, so the asset is
/// fresh and no mirror request is made (none is recorded — one would fail).
///
/// Greece is prefecture-level: every "station" is a synthetic prefecture
/// pin, which the capability already declares (`coordinates: false`).
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
    stations = await searchGreeceStations(
      File('test/fixtures/gr_selfpublished_latest.json').readAsStringSync(),
      // Athens; the service surfaces the four nearest prefectures.
      params: const SearchParams(lat: 37.9838, lng: 23.7275, radiusKm: 200),
      now: DateTime(2026, 7, 14),
    );
  });

  runStationServiceContract(
    countryCode: 'GR',
    stationsOf: () => stations,
    now: DateTime.utc(2026, 12, 31),
    exemptions: const {ContractExemption.syntheticCoordinates},
  );
}
