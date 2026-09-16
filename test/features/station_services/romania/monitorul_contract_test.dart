// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Romania against the shared provider contract (#4157, #4180, #4309).
///
/// Drives the REAL [RomaniaStationService] over the recorded Monitorul
/// Prețurilor slices (captured live 2026-06-10 around Bucharest, #3193):
/// catalog product 11 (benzină standard) and 21 (motorină standard).
/// Products 12, 22 and 31 were not recorded; they get the hand-written
/// no-rows envelope (see `monitorulNoRowsEnvelope`), which adds nothing the
/// contract inspects. RO declares `priceTimestamp: true`, so the recorded
/// day-first `updatedate` must reach `priceUpdatedAt` (#4309).
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
    stations = await searchRomaniaStations(
      recordedBodyByProductId: {
        '11': File('test/fixtures/ro_monitorul_benzina_standard_slice.json')
            .readAsStringSync(),
        '21': File('test/fixtures/ro_monitorul_motorina_standard_slice.json')
            .readAsStringSync(),
      },
      emptyProductIds: const {'12', '22', '31'},
      // Bucharest city centre — the point the slices were recorded from.
      params: const SearchParams(lat: 44.43, lng: 26.10, radiusKm: 5),
    );
  });

  runStationServiceContract(
    countryCode: 'RO',
    stationsOf: () => stations,
    now: DateTime.utc(2026, 12, 31),
  );
}
