// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Portugal against the shared provider contract (#4157, #4180).
///
/// Drives the REAL [PortugalStationService] over the recorded DGEG
/// `PesquisarPostos` slice (`pt_dgeg_postos_slice.json`, captured
/// 2026-06-10, #3196): stations 93086 (Odivelas) and 94406 (V.N. de
/// Famalicão), one row per fuel. The radius spans both, so the per-`Id`
/// merge and the duplicate check see more than one station.
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
    stations = await searchPortugalStations(
      File('test/fixtures/pt_dgeg_postos_slice.json').readAsStringSync(),
      // Between Lisbon and Braga — both recorded stations are in range.
      params: const SearchParams(lat: 40.1, lng: -8.8, radiusKm: 250),
    );
  });

  runStationServiceContract(
    countryCode: 'PT',
    stationsOf: () => stations,
    now: DateTime.utc(2026, 12, 31),
  );
}
